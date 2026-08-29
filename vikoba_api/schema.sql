-- VICOBA PostgreSQL schema + sample seed data.
-- Run against the `vikoba` database:  psql -U vikoba_app -d vikoba -f schema.sql
--
-- Dates are stored as BIGINT epoch-milliseconds to match the Flutter app's JSON
-- format exactly (no timezone conversion). Balances are NOT stored — the API
-- derives them from the transaction rows.

DROP TABLE IF EXISTS loan_guarantors, repayments, savings, fines, loans,
  agendas, meeting_attendance, meeting_minutes, meeting_actions, meetings,
  officers, sessions, membership_requests, members, amendments, group_settings,
  super_admin_sessions, super_admins CASCADE;

-- Money is stored as NUMERIC (fixed-point) rather than DOUBLE PRECISION so
-- balances and share-out splits are exact — no binary-float rounding drift.
-- The API decodes NUMERIC as a string and coerces it to double at the JSON
-- boundary, so the app's contract is unchanged.

CREATE TABLE group_settings (
  id                   INT PRIMARY KEY DEFAULT 1,
  name                 TEXT NOT NULL,
  term                 TEXT NOT NULL,
  share_value          NUMERIC(14,2) NOT NULL DEFAULT 5000,
  social_fund_per_mtg  NUMERIC(14,2) NOT NULL DEFAULT 1000,
  interest_rate_pct    NUMERIC(5,2)  NOT NULL DEFAULT 10,
  loan_multiplier      INT NOT NULL DEFAULT 3,
  max_repayment_months INT NOT NULL DEFAULT 4,
  required_guarantors  INT NOT NULL DEFAULT 2,
  min_shares           INT NOT NULL DEFAULT 1,
  max_shares           INT NOT NULL DEFAULT 5,
  cycle_months         INT NOT NULL DEFAULT 12,
  cycle_months_elapsed INT NOT NULL DEFAULT 6,
  meetings_held        INT NOT NULL DEFAULT 0,
  interest_earned      NUMERIC(14,2) NOT NULL DEFAULT 0,
  meeting_expense      NUMERIC(14,2) NOT NULL DEFAULT 0,
  other_expense        NUMERIC(14,2) NOT NULL DEFAULT 0,
  opening_cash         NUMERIC(14,2) NOT NULL DEFAULT 0,
  opening_social_fund  NUMERIC(14,2) NOT NULL DEFAULT 0,
  constitution_seeded  BOOLEAN NOT NULL DEFAULT FALSE  -- server seeds articles once
);

CREATE TABLE members (
  id        TEXT PRIMARY KEY,
  name      TEXT NOT NULL,
  phone     TEXT NOT NULL DEFAULT '',
  shares    INT  NOT NULL DEFAULT 0
              CONSTRAINT chk_members_shares CHECK (shares >= 0),
  role      TEXT NOT NULL DEFAULT 'member'   -- admin | member (which panel they see)
              CONSTRAINT chk_members_role CHECK (role IN ('admin', 'member')),
  pin       TEXT NOT NULL DEFAULT '',        -- legacy plaintext (unused; blanked on boot)
  pin_hash  TEXT,                            -- bcrypt hash of the login PIN
  active    BOOLEAN NOT NULL DEFAULT TRUE,   -- false = suspended, cannot log in
  joined_on BIGINT NOT NULL
);

-- Server-side sessions. A login inserts one row; the token is the bearer
-- credential the app sends as `Authorization: Bearer <token>`. Deleting the
-- row revokes the session (logout / expiry).
CREATE TABLE sessions (
  token      TEXT PRIMARY KEY,
  member_id  TEXT NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  role       TEXT NOT NULL
               CONSTRAINT chk_sessions_role CHECK (role IN ('admin', 'member')),
  created_at BIGINT NOT NULL,
  expires_at BIGINT NOT NULL
);

CREATE TABLE membership_requests (
  id           TEXT PRIMARY KEY,
  name         TEXT NOT NULL,
  phone        TEXT NOT NULL DEFAULT '',
  shares       INT NOT NULL DEFAULT 1
                 CONSTRAINT chk_membership_requests_shares CHECK (shares >= 0),
  status       TEXT NOT NULL DEFAULT 'pending'
                 CONSTRAINT chk_membership_requests_status
                 CHECK (status IN ('pending', 'approved', 'rejected')),
  requested_on BIGINT NOT NULL,
  decided_on   BIGINT NOT NULL DEFAULT 0,
  decided_by   TEXT NOT NULL DEFAULT ''
);
CREATE INDEX idx_membership_requests_status ON membership_requests(status);

-- Platform super-admins: the registry managers (a separate identity from group
-- members). Authenticated by username + bcrypt PIN; they hold their own session
-- tokens below. The built-in default (superadmin / 0000) is seeded at the end.
CREATE TABLE super_admins (
  id         TEXT PRIMARY KEY,
  username   TEXT NOT NULL UNIQUE,   -- stored lower-case; matched case-insensitively
  pin_hash   TEXT NOT NULL,          -- bcrypt hash of the login PIN
  active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at BIGINT NOT NULL
);

