-- Migration 18: Managed users table for KDAT-059 Authority user management.
-- managed_users is the canonical user management state, seeded from lrfd_user_roles.yaml.
-- user_management_events is the governance audit trail for enable/disable/role changes.

CREATE TABLE IF NOT EXISTS managed_users (
    email           VARCHAR PRIMARY KEY,
    display_name    VARCHAR NOT NULL DEFAULT '',
    role            VARCHAR NOT NULL DEFAULT 'member',
    status          VARCHAR NOT NULL DEFAULT 'disabled',
    provisioned_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    enabled_at      TIMESTAMPTZ,
    disabled_at     TIMESTAMPTZ,
    enabled_by      VARCHAR,
    disabled_by     VARCHAR,
    last_login      TIMESTAMPTZ
);

GRANT SELECT, INSERT, UPDATE ON managed_users TO keystone_app;

CREATE TABLE IF NOT EXISTS user_management_events (
    id              VARCHAR PRIMARY KEY,
    ts_utc          TIMESTAMPTZ NOT NULL DEFAULT now(),
    actor_email     VARCHAR NOT NULL,
    actor_role      VARCHAR NOT NULL,
    subject_email   VARCHAR NOT NULL,
    action          VARCHAR NOT NULL,
    old_value       VARCHAR,
    new_value       VARCHAR,
    note            VARCHAR
);

GRANT SELECT, INSERT ON user_management_events TO keystone_app;

-- Allow user management endpoints to invalidate sessions on disable/role-change.
GRANT DELETE ON sessions TO keystone_app;
