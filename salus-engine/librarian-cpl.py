#!/usr/bin/env python3
"""
Medical Librarian CLI — Linux + llama.cpp + Whisper Tiny + Custom VLM
=====================================================================
PDF semantic retrieval with BioBERT/ClinicalBERT + local LLM + VLM image analysis.

Setup:
------
1. Model directories:
   - ./models/whisper/              <-- Whisper Tiny files (or auto-download)
   - ./models/biobert/              <-- BioBERT (config.json + pytorch_model.bin + vocab.txt)
   - ./models/clinicalbert/         <-- ClinicalBERT (same files)
   - ./my-trained-models/
       ├── medical_slm_q4km.gguf    <-- Text LLM
       └── medical-vlm-Q8_0.gguf    <-- Your custom VLM

2. Install dependencies:
   pip install torch transformers sentencepiece pymupdf numpy scikit-learn librosa soundfile

3. llama.cpp binaries (adjust paths if compiled elsewhere):
   - ./llama.cpp/main              (text LLM)
   - ./llama.cpp/llava-cli         (VLM — or llama-cli with --mmproj depending on your build)

Usage:
------
  python librarian-cpl.py ingest <pdf_path>
  python librarian-cpl.py ask "your question"
  python librarian-cpl.py voice-ask <audio.wav>        # Hindi/Urdu/English -> English -> LLM
  python librarian-cpl.py vision-ask <image.jpg> "question about the image"
  python librarian-cpl.py transcribe <audio.wav>
  python librarian-cpl.py list
  python librarian-cpl.py search "query"
"""

import os
import sys
import re
import pickle
import hashlib
import argparse
import subprocess
from pathlib import Path
from typing import List, Dict, Optional

import numpy as np

# -------------------- CONFIGURATION --------------------
BASE_DIR = Path(__file__).parent.resolve()

MODEL_PATHS = {
    "whisper":      BASE_DIR / "models" / "whisper",
    "biobert":      BASE_DIR / "models" / "biobert",
    "clinicalbert": BASE_DIR / "models" / "clinicalbert",
}

SLM_MODEL_PATH = BASE_DIR / "my-trained-models" / "medical_slm_q4km.gguf"
VLM_MODEL_PATH = BASE_DIR / "my-trained-models" / "medical-vlm-Q8_0.gguf"

LIBRARY_DIR = BASE_DIR / "library"
INDEX_FILE = LIBRARY_DIR / "index.pkl"

CHUNK_SIZE = 512
CHUNK_OVERLAP = 128
TOP_K = 5

LLAMA_CPP_BINARY = BASE_DIR / "llama.cpp" / "main"
LLAMA_CPP_VLM_BINARY = BASE_DIR / "llama.cpp" / "llava-cli"

# CPU optimization for 8GB RAM, no GPU
os.environ["OMP_NUM_THREADS"] = "4"
os.environ["MKL_NUM_THREADS"] = "4"


# -------------------- WHISPER STT --------------------
class WhisperSTT:
    """Whisper Tiny for speech-to-text. Translates Hindi/Urdu/any language to English."""
    
    def __init__(self, model_name: str = "whisper"):
        self.model_key = model_name
        self.model_path = self._resolve_model_path()
        self._processor = None
        self._model = None
        self._device = "cpu"
        
    def _resolve_model_path(self) -> str:
        local_path = MODEL_PATHS.get(self.model_key, MODEL_PATHS["whisper"])
        if local_path.exists() and any(local_path.iterdir()):
            essentials = ["config.json", "preprocessor_config.json"]
            if all((local_path / f).exists() for f in essentials):
                return str(local_path)
        return "openai/whisper-tiny"
    
    def load(self):
        if self._model is not None:
            return
        import torch
        from transformers import WhisperProcessor, WhisperForConditionalGeneration
        
        print(f"[STT] Loading Whisper Tiny from: {self.model_path}")
        self._processor = WhisperProcessor.from_pretrained(self.model_path)
        self._model = WhisperForConditionalGeneration.from_pretrained(self.model_path)
        self._model.to(self._device)
        self._model.eval()
        torch.set_num_threads(4)
        print(f"[STT] Whisper Tiny ready on CPU (threads: 4)")
        
    def transcribe(self, audio_path: str, task: str = "translate") -> str:
        self.load()
        import torch
        import librosa
        
        if not Path(audio_path).exists():
            raise FileNotFoundError(f"Audio file not found: {audio_path}")
        
        print(f"[STT] Loading audio: {audio_path}")
        audio, sr = librosa.load(audio_path, sr=16000)
        inputs = self._processor(audio, sampling_rate=16000, return_tensors="pt")
        input_features = inputs.input_features.to(self._device)
        forced_decoder_ids = self._processor.get_decoder_prompt_ids(language="en", task=task)
        
        print(f"[STT] Running inference (task={task})...")
        with torch.no_grad():
            predicted_ids = self._model.generate(
                input_features,
                forced_decoder_ids=forced_decoder_ids,
                max_length=448
            )
        
        text = self._processor.batch_decode(predicted_ids, skip_special_tokens=True)[0]
        return text.strip()


