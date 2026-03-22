-- 04-corpus-metadata.sql — add optional metadata columns to corpus_documents.
--
-- These columns are populated by ingest_corpus.py when a sidecar
-- <filename>.metadata.json is present alongside the corpus file.
-- All columns default to '' so existing rows are unaffected.

ALTER TABLE corpus_documents ADD COLUMN IF NOT EXISTS owner          TEXT NOT NULL DEFAULT '';
ALTER TABLE corpus_documents ADD COLUMN IF NOT EXISTS effective_date TEXT NOT NULL DEFAULT '';
ALTER TABLE corpus_documents ADD COLUMN IF NOT EXISTS review_date    TEXT NOT NULL DEFAULT '';
ALTER TABLE corpus_documents ADD COLUMN IF NOT EXISTS status_override TEXT NOT NULL DEFAULT '';
