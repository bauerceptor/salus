#!/bin/bash
# ============================================================================
# MEDICAL SLM - CLOUD SETUP SCRIPT v5
# Fixed: Proper parquet download using Python API, not hf CLI
# ============================================================================

set -e

echo "========================================"
echo "MEDICAL SLM - CLOUD SETUP SCRIPT v5"
echo "========================================"

# ============================================================================
# 1. CREATE FOLDER STRUCTURE
# ============================================================================
mkdir -p datasets/{clinical_cases,pubmedqa,pubmed_rct,decagon}
mkdir -p models
mkdir -p processed
mkdir -p output

echo "[1/7] Folder structure created."

# ============================================================================
# 2. FIX SYSTEM DEPENDENCIES
# ============================================================================
echo "[2/7] Fixing system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq git wget curl python3-pip python3-venv unzip libgomp1

echo "✓ Dependencies installed."

# ============================================================================
# 3. INSTALL PYTHON PACKAGES (with uv if available)
# ============================================================================
echo "[3/7] Installing Python packages..."

if command -v uv &> /dev/null; then
    echo "  Using uv for fast package management..."
    uv pip install pandas pyarrow lxml tqdm unsloth transformers datasets trl accelerate
    CMAKE_ARGS="-DGGML_OPENMP=OFF" uv pip install llama-cpp-python --no-cache-dir
    uv pip install huggingface-hub
else
    echo "  Using pip..."
    pip install -q pandas pyarrow lxml tqdm unsloth transformers datasets trl accelerate
    CMAKE_ARGS="-DGGML_OPENMP=OFF" pip install -q llama-cpp-python --no-cache-dir
    pip install -q huggingface-hub
fi

echo "✓ Python packages installed."

# ============================================================================
# 4. DOWNLOAD DATASETS DIRECTLY ON SERVER
# ============================================================================
echo "[4/7] Downloading datasets..."

# --- Clinical Cases (medical_meadow_medical_flashcards from HuggingFace) ---
echo "  → Downloading Open Clinical Cases..."
python3 << 'PYEOF'
from huggingface_hub import hf_hub_download
import os

os.makedirs('datasets/clinical_cases', exist_ok=True)

try:
    print("  Attempting to download clinical cases parquet...")
    path = hf_hub_download(
        repo_id='medalpaca/medical_meadow_medical_flashcards',
        filename='data/train-00000-of-00001.parquet',
        repo_type='dataset',
        local_dir='datasets/clinical_cases/',
        local_dir_use_symlinks=False
    )
    print(f"  ✓ Downloaded to: {path}")

    # Rename to expected filename
    if os.path.exists('datasets/clinical_cases/data/train-00000-of-00001.parquet'):
        os.rename(
            'datasets/clinical_cases/data/train-00000-of-00001.parquet',
            'datasets/clinical_cases/en-00000-of-00001.parquet'
        )
        os.rmdir('datasets/clinical_cases/data')
        print("  ✓ Renamed to en-00000-of-00001.parquet")
    elif os.path.exists('datasets/clinical_cases/train-00000-of-00001.parquet'):
        os.rename(
            'datasets/clinical_cases/train-00000-of-00001.parquet',
            'datasets/clinical_cases/en-00000-of-00001.parquet'
        )
        print("  ✓ Renamed to en-00000-of-00001.parquet")
except Exception as e:
    print(f"  ✗ Download failed: {e}")
    print("  Trying wget fallback...")
    import subprocess
    result = subprocess.run([
        'wget', '-q', '-O', 'datasets/clinical_cases/en-00000-of-00001.parquet',
        'https://huggingface.co/datasets/medalpaca/medical_meadow_medical_flashcards/resolve/main/data/train-00000-of-00001.parquet'
    ], capture_output=True, text=True)
    if result.returncode == 0:
        print("  ✓ Downloaded via wget")
    else:
        print(f"  ✗ Wget also failed: {result.stderr}")
PYEOF

