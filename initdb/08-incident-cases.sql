-- 08-incident-cases.sql — KDAT-007: Supervisor review queue + incident case logbook
-- Run once; all statements are idempotent.

-- ── Incident cases ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS incident_cases (
    case_id        UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at_utc TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by     TEXT        NOT NULL,
    status         TEXT        NOT NULL DEFAULT 'open'
                       CHECK (status IN ('open','closed')),
    severity       TEXT        NOT NULL DEFAULT 'low'
                       CHECK (severity IN ('low','med','high','critical')),
    title          TEXT        NOT NULL DEFAULT '',
    summary        TEXT        NOT NULL DEFAULT '',
    assigned_to    TEXT,
    closed_at_utc  TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS ix_incident_cases_status     ON incident_cases (status);
CREATE INDEX IF NOT EXISTS ix_incident_cases_created_at ON incident_cases (created_at_utc DESC);

GRANT SELECT, INSERT, UPDATE ON incident_cases TO keystone_app;

-- ── Case ↔ query join table ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS incident_case_queries (
    case_id      UUID        NOT NULL,
    query_id     TEXT        NOT NULL,
    added_at_utc TIMESTAMPTZ NOT NULL DEFAULT now(),
    added_by     TEXT        NOT NULL,
    PRIMARY KEY  (case_id, query_id)
);

CREATE INDEX IF NOT EXISTS ix_incident_case_queries_case_id
    ON incident_case_queries (case_id);

GRANT SELECT, INSERT, DELETE ON incident_case_queries TO keystone_app;
