-- 12-staged-uploads.sql — Upload staging tables for governed corpus onboarding.
--
-- Workflow:
--   POST /uploads        → row in staged_uploads (status=pending or failed)
--   PATCH /uploads/{id}  → metadata correction (custodian own, admin any)
--   POST /uploads/{id}/activate → moves file to active/, writes corpus_documents row
--   POST /uploads/{id}/reject   → requires non-empty reason
--   DELETE /uploads/{id}        → restricted to pending/failed/rejected states
--
-- Status lifecycle:
--   pending            — file stored in staging/, extraction succeeded, awaiting activation
--   failed             — extraction failed; no chunks stored
--   rejected           — explicitly rejected by admin/custodian
--   activated          — committed to corpus_documents; file in active/
--   activation_file_error — DB committed but rename to active/ failed (operator attention required)

CREATE TABLE IF NOT EXISTS staged_uploads (
    id                    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    uploaded_at           TIMESTAMPTZ  NOT NULL DEFAULT now(),
    uploader_username     TEXT         NOT NULL,
    uploader_role         TEXT         NOT NULL,

    -- Stored filename in staging/ (may differ from original upload name after sanitisation)
    original_filename     TEXT         NOT NULL,
    stored_filename       TEXT         NOT NULL,

    sha256                CHAR(64)     NOT NULL,
    size_bytes            BIGINT       NOT NULL,
    mime                  TEXT         NOT NULL,

    -- Metadata supplied at upload time; patchable before activation
    title                 TEXT         NOT NULL DEFAULT '',
    owner                 TEXT         NOT NULL DEFAULT '',
    effective_date        TEXT         NOT NULL DEFAULT '',
    review_date           TEXT         NOT NULL DEFAULT '',
    domain                TEXT         NOT NULL DEFAULT '',
    content_kind          TEXT         NOT NULL DEFAULT '',
    min_role              TEXT         NOT NULL DEFAULT 'member',

    status                TEXT         NOT NULL DEFAULT 'pending',
    failure_reason        TEXT         NOT NULL DEFAULT '',  -- EXTRACTION_ERROR / NO_TEXT_EXTRACTED / UNSUPPORTED_TYPE
    failure_detail        TEXT         NOT NULL DEFAULT '',

    rejection_reason      TEXT         NOT NULL DEFAULT '',
    rejected_by           TEXT         NOT NULL DEFAULT '',
    rejected_at           TIMESTAMPTZ,

    activated_at          TIMESTAMPTZ,
    activated_by          TEXT         NOT NULL DEFAULT '',
    -- rel_path assigned at activation (equals stored_filename for top-level files)
    activated_rel_path    TEXT         NOT NULL DEFAULT '',
    activation_error      TEXT         NOT NULL DEFAULT '',

    processing_started_at  TIMESTAMPTZ,
    processing_completed_at TIMESTAMPTZ,

    CONSTRAINT staged_uploads_status_check CHECK (
        status IN ('pending', 'failed', 'rejected', 'activated', 'activation_file_error')
    ),
    CONSTRAINT staged_uploads_min_role_check CHECK (
        min_role IN ('member', 'custodian', 'officer', 'admin')
    )
);

CREATE INDEX IF NOT EXISTS ix_staged_uploads_uploaded_at
    ON staged_uploads (uploaded_at DESC);

CREATE INDEX IF NOT EXISTS ix_staged_uploads_status
    ON staged_uploads (status);

CREATE INDEX IF NOT EXISTS ix_staged_uploads_uploader
    ON staged_uploads (uploader_username);

-- ── staged_upload_chunks ──────────────────────────────────────────────────────
-- Preview chunks extracted at upload time.
-- Discarded when the upload is activated (corpus_chunks becomes authoritative)
-- or rejected/deleted.

CREATE TABLE IF NOT EXISTS staged_upload_chunks (
    id           BIGSERIAL    PRIMARY KEY,
    upload_id    UUID         NOT NULL REFERENCES staged_uploads(id) ON DELETE CASCADE,
    chunk_index  INTEGER      NOT NULL,
    page         INTEGER,
    text         TEXT         NOT NULL,
    UNIQUE (upload_id, chunk_index)
);

CREATE INDEX IF NOT EXISTS ix_staged_upload_chunks_upload_id
    ON staged_upload_chunks (upload_id);

-- ── Grants ────────────────────────────────────────────────────────────────────
-- keystone_app runtime role needs full CRUD on staged_uploads.
-- Ingest script does NOT touch these tables (owner creds only used for corpus tables).

GRANT SELECT, INSERT, UPDATE, DELETE ON staged_uploads       TO keystone_app;
GRANT SELECT, INSERT, DELETE         ON staged_upload_chunks TO keystone_app;
GRANT USAGE, SELECT ON SEQUENCE staged_upload_chunks_id_seq  TO keystone_app;
