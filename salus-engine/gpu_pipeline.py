#!/usr/bin/env python3
"""
FULL GPU PIPELINE (Remote Machine)
===================================
One script: Prepare → Generate Synthetic → Merge → Train with Unsloth
Run this on your MassedCompute GPU instance.
"""

import json
import os
import random
import re
import sys
from pathlib import Path

from tqdm import tqdm

# ============================
# CONFIGURATION
# ============================
CHUNKS_FILE = Path("chunks.jsonl")  # Upload this from your T14
MODEL_PATH = "qwen-0.5b.gguf"  # Will be downloaded automatically
OUTPUT_DIR = Path("output")
OUTPUT_DIR.mkdir(exist_ok=True)

DECAGON_SAMPLE = 150_000
TEACHER_SAMPLE = 30_000

# Training config
LORA_R = 32
LORA_ALPHA = 64
LEARNING_RATE = 2e-4
EPOCHS = 45
BATCH_SIZE = 8
MAX_SEQ_LENGTH = 1024

# ============================
# STEP 1: PREPARE DATASETS
# ============================


def prepare_datasets():
    print("\n" + "=" * 60)
    print("STEP 1: PREPARING DATASETS")
    print("=" * 60)

    decagon_out = OUTPUT_DIR / "decagon_instructions.jsonl"
    teacher_out = OUTPUT_DIR / "chunks_for_teacher.jsonl"

    if decagon_out.exists():
        decagon_out.unlink()
    if teacher_out.exists():
        teacher_out.unlink()

    decagon_indices = []
    other_indices = []

    with open(CHUNKS_FILE, "r", encoding="utf-8") as f:
        for idx, line in enumerate(f):
            rec = json.loads(line)
            if rec.get("source") == "decagon":
                decagon_indices.append(idx)
            else:
                other_indices.append(idx)

    print(f"  Total: {len(decagon_indices):,} Decagon, {len(other_indices):,} Other")

    decagon_sample = set(
        random.sample(decagon_indices, min(DECAGON_SAMPLE, len(decagon_indices)))
    )
    teacher_sample = set(
        random.sample(other_indices, min(TEACHER_SAMPLE, len(other_indices)))
    )

    templates = [
        "What adverse effect may result from combining these two drugs?",
        "Describe the drug interaction and its clinical significance.",
        "A patient is co-prescribed these medications. What should be monitored?",
        "Identify the polypharmacy side effect associated with this combination.",
        "What is the risk of hepatotoxicity or other adverse effects when these drugs are taken together?",
        "Summarize the interaction between the two pharmaceutical agents.",
        "Predict the side effect profile of this drug combination.",
        "What happens in the body when these two compounds are administered concurrently?",
    ]

    decagon_count = 0
    teacher_count = 0

    with open(CHUNKS_FILE, "r", encoding="utf-8") as f:
        for idx, line in enumerate(tqdm(f, desc="Processing")):
            rec = json.loads(line)

            if idx in decagon_sample:
                text = rec["text"]
                match = re.match(
                    r"Drug (.+?) combined with Drug (.+?) may cause (.+)\.?", text
                )
                if match:
                    d1, d2, effect = (
                        match.group(1),
                        match.group(2),
                        match.group(3).rstrip("."),
                    )
                else:
                    d1 = d2 = effect = ""

                template = random.choice(templates)
                if random.random() > 0.5 and d1 and d2:
                    instruction = template
                    input_text = f"Drug 1: {d1}\nDrug 2: {d2}"
                    output_text = (
                        f"The combination may cause {effect}." if effect else text
                    )
                else:
                    instruction = (
                        f"{template} Drug {d1} and Drug {d2}."
                        if d1 and d2
                        else template
                    )
                    input_text = ""
                    output_text = text

                with open(decagon_out, "a", encoding="utf-8") as out_f:
                    out_f.write(
                        json.dumps(
                            {
                                "instruction": instruction,
                                "input": input_text,
                                "output": output_text,
                                "source": "decagon",
                                "type": "drug_interaction",
                            },
                            ensure_ascii=False,
                        )
                        + "\n"
                    )
                decagon_count += 1

            elif idx in teacher_sample:
                with open(teacher_out, "a", encoding="utf-8") as out_f:
                    out_f.write(line)
                teacher_count += 1

    print(f"\n  ✓ Decagon instructions: {decagon_count:,}")
    print(f"  ✓ Teacher chunks: {teacher_count:,}")
    return decagon_count, teacher_count


