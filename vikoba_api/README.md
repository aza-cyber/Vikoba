# VICOBA API (PostgreSQL backend)

A small Dart HTTP server that sits between the Flutter app and PostgreSQL.

```
Flutter app  ──HTTP──►  this API  ──SQL──►  PostgreSQL
```

The app never sees the database password; this server holds it and derives all
balances from the transaction rows.

---

## Quickest start — Docker Compose

From the repo root, with [Docker](https://docs.docker.com/get-docker/) installed:

```bash
cp .env.example .env      # optionally edit PGPASSWORD
docker compose up --build
```

This starts PostgreSQL (seeded from `schema.sql` on first run) and the API,
listening on `http://localhost:8090`. Skip straight to
[Step 4 — Test it](#step-4--test-it-before-touching-the-app). `docker compose down`
stops it; add `-v` to also wipe the database volume.

To run the API against a database you manage yourself instead, follow the
manual steps below.

## Step 1 — Create the database

In **psql** (or pgAdmin), as the `postgres` superuser:

```sql
CREATE DATABASE vikoba;
CREATE USER vikoba_app WITH PASSWORD 'change_me';
GRANT ALL PRIVILEGES ON DATABASE vikoba TO vikoba_app;
\c vikoba
GRANT ALL ON SCHEMA public TO vikoba_app;
```

## Step 2 — Create the tables + sample data

From this folder:

```bash
psql -U vikoba_app -d vikoba -f schema.sql
```

(It drops/recreates the tables and inserts the sample group + first admin.)
Verify:

```bash
psql -U vikoba_app -d vikoba -c "SELECT count(*) FROM members;"   # -> 1 (the admin)
```

## Step 3 — Run the API

```bash
dart pub get
# set the DB password you chose (PowerShell):
$env:PGPASSWORD = "change_me"
dart run bin/server.dart
```

You should see: `VICOBA API listening on http://0.0.0.0:8090`.

Connection settings come from env vars (defaults in parentheses):
`PGHOST (localhost)`, `PGPORT (5432)`, `PGDATABASE (vikoba)`,
`PGUSER (vikoba_app)`, `PGPASSWORD (required, no default)`, `PORT (8090)` —
the HTTP port the API listens on (must match the app's `Config.apiPort`).

## Step 4 — Test it (before touching the app)

```bash
curl http://localhost:8090/health      # {"ok":true}
# /snapshot now requires a session token — log in first:
curl -s http://localhost:8090/login -H 'Content-Type: application/json' \
  -d '{"phone":"0000000000","password":"0000"}'          # -> {"ok":true,"token":"…",…}
curl http://localhost:8090/snapshot -H 'Authorization: Bearer <token>'
```

## Step 5 — Point the Flutter app at the API

Online mode (`Config.useApi`) is the default, so you don't edit source. Set the
backend address either at build time or on the device:

```bash
# build time — no source edit, no rebuild to change it later:
flutter run --dart-define=API_BASE_URL=http://<your-PC-IP>:8090
```

...or just type the address into the app's **Server address** field on the login
screen (it persists on the device). Pick the host for how you run the app:
- **Android emulator** → `http://10.0.2.2:8090` (10.0.2.2 = your PC; this is the default)
- **Real phone on the same Wi-Fi** → `http://<your-PC-IP>:8090`
  (find it with `ipconfig`; the API already binds `0.0.0.0`)
- **Desktop / Chrome** → `http://localhost:8090`

Other build-time knobs: `--dart-define=USE_API=false` (offline SQLite mode),
`--dart-define=API_PORT=8080` (must match the server's `PORT`).

Then run the app. Log in (see credentials below), then adding a member/saving/loan
writes to PostgreSQL, and you can see it from psql:

```bash
psql -U vikoba_app -d vikoba -c "SELECT name, shares FROM members;"
```

## Endpoints

All routes except `/health`, `/login`, and `/seed` require a session token as
`Authorization: Bearer <token>`. `/snapshot`, `/loans`, and `/logout` are open to
any logged-in member; **every other mutating route is admin-only** (`403`
otherwise). Missing/expired token → `401`.

| Method | Path | Body / notes |
|---|---|---|
| GET  | `/health` | — (public) |
| POST | `/login` | `{phone, password}` → `{ok, token, memberId, name, role}` (401 on bad credentials) |
| POST | `/logout` | — (revokes the bearer token) |
| GET  | `/snapshot` | — (whole group, balances derived; each member has a `role`) |
| GET  | `/audit` | — recent audit events (who did what, when) — admin only |
| GET  | `/reports/members` · `/reports/loans` · `/reports/cashbook` | — CSV export (member statement, loan aging, cashbook) — admin only |
| POST | `/members` | `{name, phone, shares}` — admin only |
| POST | `/savings` | `{memberId, amount, date, type, method}` — admin only |
| POST | `/loans` | `{memberId, principal, interestRate, durationMonths, dueDate, guarantorIds, status?}` — a member may only file their own `request`; admins may disburse |
| POST | `/loans/approve` · `/loans/reject` | `{loanId}` — admin only |
| POST | `/repayments` | `{loanId, amount, date}` — admin only |
| POST | `/fines` · `/fines/pay` | `{memberId, reason, amount, date}` / `{fineId}` — admin only |

(Plus admin-only meeting/agenda/minute/action/amendment routes.) Dates are
epoch-milliseconds; enums use their names (e.g. `regular`, `ongoing`).

### Admin vs member panels (login)

The app has two panels chosen by the member's `role`:
- **admin** — office bearers (chairperson, secretary, treasurer): full group management.
- **member** — everyone else: self-service (own savings/loans, loan requests, group info).

`POST /login` checks the member's phone + PIN (matching is lenient about phone
formatting — last 9 digits) and returns a session `token`. The schema seeds a
single admin to bootstrap the group; add the rest in-app:

| Phone | PIN | Role | Who |
|---|---|---|---|
| `0000000000` | `0000` | admin | Admin (chairperson) — rename after first login |

New members get PIN **1234** by default (bcrypt-hashed on the server); change it
per member as needed.

A member's loan application comes in via `POST /loans` with `status: "request"`
(pending an officer's approval); officers disbursing a loan omit it (defaults to
`ongoing`).

> Security: PINs are stored as **bcrypt hashes** (never plaintext), `/login`
> issues a **session token** kept in the `sessions` table, and routes are
> **authorized by role** (admin vs member). Still to add before public,
> internet-facing use: HTTPS/TLS and rate-limiting on `/login`.

## Notes / next steps (production)
- **HTTP only** here — fine for a LAN. For internet-facing use add HTTPS/TLS in
  front (the token is already required and checked on every non-public request).
- A phone can only reach this while on the **same network** as your PC. To use it
  anywhere, host the API + PostgreSQL on a server (or a managed Postgres).
- Android blocks plain HTTP by default in release builds; for testing use a debug
  build or add a network-security config allowing cleartext to your PC's IP.
