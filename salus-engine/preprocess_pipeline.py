#!/usr/bin/env python3
"""
Medical Dataset Preprocessing Pipeline (UPDATED)
=================================================
Fixes in this version:
1. PubMedQA: Now reads .jsonl files (line-by-line JSON), not just .json
2. Decagon: No longer discards short drug interaction sentences
3. PubMed RCT: Better filename flexibility

Run this exactly like before:
    python preprocess_pipeline.py
"""

import os
import json
import re
import hashlib
from pathlib import Path
from tqdm import tqdm

import pandas as pd

try:
    from lxml import etree
    HAS_LXML = True
except ImportError:
    from xml.etree import ElementTree as etree
    HAS_LXML = False
    print("WARNING: lxml not found. Using built-in xml parser. For better results: pip install lxml")

# ============================
# STEP 1: CONFIGURE YOUR PATHS
# ============================
BASE_DIR = Path(".")
RAW_DIR = BASE_DIR / "datasets"

# INPUT PATHS
PMC_DIR = RAW_DIR / "pmc"
CLINICAL_CASES_FILE = RAW_DIR / "clinical_cases" / "en-00000-of-00001.parquet"
PUBMEDQA_DIR = RAW_DIR / "pubmedqa"
PUBMED_RCT_DIR = RAW_DIR / "pubmed_rct"      # Will auto-detect any .csv inside
DECAGON_FILE = RAW_DIR / "decagon" / "bio-decagon-combo.csv"

# OUTPUT
PROC_DIR = BASE_DIR / "processed"
UNIFIED_FILE = PROC_DIR / "unified_corpus.jsonl"
CHUNKS_FILE = PROC_DIR / "chunks.jsonl"

# SETTINGS
MIN_LENGTH = 100          # For most text (papers, cases)
MIN_LENGTH_DRUG = 10      # For Decagon drug interactions (they are short but valuable)
CHUNK_WORDS = 400
CHUNK_OVERLAP = 50

# ============================
# STEP 2: HELPER FUNCTIONS
# ============================

def clean_text(text):
    if not text or not isinstance(text, str):
        return ""
    text = re.sub(r'<[^>]+>', ' ', text)
    text = re.sub(r'\s+', ' ', text)
    text = text.replace('\x00', '')
    return text.strip()

def get_hash(text):
    return hashlib.md5(text.encode('utf-8')).hexdigest()

def chunk_text(text, chunk_words=400, overlap=50):
    words = text.split()
    if len(words) <= chunk_words:
        return [text]
    chunks = []
    start = 0
    while start < len(words):
        end = min(start + chunk_words, len(words))
        chunk = " ".join(words[start:end])
        chunks.append(chunk)
        if end == len(words):
            break
        start = end - overlap
    return chunks

def save_jsonl(records, filepath):
    filepath.parent.mkdir(parents=True, exist_ok=True)
    with open(filepath, 'w', encoding='utf-8') as f:
        for rec in records:
            f.write(json.dumps(rec, ensure_ascii=False) + '\n')
    print(f"  ✓ Saved {len(records)} records to {filepath}")

# ============================
# STEP 3: PROCESS EACH DATASET
# ============================

