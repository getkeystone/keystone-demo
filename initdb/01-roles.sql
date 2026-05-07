-- Keystone DB permission model
-- Runs after 00-schema.sql (alphabetical order, still as DB owner = keystone).
-- Tables already exist; grants are applied to existing objects.
-- keystone_app: runtime API role — SELECT + INSERT only, no UPDATE/DELETE.
-- keystone_reader: audit inspection role — SELECT only.

-- -------------------------------------------------------------------------
-- keystone_app
-- -------------------------------------------------------------------------
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'keystone_app') THEN
    CREATE ROLE keystone_app WITH LOGIN PASSWORD 'keystone_app_pw';
  END IF;
END $$;

GRANT CONNECT ON DATABASE keystone_dev TO keystone_app;
GRANT USAGE   ON SCHEMA   public   TO keystone_app;

-- Tables were created in 00-schema.sql; grant access now.
GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA public TO keystone_app;

-- Cover any tables added in the future by the owner.
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT ON TABLES TO keystone_app;

-- -------------------------------------------------------------------------
-- keystone_reader
-- -------------------------------------------------------------------------
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'keystone_reader') THEN
    CREATE ROLE keystone_reader WITH LOGIN PASSWORD 'keystone_reader_pw';
  END IF;
END $$;

GRANT CONNECT ON DATABASE keystone_dev TO keystone_reader;
GRANT USAGE   ON SCHEMA   public   TO keystone_reader;
GRANT SELECT  ON ALL TABLES IN SCHEMA public TO keystone_reader;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO keystone_reader;

-- -------------------------------------------------------------------------
-- Proof command (run after stack is up):
--
--   docker compose exec postgres psql -U keystone_app -d keystone \
--     -c "DELETE FROM audit_log WHERE 1=0;"
--   => ERROR: permission denied for table audit_log
-- -------------------------------------------------------------------------