# -------------------- PDF EXTRACTION --------------------
def extract_text_from_pdf(pdf_path: str) -> str:
    try:
        import fitz
    except ImportError:
        print("ERROR: PyMuPDF not installed. Run: pip install pymupdf")
        sys.exit(1)

    doc = fitz.open(pdf_path)
    text = "\n".join(page.get_text() for page in doc)
    doc.close()
    return text


def chunk_text(text: str, size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP) -> List[str]:
    chunks = []
    start = 0
    text_len = len(text)
    while start < text_len:
        end = min(start + size, text_len)
        if end < text_len:
            match = re.search(r'[.!?]\s+', text[max(0, end-50):end])
            if match:
                end = max(0, end-50) + match.end()
        chunks.append(text[start:end].strip())
        start = end - overlap
        if start <= 0:
            start = end
    return [c for c in chunks if len(c) > 50]


# -------------------- BERT EMBEDDER --------------------
class BERTEmbedder:
    def __init__(self, model_name: str = "biobert"):
        self.model_name = model_name
        self.model_path = MODEL_PATHS.get(model_name, MODEL_PATHS["biobert"])
        self._model = None
        self._tokenizer = None
        self._device = "cpu"
        self._load()

    def _load(self):
        if self._model is not None:
            return
        import torch
        from transformers import AutoTokenizer, AutoModel

        if not self.model_path.exists():
            print(f"ERROR: Model path not found: {self.model_path}")
            sys.exit(1)

        print(f"[BERT] Loading {self.model_name}...")
        self._tokenizer = AutoTokenizer.from_pretrained(str(self.model_path))
        # FIX: ignore_mismatched_sizes=True handles BioBERT vocab size mismatches
        self._model = AutoModel.from_pretrained(
            str(self.model_path),
            ignore_mismatched_sizes=True
        ).to(self._device)
        self._model.eval()
        torch.set_num_threads(4)
        print(f"[BERT] Model loaded on {self._device}")

    def encode(self, texts: List[str], batch_size: int = 4) -> np.ndarray:
        import torch
        all_embeddings = []
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i+batch_size]
            inputs = self._tokenizer(
                batch, 
                return_tensors="pt",
                padding=True, 
                truncation=True, 
                max_length=512
            ).to(self._device)
            with torch.no_grad():
                outputs = self._model(**inputs)
                mask_exp = inputs['attention_mask'].unsqueeze(-1).expand(outputs.last_hidden_state.size()).float()
                sum_emb = torch.sum(outputs.last_hidden_state * mask_exp, 1)
                sum_mask = torch.clamp(mask_exp.sum(1), min=1e-9)
                embeddings = sum_emb / sum_mask
                all_embeddings.append(embeddings.cpu().numpy())
        return np.vstack(all_embeddings)


