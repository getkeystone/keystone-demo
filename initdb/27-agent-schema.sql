-- 27-agent-schema.sql
-- Agent extension tables for KDAT-002 (keystone-api v0.6.0).
-- Creates five tables: agent_plans, agent_plan_steps, agent_action_audit,
-- agent_notifications, agent_approval_tasks.
-- Includes M6 evidence-sensor columns on agent_plan_steps (supersedes 26).
--
-- Permissions are tightened in 25-agent-audit-permissions.sql.
-- Run as DB owner (keystone).

CREATE TABLE IF NOT EXISTS agent_plans (
    plan_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id        VARCHAR NOT NULL,
    user_id           VARCHAR NOT NULL,
    role              VARCHAR NOT NULL,
    status            VARCHAR NOT NULL DEFAULT 'proposed',
    plan_depth_cap    INTEGER NOT NULL DEFAULT 5,
    terminated_reason VARCHAR,
    raw_steps         JSONB,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_agent_plans_session     ON agent_plans(session_id);
CREATE INDEX IF NOT EXISTS ix_agent_plans_user        ON agent_plans(user_id);
CREATE INDEX IF NOT EXISTS ix_agent_plans_user_status ON agent_plans(user_id, status);

CREATE TABLE IF NOT EXISTS agent_plan_steps (
    step_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id          UUID NOT NULL REFERENCES agent_plans(plan_id),
    step_index       INTEGER NOT NULL,
    tool_name        VARCHAR NOT NULL,
    proposed_params  JSONB NOT NULL,
    executed_params  JSONB,
    auth_decision    VARCHAR NOT NULL DEFAULT 'pending',
    severity_tier    VARCHAR,
    executed_at      TIMESTAMPTZ,
    result           JSONB,
    error            TEXT,
    evidence_score   DOUBLE PRECISION,
    hhem_score       DOUBLE PRECISION,
    citation_count   INTEGER,
    evidence_passed  BOOLEAN
);

CREATE UNIQUE INDEX IF NOT EXISTS ix_agent_plan_steps_plan_index
    ON agent_plan_steps(plan_id, step_index);

CREATE TABLE IF NOT EXISTS agent_action_audit (
    action_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id          UUID NOT NULL,
    step_index       INTEGER NOT NULL,
    event_type       VARCHAR NOT NULL DEFAULT 'agent_action',
    tool_name        VARCHAR NOT NULL,
    params_hash      VARCHAR NOT NULL,
    auth_decision    VARCHAR NOT NULL,
    severity_tier    VARCHAR NOT NULL,
    policy_reference VARCHAR NOT NULL,
    role             VARCHAR NOT NULL,
    timestamp        TIMESTAMPTZ NOT NULL DEFAULT now(),
    prev_hash        VARCHAR NOT NULL,
    entry_hash       VARCHAR NOT NULL
);

CREATE INDEX IF NOT EXISTS ix_agent_audit_plan_step ON agent_action_audit(plan_id, step_index);
CREATE INDEX IF NOT EXISTS ix_agent_audit_timestamp ON agent_action_audit(timestamp);

CREATE TABLE IF NOT EXISTS agent_notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id         UUID NOT NULL,
    step_index      INTEGER NOT NULL,
    severity        INTEGER NOT NULL,
    message         TEXT NOT NULL,
    recipients      JSONB NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_agent_notifications_plan ON agent_notifications(plan_id);

CREATE TABLE IF NOT EXISTS agent_approval_tasks (
    approval_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id            UUID NOT NULL,
    step_index         INTEGER NOT NULL,
    tool_name          VARCHAR NOT NULL,
    proposed_params    JSONB NOT NULL,
    severity_tier      VARCHAR NOT NULL,
    requested_by       VARCHAR NOT NULL,
    requested_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    decided_by         VARCHAR,
    decided_at         TIMESTAMPTZ,
    decision           VARCHAR,
    decision_rationale TEXT,
    status             VARCHAR NOT NULL DEFAULT 'pending'
);

CREATE INDEX IF NOT EXISTS ix_agent_approval_status ON agent_approval_tasks(status);
CREATE UNIQUE INDEX IF NOT EXISTS ix_agent_approval_plan_step
    ON agent_approval_tasks(plan_id, step_index);

-- Grants for keystone_app
GRANT SELECT, INSERT, UPDATE ON agent_plans          TO keystone_app;
GRANT SELECT, INSERT, UPDATE ON agent_plan_steps     TO keystone_app;
GRANT SELECT, INSERT         ON agent_action_audit   TO keystone_app;
GRANT SELECT, INSERT         ON agent_notifications  TO keystone_app;
GRANT SELECT, INSERT, UPDATE ON agent_approval_tasks TO keystone_app;