def process_pmc():
    print("\n[1/5] Processing PMC Papers...")
    records = []
    seen = set()

    if not PMC_DIR.exists():
        print(f"  ⚠️  Folder not found: {PMC_DIR}. Skipping PMC.")
        return records

    xml_files = list(PMC_DIR.rglob("*.nxml")) + list(PMC_DIR.rglob("*.xml"))
    txt_files = list(PMC_DIR.rglob("*.txt"))
    print(f"  Found {len(xml_files)} XML and {len(txt_files)} TXT files")

    for xml_path in tqdm(xml_files, desc="  XML files"):
        try:
            tree = etree.parse(str(xml_path))
            root = tree.getroot()
            title = ""
            t_elem = root.find(".//article-title")
            if t_elem is not None and t_elem.text:
                title = t_elem.text
            abstract = ""
            a_elem = root.find(".//abstract")
            if a_elem is not None:
                abstract = " ".join(a_elem.itertext())
            body = ""
            b_elem = root.find(".//body")
            if b_elem is not None:
                body = " ".join(b_elem.itertext())
            full = f"{title}\n\n{abstract}\n\n{body}".strip()
            full = clean_text(full)
            if len(full) < MIN_LENGTH:
                continue
            h = get_hash(full)
            if h in seen:
                continue
            seen.add(h)
            records.append({
                "source": "pmc",
                "type": "research_paper",
                "text": full,
                "id": str(xml_path.stem)
            })
        except Exception:
            continue

    for txt_path in tqdm(txt_files, desc="  TXT files"):
        try:
            with open(txt_path, 'r', encoding='utf-8', errors='ignore') as f:
                text = f.read()
            text = clean_text(text)
            if len(text) < MIN_LENGTH:
                continue
            h = get_hash(text)
            if h in seen:
                continue
            seen.add(h)
            records.append({
                "source": "pmc",
                "type": "research_paper",
                "text": text,
                "id": str(txt_path.stem)
            })
        except Exception:
            continue

    print(f"  ✓ Total PMC records: {len(records)}")
    return records

def process_clinical_cases():
    print("\n[2/5] Processing Clinical Cases...")
    records = []

    if not CLINICAL_CASES_FILE.exists():
        print(f"  ⚠️  File not found: {CLINICAL_CASES_FILE}. Skipping.")
        return records

    try:
        df = pd.read_parquet(CLINICAL_CASES_FILE)
        print(f"  Columns found: {list(df.columns)}")

        text_cols = [c for c in df.columns if any(k in c.lower() for k in 
                     ['text', 'description', 'case', 'diagnosis', 'treatment', 
                      'history', 'findings', 'presentation', 'summary', 'report'])]

        if not text_cols:
            text_cols = [c for c in df.columns if df[c].dtype == 'object']
            print(f"  No obvious text columns. Using string columns: {text_cols}")
        else:
            print(f"  Using text columns: {text_cols}")

        for idx, row in tqdm(df.iterrows(), total=len(df), desc="  Cases"):
            parts = []
            for col in text_cols:
                val = row[col]
                if pd.notna(val) and str(val).strip():
                    parts.append(f"{col}: {val}")
            if not parts:
                continue
            text = "\n\n".join(parts)
            text = clean_text(text)
            if len(text) < MIN_LENGTH:
                continue
            records.append({
                "source": "clinical_cases",
                "type": "case_report",
                "text": text,
                "id": f"case_{idx}"
            })
    except Exception as e:
        print(f"  ERROR: {e}")

    print(f"  ✓ Total Clinical Case records: {len(records)}")
    return records

