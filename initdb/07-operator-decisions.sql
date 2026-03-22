-- 07-operator-decisions.sql — KDAT-006: Operator decision receipt
-- Run once; all statements are idempotent.

CREATE TABLE IF NOT EXISTS operator_decisions (
    id                         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    query_id                   TEXT        NOT NULL UNIQUE,
    created_at_utc             TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by_username        TEXT        NOT NULL,
    created_by_role            TEXT        NOT NULL,
    decision                   TEXT        NOT NULL
                                   CHECK (decision IN ('followed','partial','overridden','no_action')),
    decision_reason            TEXT        NOT NULL DEFAULT '',
    actions_taken              JSONB       NOT NULL DEFAULT '[]',
    notes                      TEXT        NOT NULL DEFAULT '',
    attachments                JSONB       NOT NULL DEFAULT '[]',
    supervisor_reviewed        BOOLEAN     NOT NULL DEFAULT FALSE,
    supervisor_username        TEXT,
    supervisor_reviewed_at_utc TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS ix_operator_decisions_query_id
    ON operator_decisions (query_id);

GRANT SELECT, INSERT, UPDATE ON operator_decisions TO keystone_app;
