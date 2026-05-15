#!/usr/bin/env python3
"""
Merge Datasets for Training
============================
Combines:
  - decagon_instructions.jsonl (direct drug interactions)
  - synthetic_instructions.jsonl (teacher-generated QA/summaries/facts)

Into one final training file: final_training_data.jsonl
"""

import json
from pathlib import Path

from tqdm import tqdm

FILES = [
    Path("processed/decagon_instructions.jsonl"),
    Path("processed/synthetic_instructions.jsonl"),
]

OUTPUT = Path("processed/final_training_data.jsonl")


def main():
    total = 0
    with open(OUTPUT, "w", encoding="utf-8") as out_f:
        for filepath in FILES:
            if not filepath.exists():
                print(f"WARNING: {filepath} not found. Skipping.")
                continue
            print(f"Merging {filepath}...")
            with open(filepath, "r", encoding="utf-8") as f:
                for line in tqdm(f, desc=filepath.name):
                    out_f.write(line)
                    total += 1
    print(f"\n✓ Final training set: {total:,} examples")
    print(f"✓ Saved to: {OUTPUT}")


if __name__ == "__main__":
    main()
