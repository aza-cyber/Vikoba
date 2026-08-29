-- Non-destructive migration: adds login support (role + PIN) to an EXISTING
-- vikoba database WITHOUT dropping/reseeding (unlike schema.sql). Safe to run
-- more than once.
--
--   psql -U vikoba_app -d vikoba -f migrate_roles.sql

ALTER TABLE members ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'member';
ALTER TABLE members ADD COLUMN IF NOT EXISTS pin  TEXT NOT NULL DEFAULT '1234';

-- Office bearers (chairperson, secretary, treasurer) get the admin panel.
UPDATE members SET role = 'admin' WHERE id IN ('M007', 'M001', 'M003');

-- Show the result so you can confirm.
SELECT id, name, phone, role, pin FROM members ORDER BY id;
