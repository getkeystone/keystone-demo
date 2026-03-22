-- 06-approvals.sql — KDAT-005: Approval workflow tables
-- Run once; all statements are idempotent.

-- ── Document change requests ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS corpus_doc_change_requests (
    id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id      TEXT         NOT NULL,
    requested_by     TEXT         NOT NULL,
    requested_by_role TEXT        NOT NULL,
    requested_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    patch            JSONB        NOT NULL DEFAULT '{}',
    reason           TEXT         NOT NULL DEFAULT '',
    status           TEXT         NOT NULL DEFAULT 'pending'
                         CHECK (status IN ('pending','approved','rejected','applied')),
    decided_by       TEXT,
    decided_by_role  TEXT,
    decided_at       TIMESTAMPTZ,
    decision_reason  TEXT         NOT NULL DEFAULT '',
    applied_at       TIMESTAMPTZ,
    before_json      JSONB        NOT NULL DEFAULT '{}',
    after_json       JSONB
);

CREATE INDEX IF NOT EXISTS ix_doc_change_requests_document_id
    ON corpus_doc_change_requests (document_id);
CREATE INDEX IF NOT EXISTS ix_doc_change_requests_status
    ON corpus_doc_change_requests (status);

GRANT SELECT, INSERT, UPDATE ON corpus_doc_change_requests TO keystone_app;

-- ── Evidence export requests ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS evidence_export_requests (
    id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    query_id             TEXT        NOT NULL,
    requested_by         TEXT        NOT NULL,
    requested_by_role    TEXT        NOT NULL,
    requested_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    reason               TEXT        NOT NULL DEFAULT '',
    status               TEXT        NOT NULL DEFAULT 'pending'
                             CHECK (status IN ('pending','approved','rejected')),
    decided_by           TEXT,
    decided_by_role      TEXT,
    decided_at           TIMESTAMPTZ,
    decision_reason      TEXT        NOT NULL DEFAULT '',
    approved_ttl_seconds INTEGER     NOT NULL DEFAULT 3600,
    approval_token_hash  TEXT
);

CREATE INDEX IF NOT EXISTS ix_evidence_export_requests_query_id
    ON evidence_export_requests (query_id);
CREATE INDEX IF NOT EXISTS ix_evidence_export_requests_status
    ON evidence_export_requests (status);

GRANT SELECT, INSERT, UPDATE ON evidence_export_requests TO keystone_app;
