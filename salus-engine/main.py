#!/usr/bin/env python3
"""
Salus Inference Engine — FastAPI API
=====================================
Wraps librarian-cpl.py models in a REST API for Rails integration.

Run:
    DATABASE_URL="postgresql://postgres:postgres@localhost:5454/salus" python main.py

The server starts on http://0.0.0.0:8000
"""

import os
import sys
import asyncio
import tempfile
import shutil
import importlib.util
from contextlib import asynccontextmanager
from pathlib import Path
from typing import List, Optional
from urllib.parse import urlparse

import numpy as np
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import uvicorn

# SQLAlchemy + pgvector
from sqlalchemy import create_engine, Column, String, Integer, Text, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import ProgrammingError
from pgvector.sqlalchemy import Vector

# ------------------------------------------------------------------
# 1. Import your existing librarian-cpl.py dynamically (handles hyphen)
# ------------------------------------------------------------------
BASE_DIR = Path(__file__).parent.resolve()
LIBRARIAN_PATH = BASE_DIR / "librarian-cpl.py"

if not LIBRARIAN_PATH.exists():
    print(f"ERROR: {LIBRARIAN_PATH} not found.")
    print("Ensure librarian-cpl.py is in the same directory as main.py")
    sys.exit(1)

spec = importlib.util.spec_from_file_location("librarian-cpl", str(LIBRARIAN_PATH))
librarian = importlib.util.module_from_spec(spec)
sys.modules["librarian_cpl"] = librarian
spec.loader.exec_module(librarian)

# Pull out the pieces we need
WhisperSTT = librarian.WhisperSTT
BERTEmbedder = librarian.BERTEmbedder
LLMClient = librarian.LLMClient
VLMClient = librarian.VLMClient
extract_text_from_pdf = librarian.extract_text_from_pdf
chunk_text = librarian.chunk_text
build_prompt = librarian.build_prompt

# ------------------------------------------------------------------
# 2. Configuration
# ------------------------------------------------------------------
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:postgres@localhost:5454/salus"
)
EMBEDDING_DIM = 768  # BioBERT / ClinicalBERT base output size

# ------------------------------------------------------------------
# 3. Database Models
# ------------------------------------------------------------------
Base = declarative_base()


class Document(Base):
    __tablename__ = "documents"
    id = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    path = Column(String)
    num_chunks = Column(Integer, default=0)
    text_preview = Column(Text)


class Chunk(Base):
    __tablename__ = "chunks"
    id = Column(String, primary_key=True)
    doc_id = Column(String, nullable=False, index=True)
    text = Column(Text, nullable=False)
    embedding = Column(Vector(EMBEDDING_DIM))


# ------------------------------------------------------------------
# 4. PGVector Store (replaces pickle-based VectorStore)
# ------------------------------------------------------------------
class PGVectorStore:
    def __init__(self, database_url: str, embedder: BERTEmbedder):
        self.database_url = database_url
        self.embedder = embedder
        self._ensure_database()
        self.engine = create_engine(database_url, pool_pre_ping=True)
        self.SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
        self._ensure_extension()
        Base.metadata.create_all(self.engine)

    def _ensure_database(self):
        """Create the target database if it does not exist."""
        parsed = urlparse(self.database_url)
        db_name = parsed.path.lstrip("/")
        if not db_name:
            return
        base_url = (
            f"{parsed.scheme}://{parsed.username}:{parsed.password}"
            f"@{parsed.hostname}:{parsed.port or 5432}/postgres"
        )
        try:
            temp_engine = create_engine(base_url, isolation_level="AUTOCOMMIT")
            with temp_engine.connect() as conn:
                conn.execute(text(f'CREATE DATABASE "{db_name}"'))
            temp_engine.dispose()
        except ProgrammingError:
            pass  # Already exists

    def _ensure_extension(self):
        with self.engine.connect() as conn:
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
            conn.commit()

    def add_document(self, pdf_path: str, doc_id: Optional[str] = None) -> dict:
        import hashlib

        pdf_path = Path(pdf_path).resolve()
        if not pdf_path.exists():
            raise FileNotFoundError(f"PDF not found: {pdf_path}")
        if doc_id is None:
            doc_id = hashlib.md5(str(pdf_path).encode()).hexdigest()[:12]

        session = self.SessionLocal()
        try:
            existing = session.query(Document).filter(Document.id == doc_id).first()
            if existing:
                return {"status": "already_indexed", "doc_id": doc_id, "name": pdf_path.name}

            text = extract_text_from_pdf(str(pdf_path))
            chunks = chunk_text(text)
            embeddings = self.embedder.encode(chunks)

            doc = Document(
                id=doc_id,
                name=pdf_path.name,
                path=str(pdf_path),
                num_chunks=len(chunks),
                text_preview=text[:500].replace("\n", " "),
            )
            session.add(doc)

            for i, (chunk_text_content, emb) in enumerate(zip(chunks, embeddings)):
                chunk = Chunk(
                    id=f"{doc_id}_{i}",
                    doc_id=doc_id,
                    text=chunk_text_content,
                    embedding=emb.tolist(),
                )
                session.add(chunk)

            session.commit()
            return {
                "status": "indexed",
                "doc_id": doc_id,
                "name": pdf_path.name,
                "chunks": len(chunks),
            }
        finally:
            session.close()

    def search(self, query: str, top_k: int = 5) -> List[dict]:
        session = self.SessionLocal()
        try:
            query_emb = self.embedder.encode([query])[0].tolist()
            results = (
                session.query(
                    Chunk,
                    Chunk.embedding.cosine_distance(query_emb).label("distance"),
                )
                .order_by("distance")
                .limit(top_k)
                .all()
            )

            output = []
            for chunk, distance in results:
                doc = (
                    session.query(Document)
                    .filter(Document.id == chunk.doc_id)
                    .first()
                )
                # cosine_distance ranges 0..2; normalize to 0..1 similarity score
                score = max(0.0, 1.0 - (float(distance) / 2.0))
                output.append(
                    {
                        "doc_name": doc.name if doc else "Unknown",
                        "text": chunk.text,
                        "score": score,
                        "doc_id": chunk.doc_id,
                    }
                )
            return output
        finally:
            session.close()

    def get_context(self, query: str, top_k: int = 5) -> str:
        results = self.search(query, top_k)
        if not results:
            return "No relevant documents found."
        return "\n---\n".join(
            f"[{r['doc_name']} | relevance: {r['score']:.3f}]\n{r['text']}"
            for r in results
        )

    def list_docs(self) -> List[dict]:
        session = self.SessionLocal()
        try:
            docs = session.query(Document).all()
            return [
                {
                    "id": d.id,
                    "name": d.name,
                    "num_chunks": d.num_chunks,
                    "text_preview": d.text_preview,
                }
                for d in docs
            ]
        finally:
            session.close()


