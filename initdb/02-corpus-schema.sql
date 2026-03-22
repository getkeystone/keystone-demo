-- Corpus FTS schema
-- Runs after 00-schema.sql and 01-roles.sql (alphabetical order, as DB owner).
-- Default privileges set in 01-roles.sql cover tables created here:
--   keystone_app  → SELECT (reads at FTS query time; ingest uses owner creds)
--   keystone_reader → SELECT
-- Ingest writes use TAMPER_DATABASE_URL (owner) so INSERT is not needed here.

-- ── corpus_documents ──────────────────────────────────────────────────────────
-- One row per file in active/. sha256 used to skip unchanged files on re-ingest.

CREATE TABLE IF NOT EXISTS corpus_documents (
    id          BIGSERIAL PRIMARY KEY,
    rel_path    TEXT NOT NULL UNIQUE,
    sha256      CHAR(64) NOT NULL,
    size_bytes  BIGINT NOT NULL,
    mtime_utc   TIMESTAMPTZ NOT NULL,
    mime        TEXT NOT NULL,
    title       TEXT NOT NULL,
    created_utc TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── corpus_chunks ─────────────────────────────────────────────────────────────
-- Fixed-size text chunks with a GENERATED tsvector for GIN FTS.
-- ON DELETE CASCADE: removing a corpus_document wipes its chunks automatically.

CREATE TABLE IF NOT EXISTS corpus_chunks (
    id          BIGSERIAL PRIMARY KEY,
    doc_id      BIGINT  NOT NULL REFERENCES corpus_documents(id) ON DELETE CASCADE,
    chunk_index INTEGER NOT NULL,
    page        INTEGER,               -- PDF page number (1-based); NULL for DOCX/text
    text        TEXT    NOT NULL,
    tsv         TSVECTOR GENERATED ALWAYS AS (to_tsvector('english', text)) STORED,
    UNIQUE (doc_id, chunk_index)
);

-- GIN index for ts_rank_cd / @@ FTS operator
CREATE INDEX IF NOT EXISTS ix_corpus_chunks_tsv    ON corpus_chunks USING GIN (tsv);
CREATE INDEX IF NOT EXISTS ix_corpus_chunks_doc_id ON corpus_chunks (doc_id);

-- ── Explicit grants (belt + suspenders over ALTER DEFAULT PRIVILEGES) ─────────
-- Runtime API (keystone_app) needs SELECT for FTS retrieval.
-- Ingest uses owner credentials (TAMPER_DATABASE_URL) — no INSERT grant needed.

GRANT SELECT ON corpus_documents TO keystone_app;
GRANT SELECT ON corpus_chunks    TO keystone_app;

GRANT SELECT ON corpus_documents TO keystone_reader;
GRANT SELECT ON corpus_chunks    TO keystone_reader;