-- Super-admin sessions (kept separate from members' `sessions` — no members FK).
CREATE TABLE super_admin_sessions (
  token      TEXT PRIMARY KEY,
  admin_id   TEXT NOT NULL REFERENCES super_admins(id) ON DELETE CASCADE,
  created_at BIGINT NOT NULL,
  expires_at BIGINT NOT NULL
);
CREATE INDEX idx_sa_sessions_admin ON super_admin_sessions(admin_id);

CREATE TABLE savings (
  id        TEXT PRIMARY KEY,
  member_id TEXT NOT NULL REFERENCES members(id),
  amount    NUMERIC(14,2) NOT NULL
              CONSTRAINT chk_savings_amount CHECK (amount > 0),
  type      TEXT NOT NULL           -- regular | special | social
              CONSTRAINT chk_savings_type
              CHECK (type IN ('regular', 'special', 'social')),
  method    TEXT NOT NULL,
  date      BIGINT NOT NULL
);

CREATE TABLE loans (
  id              TEXT PRIMARY KEY,
  member_id       TEXT NOT NULL REFERENCES members(id),
  member_name     TEXT NOT NULL,
  principal       NUMERIC(14,2) NOT NULL
                    CONSTRAINT chk_loans_principal CHECK (principal > 0),
  interest_rate   NUMERIC(5,2) NOT NULL DEFAULT 10
                    CONSTRAINT chk_loans_rate CHECK (interest_rate >= 0),
  duration_months INT NOT NULL DEFAULT 3
                    CONSTRAINT chk_loans_duration CHECK (duration_months > 0),
  due_date        BIGINT NOT NULL,
  status          TEXT NOT NULL     -- request | ongoing | paid | rejected
                    CONSTRAINT chk_loans_status
                    CHECK (status IN ('request', 'ongoing', 'paid', 'rejected')),
  purpose         TEXT NOT NULL DEFAULT '',
  disbursed_on    BIGINT NOT NULL
);

CREATE TABLE repayments (
  id      TEXT PRIMARY KEY,
  loan_id TEXT NOT NULL REFERENCES loans(id),
  amount  NUMERIC(14,2) NOT NULL
            CONSTRAINT chk_repay_amount CHECK (amount > 0),
  method  TEXT NOT NULL DEFAULT 'cash',
  date    BIGINT NOT NULL
);

CREATE TABLE fines (
  id        TEXT PRIMARY KEY,
  member_id TEXT NOT NULL REFERENCES members(id),
  reason    TEXT NOT NULL,
  amount    NUMERIC(14,2) NOT NULL
              CONSTRAINT chk_fines_amount CHECK (amount > 0),
  paid      BOOLEAN NOT NULL DEFAULT TRUE,
  date      BIGINT NOT NULL
);

CREATE TABLE meetings (
  id           TEXT PRIMARY KEY,
  number       INT NOT NULL,
  date         BIGINT NOT NULL,
  attended     INT NOT NULL DEFAULT 0,
  total        INT NOT NULL DEFAULT 0,
  agenda_items INT NOT NULL DEFAULT 0,
  decisions    INT NOT NULL DEFAULT 0,
  collections  NUMERIC(14,2) NOT NULL DEFAULT 0
                 CONSTRAINT chk_meetings_collections CHECK (collections >= 0),
  fines        NUMERIC(14,2) NOT NULL DEFAULT 0
                 CONSTRAINT chk_meetings_fines CHECK (fines >= 0),
  title        TEXT NOT NULL DEFAULT '',
  start_time   TEXT NOT NULL DEFAULT '',
  location     TEXT NOT NULL DEFAULT '',
  period       TEXT NOT NULL DEFAULT '',
  chairperson  TEXT NOT NULL DEFAULT '',
  secretary    TEXT NOT NULL DEFAULT '',
  status       TEXT NOT NULL DEFAULT 'draft'   -- draft | open | closed
                 CONSTRAINT chk_meetings_status
                 CHECK (status IN ('draft', 'open', 'closed'))
);

-- Per-member attendance for a meeting.
CREATE TABLE meeting_attendance (
  meeting_id TEXT NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  member_id  TEXT NOT NULL REFERENCES members(id),
  status     TEXT NOT NULL DEFAULT 'present'   -- present | absent | excused
               CONSTRAINT chk_attendance_status
               CHECK (status IN ('present', 'absent', 'excused')),
  PRIMARY KEY (meeting_id, member_id)
);

-- Minutes: topics discussed / decisions recorded during a meeting.
CREATE TABLE meeting_minutes (
  id         TEXT PRIMARY KEY,
  meeting_id TEXT NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  text       TEXT NOT NULL,
  position   INT NOT NULL DEFAULT 0
);

-- Follow-up action items with a responsible person and due date.
CREATE TABLE meeting_actions (
  id          TEXT PRIMARY KEY,
  meeting_id  TEXT NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  task        TEXT NOT NULL,
  responsible TEXT NOT NULL DEFAULT '',
  due_date    BIGINT NOT NULL DEFAULT 0,
  done        BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE officers (
  id          TEXT PRIMARY KEY,
  member_name TEXT NOT NULL,
  role        TEXT NOT NULL,        -- chairperson|secretary|treasurer|keyHolder|mobilizer
  phone       TEXT NOT NULL DEFAULT ''
);

-- Agenda items an officer drafts for a meeting (the dynamic meeting agenda).
CREATE TABLE agendas (
  id        TEXT PRIMARY KEY,
  meeting_id TEXT NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  text      TEXT NOT NULL,
  position  INT NOT NULL DEFAULT 0,
  done      BOOLEAN NOT NULL DEFAULT FALSE  -- ticked off as the meeting runs
);

CREATE TABLE loan_guarantors (
  loan_id   TEXT NOT NULL REFERENCES loans(id),
  member_id TEXT NOT NULL REFERENCES members(id),
  PRIMARY KEY (loan_id, member_id)
);

-- Constitution amendments: rule changes the group adds/edits over time. The
-- eight built-in articles live in the app; these are the group's own additions.
CREATE TABLE amendments (
  id    TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  body  TEXT NOT NULL,
  date  BIGINT NOT NULL
);

-- Audit trail: who did what, when. Every significant mutation (savings, loans,
-- approvals, fines, meeting edits, deletions) writes one row here with the
-- acting member from their session. `detail` is a small JSON blob. (The server
-- also adds a `created_at` column to the core tables on boot.)
CREATE TABLE audit_events (
  id         TEXT PRIMARY KEY,
  at         BIGINT NOT NULL,
  actor_id   TEXT NOT NULL DEFAULT '',
  actor_role TEXT NOT NULL DEFAULT '',
  action     TEXT NOT NULL,        -- create | update | delete | approve | reject | pay | disburse | status | request
  entity     TEXT NOT NULL,        -- member | saving | loan | repayment | fine | meeting | agenda | minute | action | amendment
  entity_id  TEXT NOT NULL DEFAULT '',
  detail     TEXT                  -- optional JSON
);
CREATE INDEX idx_audit_at ON audit_events(at);
CREATE INDEX idx_audit_entity ON audit_events(entity, entity_id);

-- ------------------------------------------------------------------- indexes
-- Speed up the common lookups: transactions by member/loan, meeting children by
-- meeting, and status/date filters. (Primary keys already cover id/token and the
-- composite meeting_attendance(meeting_id, member_id).)
CREATE INDEX idx_savings_member    ON savings(member_id);
CREATE INDEX idx_savings_date      ON savings(date);
CREATE INDEX idx_loans_member      ON loans(member_id);
CREATE INDEX idx_loans_status      ON loans(status);
CREATE INDEX idx_repayments_loan   ON repayments(loan_id);
CREATE INDEX idx_repayments_date   ON repayments(date);
CREATE INDEX idx_fines_member      ON fines(member_id);
CREATE INDEX idx_attendance_member ON meeting_attendance(member_id);
CREATE INDEX idx_minutes_meeting   ON meeting_minutes(meeting_id);
CREATE INDEX idx_actions_meeting   ON meeting_actions(meeting_id);
CREATE INDEX idx_agendas_meeting   ON agendas(meeting_id);
CREATE INDEX idx_sessions_member   ON sessions(member_id);

-- ----------------------------------------------------------------- seed data
-- A clean, real bootstrap: the group + its first admin only. Everything else
-- (members, savings, loans, meetings) is entered by users in the app.
-- Helper: epoch-ms for a date literal.
--   (EXTRACT(EPOCH FROM TIMESTAMP 'YYYY-MM-DD') * 1000)::BIGINT

INSERT INTO group_settings (id, name, term)
VALUES (1, 'Vijana Group', 'Jan 2026 - Dec 2026');

-- The first admin. Log in with this phone + PIN, then add the rest of the group,
-- and change this account's name/phone/PIN from the app afterwards.
INSERT INTO members (id, name, phone, shares, role, pin, joined_on) VALUES
  ('admin', 'Admin', '0000000000', 0, 'admin', '0000',
   (EXTRACT(EPOCH FROM TIMESTAMP '2026-01-01')*1000)::BIGINT);

INSERT INTO officers (id, member_name, role, phone) VALUES
  ('O-admin', 'Admin', 'chairperson', '0000000000');

-- Note: the built-in super admin (username `superadmin`, PIN `0000`) is NOT
-- seeded here — its PIN needs a bcrypt hash, which the server computes on first
-- boot (migration v4) when the `super_admins` table is empty. Change or replace
-- it from the in-app "Manage super admins" screen after logging in.
