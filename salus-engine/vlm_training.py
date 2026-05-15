#!/usr/bin/env python3
import os

import numpy as np
import torch
from peft import LoraConfig, get_peft_model
from torch.utils.data import DataLoader, Dataset
from tqdm import tqdm
from transformers import (
    AutoModelForVision2Seq,
    AutoProcessor,
    get_cosine_schedule_with_warmup,
)

from datasets import concatenate_datasets, load_dataset

os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "expandable_segments:True"

MODEL_ID = "HuggingFaceTB/SmolVLM-256M-Instruct"
DATASET_DIR = "./datasets"
OUTPUT_DIR = "./smolvlm-medical-lora"
BATCH_SIZE = 4
GRAD_ACCUM = 4
EPOCHS = 20
LR = 2e-4
WARMUP_STEPS = 50

os.makedirs(OUTPUT_DIR, exist_ok=True)

device = "cuda"
processor = AutoProcessor.from_pretrained(MODEL_ID)
model = AutoModelForVision2Seq.from_pretrained(
    MODEL_ID, torch_dtype=torch.bfloat16, device_map="auto"
)
model.config.use_cache = False
model.gradient_checkpointing_enable()
model.enable_input_require_grads()

model = get_peft_model(
    model,
    LoraConfig(
        r=64,
        lora_alpha=128,
        lora_dropout=0.05,
        bias="none",
        task_type="CAUSAL_LM",
        target_modules=[
            "q_proj",
            "k_proj",
            "v_proj",
            "o_proj",
            "gate_proj",
            "up_proj",
            "down_proj",
        ],
    ),
)
model.print_trainable_parameters()

# Load only SLAKE + VQA-RAD (skip ROCO)
print("Loading datasets...")
ds1 = load_dataset(
    "parquet",
    data_files={
        "train": [
            f"{DATASET_DIR}/slake_train_0.parquet",
            f"{DATASET_DIR}/slake_train_1.parquet",
        ]
    },
)["train"]
ds2 = load_dataset(
    "parquet", data_files={"train": f"{DATASET_DIR}/vqarad_train.parquet"}
)["train"]
raw = concatenate_datasets([ds1, ds2])
print(f"Total samples: {len(raw)}")


class MedicalDS(Dataset):
    def __init__(self, hf_ds, processor):
        self.processor = processor
        self.samples = []
        for i in tqdm(range(len(hf_ds)), desc="Scanning"):
            ex = hf_ds[i]
            img = ex.get("image")
            if img is None:
                continue
            q = a = None
            if "question" in ex and "answer" in ex:
                q, ans = str(ex["question"]).strip(), ex["answer"]
                a = str(ans[0]).strip() if isinstance(ans, list) else str(ans).strip()
            elif "caption" in ex:
                q, a = "Describe this radiology image.", str(ex["caption"]).strip()
            if q and a:
                self.samples.append({"image": img, "question": q, "answer": a})
        print(f"Valid: {len(self.samples)}")

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        s = self.samples[idx]
        messages = [
            {
                "role": "user",
                "content": [{"type": "image"}, {"type": "text", "text": s["question"]}],
            },
            {"role": "assistant", "content": [{"type": "text", "text": s["answer"]}]},
        ]
        fp = self.processor.apply_chat_template(
            messages, add_generation_prompt=False, tokenize=False
        )
        up = self.processor.apply_chat_template(
            [messages[0]], add_generation_prompt=True, tokenize=False
        )
        full = self.processor(text=fp, images=s["image"], return_tensors="pt")
        user = self.processor(text=up, images=s["image"], return_tensors="pt")
        pl = user["input_ids"].shape[1]
        lab = full["input_ids"][0].clone()
        lab[:pl] = -100
        out = {
            "input_ids": full["input_ids"][0],
            "attention_mask": full["attention_mask"][0],
            "labels": lab,
        }
        if "pixel_values" in full:
            out["pixel_values"] = full["pixel_values"][0]
        if "pixel_attention_mask" in full:
            out["pixel_attention_mask"] = full["pixel_attention_mask"][0]
        return out


train_ds = MedicalDS(raw, processor)


def pad_dim0(t, target_len):
    if t.shape[0] >= target_len:
        return t
    pad_shape = list(t.shape)
    pad_shape[0] = target_len - t.shape[0]
    return torch.cat([t, torch.zeros(pad_shape, dtype=t.dtype)], dim=0)


def collate(batch):
    pad_id = processor.tokenizer.pad_token_id
    out = {
        "input_ids": torch.nn.utils.rnn.pad_sequence(
            [b["input_ids"] for b in batch], batch_first=True, padding_value=pad_id
        ),
        "attention_mask": torch.nn.utils.rnn.pad_sequence(
            [b["attention_mask"] for b in batch], batch_first=True, padding_value=0
        ),
        "labels": torch.nn.utils.rnn.pad_sequence(
            [b["labels"] for b in batch], batch_first=True, padding_value=-100
        ),
    }
    if "pixel_values" in batch[0]:
        mp = max(b["pixel_values"].shape[0] for b in batch)
        out["pixel_values"] = torch.stack(
            [pad_dim0(b["pixel_values"], mp) for b in batch]
        )
    if "pixel_attention_mask" in batch[0]:
        mp = max(b["pixel_attention_mask"].shape[0] for b in batch)
        out["pixel_attention_mask"] = torch.stack(
            [pad_dim0(b["pixel_attention_mask"], mp) for b in batch]
        )
    return out


loader = DataLoader(
    train_ds, batch_size=BATCH_SIZE, shuffle=True, collate_fn=collate, num_workers=0
)

optimizer = torch.optim.AdamW(model.parameters(), lr=LR)
total_steps = (len(loader) * EPOCHS) // GRAD_ACCUM
scheduler = get_cosine_schedule_with_warmup(optimizer, WARMUP_STEPS, total_steps)

model.train()
best = float("inf")
step = 0

for epoch in range(EPOCHS):
    losses = []
    pbar = tqdm(loader, desc=f"Epoch {epoch + 1}/{EPOCHS}")
    for batch in pbar:
        batch = {
            k: v.to(device) if isinstance(v, torch.Tensor) else v
            for k, v in batch.items()
        }
        out = model(**batch)
        loss = out.loss / GRAD_ACCUM
        loss.backward()
        losses.append(loss.item() * GRAD_ACCUM)
        if (step + 1) % GRAD_ACCUM == 0:
            torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
            optimizer.step()
            scheduler.step()
            optimizer.zero_grad()
        pbar.set_postfix(
            {
                "loss": f"{loss.item() * GRAD_ACCUM:.4f}",
                "avg": f"{np.mean(losses[-20:]):.4f}",
            }
        )
        step += 1

    if step % GRAD_ACCUM != 0:
        optimizer.step()
        scheduler.step()
        optimizer.zero_grad()

    avg = np.mean(losses)
    print(f"\nEpoch {epoch + 1} avg loss: {avg:.4f}")
    model.save_pretrained(os.path.join(OUTPUT_DIR, f"epoch-{epoch + 1}"))
    processor.save_pretrained(os.path.join(OUTPUT_DIR, f"epoch-{epoch + 1}"))
    if avg < best:
        best = avg
        model.save_pretrained(os.path.join(OUTPUT_DIR, "best"))
        processor.save_pretrained(os.path.join(OUTPUT_DIR, "best"))
        print("New best saved.")

print(f"\nDone. Best model: {OUTPUT_DIR}/best")
