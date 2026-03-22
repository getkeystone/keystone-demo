-- Keystone schema bootstrap
-- Runs as the POSTGRES_USER (keystone = DB owner) before 01-roles.sql.
-- Creates all application tables so keystone_app never needs CREATE TABLE.
-- SQLAlchemy's create_all() will find these tables already exist and skip DDL.

CREATE TABLE IF NOT EXISTS users (
    id            VARCHAR NOT NULL PRIMARY KEY,
    username      VARCHAR NOT NULL UNIQUE,
    role          VARCHAR NOT NULL DEFAULT 'member',
    password_hash VARCHAR NOT NULL
);

CREATE TABLE IF NOT EXISTS documents (
    key             VARCHAR NOT NULL PRIMARY KEY,
    document_id     VARCHAR NOT NULL,
    page            INTEGER NOT NULL,
    title           VARCHAR NOT NULL,
    section         VARCHAR NOT NULL,
    status          VARCHAR NOT NULL,
    effective_date  VARCHAR,
    review_date     VARCHAR,
    owner           VARCHAR,
    excerpt         TEXT,
    highlight       VARCHAR,
    notes_json      JSON    DEFAULT '[]',
    min_role_level  INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS ix_documents_document_id ON documents (document_id);

CREATE TABLE IF NOT EXISTS queries (
    id            VARCHAR NOT NULL PRIMARY KEY,
    question      VARCHAR NOT NULL,
    role          VARCHAR NOT NULL,
    mode          VARCHAR NOT NULL,
    scenario_key  VARCHAR NOT NULL,
    guidance_json JSON    NOT NULL,
    created_at    TIMESTAMP
);

CREATE TABLE IF NOT EXISTS audit_log (
    id                      VARCHAR NOT NULL PRIMARY KEY,
    query_id                VARCHAR NOT NULL,
    receipt_id              VARCHAR NOT NULL,
    timestamp               VARCHAR NOT NULL,
    role_used               VARCHAR NOT NULL,
    mode_used               VARCHAR NOT NULL,
    policy_outcome          VARCHAR NOT NULL,
    sources_considered_json JSON    NOT NULL DEFAULT '[]',
    citations_returned_json JSON    NOT NULL DEFAULT '[]',
    prev_hash               VARCHAR NOT NULL DEFAULT '',
    entry_hash              VARCHAR NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_audit_log_query_id ON audit_log (query_id);

CREATE TABLE IF NOT EXISTS sessions (
    token      VARCHAR NOT NULL PRIMARY KEY,
    user_id    VARCHAR NOT NULL,
    username   VARCHAR NOT NULL,
    role       VARCHAR NOT NULL,
    created_at TIMESTAMP
);
