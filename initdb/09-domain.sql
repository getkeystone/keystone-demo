-- Domain column for corpus_documents (migration 09)
-- Adds a domain tag so OHS regulation and industry reference documents can be governed
-- separately.  Existing rows default to 'ohs_regulation'.
--
-- Valid values (enforced by application, not a PG constraint, so future
-- domains can be added without a schema change):
--   ohs_regulation    — fire operations, equipment manuals, tactical SOPs
--   medical_emr — Emergency Medical Response, first aid, CPR, EMR protocols

ALTER TABLE corpus_documents
  ADD COLUMN IF NOT EXISTS domain TEXT NOT NULL DEFAULT 'ohs_regulation';

CREATE INDEX IF NOT EXISTS ix_corpus_documents_domain
  ON corpus_documents (domain);

-- keystone_app runtime user needs UPDATE to allow ingest and the metadata
-- PATCH endpoint to set domain on sha-match and governance edits.
GRANT UPDATE (domain) ON corpus_documents TO keystone_app;
