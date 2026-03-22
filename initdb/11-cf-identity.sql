-- CF Access identity tables and audit_log enrichment columns.
-- Added alongside existing schema (safe to run on any existing instance).

-- cf_users: provisioned from Cloudflare Access + role config.
CREATE TABLE IF NOT EXISTS cf_users (
    id            VARCHAR NOT NULL PRIMARY KEY,
    email         VARCHAR NOT NULL UNIQUE,
    display_name  VARCHAR NOT NULL,
    assigned_role VARCHAR NOT NULL,
    status        VARCHAR NOT NULL DEFAULT 'active',
    source        VARCHAR NOT NULL DEFAULT 'cloudflare_access',
    created_at    TIMESTAMPTZ NOT NULL,
    updated_at    TIMESTAMPTZ NOT NULL,
    last_seen_at  TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_cf_users_email ON cf_users (email);

-- Audit identity enrichment (nullable; existing rows keep empty values).
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS user_id              VARCHAR;
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS user_email           VARCHAR;
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS user_display_name    VARCHAR;
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS auth_source          VARCHAR;
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS simulated_role_used  VARCHAR;

-- Grant cf_users to keystone_app (SELECT + INSERT + UPDATE; no DELETE).
GRANT SELECT, INSERT, UPDATE ON cf_users TO keystone_app;