# -------------------- VECTOR STORE --------------------
class VectorStore:
    def __init__(self, index_file: Path = INDEX_FILE):
        self.index_file = index_file
        self.documents: Dict[str, Dict] = {}
        self.chunks: List[Dict] = []
        self.embeddings: Optional[np.ndarray] = None
        self.embedder = BERTEmbedder("biobert")
        self._load()

    def _cosine_similarity(self, query_vec: np.ndarray, doc_vecs: np.ndarray) -> np.ndarray:
        q_norm = query_vec / (np.linalg.norm(query_vec) + 1e-9)
        d_norm = doc_vecs / (np.linalg.norm(doc_vecs, axis=1, keepdims=True) + 1e-9)
        return np.dot(d_norm, q_norm.T).flatten()

    def add_document(self, pdf_path: str, doc_id: Optional[str] = None) -> str:
        pdf_path = Path(pdf_path).resolve()
        if not pdf_path.exists():
            print(f"ERROR: PDF not found: {pdf_path}")
            sys.exit(1)
        if doc_id is None:
            doc_id = hashlib.md5(str(pdf_path).encode()).hexdigest()[:12]
        if doc_id in self.documents:
            print(f"Document '{pdf_path.name}' already indexed.")
            return doc_id

        print(f"Extracting text from: {pdf_path.name}")
        text = extract_text_from_pdf(str(pdf_path))
        chunks = chunk_text(text)
        print(f"Created {len(chunks)} chunks")

        print("Generating embeddings...")
        embeddings = self.embedder.encode(chunks)

        self.documents[doc_id] = {
            "path": str(pdf_path),
            "name": pdf_path.name,
            "num_chunks": len(chunks),
            "text_preview": text[:500].replace("\n", " ")
        }
        for i, (chunk, emb) in enumerate(zip(chunks, embeddings)):
            self.chunks.append({
                "doc_id": doc_id,
                "chunk_id": f"{doc_id}_{i}",
                "text": chunk,
                "embedding": emb
            })
        self._rebuild_embeddings_matrix()
        self.save()
        print(f"Indexed '{pdf_path.name}' with ID: {doc_id}")
        return doc_id

    def _rebuild_embeddings_matrix(self):
        if self.chunks:
            self.embeddings = np.vstack([c["embedding"] for c in self.chunks])
        else:
            self.embeddings = None

    def search(self, query: str, top_k: int = TOP_K) -> List[Dict]:
        if not self.chunks or self.embeddings is None:
            return []
        query_emb = self.embedder.encode([query])[0]
        sims = self._cosine_similarity(query_emb, self.embeddings)
        top_idx = np.argsort(sims)[::-1][:top_k]
        results = []
        for idx in top_idx:
            c = self.chunks[idx]
            results.append({
                "doc_name": self.documents[c["doc_id"]]["name"],
                "text": c["text"],
                "score": float(sims[idx]),
                "doc_id": c["doc_id"]
            })
        return results

    def get_context(self, query: str, top_k: int = TOP_K) -> str:
        results = self.search(query, top_k)
        if not results:
            return "No relevant documents found."
        return "\n---\n".join(
            f"[{r['doc_name']} | relevance: {r['score']:.3f}]\n{r['text']}" for r in results
        )

    def list_docs(self) -> List[Dict]:
        return list(self.documents.values())

    def save(self):
        LIBRARY_DIR.mkdir(exist_ok=True, parents=True)
        serializable_chunks = []
        for c in self.chunks:
            c_copy = {k: v for k, v in c.items() if k != "embedding"}
            serializable_chunks.append(c_copy)
        
        save_data = {
            "documents": self.documents,
            "chunks": serializable_chunks,
        }
        with open(self.index_file, "wb") as f:
            pickle.dump(save_data, f)
        if self.embeddings is not None:
            np.save(str(self.index_file) + ".embeddings.npy", self.embeddings)

    def _load(self):
        if not self.index_file.exists():
            return
        try:
            with open(self.index_file, "rb") as f:
                data = pickle.load(f)
            self.documents = data.get("documents", {})
            self.chunks = data.get("chunks", [])
            emb_file = Path(str(self.index_file) + ".embeddings.npy")
            if emb_file.exists():
                self.embeddings = np.load(str(emb_file))
                for i, c in enumerate(self.chunks):
                    if i < len(self.embeddings):
                        c["embedding"] = self.embeddings[i]
            else:
                self._rebuild_embeddings_matrix()
            print(f"Loaded library with {len(self.documents)} documents, {len(self.chunks)} chunks")
        except Exception as e:
            print(f"Warning: Could not load index ({e}). Starting fresh.")
            self.documents = {}
            self.chunks = []
            self.embeddings = None


