-- 24-review-workflow.sql
-- Review workflow for governed learning loop.
-- Auto-creates tasks from not_helpful feedback.

CREATE TABLE IF NOT EXISTS review_tasks (
    id                  VARCHAR NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::text,
    feedback_signal_id  VARCHAR NOT NULL REFERENCES feedback_signals(id),
    doc_id              BIGINT NOT NULL REFERENCES corpus_documents(id),
    source_version_id   BIGINT REFERENCES document_versions(id),
    status              VARCHAR NOT NULL DEFAULT 'open'
        CHECK (status IN ('open', 'assigned', 'in_review', 'resolved', 'dismissed')),
    assigned_to         VARCHAR,
    priority            VARCHAR DEFAULT 'normal'
        CHECK (priority IN ('low', 'normal', 'high', 'critical')),
    resolution_type     VARCHAR
        CHECK (resolution_type IN ('new_version_published', 'no_change_needed', 'escalated', 'duplicate')),
    resolution_note     TEXT,
    resolved_by         VARCHAR,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    assigned_at         TIMESTAMPTZ,
    resolved_at         TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS ix_review_tasks_status ON review_tasks(status);
CREATE INDEX IF NOT EXISTS ix_review_tasks_doc_id ON review_tasks(doc_id);

CREATE TABLE IF NOT EXISTS review_comments (
    id          VARCHAR NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::text,
    task_id     VARCHAR NOT NULL REFERENCES review_tasks(id),
    author      VARCHAR NOT NULL,
    author_role VARCHAR NOT NULL,
    body        TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_review_comments_task ON review_comments(task_id);

CREATE TABLE IF NOT EXISTS publication_decisions (
    id                  VARCHAR NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::text,
    review_task_id      VARCHAR NOT NULL REFERENCES review_tasks(id),
    old_version_id      BIGINT REFERENCES document_versions(id),
    new_version_id      BIGINT REFERENCES document_versions(id),
    decision            VARCHAR NOT NULL
        CHECK (decision IN ('publish_new_version', 'no_change', 'escalate')),
    decided_by          VARCHAR NOT NULL,
    decided_by_role     VARCHAR NOT NULL,
    decided_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Grants for keystone_app
GRANT SELECT, INSERT, UPDATE ON review_tasks TO keystone_app;
GRANT SELECT, INSERT ON review_comments TO keystone_app;
GRANT SELECT, INSERT ON publication_decisions TO keystone_app;

-- review_comments and publication_decisions are append-only
REVOKE UPDATE, DELETE, TRUNCATE ON review_comments FROM keystone_app;
REVOKE UPDATE, DELETE, TRUNCATE ON publication_decisions FROM keystone_app;
