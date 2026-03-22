-- 05-doc-governance.sql — corpus document event log for metadata change audit.
--
-- Records every PATCH /documents/{id}/metadata call with before/after state.
-- Applied idempotently via IF NOT EXISTS.

CREATE TABLE IF NOT EXISTS corpus_doc_events (
    id             BIGSERIAL    PRIMARY KEY,
    ts_utc         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    actor_username TEXT         NOT NULL,
    actor_role     TEXT         NOT NULL,
    document_id    TEXT         NOT NULL,
    action         TEXT         NOT NULL,
    before_json    JSONB        NOT NULL DEFAULT '{}',
    after_json     JSONB        NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS ix_corpus_doc_events_document_id
    ON corpus_doc_events (document_id);

-- Grant runtime user (keystone_app) permission to write events and update metadata.
-- SELECT was already granted in 02-corpus-schema.sql.
GRANT SELECT, INSERT ON corpus_doc_events TO keystone_app;
GRANT USAGE, SELECT ON SEQUENCE corpus_doc_events_id_seq TO keystone_app;
GRANT UPDATE (owner, effective_date, review_date, status_override, title)
    ON corpus_documents TO keystone_app;
