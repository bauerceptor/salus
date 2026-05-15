#!/usr/bin/env python3
"""
Synthetic Medical Instruction Generator v2
============================================
Now reads from chunks_for_teacher.jsonl (the sampled subset).
Generates QA, Summary, and Facts for each chunk.

REQUIREMENTS:
    pip install llama-cpp-python

RUN:
    python generate_synthetic_data.py
"""

import json
import os
from pathlib import Path

from llama_cpp import Llama
from tqdm import tqdm

# ============================
# CONFIGURATION
# ============================
MODEL_PATH = "qwen2.5-0.5b-instruct-fp16.gguf"
CHUNKS_FILE = Path("processed/chunks_for_teacher.jsonl")
OUTPUT_FILE = Path("processed/synthetic_instructions.jsonl")

# Model settings
N_CTX = 2048
N_THREADS = 4
MAX_TOKENS = 512
TEMPERATURE = 0.3
CHECKPOINT_EVERY = 50

# ============================
# PROMPTS
# ============================
QA_PROMPT = """You are a medical education assistant specializing in hepatology and liver diseases.
Read the following medical text carefully. Then generate ONE relevant question and a concise, accurate answer based ONLY on the text provided.

TEXT:
{chunk}

Respond in this exact format:
Question: <your question here>
Answer: <your answer here>"""

SUMMARY_PROMPT = """You are a medical summarizer. Summarize the following medical text in 2-3 sentences. Focus on liver disease, diagnosis, and treatment implications if mentioned.

TEXT:
{chunk}

Summary:"""

FACTS_PROMPT = """Extract the 3 most important medical facts from the following text. List them as bullet points. If the text mentions liver conditions, cirrhosis, hepatitis, or drug effects on the liver, prioritize those.

TEXT:
{chunk}

Facts:"""

# ============================
# HELPERS
# ============================


def load_chunks(filepath):
    chunks = []
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            chunks.append(json.loads(line))
    return chunks


def already_processed_count():
    if not OUTPUT_FILE.exists():
        return 0
    with open(OUTPUT_FILE, "r", encoding="utf-8") as f:
        return sum(1 for _ in f)


def parse_qa_output(text):
    q = ""
    a = ""
    for line in text.strip().split("\n"):
        if line.lower().startswith("question:"):
            q = line.split(":", 1)[1].strip()
        elif line.lower().startswith("answer:"):
            a = line.split(":", 1)[1].strip()
    return q, a


def generate(model, prompt):
    output = model(
        prompt,
        max_tokens=MAX_TOKENS,
        temperature=TEMPERATURE,
        stop=["</s>", "TEXT:", "Question:", "Facts:"],
        echo=False,
    )
    return output["choices"][0]["text"].strip()


# ============================
# MAIN
# ============================


def main():
    print("=" * 60)
    print("SYNTHETIC INSTRUCTION GENERATOR v2")
    print("=" * 60)

    if not Path(MODEL_PATH).exists():
        print(f"ERROR: Model file not found: {MODEL_PATH}")
        return

    print(f"\nLoading model: {MODEL_PATH}...")
    model = Llama(
        model_path=MODEL_PATH, n_ctx=N_CTX, n_threads=N_THREADS, verbose=False
    )
    print("✓ Model loaded.\n")

    print(f"Loading chunks from {CHUNKS_FILE}...")
    chunks = load_chunks(CHUNKS_FILE)
    print(f"✓ Loaded {len(chunks)} chunks.\n")

    start_idx = already_processed_count()
    if start_idx > 0:
        print(f"Resuming from chunk {start_idx}.\n")

    mode = "a" if start_idx > 0 else "w"

    with open(OUTPUT_FILE, mode, encoding="utf-8") as out_f:
        for i in tqdm(
            range(start_idx, len(chunks)), initial=start_idx, total=len(chunks)
        ):
            chunk = chunks[i]
            text = chunk["text"]

            if len(text.split()) < 20:
                continue

            # QA
            try:
                qa_raw = generate(model, QA_PROMPT.format(chunk=text))
                q, a = parse_qa_output(qa_raw)
                if q and a:
                    out_f.write(
                        json.dumps(
                            {
                                "instruction": q,
                                "input": text,
                                "output": a,
                                "source": chunk["source"],
                                "type": "qa_pair",
                                "chunk_id": chunk.get("parent_id", ""),
                            },
                            ensure_ascii=False,
                        )
                        + "\n"
                    )
            except Exception as e:
                print(f"\nQA failed at {i}: {e}")

            # Summary
            try:
                summary = generate(model, SUMMARY_PROMPT.format(chunk=text))
                if summary and len(summary) > 20:
                    out_f.write(
                        json.dumps(
                            {
                                "instruction": "Summarize the following medical text.",
                                "input": text,
                                "output": summary,
                                "source": chunk["source"],
                                "type": "summary",
                                "chunk_id": chunk.get("parent_id", ""),
                            },
                            ensure_ascii=False,
                        )
                        + "\n"
                    )
            except Exception as e:
                print(f"\nSummary failed at {i}: {e}")

            # Facts
            try:
                facts = generate(model, FACTS_PROMPT.format(chunk=text))
                if facts and len(facts) > 20:
                    out_f.write(
                        json.dumps(
                            {
                                "instruction": "Extract key medical facts from the following text.",
                                "input": text,
                                "output": facts,
                                "source": chunk["source"],
                                "type": "fact_extraction",
                                "chunk_id": chunk.get("parent_id", ""),
                            },
                            ensure_ascii=False,
                        )
                        + "\n"
                    )
            except Exception as e:
                print(f"\nFacts failed at {i}: {e}")

            out_f.flush()

            if (i + 1) % CHECKPOINT_EVERY == 0:
                print(f"\n  Checkpoint: {i + 1}/{len(chunks)}\n")

    print("\n" + "=" * 60)
    print("DONE!")
    print(f"Output: {OUTPUT_FILE}")
    print("=" * 60)


if __name__ == "__main__":
    main()
