-- Vikoba — PostgreSQL schema (tables only)
-- Mirrors lib/core/db/tables.dart (Drift)
--
-- Create the database by hand first, then run this file against it:
--   createdb -U postgres vikoba
--   psql -U postgres -d vikoba -f db\schema.sql
--
-- Drift -> Postgres type mapping used here:
--   IntColumn      -> INTEGER
--   TextColumn     -> TEXT
--   RealColumn     -> DOUBLE PRECISION
--   DateTimeColumn -> TIMESTAMPTZ
--   BoolColumn     -> BOOLEAN

-- Single-row table holding the group identity + constitution/rule settings.
CREATE TABLE IF NOT EXISTS group_settings (
    id                     INTEGER          NOT NULL DEFAULT 1,
    name                   TEXT             NOT NULL,
    term                   TEXT             NOT NULL,
    share_value            DOUBLE PRECISION NOT NULL DEFAULT 5000,
    social_fund_per_mtg    DOUBLE PRECISION NOT NULL DEFAULT 1000,
    interest_rate_pct      DOUBLE PRECISION NOT NULL DEFAULT 10,
    loan_multiplier        INTEGER          NOT NULL DEFAULT 3,
    max_repayment_months   INTEGER          NOT NULL DEFAULT 4,
    required_guarantors    INTEGER          NOT NULL DEFAULT 2,
    min_shares             INTEGER          NOT NULL DEFAULT 1,
    max_shares             INTEGER          NOT NULL DEFAULT 5,
    cycle_months           INTEGER          NOT NULL DEFAULT 12,
    cycle_months_elapsed   INTEGER          NOT NULL DEFAULT 6,
    meetings_held          INTEGER          NOT NULL DEFAULT 0,
    interest_earned        DOUBLE PRECISION NOT NULL DEFAULT 0,
    meeting_expense        DOUBLE PRECISION NOT NULL DEFAULT 0,
    other_expense          DOUBLE PRECISION NOT NULL DEFAULT 0,
    opening_cash           DOUBLE PRECISION NOT NULL DEFAULT 0,
    opening_social_fund    DOUBLE PRECISION NOT NULL DEFAULT 0,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS members (
    id         TEXT        NOT NULL,
    name       TEXT        NOT NULL,
    phone      TEXT        NOT NULL DEFAULT '',
    shares     INTEGER     NOT NULL DEFAULT 0,
    joined_on  TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS savings (
    id         TEXT             NOT NULL,
    member_id  TEXT             NOT NULL REFERENCES members (id),
    amount     DOUBLE PRECISION NOT NULL,
    type       TEXT             NOT NULL,  -- regular | special | social
    method     TEXT             NOT NULL,
    date       TIMESTAMPTZ      NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS loans (
    id              TEXT             NOT NULL,
    member_id       TEXT             NOT NULL REFERENCES members (id),
    member_name     TEXT             NOT NULL,
    principal       DOUBLE PRECISION NOT NULL,
    interest_rate   DOUBLE PRECISION NOT NULL DEFAULT 10,
    duration_months INTEGER          NOT NULL DEFAULT 3,
    due_date        TIMESTAMPTZ      NOT NULL,
    status          TEXT             NOT NULL,  -- request | ongoing | paid
    purpose         TEXT             NOT NULL DEFAULT '',
    disbursed_on    TIMESTAMPTZ      NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS repayments (
    id       TEXT             NOT NULL,
    loan_id  TEXT             NOT NULL REFERENCES loans (id),
    amount   DOUBLE PRECISION NOT NULL,
    method   TEXT             NOT NULL DEFAULT 'cash',
    date     TIMESTAMPTZ      NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fines (
    id         TEXT             NOT NULL,
    member_id  TEXT             NOT NULL REFERENCES members (id),
    reason     TEXT             NOT NULL,
    amount     DOUBLE PRECISION NOT NULL,
    paid       BOOLEAN          NOT NULL DEFAULT TRUE,
    date       TIMESTAMPTZ      NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS meetings (
    id            TEXT             NOT NULL,
    number        INTEGER          NOT NULL,
    date          TIMESTAMPTZ      NOT NULL,
    attended      INTEGER          NOT NULL DEFAULT 0,
    total         INTEGER          NOT NULL DEFAULT 0,
    agenda_items  INTEGER          NOT NULL DEFAULT 0,
    decisions     INTEGER          NOT NULL DEFAULT 0,
    collections   DOUBLE PRECISION NOT NULL DEFAULT 0,
    fines         DOUBLE PRECISION NOT NULL DEFAULT 0,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS officers (
    id           TEXT NOT NULL,
    member_name  TEXT NOT NULL,
    role         TEXT NOT NULL,
    phone        TEXT NOT NULL DEFAULT '',
    PRIMARY KEY (id)
);

-- The two guarantors (wadhamini) backing each loan (many-to-many).
CREATE TABLE IF NOT EXISTS loan_guarantors (
    loan_id    TEXT NOT NULL REFERENCES loans (id),
    member_id  TEXT NOT NULL REFERENCES members (id),
    PRIMARY KEY (loan_id, member_id)
);
