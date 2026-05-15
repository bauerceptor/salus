#!/usr/bin/env python3
r"""
Medical Librarian CLI — Single-file seamless interface
======================================================
Reads PDFs using BioBERT/ClinicalBERT for semantic retrieval,
then routes queries to SLM (medical-slm) or VLM (medical-vlm) via Ollama.

SETUP:
------
1. Place this file in: C:\Users\Lenovo\Music\slm-working\
2. Ensure your models are at:
   - biobert:     .\models\biobert\         (config.json + pytorch_model.bin + vocab.txt)
   - clinicalbert:.\models\clinicalbert\    (config.json + pytorch_model.bin + vocab.txt)
   - SLM:         .\my-trained-models\medical_slm_q4km.gguf
   - VLM:         .\my-trained-models\medical-vlm-Q8_0.gguf
3. Install dependencies:
   pip install torch transformers sentencepiece pymupdf numpy scikit-learn requests

USAGE: (you can also use uv like "uv run librarian.py ingest <pdf_path>")
------
  python librarian.py ingest <pdf_path>              # Add PDF to library
  python librarian.py ask "your question"             # Query SLM with context
  python librarian.py vision "describe this" <img>    # Query VLM with image
  python librarian.py list                           # Show indexed documents
  python librarian.py search "query"                 # Search chunks (debug)

EXAMPLES:
---------
  python librarian.py ask "What are the complications of liver cirrhosis?"
  python librarian.py vision "Describe this chest X-ray" "~/Desktop/cxr.jpg"
"""

import os
import sys
import json
import re
import pickle
import hashlib
import argparse
import subprocess
from pathlib import Path
from typing import List, Dict, Tuple, Optional

import numpy as np

# ---------------------------------------------------------------------------
# CONFIGURATION — adjust these paths to match your setup
# ---------------------------------------------------------------------------
BASE_DIR = Path(__file__).parent.resolve()

MODEL_PATHS = {
    "biobert": BASE_DIR / "models" / "biobert",
    "clinicalbert": BASE_DIR / "models" / "clinicalbert",
}

OLLAMA_MODELS = {
    "slm": "medical-slm",
    "vlm": "medical-vlm",
}

LIBRARY_DIR = BASE_DIR / "library"
INDEX_FILE = LIBRARY_DIR / "index.pkl"
CHUNK_SIZE = 512      # characters per chunk
CHUNK_OVERLAP = 128   # overlap between chunks
TOP_K = 5             # top chunks to retrieve

# ---------------------------------------------------------------------------
# PDF TEXT EXTRACTION
# ---------------------------------------------------------------------------

def extract_text_from_pdf(pdf_path: str) -> str:
    """Extract raw text from a PDF using PyMuPDF (fitz)."""
    try:
        import fitz  # pymupdf
    except ImportError:
        print("ERROR: PyMuPDF not installed. Run: pip install pymupdf")
        sys.exit(1)

    doc = fitz.open(pdf_path)
    text_parts = []
    for page in doc:
        text_parts.append(page.get_text())
    doc.close()
    return "\n".join(text_parts)


def chunk_text(text: str, size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP) -> List[str]:
    """Split text into overlapping chunks."""
    chunks = []
    start = 0
    text_len = len(text)
    while start < text_len:
        end = min(start + size, text_len)
        # Try to break at sentence boundary
        if end < text_len:
            # Look for sentence-ending punctuation followed by space or newline
            match = re.search(r'[.!?]\s+', text[end-50:end])
            if match:
                end = end - 50 + match.end()
        chunks.append(text[start:end].strip())
        start = end - overlap
        if start <= 0:
            start = end
    return [c for c in chunks if len(c) > 50]  # Filter tiny chunks

# ---------------------------------------------------------------------------
# BERT EMBEDDING MODEL (Lazy-loaded)
# ---------------------------------------------------------------------------

