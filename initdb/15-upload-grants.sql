-- 15-upload-grants.sql — Grant corpus write permissions to keystone_app for upload workflow.
--
-- The upload activation endpoint (POST /uploads/{id}/activate) runs under
-- keystone_app credentials and needs to INSERT into corpus_documents and
-- corpus_chunks.  Previously only ingest (using TAMPER_DATABASE_URL / owner
-- creds) wrote corpus rows.  The upload workflow brings this into the API.
--
-- DELETE on corpus_chunks is also granted so activation can replace chunks
-- for an existing document (same as ingest's re-ingest path).

GRANT INSERT ON corpus_documents TO keystone_app;
GRANT USAGE, SELECT ON SEQUENCE corpus_documents_id_seq TO keystone_app;

GRANT INSERT, UPDATE, DELETE ON corpus_chunks TO keystone_app;
GRANT USAGE, SELECT ON SEQUENCE corpus_chunks_id_seq TO keystone_app;

-- Allow keystone_app to UPDATE corpus_documents for activation (sets status_override, min_role, etc.)
-- UPDATE for owner/effective_date/review_date/status_override/title was already granted in 05.
-- Add the remaining columns needed by activation: sha256, size_bytes, mime, domain, content_kind, min_role.
GRANT UPDATE (sha256, size_bytes, mime, domain, content_kind, min_role)
    ON corpus_documents TO keystone_app;