# -------------------- LLM CLIENT --------------------
class LLMClient:
    def __init__(self, model_path: Path = SLM_MODEL_PATH, binary_path: Path = LLAMA_CPP_BINARY):
        self.model_path = model_path
        self.binary_path = binary_path

    def _check(self):
        if not self.model_path.exists():
            print(f"ERROR: GGUF model not found: {self.model_path}")
            sys.exit(1)
        if not self.binary_path.exists():
            alt = self.binary_path.parent / "llama-cli"
            if alt.exists():
                self.binary_path = alt
            else:
                print(f"ERROR: llama.cpp binary not found at {self.binary_path}")
                sys.exit(1)

    def generate(self, prompt: str, max_tokens: int = 512, temperature: float = 0.7) -> str:
        self._check()
        cmd = [
            str(self.binary_path),
            "-m", str(self.model_path),
            "-p", prompt,
            "-n", str(max_tokens),
            "--temp", str(temperature),
            "--no-display-prompt",
            "-ngl", "0",
        ]
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
            if result.returncode != 0:
                err = result.stderr.strip() if result.stderr else "Unknown error"
                return f"[LLM Error] {err}"
            return result.stdout.strip()
        except subprocess.TimeoutExpired:
            return "[LLM Error] Generation timed out after 5 minutes."
        except Exception as e:
            return f"[LLM Error] {e}"


# -------------------- VLM CLIENT --------------------
class VLMClient:
    def __init__(
        self,
        model_path: Path = VLM_MODEL_PATH,
        binary_path: Path = LLAMA_CPP_VLM_BINARY,
        mmproj_path: Optional[Path] = None,
    ):
        self.model_path = model_path
        self.binary_path = binary_path
        self.mmproj_path = mmproj_path

    def _resolve_binary(self) -> Path:
        candidates = [
            self.binary_path,
            self.binary_path.parent / "llava-cli",
            self.binary_path.parent / "minicpmv-cli",
            self.binary_path.parent / "llama-qwen2vl-cli",
            self.binary_path.parent / "llama-cli",
        ]
        for c in candidates:
            if c.exists():
                return c
        return self.binary_path

    def _check(self):
        if not self.model_path.exists():
            print(f"ERROR: VLM GGUF not found: {self.model_path}")
            sys.exit(1)
        
        self.binary_path = self._resolve_binary()
        if not self.binary_path.exists():
            print(f"ERROR: No llama.cpp VLM binary found.")
            print("Looked for: llava-cli, minicpmv-cli, llama-qwen2vl-cli, llama-cli")
            print(f"In directory: {self.binary_path.parent}")
            sys.exit(1)

    def analyze(self, image_path: str, prompt: str, max_tokens: int = 512, temperature: float = 0.2) -> str:
        self._check()
        
        if not Path(image_path).exists():
            return f"[VLM Error] Image not found: {image_path}"
        
        cmd = [
            str(self.binary_path),
            "-m", str(self.model_path),
            "--image", str(image_path),
            "-p", prompt,
            "-n", str(max_tokens),
            "--temp", str(temperature),
            "-ngl", "0",
        ]
        
        if self.mmproj_path and self.mmproj_path.exists():
            cmd.extend(["--mmproj", str(self.mmproj_path)])
        
        if "llava" in str(self.binary_path):
            cmd.append("--no-display-prompt")
        
        print(f"[VLM] Running: {self.binary_path.name} with {self.model_path.name}")
        print(f"[VLM] Image: {image_path}")
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
            if result.returncode != 0:
                err = result.stderr.strip() if result.stderr else "Unknown error"
                if "mmproj" in err.lower() or "clip" in err.lower() or "vision" in err.lower():
                    return f"[VLM Error] {err}\n\nHint: Your VLM likely needs a --mmproj file. Pass it with: --mmproj /path/to/mmproj.gguf"
                return f"[VLM Error] {err}"
            return result.stdout.strip()
        except subprocess.TimeoutExpired:
            return "[VLM Error] Vision inference timed out after 5 minutes."
        except Exception as e:
            return f"[VLM Error] {e}"


