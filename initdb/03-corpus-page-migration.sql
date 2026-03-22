-- Migration: add page column to corpus_chunks (idempotent).
-- Safe for both fresh DBs (02-corpus-schema.sql already creates it) and
-- existing DBs that were created before this column was added.

ALTER TABLE corpus_chunks ADD COLUMN IF NOT EXISTS page INTEGER;