class BERTEmbedder:
    """Lazy-loading embedder that auto-selects BioBERT or ClinicalBERT."""

    _instance = None
    _model = None
    _tokenizer = None
    _device = None

    def __new__(cls, model_name: str = "biobert"):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.model_name = model_name
        return cls._instance

    def _load(self):
        if self._model is not None:
            return

        import torch
        from transformers import AutoTokenizer, AutoModel

        model_path = MODEL_PATHS.get(self.model_name, MODEL_PATHS["biobert"])
        if not model_path.exists():
            print(f"ERROR: Model path not found: {model_path}")
            print("Ensure your BERT model is in ./models/<name>/ with config.json and pytorch_model.bin")
            sys.exit(1)

        print(f"Loading {self.model_name} from {model_path} ...")
        self._device = "cuda" if torch.cuda.is_available() else "cpu"

        self._tokenizer = AutoTokenizer.from_pretrained(str(model_path))
        self._model = AutoModel.from_pretrained(str(model_path))
        self._model.to(self._device)
        self._model.eval()
        print(f"Model loaded on {self._device}")

    def encode(self, texts: List[str], batch_size: int = 8) -> np.ndarray:
        self._load()
        import torch

        all_embeddings = []
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i + batch_size]
            inputs = self._tokenizer(
                batch, 
                return_tensors="pt", 
                padding=True, 
                truncation=True, 
                max_length=512
            ).to(self._device)

            with torch.no_grad():
                outputs = self._model(**inputs)
                # Mean pooling of last hidden states
                attention_mask = inputs['attention_mask']
                mask_expanded = attention_mask.unsqueeze(-1).expand(outputs.last_hidden_state.size()).float()
                sum_embeddings = torch.sum(outputs.last_hidden_state * mask_expanded, 1)
                sum_mask = torch.clamp(mask_expanded.sum(1), min=1e-9)
                embeddings = sum_embeddings / sum_mask
                all_embeddings.append(embeddings.cpu().numpy())

        return np.vstack(all_embeddings)


# ---------------------------------------------------------------------------
# VECTOR STORE (Simple in-memory with cosine similarity)
# ---------------------------------------------------------------------------

