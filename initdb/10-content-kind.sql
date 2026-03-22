-- Content kind column for corpus_documents (migration 10)
-- Adds a content_kind tag so the reranker can apply kind-aware score
-- multipliers (requirements chunks prefer docs tagged 'requirements',
-- procedure queries prefer 'procedure', reference material tagged 'reference').
--
-- Valid values (enforced by application):
--   procedure    — numbered/bulleted operational procedure (default)
--   requirements — equipment / electrical requirements specification
--   reference    — informational reference material; not a step-by-step procedure

ALTER TABLE corpus_documents
  ADD COLUMN IF NOT EXISTS content_kind TEXT NOT NULL DEFAULT 'procedure';

CREATE INDEX IF NOT EXISTS ix_corpus_documents_content_kind
  ON corpus_documents (content_kind);

-- keystone_app runtime user needs UPDATE to allow ingest to set content_kind
-- on sha-match skips (same pattern as domain live-update).
GRANT UPDATE (content_kind) ON corpus_documents TO keystone_app;
