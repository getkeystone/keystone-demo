-- Harden keystone_app DB permissions to principle of least privilege.
--
-- audit_log:        INSERT only (tamper-evident; no updates or deletes)
-- corpus_documents: SELECT only (ingest runs as superuser via TAMPER_DATABASE_URL)
-- corpus_chunks:    SELECT only (same reason)
-- queries:          SELECT + INSERT only (no update or delete of query records)
--
-- Idempotent: REVOKE on a privilege not held is a no-op in PostgreSQL.

-- audit_log: remove UPDATE and DELETE
REVOKE UPDATE, DELETE ON audit_log FROM keystone_app;

-- corpus_documents: ingest (INSERT) and delete run via TAMPER_DATABASE_URL (superuser).
-- keystone_app retains UPDATE for metadata patches (owner, dates, status_override, etc.)
-- and SELECT for all document queries.
REVOKE INSERT, DELETE ON corpus_documents FROM keystone_app;

-- corpus_chunks: fully managed by ingest via TAMPER_DATABASE_URL; app reads only.
REVOKE INSERT, UPDATE, DELETE ON corpus_chunks FROM keystone_app;

-- queries: remove UPDATE and DELETE
REVOKE UPDATE, DELETE ON queries FROM keystone_app;
