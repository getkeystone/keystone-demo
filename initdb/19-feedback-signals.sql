-- 19-feedback-signals.sql
-- Feedback signal table for the governed learning loop.
-- Referenced by review_tasks (24-review-workflow.sql) and main.py feedback endpoints.
-- Must run before 24-review-workflow.sql.
--
-- This table was present in earlier deployments but was missing from initdb.
-- Added here to ensure fresh installs initialize correctly.

CREATE TABLE IF NOT EXISTS feedback_signals (
    id                        VARCHAR NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::text,
    query_id                  VARCHAR NOT NULL REFERENCES queries(id),
    signal_type               VARCHAR NOT NULL,
    comment                   TEXT,
    created_by                VARCHAR NOT NULL,
    created_by_role           VARCHAR NOT NULL,
    document_title            TEXT,
    answer_source             VARCHAR,
    factual_consistency_score DOUBLE PRECISION,
    created_at_utc            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_feedback_signals_query ON feedback_signals(query_id);

GRANT SELECT, INSERT ON feedback_signals TO keystone_app;
REVOKE UPDATE, DELETE, TRUNCATE ON feedback_signals FROM keystone_app;