# ------------------------------------------------------------------
# 5. Pydantic Request/Response Models
# ------------------------------------------------------------------
class AskRequest(BaseModel):
    question: str
    top_k: int = 5


class AskResponse(BaseModel):
    question: str
    context: str
    answer: str


class TranscribeResponse(BaseModel):
    text: str
    task: str


class IngestResponse(BaseModel):
    status: str
    doc_id: str
    name: str
    chunks: Optional[int] = None


# ------------------------------------------------------------------
# 6. FastAPI Application
# ------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    print("[startup] Loading BERT embedder...")
    app.state.embedder = BERTEmbedder("biobert")

    print("[startup] Connecting to pgvector...")
    app.state.store = PGVectorStore(DATABASE_URL, app.state.embedder)

    print("[startup] Loading Whisper STT...")
    app.state.whisper = WhisperSTT()

    print("[startup] Loading LLM...")
    app.state.llm = LLMClient()

    print("[startup] Loading VLM...")
    app.state.vlm = VLMClient()

    print("[startup] Ready at http://0.0.0.0:8000")
    yield
    print("[shutdown] Cleaning up...")


app = FastAPI(
    title="Salus Inference Engine",
    description="Medical librarian API: STT, RAG, LLM, VLM",
    version="1.0.0",
    lifespan=lifespan,
)


# ------------------------------------------------------------------
# 7. API Endpoints
# ------------------------------------------------------------------


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/ingest", response_model=IngestResponse)
async def ingest(file: UploadFile = File(...)):
    """Upload and index a PDF into pgvector."""
    suffix = Path(file.filename).suffix or ".pdf"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        shutil.copyfileobj(file.file, tmp)
        tmp_path = tmp.name

    try:
        result = await asyncio.to_thread(app.state.store.add_document, tmp_path)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        os.unlink(tmp_path)


@app.post("/ask", response_model=AskResponse)
async def ask(body: AskRequest):
    """Text question → RAG retrieval → LLM answer."""
    try:
        context = await asyncio.to_thread(
            app.state.store.get_context, body.question, body.top_k
        )
        prompt = build_prompt(body.question, context)
        answer = await asyncio.to_thread(app.state.llm.generate, prompt)
        return AskResponse(question=body.question, context=context, answer=answer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/voice-ask")
async def voice_ask(
    audio: UploadFile = File(...),
    top_k: int = Form(5),
    task: str = Form("translate"),
):
    """Audio (Hindi/Urdu/English) → English text → RAG → LLM answer."""
    suffix = Path(audio.filename).suffix or ".wav"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        shutil.copyfileobj(audio.file, tmp)
        tmp_path = tmp.name

    try:
        transcribed = await asyncio.to_thread(
            app.state.whisper.transcribe, tmp_path, task
        )
        context = await asyncio.to_thread(
            app.state.store.get_context, transcribed, top_k
        )
        prompt = build_prompt(transcribed, context)
        answer = await asyncio.to_thread(app.state.llm.generate, prompt)
        return {
            "transcribed_question": transcribed,
            "context": context,
            "answer": answer,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        os.unlink(tmp_path)


@app.post("/transcribe", response_model=TranscribeResponse)
async def transcribe(
    audio: UploadFile = File(...),
    task: str = Form("translate"),
):
    """Audio → English transcribed text."""
    suffix = Path(audio.filename).suffix or ".wav"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        shutil.copyfileobj(audio.file, tmp)
        tmp_path = tmp.name

    try:
        text = await asyncio.to_thread(app.state.whisper.transcribe, tmp_path, task)
        return TranscribeResponse(text=text, task=task)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        os.unlink(tmp_path)


@app.post("/vision-ask")
async def vision_ask(
    image: UploadFile = File(...),
    prompt: str = Form(...),
    max_tokens: int = Form(512),
    temperature: float = Form(0.2),
):
    """Image + prompt → VLM response."""
    suffix = Path(image.filename).suffix or ".jpg"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        shutil.copyfileobj(image.file, tmp)
        img_path = tmp.name

    try:
        answer = await asyncio.to_thread(
            app.state.vlm.analyze,
            img_path,
            prompt,
            max_tokens,
            temperature,
        )
        return {"answer": answer}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        os.unlink(img_path)


@app.get("/documents")
async def list_documents():
    """List all indexed documents."""
    docs = await asyncio.to_thread(app.state.store.list_docs)
    return {"documents": docs}


# ------------------------------------------------------------------
# 8. Entrypoint
# ------------------------------------------------------------------
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)
