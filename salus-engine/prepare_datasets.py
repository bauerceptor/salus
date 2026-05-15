#!/usr/bin/env python3
"""
Prepare Training Datasets (Smart Sampling)
============================================
Reads your full 5.4M chunks.jsonl and creates two files:
1. decagon_instructions.jsonl  - Directly converted drug interactions (NO teacher model needed)
2. chunks_for_teacher.jsonl    - Random sample of medical texts FOR synthetic generation

This avoids re-running preprocessing and avoids wasting GPU time on 4.6M Decagon records.
"""

import json
import random
import re
from pathlib import Path
from tqdm import tqdm

# ============================
# CONFIGURATION
# ============================
CHUNKS_FILE = Path("processed/chunks.jsonl")
OUTPUT_DIR = Path("processed")

# How many examples to use?
DECAGON_SAMPLE_SIZE = 150_000       # Direct instructions from drug data
TEACHER_SAMPLE_SIZE = 30_000        # Chunks to send through Qwen teacher model

# Ensure reproducibility
random.seed(42)

# ============================
# DIVERSE INSTRUCTION TEMPLATES
# ============================
# Using varied phrasing prevents the model from memorizing a single pattern
DECAGON_TEMPLATES = [
    "What adverse effect may result from combining these two drugs?",
    "Describe the drug interaction and its clinical significance.",
    "A patient is co-prescribed these medications. What should be monitored?",
    "Identify the polypharmacy side effect associated with this combination.",
    "What is the risk of hepatotoxicity or other adverse effects when these drugs are taken together?",
    "Summarize the interaction between the two pharmaceutical agents.",
    "Predict the side effect profile of this drug combination.",
    "What happens in the body when these two compounds are administered concurrently?",
]

def parse_decagon_text(text):
    """
    Parse text like:
      'Drug CID123 combined with Drug CID456 may cause Nausea.'
    Returns (drug1, drug2, side_effect) or None if unparseable.
    """
    # Remove the word "Drug " prefixes
    cleaned = text.replace("Drug ", "")
    # Pattern: X combined with Drug Y may cause Z.
    # After replacement: X combined with Y may cause Z.
    match = re.match(r"(.+?) combined with (.+?) may cause (.+)\.?", cleaned)
    if match:
        return match.group(1).strip(), match.group(2).strip(), match.group(3).strip().rstrip(".")
    return None, None, None

def main():
    print("=" * 60)
    print("PREPARING TRAINING DATASETS")
    print("=" * 60)

    if not CHUNKS_FILE.exists():
        print(f"ERROR: {CHUNKS_FILE} not found. Run preprocessing first.")
        return

    # --- Pass 1: Count and separate ---
    print("\nPass 1: Scanning chunks.jsonl...")
    decagon_indices = []
    other_indices = []

    with open(CHUNKS_FILE, 'r', encoding='utf-8') as f:
        for idx, line in enumerate(tqdm(f, desc="Scanning")):
            rec = json.loads(line)
            if rec.get("source") == "decagon":
                decagon_indices.append(idx)
            else:
                other_indices.append(idx)

    print(f"  Total chunks: {len(decagon_indices) + len(other_indices):,}")
    print(f"  Decagon (drug interactions): {len(decagon_indices):,}")
    print(f"  Other (clinical + research): {len(other_indices):,}")

    # --- Sampling ---
    decagon_sample_idx = set(random.sample(decagon_indices, min(DECAGON_SAMPLE_SIZE, len(decagon_indices))))
    teacher_sample_idx = set(random.sample(other_indices, min(TEACHER_SAMPLE_SIZE, len(other_indices))))

    print(f"\n  Sampling {len(decagon_sample_idx):,} Decagon records for DIRECT conversion")
    print(f"  Sampling {len(teacher_sample_idx):,} medical chunks for TEACHER generation")

    # --- Pass 2: Write output files ---
    decagon_out = OUTPUT_DIR / "decagon_instructions.jsonl"
    teacher_out = OUTPUT_DIR / "chunks_for_teacher.jsonl"

    # Remove old files if they exist
    if decagon_out.exists():
        decagon_out.unlink()
    if teacher_out.exists():
        teacher_out.unlink()

    decagon_count = 0
    teacher_count = 0

    with open(CHUNKS_FILE, 'r', encoding='utf-8') as f:
        for idx, line in enumerate(tqdm(f, desc="Writing")):
            rec = json.loads(line)

            if idx in decagon_sample_idx:
                text = rec["text"]
                d1, d2, effect = parse_decagon_text(text)

                # Build varied instruction
                template = random.choice(DECAGON_TEMPLATES)

                # 50% of the time, put drug names in the input for variety
                if random.random() > 0.5 and d1 and d2:
                    instruction = template
                    input_text = f"Drug 1: {d1}\nDrug 2: {d2}"
                    output_text = f"The combination may cause {effect}." if effect else text
                else:
                    # Put everything in the instruction, output is the full sentence
                    if d1 and d2 and effect:
                        instruction = f"{template} Drug {d1} and Drug {d2}."
                    else:
                        instruction = template
                    input_text = ""
                    output_text = text

                out_rec = {
                    "instruction": instruction,
                    "input": input_text,
                    "output": output_text,
                    "source": "decagon",
                    "type": "drug_interaction"
                }

                with open(decagon_out, 'a', encoding='utf-8') as out_f:
                    out_f.write(json.dumps(out_rec, ensure_ascii=False) + '\n')
                decagon_count += 1

            elif idx in teacher_sample_idx:
                with open(teacher_out, 'a', encoding='utf-8') as out_f:
                    out_f.write(line)
                teacher_count += 1

    print(f"\n✓ Created {decagon_out} with {decagon_count:,} direct instructions")
    print(f"✓ Created {teacher_out} with {teacher_count:,} chunks for teacher model")
    print("\n" + "=" * 60)
    print("NEXT STEPS:")
    print("  1. Run synthetic generation on chunks_for_teacher.jsonl")
    print("  2. Combine decagon_instructions.jsonl + synthetic output")
    print("  3. Train your model on the combined file")
    print("=" * 60)

if __name__ == "__main__":
    main()