# -------------------- MAIN CLI --------------------
def build_prompt(question: str, context: str) -> str:
    return f"""You are a medical librarian assistant. Use the following retrieved document excerpts to answer the user's question. If the context does not contain enough information, say so clearly.

--- CONTEXT ---
{context}
--- END CONTEXT ---

Question: {question}

Answer:"""


def main():
    parser = argparse.ArgumentParser(description="Medical Librarian CLI")
    sub = parser.add_subparsers(dest="command", help="Commands")

    p_ingest = sub.add_parser("ingest", help="Index a PDF")
    p_ingest.add_argument("pdf", help="Path to PDF file")

    p_ask = sub.add_parser("ask", help="Ask a question (text LLM)")
    p_ask.add_argument("question", help="Your question")
    p_ask.add_argument("--top-k", type=int, default=TOP_K)

    p_voice = sub.add_parser("voice-ask", help="Ask via audio (Hindi/Urdu/English -> English -> LLM)")
    p_voice.add_argument("audio", help="Path to audio file")
    p_voice.add_argument("--top-k", type=int, default=TOP_K)
    p_voice.add_argument("--task", default="translate", choices=["translate", "transcribe"])

    p_vision = sub.add_parser("vision-ask", help="Ask about an image using your custom VLM")
    p_vision.add_argument("image", help="Path to image file (.jpg, .png, etc.)")
    p_vision.add_argument("question", help="Question about the image")
    p_vision.add_argument("--mmproj", type=Path, default=None,
                          help="Path to mmproj.gguf (vision projector) if required by your VLM")
    p_vision.add_argument("--max-tokens", type=int, default=512)
    p_vision.add_argument("--temp", type=float, default=0.2)

    p_trans = sub.add_parser("transcribe", help="Just transcribe audio to English text")
    p_trans.add_argument("audio", help="Path to audio file")
    p_trans.add_argument("--task", default="translate", choices=["translate", "transcribe"])

    sub.add_parser("list", help="List indexed documents")

    p_search = sub.add_parser("search", help="Search documents (no LLM)")
    p_search.add_argument("query", help="Search query")
    p_search.add_argument("--top-k", type=int, default=TOP_K)

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(0)

    store = VectorStore()

    if args.command == "ingest":
        store.add_document(args.pdf)

    elif args.command == "ask":
        context = store.get_context(args.question, args.top_k)
        print("=== RETRIEVED CONTEXT ===")
        print(context)
        print("\n=== LLM RESPONSE ===")
        llm = LLMClient()
        prompt = build_prompt(args.question, context)
        print(llm.generate(prompt))

    elif args.command == "voice-ask":
        stt = WhisperSTT()
        transcribed = stt.transcribe(args.audio, task=args.task)
        print(f"\n=== TRANSCRIBED QUESTION ===\n{transcribed}\n")
        
        context = store.get_context(transcribed, args.top_k)
        print("=== RETRIEVED CONTEXT ===")
        print(context)
        print("\n=== LLM RESPONSE ===")
        llm = LLMClient()
        prompt = build_prompt(transcribed, context)
        print(llm.generate(prompt))

    elif args.command == "vision-ask":
        vlm = VLMClient(mmproj_path=args.mmproj)
        answer = vlm.analyze(
            image_path=args.image,
            prompt=args.question,
            max_tokens=args.max_tokens,
            temperature=args.temp
        )
        print("\n=== VLM RESPONSE ===")
        print(answer)

    elif args.command == "transcribe":
        stt = WhisperSTT()
        text = stt.transcribe(args.audio, task=args.task)
        print(text)

    elif args.command == "list":
        if not store.documents:
            print("No documents indexed.")
        for doc_id, info in store.documents.items():
            print(f"- {info['name']} ({info['num_chunks']} chunks) [ID: {doc_id}]")

    elif args.command == "search":
        results = store.search(args.query, args.top_k)
        if not results:
            print("No results found.")
        for r in results:
            print(f"\n[{r['doc_name']} | score: {r['score']:.3f}]\n{r['text'][:500]}...")


if __name__ == "__main__":
    main()