# Check if file exists and has content
if [ -f datasets/clinical_cases/en-00000-of-00001.parquet ]; then
    FILESIZE=$(stat -c%s datasets/clinical_cases/en-00000-of-00001.parquet 2>/dev/null || stat -f%z datasets/clinical_cases/en-00000-of-00001.parquet 2>/dev/null || echo "0")
    echo "  Parquet file size: $FILESIZE bytes"
    if [ "$FILESIZE" -lt 1000 ]; then
        echo "  ✗ File is too small or empty!"
        rm -f datasets/clinical_cases/en-00000-of-00001.parquet
    else
        echo "  ✓ Clinical cases file ready."
    fi
else
    echo "  ⚠ Clinical cases file not found after download attempts."
fi

# --- PubMedQA ---
echo "  → Checking PubMedQA..."
if [ -z "$(ls -A datasets/pubmedqa 2>/dev/null)" ]; then
    echo "    Downloading PubMedQA..."
    cd datasets/pubmedqa
    wget -q -c "https://raw.githubusercontent.com/pubmedqa/pubmedqa/master/data/test_set.json" || true
    wget -q -c "https://raw.githubusercontent.com/pubmedqa/pubmedqa/master/data/train_set.json" || true
    wget -q -c "https://raw.githubusercontent.com/pubmedqa/pubmedqa/master/data/dev_set.json" || true
    cd ../..
else
    echo "    ✓ PubMedQA files already present."
fi

