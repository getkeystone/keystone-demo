-- 14-min-role.sql — Per-document minimum role for FTS retrieval.
--
-- Adds an additive access-control column to corpus_documents.
-- The FTS retrieval path checks BOTH _SCENARIO_MIN_LEVEL (query-level gate)
-- AND this column (per-document gate).  A document is returned only when
-- the requester's role satisfies both gates simultaneously.
--
-- Default 'member' is fully permissive — existing documents are unaffected.
-- Set to 'custodian', 'officer', or 'admin' to restrict individual documents.

ALTER TABLE corpus_documents
    ADD COLUMN IF NOT EXISTS min_role TEXT NOT NULL DEFAULT 'member';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'corpus_documents_min_role_check'
          AND conrelid = 'corpus_documents'::regclass
    ) THEN
        ALTER TABLE corpus_documents
            ADD CONSTRAINT corpus_documents_min_role_check
            CHECK (min_role IN ('member', 'custodian', 'officer', 'admin'));
    END IF;
END$$;

-- Also add to staged_uploads (already defined in 12) — no-op when run on a
-- fresh cluster (12 creates it); idempotent ALTER guards existing clusters.
-- (Column already defined in 12-staged-uploads.sql; this file covers
--  corpus_documents only.)
