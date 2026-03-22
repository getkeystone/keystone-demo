-- 13-corpus-events-upload-id.sql — Add upload_id traceability to corpus_doc_events.
--
-- Links activation events (action='activated') back to the staged_uploads row
-- that triggered them.  NULL for events produced by PATCH /documents/{id}/metadata
-- or the legacy ingest script (which does not write corpus_doc_events).

ALTER TABLE corpus_doc_events
    ADD COLUMN IF NOT EXISTS upload_id UUID REFERENCES staged_uploads(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS ix_corpus_doc_events_upload_id
    ON corpus_doc_events (upload_id)
    WHERE upload_id IS NOT NULL;
