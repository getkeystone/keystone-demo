-- KDAT-064b: pgvector extension and embedding column
-- Requires pgvector/pgvector:pg16 image (or postgres with
-- pgvector compiled in).
--
-- Idempotent: safe to run on a fresh DB or one that already
-- has the extension/column (IF NOT EXISTS guards throughout).

CREATE EXTENSION IF NOT EXISTS vector;

ALTER TABLE corpus_chunks
ADD COLUMN IF NOT EXISTS embedding vector(768);

CREATE INDEX IF NOT EXISTS ix_corpus_chunks_embedding
ON corpus_chunks USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 200);
