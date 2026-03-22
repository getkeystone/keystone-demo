-- Restrict keystone_app from reading password hashes.
-- The login endpoint uses TAMPER_DATABASE_URL (superuser connection) for
-- password verification, so keystone_app no longer needs password_hash.

-- Create a view that excludes password_hash (for convenience)
CREATE OR REPLACE VIEW users_safe AS
  SELECT id, username, role FROM users;

-- Revoke direct table-level SELECT from the app role
REVOKE SELECT ON users FROM keystone_app;

-- Grant SELECT only on the safe columns (id, username, role)
GRANT SELECT (id, username, role) ON users TO keystone_app;

-- Grant SELECT on the safe view
GRANT SELECT ON users_safe TO keystone_app;