# ============================
# STEP 2: SYNTHETIC GENERATION
# ============================


def generate_synthetic():
    print("\n" + "=" * 60)
    print("STEP 2: SYNTHETIC DATA GENERATION")
    print("=" * 60)

    from llama_cpp import Llama

    teacher_file = OUTPUT_DIR / "chunks_for_teacher.jsonl"
    synth_out = OUTPUT_DIR / "synthetic_instructions.jsonl"

    if not Path(MODEL_PATH).exists():
        print(f"ERROR: Model not found at {MODEL_PATH}")
        print(
            "Download it first: huggingface-cli download Qwen/Qwen2.5-0.5B-Instruct-GGUF"
        )
        sys.exit(1)

    print(f"Loading {MODEL_PATH}...")
    model = Llama(model_path=MODEL_PATH, n_ctx=2048, n_gpu_layers=-1, verbose=False)
    print("✓ Model loaded on GPU\n")

    chunks = []
    with open(teacher_file, "r", encoding="utf-8") as f:
        for line in f:
            chunks.append(json.loads(line))

    qa_prompt = "You are a medical education assistant specializing in hepatology.\nRead the text and generate ONE question and answer.\n\nTEXT:\n{chunk}\n\nQuestion: <question>\nAnswer: <answer>"
    summary_prompt = "Summarize this medical text in 2-3 sentences, focusing on liver disease if mentioned.\n\nTEXT:\n{chunk}\n\nSummary:"
    facts_prompt = "Extract 3 key medical facts as bullet points. Prioritize liver conditions if mentioned.\n\nTEXT:\n{chunk}\n\nFacts:"

    with open(synth_out, "w", encoding="utf-8") as out_f:
        for chunk in tqdm(chunks, desc="Generating"):
            text = chunk["text"]
            if len(text.split()) < 20:
                continue

            # QA
            try:
                out = model(
                    qa_prompt.format(chunk=text),
                    max_tokens=256,
                    temperature=0.3,
                    stop=["</s>", "TEXT:"],
                    echo=False,
                )
                qa_text = out["choices"][0]["text"].strip()
                q = a = ""
                for line in qa_text.split("\n"):
                    if line.lower().startswith("question:"):
                        q = line.split(":", 1)[1].strip()
                    elif line.lower().startswith("answer:"):
                        a = line.split(":", 1)[1].strip()
                if q and a:
                    out_f.write(
                        json.dumps(
                            {
                                "instruction": q,
                                "input": text,
                                "output": a,
                                "source": chunk["source"],
                                "type": "qa_pair",
                            },
                            ensure_ascii=False,
                        )
                        + "\n"
                    )
            except:
                pass

            # Summary
            try:
                out = model(
                    summary_prompt.format(chunk=text),
                    max_tokens=128,
                    temperature=0.3,
                    stop=["</s>", "TEXT:"],
                    echo=False,
                )
                summary = out["choices"][0]["text"].strip()
                if summary and len(summary) > 20:
                    out_f.write(
                        json.dumps(
                            {
                                "instruction": "Summarize the following medical text.",
                                "input": text,
                                "output": summary,
                                "source": chunk["source"],
                                "type": "summary",
                            },
                            ensure_ascii=False,
                        )
                        + "\n"
                    )
            except:
                pass

            # Facts
            try:
                out = model(
                    facts_prompt.format(chunk=text),
                    max_tokens=256,
                    temperature=0.3,
                    stop=["</s>", "TEXT:"],
                    echo=False,
                )
                facts = out["choices"][0]["text"].strip()
                if facts and len(facts) > 20:
                    out_f.write(
                        json.dumps(
                            {
                                "instruction": "Extract key medical facts.",
                                "input": text,
                                "output": facts,
                                "source": chunk["source"],
                                "type": "fact_extraction",
                            },
                            ensure_ascii=False,
                        )
                        + "\n"
                    )
            except:
                pass

            out_f.flush()

    print(f"\n  ✓ Synthetic data saved to {synth_out}")


# ============================
# STEP 3: MERGE
# ============================


def merge_datasets():
    print("\n" + "=" * 60)
    print("STEP 3: MERGING DATASETS")
    print("=" * 60)

    files = [
        OUTPUT_DIR / "decagon_instructions.jsonl",
        OUTPUT_DIR / "synthetic_instructions.jsonl",
    ]
    final = OUTPUT_DIR / "final_training_data.jsonl"

    total = 0
    with open(final, "w", encoding="utf-8") as out_f:
        for filepath in files:
            if not filepath.exists():
                print(f"  WARNING: {filepath} not found, skipping")
                continue
            with open(filepath, "r", encoding="utf-8") as f:
                for line in f:
                    out_f.write(line)
                    total += 1

    print(f"  ✓ Final training set: {total:,} examples")
    print(f"  ✓ Saved to {final}")
    return final