def process_pubmedqa():
    """Read PubMedQA .json AND .jsonl files."""
    print("\n[3/5] Processing PubMedQA...")
    records = []

    if not PUBMEDQA_DIR.exists():
        print(f"  ⚠️  Folder not found: {PUBMEDQA_DIR}. Skipping.")
        return records

    # Look for BOTH .json and .jsonl
    json_files = list(PUBMEDQA_DIR.glob("*.json"))
    jsonl_files = list(PUBMEDQA_DIR.glob("*.jsonl"))
    all_files = json_files + jsonl_files

    if not all_files:
        print(f"  ⚠️  No .json or .jsonl files found in {PUBMEDQA_DIR}. Skipping.")
        return records

    print(f"  Found {len(json_files)} .json and {len(jsonl_files)} .jsonl files")

    for jf in all_files:
        try:
            # --- Handle .jsonl (line-by-line) ---
            if jf.suffix == '.jsonl':
                with open(jf, 'r', encoding='utf-8') as f:
                    lines = f.readlines()

                for line_num, line in enumerate(tqdm(lines, desc=f"  {jf.name}")):
                    line = line.strip()
                    if not line:
                        continue
                    item = json.loads(line)
                    q = item.get('question', '')
                    ctx = item.get('context', '')
                    if isinstance(ctx, list):
                        ctx = ' '.join(ctx)
                    ans = item.get('long_answer', item.get('answer', ''))

                    text = f"Question: {q}\n\nContext: {ctx}\n\nAnswer: {ans}"
                    text = clean_text(text)
                    if len(text) < MIN_LENGTH:
                        continue
                    records.append({
                        "source": "pubmedqa",
                        "type": "qa_pair",
                        "text": text,
                        "id": f"pmqa_{jf.stem}_{line_num}"
                    })

            # --- Handle .json (single object or dict-of-items) ---
            else:
                with open(jf, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                items = list(data.values()) if isinstance(data, dict) else data

                for idx, item in enumerate(tqdm(items, desc=f"  {jf.name}")):
                    q = item.get('question', '')
                    ctx = item.get('context', '')
                    if isinstance(ctx, list):
                        ctx = ' '.join(ctx)
                    ans = item.get('long_answer', item.get('answer', ''))

                    text = f"Question: {q}\n\nContext: {ctx}\n\nAnswer: {ans}"
                    text = clean_text(text)
                    if len(text) < MIN_LENGTH:
                        continue
                    records.append({
                        "source": "pubmedqa",
                        "type": "qa_pair",
                        "text": text,
                        "id": f"pmqa_{jf.stem}_{idx}"
                    })
        except Exception as e:
            print(f"  ERROR in {jf.name}: {e}")

    print(f"  ✓ Total PubMedQA records: {len(records)}")
    return records

def process_pubmed_rct():
    """Auto-detect any CSV in the pubmed_rct folder."""
    print("\n[4/5] Processing PubMed 200k RCT...")
    records = []

    if not PUBMED_RCT_DIR.exists():
        print(f"  ⚠️  Folder not found: {PUBMED_RCT_DIR}. Skipping.")
        return records

    csv_files = list(PUBMED_RCT_DIR.glob("*.csv"))
    if not csv_files:
        print(f"  ⚠️  No .csv files found in {PUBMED_RCT_DIR}. Skipping.")
        return records

    print(f"  Found {len(csv_files)} CSV file(s): {[c.name for c in csv_files]}")

    for csv_path in csv_files:
        try:
            df = pd.read_csv(csv_path, sep=None, engine='python')
            print(f"  [{csv_path.name}] Columns: {list(df.columns)}")

            text_col = None
            for c in df.columns:
                if 'sentence' in c.lower() or 'text' in c.lower():
                    text_col = c
                    break
            if text_col is None:
                text_col = df.columns[0]
                print(f"  Using first column as text: {text_col}")
            else:
                print(f"  Using text column: {text_col}")

            group_col = None
            for c in df.columns:
                if 'abstract' in c.lower() and 'id' in c.lower():
                    group_col = c
                    break

            if group_col and group_col in df.columns:
                print(f"  Grouping by: {group_col}")
                for gid, group in tqdm(df.groupby(group_col), desc=f"  Abstracts"):
                    sentences = group[text_col].dropna().astype(str).tolist()
                    text = " ".join(sentences)
                    text = clean_text(text)
                    if len(text) < MIN_LENGTH:
                        continue
                    records.append({
                        "source": "pubmed_rct",
                        "type": "structured_abstract",
                        "text": text,
                        "id": f"rct_{gid}"
                    })
            else:
                for idx, row in tqdm(df.iterrows(), total=len(df), desc=f"  Rows"):
                    text = str(row[text_col])
                    text = clean_text(text)
                    if len(text) < MIN_LENGTH:
                        continue
                    records.append({
                        "source": "pubmed_rct",
                        "type": "rct_sentence",
                        "text": text,
                        "id": f"rct_{csv_path.stem}_{idx}"
                    })
        except Exception as e:
            print(f"  ERROR in {csv_path.name}: {e}")

    print(f"  ✓ Total PubMed RCT records: {len(records)}")
    return records

def process_decagon():
    """Read Decagon drug interaction CSV. FIXED: no longer discards short sentences."""
    print("\n[5/5] Processing Decagon Drug Graph...")
    records = []

    if not DECAGON_FILE.exists():
        print(f"  ⚠️  File not found: {DECAGON_FILE}. Skipping.")
        return records

    try:
        df = pd.read_csv(DECAGON_FILE)
        print(f"  Columns found: {list(df.columns)}")

        cols = list(df.columns)
        c1 = cols[0]
        c2 = cols[1] if len(cols) > 1 else None
        c3 = cols[2] if len(cols) > 2 else None
        c4 = cols[3] if len(cols) > 3 else None  # Side Effect Name (human readable)

        print(f"  Using: {c1}=drug1, {c2}=drug2, {c3}=relation_id, {c4}=relation_name")

        for idx, row in tqdm(df.iterrows(), total=len(df), desc="  Triples"):
            d1 = str(row[c1]) if c1 and pd.notna(row[c1]) else ""
            d2 = str(row[c2]) if c2 and pd.notna(row[c2]) else ""
            rel_id = str(row[c3]) if c3 and pd.notna(row[c3]) else ""
            rel_name = str(row[c4]) if c4 and pd.notna(row[c4]) else ""

            if not d1 or not d2:
                continue

            # Prefer human-readable side effect name if available
            relation = rel_name if rel_name else rel_id

            if relation:
                text = f"Drug {d1} combined with Drug {d2} may cause {relation}."
            else:
                text = f"Drug {d1} combined with Drug {d2} may cause adverse interactions."

            text = clean_text(text)

            # FIX: Use lower threshold for drug interactions instead of MIN_LENGTH
            if len(text) < MIN_LENGTH_DRUG:
                continue

            records.append({
                "source": "decagon",
                "type": "drug_interaction",
                "text": text,
                "id": f"dec_{idx}"
            })
    except Exception as e:
        print(f"  ERROR: {e}")

    print(f"  ✓ Total Decagon records: {len(records)}")
    return records

# ============================
# STEP 4: MAIN
# ============================

def main():
    print("=" * 60)
    print("MEDICAL DATASET PREPROCESSING PIPELINE v2")
    print("=" * 60)

    PROC_DIR.mkdir(parents=True, exist_ok=True)

    if UNIFIED_FILE.exists():
        UNIFIED_FILE.unlink()
        print("\nRemoved old unified_corpus.jsonl")

    all_records = []
    all_records.extend(process_pmc())
    all_records.extend(process_clinical_cases())
    all_records.extend(process_pubmedqa())      # NOW SUPPORTS .jsonl
    all_records.extend(process_pubmed_rct())    # NOW AUTO-DETECTS ANY .csv
    all_records.extend(process_decagon())       # NOW KEEPS SHORT DRUG TEXTS

    print(f"\n>>> Combined total before deduplication: {len(all_records)}")

    seen_hashes = set()
    deduped = []
    for rec in all_records:
        h = get_hash(rec['text'])
        if h not in seen_hashes:
            seen_hashes.add(h)
            deduped.append(rec)

    print(f">>> After deduplication: {len(deduped)}")

    save_jsonl(deduped, UNIFIED_FILE)

    print("\n--- Chunking long texts into training passages ---")
    chunk_records = []
    for rec in tqdm(deduped, desc="Chunking"):
        chunks = chunk_text(rec['text'], CHUNK_WORDS, CHUNK_OVERLAP)
        for i, chunk in enumerate(chunks):
            chunk_records.append({
                "source": rec['source'],
                "type": rec['type'],
                "text": chunk,
                "parent_id": rec['id'],
                "chunk_index": i
            })

    save_jsonl(chunk_records, CHUNKS_FILE)

    print("\n" + "=" * 60)
    print("DONE! Next step:")
    print(f"  → Unified corpus: {UNIFIED_FILE}")
    print(f"  → Chunked data:   {CHUNKS_FILE}")
    print("  → Use chunks.jsonl for synthetic instruction generation.")
    print("=" * 60)

if __name__ == "__main__":
    main()
