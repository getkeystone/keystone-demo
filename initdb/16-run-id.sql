-- 16-run-id.sql — Add nullable run_id column to write tables (KDAT-046).
--
-- Idempotent: uses ADD COLUMN IF NOT EXISTS and CREATE INDEX IF NOT EXISTS.
-- Applied at DB init; for existing databases run via migrate-run-id.sh or
-- manually:
--   docker compose exec -T postgres psql -U keystone -d keystone -f /docker-entrypoint-initdb.d/16-run-id.sql

ALTER TABLE operator_decisions
  ADD COLUMN IF NOT EXISTS run_id TEXT;

ALTER TABLE incident_cases
  ADD COLUMN IF NOT EXISTS run_id TEXT;

ALTER TABLE incident_case_queries
  ADD COLUMN IF NOT EXISTS run_id TEXT;

CREATE INDEX IF NOT EXISTS idx_operator_decisions_run_id
  ON operator_decisions (run_id)
  WHERE run_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_incident_cases_run_id
  ON incident_cases (run_id)
  WHERE run_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_incident_case_queries_run_id
  ON incident_case_queries (run_id)
  WHERE run_id IS NOT NULL;