# ============================
# STEP 4: TRAIN WITH UNSLOTH
# ============================


def train_model(final_data_path):
    print("\n" + "=" * 60)
    print("STEP 4: TRAINING WITH UNSLOTH")
    print("=" * 60)

    import torch
    from transformers import TrainingArguments
    from trl import SFTTrainer
    from unsloth import FastLanguageModel

    from datasets import load_dataset

    print("Loading base model...")
    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name="unsloth/Qwen2.5-0.5B-Instruct",
        max_seq_length=MAX_SEQ_LENGTH,
        dtype=torch.bfloat16,
        load_in_4bit=True,
    )

    model = FastLanguageModel.get_peft_model(
        model,
        r=LORA_R,
        target_modules=[
            "q_proj",
            "k_proj",
            "v_proj",
            "o_proj",
            "gate_proj",
            "up_proj",
            "down_proj",
        ],
        lora_alpha=LORA_ALPHA,
        lora_dropout=0,
        bias="none",
        use_gradient_checkpointing="unsloth",
        random_state=3407,
        use_rslora=False,
    )

    # Load dataset
    print("Loading training data...")
    dataset = load_dataset("json", data_files=str(final_data_path), split="train")

    # Format to chat template
    def formatting_prompts_func(examples):
        instructions = examples["instruction"]
        inputs = examples["input"]
        outputs = examples["output"]
        texts = []
        for instruction, input_text, output in zip(instructions, inputs, outputs):
            if input_text:
                prompt = f"<|im_start|>user\n{instruction}\n\n{input_text}<|im_end|>\n<|im_start|>assistant\n{output}<|im_end|>"
            else:
                prompt = f"<|im_start|>user\n{instruction}<|im_end|>\n<|im_start|>assistant\n{output}<|im_end|>"
            texts.append(prompt)
        return {"text": texts}

    dataset = dataset.map(formatting_prompts_func, batched=True)

    print("Starting training...")
    trainer = SFTTrainer(
        model=model,
        tokenizer=tokenizer,
        train_dataset=dataset,
        dataset_text_field="text",
        max_seq_length=MAX_SEQ_LENGTH,
        dataset_num_proc=2,
        packing=False,
        args=TrainingArguments(
            per_device_train_batch_size=BATCH_SIZE,
            gradient_accumulation_steps=4,
            warmup_steps=100,
            num_train_epochs=EPOCHS,
            learning_rate=LEARNING_RATE,
            fp16=not torch.cuda.is_bf16_supported(),
            bf16=torch.cuda.is_bf16_supported(),
            logging_steps=50,
            optim="adamw_8bit",
            weight_decay=0.01,
            lr_scheduler_type="linear",
            seed=3407,
            output_dir="lora_output",
            report_to="none",
        ),
    )

    trainer_stats = trainer.train()
    print(f"\n  Training complete! Final loss: {trainer_stats.training_loss:.4f}")

    # Save
    model.save_pretrained("lora_output/final_model")
    tokenizer.save_pretrained("lora_output/final_model")
    print("  ✓ Model saved to lora_output/final_model/")

    # Merge and save GGUF
    print("\nMerging LoRA weights and saving GGUF...")
    model.save_pretrained_gguf(
        "lora_output/merged_gguf", tokenizer, quantization_method="q4_k_m"
    )
    print("  ✓ GGUF saved to lora_output/merged_gguf/")


# ============================
# MAIN
# ============================


def main():
    print("=" * 60)
    print("FULL MEDICAL SLM PIPELINE")
    print("=" * 60)

    if not CHUNKS_FILE.exists():
        print(f"ERROR: {CHUNKS_FILE} not found. Upload it first.")
        sys.exit(1)

    # Step 1
    prepare_datasets()

    # Step 2
    generate_synthetic()

    # Step 3
    final_path = merge_datasets()

    # Step 4
    train_model(final_path)

    print("\n" + "=" * 60)
    print("ALL DONE!")
    print("Download lora_output/merged_gguf/ back to your T14")
    print("=" * 60)


if __name__ == "__main__":
    main()
