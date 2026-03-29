-- 23-document-versions.sql
-- Document version tracking for governed learning loop.
-- Additive: does not modify existing tables destructively.

CREATE TABLE IF NOT EXISTS document_versions (
    id                      BIGSERIAL PRIMARY KEY,
    doc_id                  BIGINT NOT NULL REFERENCES corpus_documents(id) ON DELETE CASCADE,
    version_number          INTEGER NOT NULL DEFAULT 1,
    status                  TEXT NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'pending_review', 'active', 'superseded')),
    effective_from          TIMESTAMPTZ,
    effective_to            TIMESTAMPTZ,
    supersedes_version_id   BIGINT REFERENCES document_versions(id),
    content_hash            CHAR(64),
    file_path               TEXT,
    change_summary          TEXT,
    created_by              TEXT NOT NULL,
    approved_by             TEXT,
    published_at            TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(doc_id, version_number)
);

CREATE INDEX IF NOT EXISTS ix_document_versions_doc_id ON document_versions(doc_id);
CREATE INDEX IF NOT EXISTS ix_document_versions_status ON document_versions(status);

-- At most one active version per document. Database-enforced.
-- Use a unique partial index. Drop first if it exists (idempotent re-run).
DROP INDEX IF EXISTS ix_one_active_version;
CREATE UNIQUE INDEX ix_one_active_version
    ON document_versions(doc_id)
    WHERE status = 'active';

-- Version lifecycle events (append-only audit trail)
CREATE TABLE IF NOT EXISTS version_events (
    id              BIGSERIAL PRIMARY KEY,
    version_id      BIGINT NOT NULL REFERENCES document_versions(id),
    event_type      TEXT NOT NULL
        CHECK (event_type IN ('created', 'submitted_for_review', 'approved', 'published', 'superseded', 'rejected')),
    actor           TEXT NOT NULL,
    actor_role      TEXT NOT NULL,
    detail          JSONB DEFAULT '{}'::jsonb,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_version_events_version_id ON version_events(version_id);

-- Add version_id to corpus_chunks (nullable for backward compat with existing chunks)
ALTER TABLE corpus_chunks ADD COLUMN IF NOT EXISTS version_id BIGINT REFERENCES document_versions(id);

-- Grants for keystone_app (runtime role)
GRANT SELECT, INSERT, UPDATE ON document_versions TO keystone_app;
GRANT SELECT, INSERT ON version_events TO keystone_app;
GRANT USAGE, SELECT ON SEQUENCE document_versions_id_seq TO keystone_app;
GRANT USAGE, SELECT ON SEQUENCE version_events_id_seq TO keystone_app;

-- version_events is append-only: no UPDATE or DELETE for app role
REVOKE UPDATE, DELETE, TRUNCATE ON version_events FROM keystone_app;