# --- PubMed 200k RCT ---
echo "  → Checking PubMed 200k RCT..."
if [ -z "$(ls -A datasets/pubmed_rct 2>/dev/null)" ]; then
    echo "    Downloading PubMed 200k RCT..."
    wget -q -c "https://github.com/Franck-Dernoncourt/pubmed-rct/archive/refs/heads/master.zip" -O datasets/pubmed_rct/master.zip || true
    if [ -f datasets/pubmed_rct/master.zip ]; then
        unzip -q datasets/pubmed_rct/master.zip -d datasets/pubmed_rct/
        mv datasets/pubmed_rct/pubmed-rct-master/* datasets/pubmed_rct/ 2>/dev/null || true
        rm -rf datasets/pubmed_rct/master.zip datasets/pubmed_rct/pubmed-rct-master
    fi
else
    echo "    ✓ PubMed RCT files already present."
fi

# --- Decagon (Polypharmacy Side Effects) ---
echo "  → Checking Decagon..."
if [ ! -f datasets/decagon/bio-decagon-combo.csv ]; then
    echo "    Downloading Decagon dataset..."
    wget -q -c "https://snap.stanford.edu/decagon/bio-decagon-combo.tar.gz" -O datasets/decagon/bio-decagon-combo.tar.gz
    if [ -f datasets/decagon/bio-decagon-combo.tar.gz ]; then
        tar -xzf datasets/decagon/bio-decagon-combo.tar.gz -C datasets/decagon/
        mv datasets/decagon/bio-decagon-combo.csv datasets/decagon/ 2>/dev/null || true
    fi
else
    echo "    ✓ Decagon file already present."
fi

echo "✓ Dataset downloads complete."

# ============================================================================
# 5. DOWNLOAD QWEN MODEL (using hf CLI)
# ============================================================================
echo "[5/7] Downloading Qwen 0.5B GGUF model..."

if [ ! -f "./qwen-0.5b.gguf" ]; then
    # Use hf CLI to download model
    hf download Qwen/Qwen2.5-0.5B-Instruct-GGUF         --include "*.gguf"         --local-dir ./models/ 2>/dev/null ||     python3 -c "
from huggingface_hub import hf_hub_download
import os
os.makedirs('models', exist_ok=True)
try:
    path = hf_hub_download(repo_id='Qwen/Qwen2.5-0.5B-Instruct-GGUF', filename='qwen2.5-0.5b-instruct-q4_k_m.gguf', local_dir='models/', local_dir_use_symlinks=False)
    print(f'Downloaded to {path}')
except Exception as e:
    print(f'Download failed: {e}')
" ||     wget -q -O models/qwen-0.5b.gguf "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf" || true

    # Find and rename the GGUF file for simplicity
    GGUF_FILE=$(find models/ -name "*.gguf" | head -1)
    if [ -n "$GGUF_FILE" ]; then
        cp "$GGUF_FILE" ./qwen-0.5b.gguf
        echo "✓ Model downloaded: $GGUF_FILE → ./qwen-0.5b.gguf"
    else
        echo "⚠ Model download may have failed. Check models/ folder."
    fi
else
    echo "✓ Model already exists: ./qwen-0.5b.gguf"
fi

# ============================================================================
# 6. CREATE PIPELINE SCRIPTS
# ============================================================================
echo "[6/7] Creating pipeline scripts..."

cat > preprocess_pipeline.py << 'PYEOF'
#!/usr/bin/env python3
"""Medical Dataset Preprocessing Pipeline v2"""
import os, json, re, hashlib
from pathlib import Path
from tqdm import tqdm
import pandas as pd
try:
    from lxml import etree
    HAS_LXML = True
except ImportError:
    from xml.etree import ElementTree as etree
    HAS_LXML = False

BASE_DIR = Path(".")
RAW_DIR = BASE_DIR / "datasets"
PMC_DIR = RAW_DIR / "pmc"
CLINICAL_CASES_FILE = RAW_DIR / "clinical_cases" / "en-00000-of-00001.parquet"
PUBMEDQA_DIR = RAW_DIR / "pubmedqa"
PUBMED_RCT_DIR = RAW_DIR / "pubmed_rct"
DECAGON_FILE = RAW_DIR / "decagon" / "bio-decagon-combo.csv"
PROC_DIR = BASE_DIR / "processed"
UNIFIED_FILE = PROC_DIR / "unified_corpus.jsonl"
CHUNKS_FILE = PROC_DIR / "chunks.jsonl"
MIN_LENGTH = 100
MIN_LENGTH_DRUG = 10
CHUNK_WORDS = 400
CHUNK_OVERLAP = 50

def clean_text(text):
    if not text or not isinstance(text, str): return ""
    text = re.sub(r'<[^>]+>', ' ', text)
    text = re.sub(r'\s+', ' ', text)
    return text.strip()

def get_hash(text): return hashlib.md5(text.encode('utf-8')).hexdigest()

def chunk_text(text, chunk_words=400, overlap=50):
    words = text.split()
    if len(words) <= chunk_words: return [text]
    chunks = []; start = 0
    while start < len(words):
        end = min(start + chunk_words, len(words))
        chunks.append(" ".join(words[start:end]))
        if end == len(words): break
        start = end - overlap
    return chunks

def save_jsonl(records, filepath):
    filepath.parent.mkdir(parents=True, exist_ok=True)
    with open(filepath, 'w', encoding='utf-8') as f:
        for rec in records: f.write(json.dumps(rec, ensure_ascii=False) + '\n')
    print(f"  ✓ Saved {len(records)} records to {filepath}")

def process_pmc():
    print("\n[1/5] Processing PMC Papers...")
    records = []; seen = set()
    if not PMC_DIR.exists():
        print(f"  ⚠️ Folder not found: {PMC_DIR}. Skipping PMC.")
        return records
    xml_files = list(PMC_DIR.rglob("*.nxml")) + list(PMC_DIR.rglob("*.xml"))
    txt_files = list(PMC_DIR.rglob("*.txt"))
    print(f"  Found {len(xml_files)} XML and {len(txt_files)} TXT files")
    for xml_path in tqdm(xml_files, desc="  XML files"):
        try:
            tree = etree.parse(str(xml_path)); root = tree.getroot()
            title = ""; t_elem = root.find(".//article-title")
            if t_elem is not None and t_elem.text: title = t_elem.text
            abstract = ""; a_elem = root.find(".//abstract")
            if a_elem is not None: abstract = " ".join(a_elem.itertext())
            body = ""; b_elem = root.find(".//body")
            if b_elem is not None: body = " ".join(b_elem.itertext())
            full = f"{title}\n\n{abstract}\n\n{body}".strip()
            full = clean_text(full)
            if len(full) < MIN_LENGTH: continue
            h = get_hash(full)
            if h in seen: continue
            seen.add(h)
            records.append({"source": "pmc", "type": "research_paper", "text": full, "id": str(xml_path.stem)})
        except Exception: continue
    for txt_path in tqdm(txt_files, desc="  TXT files"):
        try:
            with open(txt_path, 'r', encoding='utf-8', errors='ignore') as f: text = f.read()
            text = clean_text(text)
            if len(text) < MIN_LENGTH: continue
            h = get_hash(text)
            if h in seen: continue
            seen.add(h)
            records.append({"source": "pmc", "type": "research_paper", "text": text, "id": str(txt_path.stem)})
        except Exception: continue
    print(f"  ✓ Total PMC records: {len(records)}")
    return records

def process_clinical_cases():
    print("\n[2/5] Processing Clinical Cases...")
    records = []
    if not CLINICAL_CASES_FILE.exists():
        print(f"  ⚠️ File not found: {CLINICAL_CASES_FILE}. Skipping.")
        return records
    try:
        file_size = CLINICAL_CASES_FILE.stat().st_size
        print(f"  File size: {file_size:,} bytes")
        if file_size < 1000:
            print(f"  ✗ File is too small or empty! Skipping.")
            return records
        df = pd.read_parquet(CLINICAL_CASES_FILE)
        print(f"  Columns found: {list(df.columns)}")
        text_cols = [c for c in df.columns if any(k in c.lower() for k in ['text', 'description', 'case', 'diagnosis', 'treatment', 'history', 'findings', 'presentation', 'summary', 'report'])]
        if not text_cols:
            text_cols = [c for c in df.columns if df[c].dtype == 'object']
            print(f"  Using string columns: {text_cols}")
        else:
            print(f"  Using text columns: {text_cols}")
        for idx, row in tqdm(df.iterrows(), total=len(df), desc="  Cases"):
            parts = []
            for col in text_cols:
                val = row[col]
                if pd.notna(val) and str(val).strip(): parts.append(f"{col}: {val}")
            if not parts: continue
            text = "\n\n".join(parts); text = clean_text(text)
            if len(text) < MIN_LENGTH: continue
            records.append({"source": "clinical_cases", "type": "case_report", "text": text, "id": f"case_{idx}"})
    except Exception as e: print(f"  ERROR: {e}")
    print(f"  ✓ Total Clinical Case records: {len(records)}")
    return records

def process_pubmedqa():
    print("\n[3/5] Processing PubMedQA...")
    records = []
    if not PUBMEDQA_DIR.exists():
        print(f"  ⚠️ Folder not found: {PUBMEDQA_DIR}. Skipping.")
        return records
    json_files = list(PUBMEDQA_DIR.glob("*.json"))
    jsonl_files = list(PUBMEDQA_DIR.glob("*.jsonl"))
    all_files = json_files + jsonl_files
    if not all_files:
        print(f"  ⚠️ No .json or .jsonl files found. Skipping.")
        return records
    print(f"  Found {len(json_files)} .json and {len(jsonl_files)} .jsonl files")
    for jf in all_files:
        try:
            if jf.suffix == '.jsonl':
                with open(jf, 'r', encoding='utf-8') as f: lines = f.readlines()
                for line_num, line in enumerate(tqdm(lines, desc=f"  {jf.name}")):
                    line = line.strip()
                    if not line: continue
                    item = json.loads(line)
                    q = item.get('question', ''); ctx = item.get('context', '')
                    if isinstance(ctx, list): ctx = ' '.join(ctx)
                    ans = item.get('long_answer', item.get('answer', ''))
                    text = f"Question: {q}\n\nContext: {ctx}\n\nAnswer: {ans}"
                    text = clean_text(text)
                    if len(text) < MIN_LENGTH: continue
                    records.append({"source": "pubmedqa", "type": "qa_pair", "text": text, "id": f"pmqa_{jf.stem}_{line_num}"})
            else:
                with open(jf, 'r', encoding='utf-8') as f: data = json.load(f)
                items = list(data.values()) if isinstance(data, dict) else data
                for idx, item in enumerate(tqdm(items, desc=f"  {jf.name}")):
                    q = item.get('question', ''); ctx = item.get('context', '')
                    if isinstance(ctx, list): ctx = ' '.join(ctx)
                    ans = item.get('long_answer', item.get('answer', ''))
                    text = f"Question: {q}\n\nContext: {ctx}\n\nAnswer: {ans}"
                    text = clean_text(text)
                    if len(text) < MIN_LENGTH: continue
                    records.append({"source": "pubmedqa", "type": "qa_pair", "text": text, "id": f"pmqa_{jf.stem}_{idx}"})
        except Exception as e: print(f"  ERROR in {jf.name}: {e}")
    print(f"  ✓ Total PubMedQA records: {len(records)}")
    return records

def process_pubmed_rct():
    print("\n[4/5] Processing PubMed 200k RCT...")
    records = []
    if not PUBMED_RCT_DIR.exists():
        print(f"  ⚠️ Folder not found: {PUBMED_RCT_DIR}. Skipping.")
        return records
    csv_files = list(PUBMED_RCT_DIR.glob("*.csv"))
    if not csv_files:
        print(f"  ⚠️ No .csv files found. Skipping.")
        return records
    print(f"  Found {len(csv_files)} CSV file(s): {[c.name for c in csv_files]}")
    for csv_path in csv_files:
        try:
            df = pd.read_csv(csv_path, sep=None, engine='python')
            print(f"  [{csv_path.name}] Columns: {list(df.columns)}")
            text_col = None
            for c in df.columns:
                if 'sentence' in c.lower() or 'text' in c.lower(): text_col = c; break
            if text_col is None: text_col = df.columns[0]; print(f"  Using first column: {text_col}")
            else: print(f"  Using text column: {text_col}")
            group_col = None
            for c in df.columns:
                if 'abstract' in c.lower() and 'id' in c.lower(): group_col = c; break
            if group_col and group_col in df.columns:
                print(f"  Grouping by: {group_col}")
                for gid, group in tqdm(df.groupby(group_col), desc=f"  Abstracts"):
                    sentences = group[text_col].dropna().astype(str).tolist()
                    text = " ".join(sentences); text = clean_text(text)
                    if len(text) < MIN_LENGTH: continue
                    records.append({"source": "pubmed_rct", "type": "structured_abstract", "text": text, "id": f"rct_{gid}"})
            else:
                for idx, row in tqdm(df.iterrows(), total=len(df), desc=f"  Rows"):
                    text = str(row[text_col]); text = clean_text(text)
                    if len(text) < MIN_LENGTH: continue
                    records.append({"source": "pubmed_rct", "type": "rct_sentence", "text": text, "id": f"rct_{csv_path.stem}_{idx}"})
        except Exception as e: print(f"  ERROR in {csv_path.name}: {e}")
    print(f"  ✓ Total PubMed RCT records: {len(records)}")
    return records

def process_decagon():
    print("\n[5/5] Processing Decagon Drug Graph...")
    records = []
    if not DECAGON_FILE.exists():
        print(f"  ⚠️ File not found: {DECAGON_FILE}. Skipping.")
        return records
    try:
        df = pd.read_csv(DECAGON_FILE)
        print(f"  Columns found: {list(df.columns)}")
        cols = list(df.columns)
        c1, c2, c3, c4 = cols[0], cols[1] if len(cols) > 1 else None, cols[2] if len(cols) > 2 else None, cols[3] if len(cols) > 3 else None
        print(f"  Using: {c1}=drug1, {c2}=drug2, {c3}=relation_id, {c4}=relation_name")
        for idx, row in tqdm(df.iterrows(), total=len(df), desc="  Triples"):
            d1 = str(row[c1]) if c1 and pd.notna(row[c1]) else ""
            d2 = str(row[c2]) if c2 and pd.notna(row[c2]) else ""
            rel_id = str(row[c3]) if c3 and pd.notna(row[c3]) else ""
            rel_name = str(row[c4]) if c4 and pd.notna(row[c4]) else ""
            if not d1 or not d2: continue
            relation = rel_name if rel_name else rel_id
            if relation: text = f"Drug {d1} combined with Drug {d2} may cause {relation}."
            else: text = f"Drug {d1} combined with Drug {d2} may cause adverse interactions."
            text = clean_text(text)
            if len(text) < MIN_LENGTH_DRUG: continue
            records.append({"source": "decagon", "type": "drug_interaction", "text": text, "id": f"dec_{idx}"})
    except Exception as e: print(f"  ERROR: {e}")
    print(f"  ✓ Total Decagon records: {len(records)}")
    return records

def main():
    print("=" * 60); print("MEDICAL DATASET PREPROCESSING PIPELINE v2"); print("=" * 60)
    PROC_DIR.mkdir(parents=True, exist_ok=True)
    if UNIFIED_FILE.exists(): UNIFIED_FILE.unlink(); print("\nRemoved old unified_corpus.jsonl")
    all_records = []
    all_records.extend(process_pmc())
    all_records.extend(process_clinical_cases())
    all_records.extend(process_pubmedqa())
    all_records.extend(process_pubmed_rct())
    all_records.extend(process_decagon())
    print(f"\n>>> Combined total before deduplication: {len(all_records)}")
    seen_hashes = set(); deduped = []
    for rec in all_records:
        h = get_hash(rec['text'])
        if h not in seen_hashes: seen_hashes.add(h); deduped.append(rec)
    print(f">>> After deduplication: {len(deduped)}")
    save_jsonl(deduped, UNIFIED_FILE)
    print("\n--- Chunking long texts ---")
    chunk_records = []
    for rec in tqdm(deduped, desc="Chunking"):
        chunks = chunk_text(rec['text'], CHUNK_WORDS, CHUNK_OVERLAP)
        for i, chunk in enumerate(chunks):
            chunk_records.append({"source": rec['source'], "type": rec['type'], "text": chunk, "parent_id": rec['id'], "chunk_index": i})
    save_jsonl(chunk_records, CHUNKS_FILE)
    print("\n" + "=" * 60)
    print("DONE!"); print(f"  → {UNIFIED_FILE}"); print(f"  → {CHUNKS_FILE}")
    print("=" * 60)

if __name__ == "__main__":
    main()
PYEOF

cat > gpu_pipeline.py << 'PYEOF'
#!/usr/bin/env python3
"""FULL GPU PIPELINE: Prepare → Generate → Merge → Train"""
import json, random, re, os, sys
from pathlib import Path
from tqdm import tqdm

CHUNKS_FILE = Path("processed/chunks.jsonl")
MODEL_PATH = "qwen-0.5b.gguf"
OUTPUT_DIR = Path("output")
OUTPUT_DIR.mkdir(exist_ok=True)
DECAGON_SAMPLE = 150_000
TEACHER_SAMPLE = 30_000
LORA_R = 32; LORA_ALPHA = 64; LEARNING_RATE = 2e-4; EPOCHS = 3; BATCH_SIZE = 8; MAX_SEQ_LENGTH = 1024

def prepare_datasets():
    print("\n" + "=" * 60); print("STEP 1: PREPARING DATASETS"); print("=" * 60)
    decagon_out = OUTPUT_DIR / "decagon_instructions.jsonl"
    teacher_out = OUTPUT_DIR / "chunks_for_teacher.jsonl"
    if decagon_out.exists(): decagon_out.unlink()
    if teacher_out.exists(): teacher_out.unlink()
    decagon_indices, other_indices = [], []
    with open(CHUNKS_FILE, 'r', encoding='utf-8') as f:
        for idx, line in enumerate(f):
            rec = json.loads(line)
            if rec.get("source") == "decagon": decagon_indices.append(idx)
            else: other_indices.append(idx)
    print(f"  Total: {len(decagon_indices):,} Decagon, {len(other_indices):,} Other")
    decagon_sample = set(random.sample(decagon_indices, min(DECAGON_SAMPLE, len(decagon_indices))))
    teacher_sample = set(random.sample(other_indices, min(TEACHER_SAMPLE, len(other_indices))))
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
    decagon_count = teacher_count = 0
    with open(CHUNKS_FILE, 'r', encoding='utf-8') as f:
        for idx, line in enumerate(tqdm(f, desc="Processing")):
            rec = json.loads(line)
            if idx in decagon_sample:
                text = rec["text"]
                match = re.match(r"Drug (.+?) combined with Drug (.+?) may cause (.+)\.?", text)
                d1, d2, effect = (match.group(1), match.group(2), match.group(3).rstrip(".")) if match else ("", "", "")
                template = random.choice(templates)
                if random.random() > 0.5 and d1 and d2:
                    instruction, input_text, output_text = template, f"Drug 1: {d1}\nDrug 2: {d2}", (f"The combination may cause {effect}." if effect else text)
                else:
                    instruction = f"{template} Drug {d1} and Drug {d2}." if d1 and d2 else template
                    input_text, output_text = "", text
                with open(decagon_out, 'a', encoding='utf-8') as out_f:
                    out_f.write(json.dumps({"instruction": instruction, "input": input_text, "output": output_text, "source": "decagon", "type": "drug_interaction"}, ensure_ascii=False) + '\n')
                decagon_count += 1
            elif idx in teacher_sample:
                with open(teacher_out, 'a', encoding='utf-8') as out_f: out_f.write(line)
                teacher_count += 1
    print(f"\n  ✓ Decagon instructions: {decagon_count:,}")
    print(f"  ✓ Teacher chunks: {teacher_count:,}")
    return decagon_count, teacher_count

def generate_synthetic():
    print("\n" + "=" * 60); print("STEP 2: SYNTHETIC DATA GENERATION"); print("=" * 60)
    from llama_cpp import Llama
    teacher_file = OUTPUT_DIR / "chunks_for_teacher.jsonl"
    synth_out = OUTPUT_DIR / "synthetic_instructions.jsonl"
    if not Path(MODEL_PATH).exists():
        print(f"ERROR: Model not found at {MODEL_PATH}"); sys.exit(1)
    print(f"Loading {MODEL_PATH}...")
    model = Llama(model_path=MODEL_PATH, n_ctx=2048, n_gpu_layers=-1, verbose=False)
    print("✓ Model loaded on GPU\n")
    chunks = []
    with open(teacher_file, 'r', encoding='utf-8') as f:
        for line in f: chunks.append(json.loads(line))
    qa_prompt = "You are a medical education assistant specializing in hepatology.\nRead the text and generate ONE question and answer.\n\nTEXT:\n{chunk}\n\nQuestion: <question>\nAnswer: <answer>"
    summary_prompt = "Summarize this medical text in 2-3 sentences, focusing on liver disease if mentioned.\n\nTEXT:\n{chunk}\n\nSummary:"
    facts_prompt = "Extract 3 key medical facts as bullet points. Prioritize liver conditions if mentioned.\n\nTEXT:\n{chunk}\n\nFacts:"
    with open(synth_out, 'w', encoding='utf-8') as out_f:
        for chunk in tqdm(chunks, desc="Generating"):
            text = chunk["text"]
            if len(text.split()) < 20: continue
            try:
                out = model(qa_prompt.format(chunk=text), max_tokens=256, temperature=0.3, stop=["</s>", "TEXT:"], echo=False)
                qa_text = out["choices"][0]["text"].strip()
                q = a = ""
                for line in qa_text.split("\n"):
                    if line.lower().startswith("question:"): q = line.split(":", 1)[1].strip()
                    elif line.lower().startswith("answer:"): a = line.split(":", 1)[1].strip()
                if q and a:
                    out_f.write(json.dumps({"instruction": q, "input": text, "output": a, "source": chunk["source"], "type": "qa_pair"}, ensure_ascii=False) + "\n")
            except: pass
            try:
                out = model(summary_prompt.format(chunk=text), max_tokens=128, temperature=0.3, stop=["</s>", "TEXT:"], echo=False)
                summary = out["choices"][0]["text"].strip()
                if summary and len(summary) > 20:
                    out_f.write(json.dumps({"instruction": "Summarize the following medical text.", "input": text, "output": summary, "source": chunk["source"], "type": "summary"}, ensure_ascii=False) + "\n")
            except: pass
            try:
                out = model(facts_prompt.format(chunk=text), max_tokens=256, temperature=0.3, stop=["</s>", "TEXT:"], echo=False)
                facts = out["choices"][0]["text"].strip()
                if facts and len(facts) > 20:
                    out_f.write(json.dumps({"instruction": "Extract key medical facts.", "input": text, "output": facts, "source": chunk["source"], "type": "fact_extraction"}, ensure_ascii=False) + "\n")
            except: pass
            out_f.flush()
    print(f"\n  ✓ Synthetic data saved to {synth_out}")

def merge_datasets():
    print("\n" + "=" * 60); print("STEP 3: MERGING DATASETS"); print("=" * 60)
    files = [OUTPUT_DIR / "decagon_instructions.jsonl", OUTPUT_DIR / "synthetic_instructions.jsonl"]
    final = OUTPUT_DIR / "final_training_data.jsonl"
    total = 0
    with open(final, 'w', encoding='utf-8') as out_f:
        for filepath in files:
            if not filepath.exists(): print(f"  WARNING: {filepath} not found, skipping"); continue
            with open(filepath, 'r', encoding='utf-8') as f:
                for line in f: out_f.write(line); total += 1
    print(f"  ✓ Final training set: {total:,} examples"); print(f"  ✓ Saved to {final}")
    return final

def train_model(final_data_path):
    print("\n" + "=" * 60); print("STEP 4: TRAINING WITH UNSLOTH"); print("=" * 60)
    import torch
    from unsloth import FastLanguageModel
    from transformers import TrainingArguments
    from trl import SFTTrainer
    from datasets import load_dataset
    print("Loading base model...")
    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name="unsloth/Qwen2.5-0.5B-Instruct", max_seq_length=MAX_SEQ_LENGTH,
        dtype=torch.bfloat16, load_in_4bit=True,
    )
    model = FastLanguageModel.get_peft_model(
        model, r=LORA_R, target_modules=["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
        lora_alpha=LORA_ALPHA, lora_dropout=0, bias="none", use_gradient_checkpointing="unsloth", random_state=3407, use_rslora=False,
    )
    print("Loading training data...")
    dataset = load_dataset("json", data_files=str(final_data_path), split="train")
    def formatting_prompts_func(examples):
        instructions, inputs, outputs = examples["instruction"], examples["input"], examples["output"]
        texts = []
        for instruction, input_text, output in zip(instructions, inputs, outputs):
            if input_text: prompt = f"<|im_start|>user\n{instruction}\n\n{input_text}\n<|im_start|>assistant\n{output}\n"
            else: prompt = f"<|im_start|>user\n{instruction}\n<|im_start|>assistant\n{output}\n"
            texts.append(prompt)
        return {"text": texts}
    dataset = dataset.map(formatting_prompts_func, batched=True)
    print("Starting training...")
    trainer = SFTTrainer(
        model=model, tokenizer=tokenizer, train_dataset=dataset, dataset_text_field="text",
        max_seq_length=MAX_SEQ_LENGTH, dataset_num_proc=2, packing=False,
        args=TrainingArguments(
            per_device_train_batch_size=BATCH_SIZE, gradient_accumulation_steps=4, warmup_steps=100,
            num_train_epochs=EPOCHS, learning_rate=LEARNING_RATE,
            fp16=not torch.cuda.is_bf16_supported(), bf16=torch.cuda.is_bf16_supported(),
            logging_steps=50, optim="adamw_8bit", weight_decay=0.01, lr_scheduler_type="linear",
            seed=3407, output_dir="lora_output", report_to="none",
        ),
    )
    trainer_stats = trainer.train()
    print(f"\n  Training complete! Final loss: {trainer_stats.training_loss:.4f}")
    model.save_pretrained("lora_output/final_model")
    tokenizer.save_pretrained("lora_output/final_model")
    print("  ✓ Model saved to lora_output/final_model/")
    print("\nMerging LoRA weights and saving GGUF...")
    model.save_pretrained_gguf("lora_output/merged_gguf", tokenizer, quantization_method="q4_k_m")
    print("  ✓ GGUF saved to lora_output/merged_gguf/")

def main():
    print("=" * 60); print("FULL MEDICAL SLM PIPELINE"); print("=" * 60)
    if not CHUNKS_FILE.exists(): print(f"ERROR: {CHUNKS_FILE} not found. Run preprocessing first."); sys.exit(1)
    prepare_datasets(); generate_synthetic(); final_path = merge_datasets(); train_model(final_path)
    print("\n" + "=" * 60); print("ALL DONE!"); print("Download lora_output/merged_gguf/ back to your T14"); print("=" * 60)

if __name__ == "__main__":
    main()
PYEOF

echo "✓ Scripts created."

# ============================================================================
# 7. RUN EVERYTHING
# ============================================================================
echo "[7/7] Running full pipeline..."
echo ""
echo "========================================"
echo "STEP A: PREPROCESSING"
echo "========================================"
python3 preprocess_pipeline.py

echo ""
echo "========================================"
echo "STEP B: TRAINING PIPELINE"
echo "========================================"
python3 gpu_pipeline.py

echo ""
echo "========================================"
echo "COMPLETE!"
echo "========================================"
echo "Your fine-tuned model is in: lora_output/merged_gguf/"
echo "Download it back to your T14 laptop."