class VectorStore:
    def __init__(self, index_file: Path = INDEX_FILE):
        self.index_file = index_file
        self.documents: Dict[str, Dict] = {}  # doc_id -> metadata
        self.chunks: List[Dict] = []          # chunk entries
        self.embeddings: Optional[np.ndarray] = None
        self.embedder = BERTEmbedder("biobert")

    def _cosine_similarity(self, query_vec: np.ndarray, doc_vecs: np.ndarray) -> np.ndarray:
        query_norm = query_vec / (np.linalg.norm(query_vec) + 1e-9)
        doc_norm = doc_vecs / (np.linalg.norm(doc_vecs, axis=1, keepdims=True) + 1e-9)
        return np.dot(doc_norm, query_norm.T).flatten()

    def add_document(self, pdf_path: str, doc_id: Optional[str] = None) -> str:
        """Ingest a PDF: extract text, chunk, embed, and store."""
        pdf_path = Path(pdf_path).resolve()
        if not pdf_path.exists():
            print(f"ERROR: PDF not found: {pdf_path}")
            sys.exit(1)

        if doc_id is None:
            doc_id = hashlib.md5(str(pdf_path).encode()).hexdigest()[:12]

        if doc_id in self.documents:
            print(f"Document '{pdf_path.name}' already indexed (ID: {doc_id})")
            return doc_id

        print(f"Extracting text from: {pdf_path.name}")
        text = extract_text_from_pdf(str(pdf_path))

        if len(text.strip()) < 100:
            print(f"WARNING: PDF has very little text. It may be image-based.")

        chunks = chunk_text(text)
        print(f"Created {len(chunks)} chunks")

        print("Generating embeddings...")
        embeddings = self.embedder.encode(chunks)

        # Store document metadata
        self.documents[doc_id] = {
            "path": str(pdf_path),
            "name": pdf_path.name,
            "num_chunks": len(chunks),
            "text_preview": text[:500].replace("\n", " ")
        }

        # Store chunks with embeddings
        for i, (chunk, emb) in enumerate(zip(chunks, embeddings)):
            self.chunks.append({
                "doc_id": doc_id,
                "chunk_id": f"{doc_id}_{i}",
                "text": chunk,
                "embedding": emb,
                "index": len(self.chunks)
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
        """Semantic search over all chunks."""
        if not self.chunks:
            return []

        query_emb = self.embedder.encode([query])[0]
        similarities = self._cosine_similarity(query_emb, self.embeddings)
        top_indices = np.argsort(similarities)[::-1][:top_k]

        results = []
        for idx in top_indices:
            chunk = self.chunks[idx]
            results.append({
                "doc_name": self.documents[chunk["doc_id"]]["name"],
                "text": chunk["text"],
                "score": float(similarities[idx]),
                "doc_id": chunk["doc_id"]
            })
        return results

    def get_context(self, query: str, top_k: int = TOP_K) -> str:
        """Get concatenated context string for LLM prompting."""
        results = self.search(query, top_k)
        if not results:
            return "No relevant documents found in the library."

        context_parts = []
        for i, r in enumerate(results, 1):
            context_parts.append(f"[Document: {r['doc_name']} (relevance: {r['score']:.3f})]\n{r['text']}\n")

        return "\n---\n".join(context_parts)

    def list_docs(self) -> List[Dict]:
        return list(self.documents.values())

    def save(self):
        LIBRARY_DIR.mkdir(parents=True, exist_ok=True)
        # Save without embeddings (too large), rebuild on load
        save_data = {
            "documents": self.documents,
            "chunks": [{k: v for k, v in c.items() if k != "embedding"} for c in self.chunks]
        }
        with open(self.index_file, "wb") as f:
            pickle.dump(save_data, f)

    def load(self):
        if not self.index_file.exists():
            return
        with open(self.index_file, "rb") as f:
            data = pickle.load(f)
        self.documents = data.get("documents", {})
        raw_chunks = data.get("chunks", [])

        if raw_chunks:
            print(f"Loading library with {len(self.documents)} documents, {len(raw_chunks)} chunks...")
            texts = [c["text"] for c in raw_chunks]
            print("Recomputing embeddings (this may take a moment)...")
            embeddings = self.embedder.encode(texts)

            self.chunks = []
            for c, emb in zip(raw_chunks, embeddings):
                c["embedding"] = emb
                self.chunks.append(c)
            self._rebuild_embeddings_matrix()
            print("Library loaded successfully.")
        else:
            self.chunks = []
            self.embeddings = None


# ---------------------------------------------------------------------------
# OLLAMA CLIENT
# ---------------------------------------------------------------------------

class OllamaClient:
    def __init__(self, host: str = "http://localhost:11434"):
        self.host = host
        self._check_ollama()

    def _check_ollama(self):
        """Verify Ollama is running."""
        try:
            import requests
            r = requests.get(f"{self.host}/api/tags", timeout=5)
            if r.status_code != 200:
                raise ConnectionError()
        except Exception:
            print("ERROR: Ollama is not running or not accessible at http://localhost:11434")
            print("Start Ollama first, then try again.")
            sys.exit(1)

    def generate(self, model: str, prompt: str, system: str = "", images: Optional[List[str]] = None) -> str:
        import requests
        import base64

        url = f"{self.host}/api/generate"

        payload = {
            "model": model,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": 0.7,
                "top_p": 0.9,
                "repeat_penalty": 1.1,
                "num_ctx": 2048
            }
        }

        if system:
            payload["system"] = system

        if images:
            encoded_images = []
            for img_path in images:
                with open(img_path, "rb") as f:
                    encoded_images.append(base64.b64encode(f.read()).decode("utf-8"))
            payload["images"] = encoded_images

        try:
            r = requests.post(url, json=payload, timeout=120)
            r.raise_for_status()
            return r.json().get("response", "[No response]")
        except requests.exceptions.RequestException as e:
            return f"ERROR communicating with Ollama: {e}"


# ---------------------------------------------------------------------------
# CLI INTERFACE
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Medical Librarian — PDF ingestion + BERT retrieval + SLM/VLM via Ollama",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s ingest paper.pdf
  %(prog)s ask "What are the side effects of interferon?"
  %(prog)s vision "Describe this MRI" scan.jpg
  %(prog)s list
  %(prog)s search "hepatocellular carcinoma treatment"
        """
    )

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # ingest
    ingest_parser = subparsers.add_parser("ingest", help="Add a PDF to the library")
    ingest_parser.add_argument("pdf_path", help="Path to the PDF file")
    ingest_parser.add_argument("--model", choices=["biobert", "clinicalbert"], default="biobert",
                               help="Which BERT model to use for embeddings (default: biobert)")

    # ask
    ask_parser = subparsers.add_parser("ask", help="Ask the SLM a question using retrieved context")
    ask_parser.add_argument("question", help="Your medical question")
    ask_parser.add_argument("--top-k", type=int, default=TOP_K, help=f"Number of chunks to retrieve (default: {TOP_K})")
    ask_parser.add_argument("--no-context", action="store_true", help="Ask without document context")

    # vision
    vision_parser = subparsers.add_parser("vision", help="Ask the VLM about an image")
    vision_parser.add_argument("question", help="Question about the image")
    vision_parser.add_argument("image", help="Path to the image file")

    # list
    subparsers.add_parser("list", help="List all indexed documents")

    # search
    search_parser = subparsers.add_parser("search", help="Search the library (debug/inspection)")
    search_parser.add_argument("query", help="Search query")
    search_parser.add_argument("--top-k", type=int, default=5, help="Number of results")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(0)

    # Initialize store
    store = VectorStore()
    store.load()

    if args.command == "ingest":
        # Optionally switch embedder model
        if args.model != "biobert":
            store.embedder = BERTEmbedder(args.model)
        store.add_document(args.pdf_path)

    elif args.command == "list":
        docs = store.list_docs()
        if not docs:
            print("Library is empty. Use 'ingest' to add PDFs.")
        else:
            print(f"\n{'='*60}")
            print(f"Indexed Documents ({len(docs)})")
            print(f"{'='*60}")
            for d in docs:
                print(f"\n  Name:  {d['name']}")
                print(f"  Path:  {d['path']}")
                print(f"  Chunks: {d['num_chunks']}")
                print(f"  Preview: {d['text_preview'][:100]}...")

    elif args.command == "search":
        results = store.search(args.query, top_k=args.top_k)
        if not results:
            print("No results found.")
        else:
            print(f"\nTop {len(results)} results for: '{args.query}'\n")
            for i, r in enumerate(results, 1):
                print(f"{i}. [{r['doc_name']}] (score: {r['score']:.3f})")
                print(f"   {r['text'][:300]}...\n")

    elif args.command == "ask":
        ollama = OllamaClient()

        if args.no_context:
            context = ""
        else:
            context = store.get_context(args.question, top_k=args.top_k)

        system_prompt = (
            "You are a medical assistant specializing in hepatology, liver disease, "
            "and drug interactions. Use the provided document context to answer accurately. "
            "If the context doesn't contain the answer, say so clearly. "
            "Answer in plain English, clearly and concisely."
        )

        if context and not args.no_context:
            full_prompt = (
                f"Use the following document excerpts to answer the question.\n\n"
                f"CONTEXT:\n{context}\n\n"
                f"QUESTION: {args.question}\n\n"
                f"ANSWER:"
            )
        else:
            full_prompt = args.question

        print(f"\nQuestion: {args.question}")
        if not args.no_context:
            print(f"Retrieved {args.top_k} context chunks from library.\n")
        print("-" * 60)

        response = ollama.generate(
            model=OLLAMA_MODELS["slm"],
            prompt=full_prompt,
            system=system_prompt
        )
        print(response)

    elif args.command == "vision":
        img_path = Path(args.image)
        if not img_path.exists():
            print(f"ERROR: Image not found: {img_path}")
            sys.exit(1)

        ollama = OllamaClient()

        system_prompt = (
            "You are a medical vision assistant trained to analyze medical images "
            "including X-rays, MRIs, CT scans, histology slides, and clinical photographs. "
            "Describe findings accurately and concisely."
        )

        print(f"\nImage: {img_path.name}")
        print(f"Question: {args.question}\n")
        print("-" * 60)

        response = ollama.generate(
            model=OLLAMA_MODELS["vlm"],
            prompt=args.question,
            system=system_prompt,
            images=[str(img_path)]
        )
        print(response)


if __name__ == "__main__":
    main()
