-- Migration 17: Four-role permission model
-- Replaces admin role with authority in users and sessions tables.
-- Run once on existing deployments. Safe to re-run (idempotent via WHERE clause).
--
-- Roles after this migration: member, officer, custodian, authority
-- Separation of duties: custodian uploads, authority approves — never the same person.

-- Migrate any users with role='admin' to role='authority'
UPDATE users SET role = 'authority' WHERE role = 'admin';

-- Migrate any cached sessions with role='admin' to role='authority'
UPDATE sessions SET role = 'authority' WHERE role = 'admin';

-- Note: audit_log.role_used entries with 'admin' are left as-is.
-- Historical records are immutable; the HMAC chain covers them.
-- 'admin' entries in audit_log represent pre-migration activity.
