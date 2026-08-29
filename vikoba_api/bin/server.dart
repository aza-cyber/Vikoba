import 'dart:convert';
import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:vikoba_api/fcm.dart';
import 'package:vikoba_api/migrations.dart';
import 'package:vikoba_api/rules.dart' as rules;
import 'package:vikoba_api/sms.dart';

/// VICOBA backend API.
///
/// The Flutter app talks to this over HTTP; only this server talks to
/// PostgreSQL (so the DB password never ships in the app). Balances are DERIVED
/// here from the transaction rows, then returned as JSON the app understands.
///
/// Configure the DB connection via environment variables (with sane defaults):
///   PGHOST (localhost)  PGPORT (5432)  PGDATABASE (vikoba)
///   PGUSER (postgres) PGPASSWORD (12345)
late final Connection db;

/// The SMS gateway used to deliver login one-time passcodes. Resolved from the
/// AT_* environment variables at boot; falls back to a logging no-op sender when
/// no provider is configured (so OTP works in development).
late final SmsSender sms;

/// The push gateway (Firebase Cloud Messaging) used to notify members of loans,
/// meetings, etc. Resolved from FCM_SERVICE_ACCOUNT at boot; falls back to a
/// logging no-op when no Firebase project is configured.
late final PushSender push;

Future<void> main() async {
  final env = Platform.environment;
  sms = smsSenderFromEnv(env);
  push = pushSenderFromEnv(env);
  final pgPassword = env['PGPASSWORD'];
  if (pgPassword == null || pgPassword.isEmpty) {
    stderr.writeln('PGPASSWORD environment variable is required.');
    exit(1);
  }
  db = await Connection.open(
    Endpoint(
      host: env['PGHOST'] ?? 'localhost',
      port: int.tryParse(env['PGPORT'] ?? '') ?? 5432,
      database: env['PGDATABASE'] ?? 'vikoba',
      username: env['PGUSER'] ?? 'postgres',
      password: pgPassword,
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );
  stdout.writeln('Connected to PostgreSQL.');
  await _ensureSchema();

  final router = Router()
    ..get('/health', (Request r) => _json({'ok': true}))
    ..post('/seed', (Request r) => _json({'ok': true})) // schema.sql seeds
    ..get('/snapshot', _snapshot)
    ..get('/audit', _auditLog)
    ..get('/reports/members', _reportMembers)
    ..get('/reports/loans', _reportLoans)
    ..get('/reports/cashbook', _reportCashbook)
    ..post('/login', _login)
    ..post('/otp/request', _otpRequest)
    ..post('/otp/verify', _otpVerify)
    ..post('/devices/register', _registerDevice)
    ..post('/devices/unregister', _unregisterDevice)
    ..post('/logout', _logout)
    ..post('/superadmin/login', _superAdminLogin)
    ..post('/superadmin/logout', _superAdminLogout)
    ..get('/superadmin/list', _superAdminList)
    ..post('/superadmin/add', _superAdminAdd)
    ..post('/superadmin/remove', _superAdminRemove)
    ..post('/superadmin/reset-pin', _superAdminResetPin)
    ..post('/superadmin/toggle', _superAdminToggle)
    ..get('/superadmin/groups', _groupsList)
    ..post('/superadmin/groups/add', _groupAdd)
    ..post('/superadmin/groups/update', _groupUpdate)
    ..post('/superadmin/groups/toggle', _groupToggle)
    ..post('/superadmin/groups/remove', _groupRemove)
    ..post('/superadmin/open-group', _openGroup)
    ..post('/members', _addMember)
    ..post('/members/status', _setMemberActive)
    ..post('/members/delete', _deleteMember)
    ..post('/officers/update', _updateOfficerName)
    ..post('/officers/add', _addOfficer)
    ..post('/officers/remove', _removeOfficer)
    ..post('/settings/rules', _updateRules)
    ..post('/membership-requests/apply', _requestMembership)
    ..post('/membership-requests/approve', _approveMembershipRequest)
    ..post('/membership-requests/reject', _rejectMembershipRequest)
    ..post('/savings', _addSaving)
    ..post('/savings/approve', _approveSaving)
    ..post('/savings/reject', _rejectSaving)
    ..post('/shares', _addShares)
    ..post('/shares/approve', _approveShares)
    ..post('/shares/reject', _rejectShares)
    ..post('/loans', _addLoan)
    ..post('/loans/approve', _approveLoan)
    ..post('/loans/reject', _rejectLoan)
    ..post('/repayments', _addRepayment)
    ..post('/fines', _addFine)
    ..post('/fines/pay', _payFine)
    ..post('/amendments', _addAmendment)
    ..post('/amendments/update', _updateAmendment)
    ..post('/amendments/delete', _deleteAmendment)
    ..post('/meetings', _addMeeting)
    ..post('/meetings/update', _updateMeeting)
    ..post('/meetings/status', _setMeetingStatus)
    ..post('/attendance', _setAttendance)
    ..post('/minutes', _addMinute)
    ..post('/minutes/delete', _deleteMinute)
    ..post('/actions', _addAction)
    ..post('/actions/toggle', _toggleAction)
    ..post('/actions/delete', _deleteAction)
    ..post('/agendas', _addAgenda)
    ..post('/agendas/toggle', _toggleAgenda)
    ..post('/agendas/delete', _deleteAgenda);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_cors())
      .addMiddleware(_auth())
      .addHandler(router.call);

  // Port is configurable via the PORT env var (default 8090); the app's
  // Config.apiPort must match. Binds 0.0.0.0 so a phone on the LAN can reach it.
  final port = int.tryParse(env['PORT'] ?? '') ?? 8090;
  final server = await io.serve(handler, '0.0.0.0', port);
  stdout.writeln(
      'VICOBA API listening on http://${server.address.host}:${server.port}');
}

// --------------------------------------------------------------- helpers
Response _json(Object data, {int status = 200}) => Response(
      status,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );

Middleware _cors() => (Handler inner) => (Request req) async {
      if (req.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final res = await inner(req);
      return res.change(headers: _corsHeaders);
    };

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

// --------------------------------------------------------------- auth
/// A verified caller, resolved from the `Authorization: Bearer <token>` header
/// against the `sessions` table. Attached to the request context so handlers
/// know who is acting and whether they are an admin.
class _Session {
  /// The logged-in member's id, or null for a super-admin-opened group session
  /// (which acts as an admin of the group but is not itself a member).
  final String? memberId;
  final String role;

  /// The group this session is scoped to. Every data query filters on it.
  final String groupId;
  const _Session(this.memberId, this.role, this.groupId);
}

/// Routes anyone may reach without a token: the health probe, login, and the
/// (no-op) seed the app pings at startup.
const _publicPaths = {
  'health',
  'login',
  'otp/request',
  'otp/verify',
  'seed',
  'membership-requests/apply',
};

/// Routes an authenticated *member* (non-admin) may reach. `snapshot` is the
/// group ledger every member can view; `loans` is a member applying for their
/// own loan (constrained further in [_addLoan]); `logout` ends their session.
/// Every other route is admin-only.
const _memberPaths = {
  'snapshot',
  'loans',
  // A member may submit their own deposit ('savings') or share purchase
  // ('shares'); the handler forces it to their session id + 'pending' status.
  // Approving/rejecting stays admin-only.
  'savings',
  'shares',
  'logout',
  'officers/add',
  'devices/register',
  'devices/unregister',
};

/// Gatekeeper for every request. Public paths pass through; everything else
/// needs a valid session token, and non-admins are limited to [_memberPaths].
/// The resolved [_Session] is stashed in the request context for handlers.
Middleware _auth() => (Handler inner) => (Request req) async {
      if (req.method == 'OPTIONS') return inner(req);
      final path = req.url.path; // shelf strips the leading slash
      if (_publicPaths.contains(path)) return inner(req);

      // Super-admin routes are a separate identity domain: authenticated against
      // `super_admins` (not `members`). Login is public; every other one needs a
      // valid super-admin token. The resolved id is stashed for the handlers.
      if (path.startsWith('superadmin/')) {
        if (path == 'superadmin/login') return inner(req);
        final adminId = await _superAdminFor(req);
        if (adminId == null) {
          return _json({'ok': false, 'error': 'unauthorized'}, status: 401);
        }
        return inner(req.change(context: {'superAdminId': adminId}));
      }

      final session = await _sessionFor(req);
      if (session == null) {
        return _json({'ok': false, 'error': 'unauthorized'}, status: 401);
      }
      final isAdmin = session.role == 'admin';
      if (!isAdmin && !_memberPaths.contains(path)) {
        return _json({'ok': false, 'error': 'forbidden'}, status: 403);
      }
      return inner(req.change(context: {
        if (session.memberId != null) 'memberId': session.memberId!,
        'role': session.role,
        'groupId': session.groupId,
      }));
    };

/// Resolves the bearer token on a request to a live (non-expired) session, or
/// null if the header is missing/invalid or the session is gone/expired.
Future<_Session?> _sessionFor(Request req) async {
  final header = req.headers['authorization'] ?? '';
  if (!header.startsWith('Bearer ')) return null;
  final token = header.substring(7).trim();
  if (token.isEmpty) return null;
  final rows = await db.execute(
    Sql.named('SELECT member_id, role, group_id, expires_at FROM sessions '
        'WHERE token = @t'),
    parameters: {'t': token},
  );
  if (rows.isEmpty) return null;
  final m = rows.first.toColumnMap();
  if (_i(m['expires_at']) < DateTime.now().millisecondsSinceEpoch) {
    await db.execute(Sql.named('DELETE FROM sessions WHERE token = @t'),
        parameters: {'t': token});
    return null;
  }
  return _Session(m['member_id'] as String?, (m['role'] ?? 'member') as String,
      (m['group_id'] ?? '') as String);
}

/// A 256-bit cryptographically-random opaque session token, hex-encoded.
String _randomToken() => rules.randomToken();

/// Sessions live 30 days, then the caller must log in again.
const _sessionTtlMs = 30 * 24 * 60 * 60 * 1000;

Future<List<Map<String, dynamic>>> _rows(String sql,
    [Map<String, dynamic>? params]) async {
  final result = params == null
      ? await db.execute(sql)
      : await db.execute(Sql.named(sql), parameters: params);
  return result.map((r) => r.toColumnMap()).toList();
}

/// The group the current request is scoped to (from the authenticated session).
String _gid(Request req) => (req.context['groupId'] as String?) ?? '';

/// Idempotently converts a legacy DOUBLE PRECISION money column to [type]
/// (NUMERIC) in place, without data loss. No-op once already converted, so it's
/// safe to run on every boot. Table/column names are internal constants (never
/// user input), so the string interpolation here is not an injection vector.
Future<void> _ensureNumeric(String table, String col,
    [String type = 'NUMERIC(14,2)']) async {
  final rows = await _rows("SELECT data_type FROM information_schema.columns "
      "WHERE table_name = '$table' AND column_name = '$col'");
  if (rows.isNotEmpty && rows.first['data_type'] == 'double precision') {
    await db.execute(
        'ALTER TABLE $table ALTER COLUMN $col TYPE $type USING $col::$type');
    stdout.writeln('Migrated $table.$col to $type.');
  }
}

/// Idempotently adds a named CHECK/FK constraint to an existing table. Skips if
/// already present (matched by name). If existing rows violate it, the ALTER is
/// caught and logged rather than crashing startup — the constraint then applies
/// on the next boot once the data is clean (or on a fresh schema.sql install).
Future<void> _addConstraint(String table, String name, String ddl) async {
  final exists = await _rows("SELECT 1 FROM pg_constraint WHERE conname = '$name'");
  if (exists.isNotEmpty) return;
  try {
    await db.execute('ALTER TABLE $table ADD CONSTRAINT $name $ddl');
  } catch (e) {
    stdout.writeln('Skipped constraint $name — existing data violates it: $e');
  }
}

/// Money columns are NUMERIC, which the postgres driver decodes to a String
/// (to preserve precision). This coerces either representation — legacy
/// DOUBLE (num) or NUMERIC (String) — to a double, so a schema in either state
/// reads correctly. Without the String branch, every NUMERIC balance would
/// silently read as 0.
// These thin wrappers delegate to the shared, unit-tested logic in
// `package:vikoba_api/rules.dart`, so the server and the test suite run the
// exact same code.
double _d(Object? v) => rules.coerceDouble(v);
int _i(Object? v) => rules.coerceInt(v);
String _tzs(double v) => rules.tzs(v);
String _id(String prefix) => '$prefix-${rules.uuidV4()}';

/// Records one entry in the audit trail: who (from the session) did what to
/// which entity, when, with optional detail. Best-effort — a logging failure
/// must never fail the underlying operation.
Future<void> _audit(Request req, String action, String entity, String entityId,
    [Map<String, dynamic>? detail]) async {
  // Public (unauthenticated) actions have no group to attribute the entry to.
  if (_gid(req).isEmpty) return;
  try {
    await db.execute(
      Sql.named('INSERT INTO audit_events '
          '(id, group_id, at, actor_id, actor_role, action, entity, entity_id, detail) '
          'VALUES (@id, @g, @at, @ai, @ar, @ac, @en, @ei, @dt)'),
      parameters: {
        'id': _id('AUD'),
        'g': _gid(req),
        'at': DateTime.now().millisecondsSinceEpoch,
        'ai': (req.context['memberId'] as String?) ?? '',
        'ar': (req.context['role'] as String?) ?? '',
        'ac': action,
        'en': entity,
        'ei': entityId,
        'dt': detail == null ? null : jsonEncode(detail),
      },
    );
  } catch (e) {
    stdout.writeln('Audit log failed ($action $entity): $e');
  }
}

/// Cash currently in the box, derived from the ledger — the same figure
/// `/snapshot` reports as `cashInHand`. Used to block disbursing more than the
/// group actually holds. (The savings SUM already includes the social fund, so
/// that component is folded in and `socialFund` is passed as 0.)
Future<double> _availableCash(String gid) async {
  final g = {'g': gid};
  final s = (await _rows('SELECT opening_cash, meeting_expense, other_expense '
          'FROM groups WHERE id = @g', g))
      .first;
  final savings = (await _rows(
          'SELECT COALESCE(SUM(amount), 0) AS t FROM savings '
          "WHERE group_id = @g AND status = 'confirmed'",
          g))
      .first;
  final repays = (await _rows(
          'SELECT COALESCE(SUM(amount), 0) AS t FROM repayments WHERE group_id = @g',
          g))
      .first;
  final finesPaid = (await _rows(
          'SELECT COALESCE(SUM(amount), 0) AS t FROM fines '
          'WHERE paid = TRUE AND group_id = @g',
          g))
      .first;
  final disbursed = (await _rows('SELECT COALESCE(SUM(principal), 0) AS t '
          "FROM loans WHERE status NOT IN ('request', 'rejected') "
          'AND group_id = @g', g))
      .first;
  return rules.cashInHand(
    openingCash: _d(s['opening_cash']),
    savings: _d(savings['t']),
    socialFund: 0,
    repayments: _d(repays['t']),
    finesPaid: _d(finesPaid['t']),
    loansDisbursed: _d(disbursed['t']),
    meetingExpense: _d(s['meeting_expense']),
    otherExpense: _d(s['other_expense']),
  );
}

/// Reduces a phone number to its last 9 digits, so login is lenient about
/// formatting and country prefixes ('+255 712 345 678', '0712345678' and
/// '255712345678' all match the same member).
String _normPhone(Object? p) {
  final digits = (p ?? '').toString().replaceAll(RegExp(r'\D'), '');
  return digits.length > 9 ? digits.substring(digits.length - 9) : digits;
}

Future<bool> _memberPhoneExists(String gid, String phone) async {
  final normPhone = _normPhone(phone);
  if (normPhone.isEmpty) return false;
  final existing =
      await _rows('SELECT phone FROM members WHERE group_id = @g', {'g': gid});
  return existing.any((m) => _normPhone(m['phone']) == normPhone);
}

Future<bool> _pendingMembershipRequestExists(String gid, String phone,
    {String? exceptId}) async {
  final normPhone = _normPhone(phone);
  if (normPhone.isEmpty) return false;
  final pending = await _rows(
      "SELECT id, phone FROM membership_requests "
      "WHERE status = 'pending' AND group_id = @g",
      {'g': gid});
  return pending.any((r) =>
      r['id'] != exceptId && _normPhone(r['phone']) == normPhone);
}

Future<String?> _membershipPhoneError(String gid, String phone,
    {String? exceptId}) async {
  if (await _memberPhoneExists(gid, phone)) {
    return 'A member with this phone already exists.';
  }
  if (await _pendingMembershipRequestExists(gid, phone, exceptId: exceptId)) {
    return 'A membership request with this phone is already pending.';
  }
  return null;
}

// --------------------------------------------------------------- POST /login
/// Authenticates by phone + PIN. On success it mints a random session token
/// (stored server-side in `sessions`) and returns it with the member's identity
/// and panel (`role`: admin | member). The app sends the token as
/// `Authorization: Bearer <token>` on every subsequent request. PINs are checked
/// against the bcrypt hash in `pin_hash` — the plaintext is never stored.
Future<Response> _login(Request req) async {
  final b = await _body(req);
  final phone = _normPhone(b['phone']);
  final pass = (b['password'] ?? '').toString();
  if (phone.isEmpty) return _json({'ok': false}, status: 401);
  // Multi-tenant: a member's group is resolved by their phone. Match across
  // every group, then verify the PIN; the session is scoped to that group.
  final members = await _rows(
      'SELECT m.id, m.name, m.phone, m.role, m.pin_hash, m.active, '
      'm.group_id, g.name AS group_name, g.active AS group_active '
      'FROM members m JOIN groups g ON g.id = m.group_id');
  for (final m in members) {
    final hash = (m['pin_hash'] ?? '').toString();
    if (_normPhone(m['phone']) == phone &&
        hash.isNotEmpty &&
        BCrypt.checkpw(pass, hash)) {
      // Credentials are correct — but a suspended member (or a deactivated
      // group) cannot sign in. Distinct 403 (vs the 401 for a bad phone/PIN)
      // so the app can show a clear "account not active" message.
      if (m['active'] == false || m['group_active'] == false) {
        return _json({'ok': false, 'error': 'account_inactive'}, status: 403);
      }
      return _json(await _mintMemberSession(m));
    }
  }
  return _json({'ok': false}, status: 401);
}

/// Mints a session for an authenticated member row (from `members JOIN groups`)
/// and returns the JSON payload the app expects — token, identity, role, group.
/// Shared by password login and OTP verification so both issue identical
/// sessions.
Future<Map<String, dynamic>> _mintMemberSession(
    Map<String, dynamic> m) async {
  final token = _randomToken();
  final now = DateTime.now().millisecondsSinceEpoch;
  final role = (m['role'] ?? 'member').toString();
  await db.execute(
    Sql.named('INSERT INTO sessions '
        '(token, member_id, role, group_id, created_at, expires_at) '
        'VALUES (@t, @m, @r, @g, @c, @e)'),
    parameters: {
      't': token,
      'm': m['id'],
      'r': role,
      'g': m['group_id'],
      'c': now,
      'e': now + _sessionTtlMs,
    },
  );
  return {
    'ok': true,
    'token': token,
    'memberId': m['id'],
    'name': m['name'],
    'role': role,
    'groupId': m['group_id'],
    'groupName': m['group_name'],
  };
}

// ------------------------------------------------------- OTP (SMS) login
/// One-time passcodes live 5 minutes; after that the member must request a new
/// one. Short enough to limit exposure, long enough to type a texted code.
const _otpTtlMs = 5 * 60 * 1000;

/// A fresh code can only be requested once per this window, so a caller can't
/// spam a member's phone (or run up the SMS bill) by hammering /otp/request.
const _otpResendMs = 60 * 1000;

/// Wrong-code guesses allowed before the code is burned and a new one must be
/// requested — caps brute-forcing of the 6-digit space.
const _otpMaxAttempts = 5;

/// Looks up the single active member matching [phone] (across all groups),
/// joined to their group. Returns null if no active member/active group matches.
/// Mirrors the matching rules used by password [_login].
Future<Map<String, dynamic>?> _activeMemberByPhone(String phone) async {
  final members = await _rows(
      'SELECT m.id, m.name, m.phone, m.role, m.active, '
      'm.group_id, g.name AS group_name, g.active AS group_active '
      'FROM members m JOIN groups g ON g.id = m.group_id');
  for (final m in members) {
    if (_normPhone(m['phone']) == phone &&
        m['active'] != false &&
        m['group_active'] != false) {
      return m;
    }
  }
  return null;
}

/// POST /otp/request — body `{phone}`. Generates a 6-digit code, stores its
/// bcrypt hash (upserted per phone) and texts it via the configured SMS gateway.
///
/// To avoid leaking which numbers are registered, the response is always
/// `{ok:true}` regardless of whether the phone matched a member — the code is
/// only ever sent to a real, active member. When no SMS provider is configured
/// (dev mode) the code is returned as `devCode` so the flow is testable.
Future<Response> _otpRequest(Request req) async {
  final b = await _body(req);
  final phone = _normPhone(b['phone']);
  if (phone.length < 9) {
    return _json({'ok': false, 'error': 'invalid_phone'}, status: 400);
  }

  final member = await _activeMemberByPhone(phone);
  // Unknown/inactive number: pretend success so callers can't enumerate members.
  if (member == null) return _json({'ok': true});

  final now = DateTime.now().millisecondsSinceEpoch;

  // Rate-limit resends per phone.
  final existing =
      await _rows('SELECT created_at FROM otp_codes WHERE phone = @p', {'p': phone});
  if (existing.isNotEmpty &&
      now - _i(existing.first['created_at']) < _otpResendMs) {
    return _json({'ok': false, 'error': 'too_soon'}, status: 429);
  }

  final code = rules.otpCode();
  await db.execute(
    Sql.named('INSERT INTO otp_codes (phone, code_hash, expires_at, attempts, created_at) '
        'VALUES (@p, @h, @e, 0, @c) '
        'ON CONFLICT (phone) DO UPDATE SET '
        'code_hash = EXCLUDED.code_hash, expires_at = EXCLUDED.expires_at, '
        'attempts = 0, created_at = EXCLUDED.created_at'),
    parameters: {
      'p': phone,
      'h': BCrypt.hashpw(code, BCrypt.gensalt()),
      'e': now + _otpTtlMs,
      'c': now,
    },
  );

  final message = 'VICOBA: your login code is $code. It expires in 5 minutes. '
      'Do not share it with anyone.';
  // `phone` is the normalised 9-digit national number, so the Tanzanian E.164
  // form is simply +255 followed by it.
  final result =
      await sms.send(toPhone: '+255$phone', message: message);
  if (!result.ok) {
    stdout.writeln('OTP SMS failed for ...${phone.substring(phone.length - 3)}: '
        '${result.detail}');
  }

  return _json({
    'ok': true,
    // Only ever include the code when there is no live SMS gateway — this makes
    // local/dev testing possible and is a no-op in production.
    if (!sms.isLive) 'devCode': code,
  });
}

/// POST /otp/verify — body `{phone, code}`. Checks the code against the stored
/// hash (not expired, attempts remaining); on success it burns the code and
/// mints a member session identical to a password login. Wrong codes increment
/// the attempt counter; too many burns the code.
Future<Response> _otpVerify(Request req) async {
  final b = await _body(req);
  final phone = _normPhone(b['phone']);
  final code = (b['code'] ?? '').toString().trim();
  if (phone.isEmpty || code.isEmpty) {
    return _json({'ok': false, 'error': 'invalid'}, status: 400);
  }

  final rows =
      await _rows('SELECT * FROM otp_codes WHERE phone = @p', {'p': phone});
  if (rows.isEmpty) {
    return _json({'ok': false, 'error': 'no_code'}, status: 401);
  }
  final row = rows.first;
  final now = DateTime.now().millisecondsSinceEpoch;

  if (_i(row['expires_at']) < now) {
    await db.execute(
        Sql.named('DELETE FROM otp_codes WHERE phone = @p'), parameters: {'p': phone});
    return _json({'ok': false, 'error': 'expired'}, status: 401);
  }
  if (_i(row['attempts']) >= _otpMaxAttempts) {
    await db.execute(
        Sql.named('DELETE FROM otp_codes WHERE phone = @p'), parameters: {'p': phone});
    return _json({'ok': false, 'error': 'too_many_attempts'}, status: 429);
  }

  final matches = BCrypt.checkpw(code, (row['code_hash'] ?? '').toString());
  if (!matches) {
    await db.execute(
        Sql.named('UPDATE otp_codes SET attempts = attempts + 1 WHERE phone = @p'),
        parameters: {'p': phone});
    return _json({'ok': false, 'error': 'wrong_code'}, status: 401);
  }

  // Correct code — the account may still have been suspended since the code was
  // issued, so re-check it's an active member before minting a session.
  final member = await _activeMemberByPhone(phone);
  await db.execute(
      Sql.named('DELETE FROM otp_codes WHERE phone = @p'), parameters: {'p': phone});
  if (member == null) {
    return _json({'ok': false, 'error': 'account_inactive'}, status: 403);
  }
  return _json(await _mintMemberSession(member));
}

// ------------------------------------------------- push device tokens
/// POST /devices/register — body `{token, platform?}`. Saves (upserts) the
/// caller's FCM device token so the server can push notifications to it. Bound
/// to the authenticated member + group.
Future<Response> _registerDevice(Request req) async {
  final b = await _body(req);
  final token = (b['token'] ?? '').toString().trim();
  if (token.isEmpty) {
    return _json({'ok': false, 'error': 'token required'}, status: 400);
  }
  final memberId = (req.context['memberId'] as String?) ?? '';
  if (memberId.isEmpty) {
    // A super-admin-opened group session has no member to attribute a device to.
    return _json({'ok': false, 'error': 'no member'}, status: 400);
  }
  await db.execute(
    Sql.named('INSERT INTO device_tokens (token, member_id, group_id, platform, updated_at) '
        'VALUES (@t, @m, @g, @p, @u) '
        'ON CONFLICT (token) DO UPDATE SET '
        'member_id = EXCLUDED.member_id, group_id = EXCLUDED.group_id, '
        'platform = EXCLUDED.platform, updated_at = EXCLUDED.updated_at'),
    parameters: {
      't': token,
      'm': memberId,
      'g': _gid(req),
      'p': (b['platform'] ?? '').toString(),
      'u': DateTime.now().millisecondsSinceEpoch,
    },
  );
  return _json({'ok': true});
}

/// POST /devices/unregister — body `{token}`. Removes a device token (called at
/// sign-out) so a signed-out phone stops receiving this member's notifications.
Future<Response> _unregisterDevice(Request req) async {
  final b = await _body(req);
  final token = (b['token'] ?? '').toString().trim();
  if (token.isNotEmpty) {
    await db.execute(Sql.named('DELETE FROM device_tokens WHERE token = @t'),
        parameters: {'t': token});
  }
  return _json({'ok': true});
}

/// Fire-and-forget push to a set of members. Loads their device tokens, sends
/// via [push], and prunes any tokens FCM reports as dead. Best-effort: a push
/// failure must never fail the underlying operation, so all errors are
/// swallowed and logged.
Future<void> _notifyMembers(
  List<String> memberIds, {
  required String title,
  required String body,
  Map<String, String>? data,
}) async {
  final ids = memberIds.where((id) => id.isNotEmpty).toSet().toList();
  if (ids.isEmpty) return;
  try {
    final rows = await _rows(
      'SELECT token FROM device_tokens WHERE member_id = ANY(@ids)',
      {'ids': ids},
    );
    final tokens =
        rows.map((r) => (r['token'] ?? '').toString()).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return;
    final result =
        await push.sendToTokens(tokens, title: title, body: body, data: data);
    for (final dead in result.invalidTokens) {
      await db.execute(Sql.named('DELETE FROM device_tokens WHERE token = @t'),
          parameters: {'t': dead});
    }
  } catch (e) {
    stdout.writeln('Push notify failed ($title): $e');
  }
}

/// All member ids in a group — used to broadcast group-wide notifications
/// (e.g. a new meeting). Excludes suspended members.
Future<List<String>> _activeMemberIds(String gid) async {
  final rows = await _rows(
      'SELECT id FROM members WHERE group_id = @g AND active IS NOT FALSE',
      {'g': gid});
  return rows.map((r) => (r['id'] ?? '').toString()).toList();
}

// --------------------------------------------------------------- GET /audit
/// Admin-only history: the most recent audit events, newest first, with the
/// actor's name resolved. (Admin-only is enforced by the auth middleware.)
Future<Response> _auditLog(Request req) async {
  final rows = await _rows(
      'SELECT a.*, m.name AS actor_name FROM audit_events a '
      'LEFT JOIN members m ON m.id = a.actor_id '
      'WHERE a.group_id = @g ORDER BY a.at DESC LIMIT 200',
      {'g': _gid(req)});
  return _json({
    'events': rows
        .map((e) => {
              'id': e['id'],
              'at': _i(e['at']),
              'actorId': e['actor_id'],
              'actorName': e['actor_name'] ?? '',
              'actorRole': e['actor_role'],
              'action': e['action'],
              'entity': e['entity'],
              'entityId': e['entity_id'],
              'detail': e['detail'],
            })
        .toList()
  });
}

// --------------------------------------------------------------- reports
/// A downloadable CSV response (admin-only via the middleware).
Response _csv(String body, String filename) => Response(
      200,
      body: body,
      headers: {
        'Content-Type': 'text/csv; charset=utf-8',
        'Content-Disposition': 'attachment; filename="$filename"',
      },
    );

/// Formats an epoch-ms timestamp as an ISO date (yyyy-mm-dd), or '' for 0.
String _dateStr(int ms) => ms <= 0
    ? ''
    : DateTime.fromMillisecondsSinceEpoch(ms).toUtc().toIso8601String().substring(0, 10);

/// The repayments total for a loan, across a preloaded repayment list.
double _repaidFor(String loanId, List<Map<String, dynamic>> repays) => repays
    .where((r) => r['loan_id'] == loanId)
    .fold(0.0, (a, r) => a + _d(r['amount']));

/// GET /reports/members — a member statement: shares, savings, outstanding loan
/// balance and unpaid fines per member.
Future<Response> _reportMembers(Request req) async {
  final g = {'g': _gid(req)};
  final members =
      await _rows('SELECT * FROM members WHERE group_id = @g ORDER BY name', g);
  final savings = await _rows(
      'SELECT member_id, amount, type FROM savings '
      "WHERE group_id = @g AND status = 'confirmed'",
      g);
  final fines = await _rows(
      'SELECT member_id, amount, paid FROM fines WHERE group_id = @g', g);
  final loans = await _rows('SELECT * FROM loans WHERE group_id = @g', g);
  final repays =
      await _rows('SELECT loan_id, amount FROM repayments WHERE group_id = @g', g);
  final rows = members.map((m) {
    final id = m['id'];
    final sav = savings
        .where((s) => s['member_id'] == id && s['type'] != 'social')
        .fold(0.0, (a, s) => a + _d(s['amount']));
    final owed = fines
        .where((f) => f['member_id'] == id && f['paid'] != true)
        .fold(0.0, (a, f) => a + _d(f['amount']));
    final bal = loans.where((l) => l['member_id'] == id).fold(0.0, (a, l) {
      final total = rules.loanTotalDue(
          _d(l['principal']), _d(l['interest_rate']), _i(l['duration_months']));
      final b = rules.loanBalance(total, _repaidFor(l['id'] as String, repays));
      return a +
          (rules.effectiveLoanStatus(l['status'] as String, b) == 'ongoing'
              ? b
              : 0);
    });
    return <Object?>[
      id,
      m['name'],
      m['phone'],
      _i(m['shares']),
      sav.toStringAsFixed(2),
      bal.toStringAsFixed(2),
      owed.toStringAsFixed(2),
    ];
  }).toList();
  return _csv(
      rules.toCsv(const [
        'id', 'name', 'phone', 'shares', 'savings', 'loan_balance', 'fines_owed'
      ], rows),
      'members.csv');
}

/// GET /reports/loans — loan aging: principal, outstanding balance, effective
/// status and due date for every loan.
Future<Response> _reportLoans(Request req) async {
  final g = {'g': _gid(req)};
  final loans = await _rows(
      'SELECT * FROM loans WHERE group_id = @g ORDER BY disbursed_on DESC', g);
  final repays =
      await _rows('SELECT loan_id, amount FROM repayments WHERE group_id = @g', g);
  final rows = loans.map((l) {
    final total = rules.loanTotalDue(
        _d(l['principal']), _d(l['interest_rate']), _i(l['duration_months']));
    final bal = rules.loanBalance(total, _repaidFor(l['id'] as String, repays));
    final status = rules.effectiveLoanStatus(l['status'] as String, bal);
    return <Object?>[
      l['id'],
      l['member_name'],
      _d(l['principal']).toStringAsFixed(2),
      bal.toStringAsFixed(2),
      status,
      _d(l['interest_rate']),
      _i(l['duration_months']),
      _dateStr(_i(l['due_date'])),
    ];
  }).toList();
  return _csv(
      rules.toCsv(const [
        'id', 'member', 'principal', 'balance', 'status', 'interest_rate',
        'duration_months', 'due_date'
      ], rows),
      'loans.csv');
}

/// GET /reports/cashbook — every cash movement in date order: savings,
/// repayments and paid fines are cash in; disbursed loans are cash out.
Future<Response> _reportCashbook(Request req) async {
  final g = {'g': _gid(req)};
  final members =
      await _rows('SELECT id, name FROM members WHERE group_id = @g', g);
  final nameById = {for (final m in members) m['id']: m['name']};
  final savings = await _rows(
      "SELECT * FROM savings WHERE group_id = @g AND status = 'confirmed'", g);
  final repays = await _rows('SELECT * FROM repayments WHERE group_id = @g', g);
  final loans = await _rows('SELECT * FROM loans WHERE group_id = @g', g);
  final fines = await _rows('SELECT * FROM fines WHERE group_id = @g', g);
  final loanName = {for (final l in loans) l['id']: l['member_name']};

  final entries = <(int, List<Object?>)>[];
  void add(int date, String type, Object? member, double inAmt, double outAmt) {
    entries.add((
      date,
      [
        _dateStr(date),
        type,
        member ?? '',
        inAmt == 0 ? '' : inAmt.toStringAsFixed(2),
        outAmt == 0 ? '' : outAmt.toStringAsFixed(2),
      ]
    ));
  }

  for (final s in savings) {
    add(_i(s['date']), 'saving', nameById[s['member_id']], _d(s['amount']), 0);
  }
  for (final r in repays) {
    add(_i(r['date']), 'repayment', loanName[r['loan_id']], _d(r['amount']), 0);
  }
  for (final f in fines.where((f) => f['paid'] == true)) {
    add(_i(f['date']), 'fine', nameById[f['member_id']], _d(f['amount']), 0);
  }
  for (final l
      in loans.where((l) => l['status'] != 'request' && l['status'] != 'rejected')) {
    add(_i(l['disbursed_on']), 'loan disbursed', l['member_name'], 0,
        _d(l['principal']));
  }
  entries.sort((a, b) => a.$1.compareTo(b.$1));
  return _csv(
      rules.toCsv(const ['date', 'type', 'member', 'cash_in', 'cash_out'],
          entries.map((e) => e.$2).toList()),
      'cashbook.csv');
}

// -------------------------------------------------------------- POST /logout
/// Ends the caller's session by deleting its token, so it can't be reused.
Future<Response> _logout(Request req) async {
  final header = req.headers['authorization'] ?? '';
  if (header.startsWith('Bearer ')) {
    await db.execute(Sql.named('DELETE FROM sessions WHERE token = @t'),
        parameters: {'t': header.substring(7).trim()});
  }
  return _json({'ok': true});
}

// ------------------------------------------------------------ super-admin
/// Resolves a super-admin bearer token to the admin's id, or null if the header
/// is missing/invalid, the session is expired, or the account was deactivated.
/// Mirrors [_sessionFor] but against the platform `super_admin_sessions` table.
Future<String?> _superAdminFor(Request req) async {
  final header = req.headers['authorization'] ?? '';
  if (!header.startsWith('Bearer ')) return null;
  final token = header.substring(7).trim();
  if (token.isEmpty) return null;
  final rows = await db.execute(
    Sql.named('SELECT s.admin_id, s.expires_at, a.active '
        'FROM super_admin_sessions s '
        'JOIN super_admins a ON a.id = s.admin_id '
        'WHERE s.token = @t'),
    parameters: {'t': token},
  );
  if (rows.isEmpty) return null;
  final m = rows.first.toColumnMap();
  if (_i(m['expires_at']) < DateTime.now().millisecondsSinceEpoch) {
    await db.execute(
        Sql.named('DELETE FROM super_admin_sessions WHERE token = @t'),
        parameters: {'t': token});
    return null;
  }
  if (m['active'] == false) return null; // deactivated mid-session
  return m['admin_id'] as String;
}

/// POST /superadmin/login — authenticates a platform super admin by username +
/// PIN against `super_admins` (bcrypt), mints a session token, and returns it.
/// Usernames are matched case-insensitively (stored lower-case).
Future<Response> _superAdminLogin(Request req) async {
  final b = await _body(req);
  final username = (b['username'] ?? '').toString().trim().toLowerCase();
  final pass = (b['password'] ?? '').toString();
  if (username.isEmpty) return _json({'ok': false}, status: 401);
  final rows = await db.execute(
    Sql.named('SELECT id, pin_hash, active FROM super_admins '
        'WHERE username = @u'),
    parameters: {'u': username},
  );
  if (rows.isEmpty) return _json({'ok': false}, status: 401);
  final m = rows.first.toColumnMap();
  final hash = (m['pin_hash'] ?? '').toString();
  if (hash.isEmpty || !BCrypt.checkpw(pass, hash)) {
    return _json({'ok': false}, status: 401);
  }
  if (m['active'] == false) {
    return _json({'ok': false, 'error': 'account_inactive'}, status: 403);
  }
  final token = _randomToken();
  final now = DateTime.now().millisecondsSinceEpoch;
  await db.execute(
    Sql.named('INSERT INTO super_admin_sessions '
        '(token, admin_id, created_at, expires_at) VALUES (@t, @a, @c, @e)'),
    parameters: {'t': token, 'a': m['id'], 'c': now, 'e': now + _sessionTtlMs},
  );
  return _json(
      {'ok': true, 'token': token, 'id': m['id'], 'username': username});
}

/// POST /superadmin/logout — revokes the caller's super-admin session token.
Future<Response> _superAdminLogout(Request req) async {
  final header = req.headers['authorization'] ?? '';
  if (header.startsWith('Bearer ')) {
    await db.execute(
        Sql.named('DELETE FROM super_admin_sessions WHERE token = @t'),
        parameters: {'t': header.substring(7).trim()});
  }
  return _json({'ok': true});
}

/// GET /superadmin/list — every super-admin account (no PIN hashes), oldest
/// first. Super-admin authenticated (enforced by the middleware).
Future<Response> _superAdminList(Request req) async {
  final rows = await _rows('SELECT id, username, active, created_at '
      'FROM super_admins ORDER BY created_at');
  return _json({
    'admins': rows
        .map((a) => {
              'id': a['id'],
              'username': a['username'],
              'active': a['active'] != false,
              'createdAt': _i(a['created_at']),
            })
        .toList()
  });
}

/// POST /superadmin/add — creates a new super-admin account (unique username,
/// bcrypt-hashed PIN of at least 4 characters).
Future<Response> _superAdminAdd(Request req) async {
  final b = await _body(req);
  final username = (b['username'] ?? '').toString().trim().toLowerCase();
  final pass = (b['password'] ?? '').toString();
  if (username.isEmpty) {
    return _json({'ok': false, 'error': 'Username is required.'}, status: 400);
  }
  if (pass.length < 4) {
    return _json({'ok': false, 'error': 'PIN must be at least 4 characters.'},
        status: 400);
  }
  final exists = await db.execute(
    Sql.named('SELECT 1 FROM super_admins WHERE username = @u'),
    parameters: {'u': username},
  );
  if (exists.isNotEmpty) {
    return _json(
        {'ok': false, 'error': 'A super admin with this username exists.'},
        status: 409);
  }
  await db.execute(
    Sql.named('INSERT INTO super_admins '
        '(id, username, pin_hash, active, created_at) '
        'VALUES (@id, @u, @h, TRUE, @c)'),
    parameters: {
      'id': _id('SA'),
      'u': username,
      'h': BCrypt.hashpw(pass, BCrypt.gensalt()),
      'c': DateTime.now().millisecondsSinceEpoch,
    },
  );
  return _json({'ok': true});
}

/// POST /superadmin/remove — deletes a super-admin account. Guards against
/// removing the last one (which would lock everyone out of the panel).
Future<Response> _superAdminRemove(Request req) async {
  final b = await _body(req);
  final id = (b['id'] ?? '').toString();
  if (id.isEmpty) {
    return _json({'ok': false, 'error': 'Admin id required.'}, status: 400);
  }
  final total = _i((await _rows('SELECT COUNT(*) AS c FROM super_admins'))
      .first['c']);
  if (total <= 1) {
    return _json(
        {'ok': false, 'error': 'Cannot remove the last super admin.'},
        status: 400);
  }
  final affected = await db.execute(
    Sql.named('DELETE FROM super_admins WHERE id = @id'),
    parameters: {'id': id},
  );
  if (affected.affectedRows == 0) {
    return _json({'ok': false, 'error': 'Super admin not found.'}, status: 404);
  }
  return _json({'ok': true});
}

/// POST /superadmin/reset-pin — sets a new bcrypt PIN for an account and revokes
/// that admin's live sessions, forcing a fresh login with the new PIN.
Future<Response> _superAdminResetPin(Request req) async {
  final b = await _body(req);
  final id = (b['id'] ?? '').toString();
  final pass = (b['password'] ?? '').toString();
  if (id.isEmpty) {
    return _json({'ok': false, 'error': 'Admin id required.'}, status: 400);
  }
  if (pass.length < 4) {
    return _json({'ok': false, 'error': 'PIN must be at least 4 characters.'},
        status: 400);
  }
  final affected = await db.execute(
    Sql.named('UPDATE super_admins SET pin_hash = @h WHERE id = @id'),
    parameters: {'h': BCrypt.hashpw(pass, BCrypt.gensalt()), 'id': id},
  );
  if (affected.affectedRows == 0) {
    return _json({'ok': false, 'error': 'Super admin not found.'}, status: 404);
  }
  await db.execute(
      Sql.named('DELETE FROM super_admin_sessions WHERE admin_id = @id'),
      parameters: {'id': id});
  return _json({'ok': true});
}

/// POST /superadmin/toggle — activates/deactivates an account. A deactivated
/// admin cannot log in and is signed out immediately. Guards against
/// deactivating the last active account.
Future<Response> _superAdminToggle(Request req) async {
  final b = await _body(req);
  final id = (b['id'] ?? '').toString();
  final active = b['active'] == true;
  if (id.isEmpty) {
    return _json({'ok': false, 'error': 'Admin id required.'}, status: 400);
  }
  if (!active) {
    final activeCount = _i((await _rows(
            'SELECT COUNT(*) AS c FROM super_admins WHERE active = TRUE'))
        .first['c']);
    // Block only if this id is currently the sole active account.
    final isActiveNow = (await db.execute(
      Sql.named('SELECT active FROM super_admins WHERE id = @id'),
      parameters: {'id': id},
    ));
    final currentlyActive =
        isActiveNow.isNotEmpty && isActiveNow.first.toColumnMap()['active'] == true;
    if (activeCount <= 1 && currentlyActive) {
      return _json(
          {'ok': false, 'error': 'Cannot deactivate the last super admin.'},
          status: 400);
    }
  }
  final affected = await db.execute(
    Sql.named('UPDATE super_admins SET active = @a WHERE id = @id'),
    parameters: {'a': active, 'id': id},
  );
  if (affected.affectedRows == 0) {
    return _json({'ok': false, 'error': 'Super admin not found.'}, status: 404);
  }
  if (!active) {
    await db.execute(
        Sql.named('DELETE FROM super_admin_sessions WHERE admin_id = @id'),
        parameters: {'id': id});
  }
  return _json({'ok': true});
}

// ------------------------------------------------ super-admin group registry
/// GET /superadmin/groups — every group with its live member count.
Future<Response> _groupsList(Request req) async {
  final rows = await _rows(
      'SELECT g.*, (SELECT COUNT(*) FROM members m WHERE m.group_id = g.id) '
      'AS members_count FROM groups g ORDER BY g.created_at');
  return _json({
    'groups': rows
        .map((g) => {
              'id': g['id'],
              'name': g['name'],
              'term': g['term'],
              'leader': g['leader'],
              'membersCount': _i(g['members_count']),
              'active': g['active'] != false,
            })
        .toList()
  });
}

/// POST /superadmin/groups/add — create a new (empty) group.
Future<Response> _groupAdd(Request req) async {
  final b = await _body(req);
  final name = (b['name'] ?? '').toString().trim();
  if (name.isEmpty) {
    return _json({'ok': false, 'error': 'Group name is required.'}, status: 400);
  }
  final id = _id('G');
  await db.execute(
    Sql.named('INSERT INTO groups (id, name, term, leader, created_at) '
        'VALUES (@id, @n, @t, @l, @c)'),
    parameters: {
      'id': id,
      'n': name,
      't': (b['term'] ?? '').toString().trim(),
      'l': (b['leader'] ?? '').toString().trim(),
      'c': DateTime.now().millisecondsSinceEpoch,
    },
  );
  return _json({'ok': true, 'id': id});
}

/// POST /superadmin/groups/update — edit a group's identity.
Future<Response> _groupUpdate(Request req) async {
  final b = await _body(req);
  final affected = await db.execute(
    Sql.named('UPDATE groups SET name = @n, term = @t, leader = @l '
        'WHERE id = @id'),
    parameters: {
      'id': b['id'],
      'n': (b['name'] ?? '').toString().trim(),
      't': (b['term'] ?? '').toString().trim(),
      'l': (b['leader'] ?? '').toString().trim(),
    },
  );
  if (affected.affectedRows == 0) {
    return _json({'ok': false, 'error': 'Group not found.'}, status: 404);
  }
  return _json({'ok': true});
}

/// POST /superadmin/groups/toggle — enable/disable a group (a disabled group's
/// members cannot sign in).
Future<Response> _groupToggle(Request req) async {
  final b = await _body(req);
  await db.execute(
    Sql.named('UPDATE groups SET active = @a WHERE id = @id'),
    parameters: {'id': b['id'], 'a': b['active'] == true},
  );
  return _json({'ok': true});
}

/// POST /superadmin/groups/remove — permanently delete a group and ALL of its
/// data (ON DELETE CASCADE clears members, savings, loans, etc.).
Future<Response> _groupRemove(Request req) async {
  final b = await _body(req);
  await db.execute(Sql.named('DELETE FROM groups WHERE id = @id'),
      parameters: {'id': b['id']});
  return _json({'ok': true});
}

/// POST /superadmin/open-group — mints an admin-scoped *member* session for the
/// given group, so the super admin can manage that group through the ordinary
/// (member) API. The session has no member_id (it isn't a member) and role
/// 'admin', so it passes every admin gate while staying scoped to the group.
Future<Response> _openGroup(Request req) async {
  final b = await _body(req);
  final groupId = (b['groupId'] ?? '').toString();
  final rows = await _rows('SELECT id, name FROM groups WHERE id = @g',
      {'g': groupId});
  if (rows.isEmpty) {
    return _json({'ok': false, 'error': 'Group not found.'}, status: 404);
  }
  final token = _randomToken();
  final now = DateTime.now().millisecondsSinceEpoch;
  await db.execute(
    Sql.named('INSERT INTO sessions '
        '(token, member_id, role, group_id, created_at, expires_at) '
        "VALUES (@t, NULL, 'admin', @g, @c, @e)"),
    parameters: {'t': token, 'g': groupId, 'c': now, 'e': now + _sessionTtlMs},
  );
  return _json({
    'ok': true,
    'token': token,
    'groupId': groupId,
    'groupName': rows.first['name'],
  });
}

/// Runs pending schema migrations, then seeds constitution data. Migration v1
/// ([_baselineSchema]) brings any pre-versioning database up to the current
/// baseline; later migrations (v2+) are ordered, one-time, transactional.
Future<void> _ensureSchema() async {
  await runMigrations(db, _appMigrations, log: stdout.writeln);
  await _seedConstitution();
  stdout.writeln('Schema up to date.');
}

/// The ordered migration list. v1 is the (idempotent) baseline; add each new
/// schema change as the next version. See `lib/migrations.dart`.
final _appMigrations = <Migration>[
  Migration(1, 'baseline', (_) => _baselineSchema(), transactional: false),
  Migration(2, 'updated_at', _addUpdatedAt),
  Migration(3, 'member_active', _addMemberActive),
  Migration(4, 'super_admins', _addSuperAdmins),
  Migration(5, 'membership_requests', _addMembershipRequests),
  Migration(6, 'multi_tenant', _addMultiTenancy),
  Migration(7, 'otp_codes', _addOtpCodes),
  Migration(8, 'device_tokens', _addDeviceTokens),
  Migration(9, 'group_rule_fields', _addGroupRuleFields),
  Migration(10, 'savings_status', _addSavingsStatus),
  Migration(11, 'share_tx', _addShareTx),
];

/// v11 — paid share ownership. Members buy shares (share_count × the group's
/// share price); the payment brings real cash into the fund. A purchase is
/// 'confirmed' (owned + counts toward the fund) or 'pending' (a member-submitted
/// buy awaiting an officer's approval). Owned shares are derived by adding
/// confirmed purchases on top of each member's opening `members.shares`.
Future<void> _addShareTx(Session tx) async {
  await tx.execute('CREATE TABLE IF NOT EXISTS share_tx ('
      'id TEXT PRIMARY KEY, '
      'group_id TEXT NOT NULL REFERENCES groups(id) ON DELETE CASCADE, '
      'member_id TEXT NOT NULL REFERENCES members(id) ON DELETE CASCADE, '
      'share_count INT NOT NULL CHECK (share_count > 0), '
      'amount NUMERIC(14,2) NOT NULL CHECK (amount > 0), '
      "method TEXT NOT NULL DEFAULT 'cash', "
      'date BIGINT NOT NULL, '
      "status TEXT NOT NULL DEFAULT 'confirmed' "
      "CHECK (status IN ('confirmed', 'pending')))");
  await tx.execute(
      'CREATE INDEX IF NOT EXISTS idx_share_tx_group ON share_tx(group_id)');
  await tx.execute(
      'CREATE INDEX IF NOT EXISTS idx_share_tx_member ON share_tx(member_id)');
  await tx.execute(
      'CREATE INDEX IF NOT EXISTS idx_share_tx_status ON share_tx(status)');
}

/// v10 — member self-service deposits. Savings gain a `status`: 'confirmed'
/// (counts toward balances — every existing row and anything an officer records)
/// or 'pending' (a member-submitted deposit awaiting an officer's confirmation,
/// excluded from all balances until approved). Backfills existing rows to
/// 'confirmed' so no balance moves.
Future<void> _addSavingsStatus(Session tx) async {
  await tx.execute("ALTER TABLE savings ADD COLUMN IF NOT EXISTS status TEXT "
      "NOT NULL DEFAULT 'confirmed'");
  await tx.execute("UPDATE savings SET status = 'confirmed' "
      "WHERE status IS NULL OR status = ''");
  await tx.execute('CREATE INDEX IF NOT EXISTS idx_savings_status '
      'ON savings(status)');
}

/// The built-in fine types a fresh group starts with (name + default amount in
/// TZS). Stored as a JSON array in `groups.fine_types`; editable per group.
const _defaultFineTypesJson =
    '[{"name":"Kutohudhuria mkutano","amount":5000},'
    '{"name":"Kuchelewa malipo","amount":2000},'
    '{"name":"Nyingine","amount":1000}]';

/// v9 — the remaining per-group rules the app used to keep only on-device
/// (loan duration default, meeting cadence/time/place, quorum, and the fine-type
/// catalogue). Adding them as columns on `groups` makes the whole rulebook
/// per-tenant and editable via POST /settings/rules. `fine_types` is a JSON
/// array of {name, amount}, stored as TEXT (matching the audit `detail` pattern)
/// so the driver never has to decode JSONB.
Future<void> _addGroupRuleFields(Session tx) async {
  await tx.execute('ALTER TABLE groups '
      'ADD COLUMN IF NOT EXISTS loan_duration_months INT NOT NULL DEFAULT 3, '
      'ADD COLUMN IF NOT EXISTS quorum_percent INT NOT NULL DEFAULT 50, '
      "ADD COLUMN IF NOT EXISTS meeting_frequency TEXT NOT NULL DEFAULT 'weekly', "
      "ADD COLUMN IF NOT EXISTS meeting_start_time TEXT NOT NULL DEFAULT '10:00', "
      "ADD COLUMN IF NOT EXISTS meeting_location TEXT NOT NULL DEFAULT '', "
      'ADD COLUMN IF NOT EXISTS fine_types TEXT NOT NULL '
      "DEFAULT '$_defaultFineTypesJson'");
}

/// v8 — push notification device tokens. One row per (member, device token);
/// the token is the primary key so re-registering the same device is an upsert
/// that just refreshes ownership/timestamp. Scoped by group so notifications
/// stay within a tenant.
Future<void> _addDeviceTokens(Session tx) async {
  await tx.execute('CREATE TABLE IF NOT EXISTS device_tokens ('
      'token TEXT PRIMARY KEY, '
      'member_id TEXT NOT NULL, '
      'group_id TEXT NOT NULL, '
      'platform TEXT NOT NULL DEFAULT \'\', '
      'updated_at BIGINT NOT NULL)');
  await tx.execute('CREATE INDEX IF NOT EXISTS idx_device_tokens_member '
      'ON device_tokens (member_id)');
}

/// v7 — SMS login one-time passcodes. One row per phone (the code is upserted on
/// each request), holding the bcrypt hash of the current code, its expiry, and a
/// wrong-guess counter. Not tied to a group: a member is resolved by phone at
/// verify time, exactly as password login does.
Future<void> _addOtpCodes(Session tx) async {
  await tx.execute('CREATE TABLE IF NOT EXISTS otp_codes ('
      'phone TEXT PRIMARY KEY, '
      'code_hash TEXT NOT NULL, '
      'expires_at BIGINT NOT NULL, '
      'attempts INT NOT NULL DEFAULT 0, '
      'created_at BIGINT NOT NULL)');
}

/// v6 — multi-tenancy. Introduces a `groups` table (one row per VICOBA group,
/// holding its identity + rule settings), tags every data row with a `group_id`,
/// and moves all existing data into a single default group so nothing is lost.
/// Sessions gain a `group_id` (the group a login authenticated into); a
/// super-admin-opened group session has no member, so `member_id` becomes
/// nullable. `group_settings` is left in place (unused going forward) to keep the
/// migration reversible.
Future<void> _addMultiTenancy(Session tx) async {
  const defaultGid = 'G-default';
  final now = DateTime.now().millisecondsSinceEpoch;

  // 1) The groups table — same rule columns group_settings had, plus identity.
  await tx.execute('CREATE TABLE IF NOT EXISTS groups ('
      'id TEXT PRIMARY KEY, '
      'name TEXT NOT NULL, '
      "term TEXT NOT NULL DEFAULT '', "
      "leader TEXT NOT NULL DEFAULT '', "
      'share_value NUMERIC(14,2) NOT NULL DEFAULT 5000, '
      'social_fund_per_mtg NUMERIC(14,2) NOT NULL DEFAULT 1000, '
      'interest_rate_pct NUMERIC(5,2) NOT NULL DEFAULT 10, '
      'loan_multiplier INT NOT NULL DEFAULT 3, '
      'max_repayment_months INT NOT NULL DEFAULT 4, '
      'required_guarantors INT NOT NULL DEFAULT 2, '
      'min_shares INT NOT NULL DEFAULT 1, '
      'max_shares INT NOT NULL DEFAULT 5, '
      'cycle_months INT NOT NULL DEFAULT 12, '
      'cycle_months_elapsed INT NOT NULL DEFAULT 6, '
      'meetings_held INT NOT NULL DEFAULT 0, '
      'interest_earned NUMERIC(14,2) NOT NULL DEFAULT 0, '
      'meeting_expense NUMERIC(14,2) NOT NULL DEFAULT 0, '
      'other_expense NUMERIC(14,2) NOT NULL DEFAULT 0, '
      'opening_cash NUMERIC(14,2) NOT NULL DEFAULT 0, '
      'opening_social_fund NUMERIC(14,2) NOT NULL DEFAULT 0, '
      'constitution_seeded BOOLEAN NOT NULL DEFAULT FALSE, '
      'active BOOLEAN NOT NULL DEFAULT TRUE, '
      'created_at BIGINT NOT NULL DEFAULT 0)');

  // 2) Seed the default group from the existing single group_settings row.
  await tx.execute(
    Sql.named('INSERT INTO groups (id, name, term, share_value, '
        'social_fund_per_mtg, interest_rate_pct, loan_multiplier, '
        'max_repayment_months, required_guarantors, min_shares, max_shares, '
        'cycle_months, cycle_months_elapsed, meetings_held, interest_earned, '
        'meeting_expense, other_expense, opening_cash, opening_social_fund, '
        'constitution_seeded, active, created_at) '
        'SELECT @id, name, term, share_value, social_fund_per_mtg, '
        'interest_rate_pct, loan_multiplier, max_repayment_months, '
        'required_guarantors, min_shares, max_shares, cycle_months, '
        'cycle_months_elapsed, meetings_held, interest_earned, meeting_expense, '
        'other_expense, opening_cash, opening_social_fund, constitution_seeded, '
        'TRUE, @now FROM group_settings WHERE id = 1 '
        'ON CONFLICT (id) DO NOTHING'),
    parameters: {'id': defaultGid, 'now': now},
  );
  // Fresh DB with no group_settings row: still guarantee a default group.
  await tx.execute(
    Sql.named("INSERT INTO groups (id, name, term, created_at) "
        "SELECT @id, 'My Group', '', @now "
        "WHERE NOT EXISTS (SELECT 1 FROM groups WHERE id = @id)"),
    parameters: {'id': defaultGid, 'now': now},
  );

  // 3) Tag every data row with its group. All current data is the one group.
  const tables = [
    'members', 'savings', 'loans', 'repayments', 'fines', 'officers',
    'membership_requests', 'meetings', 'agendas', 'meeting_attendance',
    'meeting_minutes', 'meeting_actions', 'amendments', 'audit_events',
    'loan_guarantors',
  ];
  for (final t in tables) {
    await tx.execute('ALTER TABLE $t ADD COLUMN IF NOT EXISTS group_id TEXT');
    await tx.execute(
      Sql.named('UPDATE $t SET group_id = @g WHERE group_id IS NULL'),
      parameters: {'g': defaultGid},
    );
    await tx.execute('ALTER TABLE $t ALTER COLUMN group_id SET NOT NULL');
    await tx.execute('ALTER TABLE $t ADD CONSTRAINT ${t}_group_fk '
        'FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE');
    await tx.execute(
        'CREATE INDEX IF NOT EXISTS idx_${t}_group ON $t(group_id)');
  }

  // 4) Sessions carry their group; super-admin-opened sessions have no member.
  await tx.execute('ALTER TABLE sessions ADD COLUMN IF NOT EXISTS group_id TEXT');
  await tx.execute(
    Sql.named('UPDATE sessions SET group_id = @g WHERE group_id IS NULL'),
    parameters: {'g': defaultGid},
  );
  await tx.execute('ALTER TABLE sessions ALTER COLUMN member_id DROP NOT NULL');
}

Future<void> _addMembershipRequests(Session tx) async {
  await tx.execute('CREATE TABLE IF NOT EXISTS membership_requests ('
      'id TEXT PRIMARY KEY, '
      'name TEXT NOT NULL, '
      'phone TEXT NOT NULL DEFAULT \'\', '
      'shares INT NOT NULL DEFAULT 1 CHECK (shares >= 0), '
      "status TEXT NOT NULL DEFAULT 'pending' "
      "CHECK (status IN ('pending', 'approved', 'rejected')), "
      'requested_on BIGINT NOT NULL, '
      'decided_on BIGINT NOT NULL DEFAULT 0, '
      'decided_by TEXT NOT NULL DEFAULT \'\')');
  await tx.execute('CREATE INDEX IF NOT EXISTS idx_membership_requests_status '
      'ON membership_requests(status)');
}

/// v4: platform super-admins live in the database (previously a hardcoded
/// credential in the app). They manage the group registry and are authenticated
/// against `super_admins` (bcrypt PIN), holding their own session tokens in
/// `super_admin_sessions` — kept separate from members' `sessions` because a
/// super admin is not a group member (no `members` FK). The built-in default
/// (superadmin / 0000) is seeded once so existing installs keep working; it can
/// then be changed or removed from the in-app management screen.
Future<void> _addSuperAdmins(Session tx) async {
  await tx.execute('CREATE TABLE IF NOT EXISTS super_admins ('
      'id TEXT PRIMARY KEY, username TEXT NOT NULL UNIQUE, '
      'pin_hash TEXT NOT NULL, active BOOLEAN NOT NULL DEFAULT TRUE, '
      'created_at BIGINT NOT NULL)');
  await tx.execute('CREATE TABLE IF NOT EXISTS super_admin_sessions ('
      'token TEXT PRIMARY KEY, '
      'admin_id TEXT NOT NULL REFERENCES super_admins(id) ON DELETE CASCADE, '
      'created_at BIGINT NOT NULL, expires_at BIGINT NOT NULL)');
  await tx.execute('CREATE INDEX IF NOT EXISTS idx_sa_sessions_admin '
      'ON super_admin_sessions(admin_id)');
  // Seed the built-in default only when the registry is empty, so an upgrade
  // preserves the app's previous superadmin/0000 login without clobbering any
  // admins created later.
  final countRow = await tx.execute('SELECT COUNT(*) AS c FROM super_admins');
  if (_i(countRow.first.toColumnMap()['c']) == 0) {
    await tx.execute(
      Sql.named('INSERT INTO super_admins '
          '(id, username, pin_hash, active, created_at) '
          'VALUES (@id, @u, @h, TRUE, @c)'),
      parameters: {
        'id': _id('SA'),
        'u': 'superadmin',
        'h': BCrypt.hashpw('0000', BCrypt.gensalt()),
        'c': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}

/// v3: a member can be suspended (active = false). Suspended members keep all
/// their history but can no longer log in — the group admin controls this. New
/// and existing members default to active.
Future<void> _addMemberActive(Session tx) async {
  await tx.execute('ALTER TABLE members '
      'ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT TRUE');
}

/// v2: track last-modified time on the core tables. A trigger keeps `updated_at`
/// current on every UPDATE, so the audit story is created_at + updated_at +
/// audit_events. Transactional: all-or-nothing.
Future<void> _addUpdatedAt(Session tx) async {
  await tx.execute('CREATE OR REPLACE FUNCTION set_updated_at() '
      'RETURNS trigger AS \$\$ BEGIN '
      'NEW.updated_at := (EXTRACT(EPOCH FROM now()) * 1000)::BIGINT; '
      'RETURN NEW; END; \$\$ LANGUAGE plpgsql');
  for (final t in const [
    'members', 'savings', 'loans', 'repayments', 'fines', 'meetings'
  ]) {
    await tx.execute('ALTER TABLE $t ADD COLUMN IF NOT EXISTS updated_at BIGINT');
    await tx.execute('DROP TRIGGER IF EXISTS trg_${t}_updated ON $t');
    await tx.execute('CREATE TRIGGER trg_${t}_updated BEFORE UPDATE ON $t '
        'FOR EACH ROW EXECUTE FUNCTION set_updated_at()');
  }
}

/// Migration v1 baseline: brings any pre-versioning database up to the current
/// schema. Deliberately idempotent (safe to run on a database at any prior
/// state), which is why it runs outside a transaction.
Future<void> _baselineSchema() async {
  await db.execute(
      "ALTER TABLE members ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'member'");
  await db.execute(
      "ALTER TABLE members ADD COLUMN IF NOT EXISTS pin TEXT NOT NULL DEFAULT '1234'");
  // Security: PINs are stored as bcrypt hashes in `pin_hash`, never plaintext.
  await db.execute('ALTER TABLE members ADD COLUMN IF NOT EXISTS pin_hash TEXT');
  // Server-side sessions: a login mints one row here; the token is the bearer
  // credential and can be revoked by deleting the row (see /logout).
  await db.execute('CREATE TABLE IF NOT EXISTS sessions ('
      'token TEXT PRIMARY KEY, member_id TEXT NOT NULL, role TEXT NOT NULL, '
      'created_at BIGINT NOT NULL, expires_at BIGINT NOT NULL)');
  // Migrate any legacy plaintext PINs to bcrypt hashes, then blank the
  // plaintext so it is no longer at rest. Runs once per member (idempotent:
  // members with a hash already are skipped).
  final needHash =
      await _rows("SELECT id, pin FROM members WHERE pin_hash IS NULL");
  for (final m in needHash) {
    final plain = (m['pin'] ?? '').toString();
    final hash = BCrypt.hashpw(plain.isEmpty ? '1234' : plain, BCrypt.gensalt());
    await db.execute(
      Sql.named("UPDATE members SET pin_hash = @h, pin = '' WHERE id = @id"),
      parameters: {'h': hash, 'id': m['id']},
    );
  }
  await db.execute('CREATE TABLE IF NOT EXISTS amendments ('
      'id TEXT PRIMARY KEY, title TEXT NOT NULL, body TEXT NOT NULL, '
      'date BIGINT NOT NULL)');
  await db.execute('CREATE TABLE IF NOT EXISTS agendas ('
      'id TEXT PRIMARY KEY, meeting_id TEXT NOT NULL, text TEXT NOT NULL, '
      'position INT NOT NULL DEFAULT 0)');
  await db.execute('ALTER TABLE agendas '
      'ADD COLUMN IF NOT EXISTS done BOOLEAN NOT NULL DEFAULT FALSE');
  // Meeting metadata + lifecycle (added to older databases automatically).
  for (final col in const [
    "title TEXT NOT NULL DEFAULT ''",
    "start_time TEXT NOT NULL DEFAULT ''",
    "location TEXT NOT NULL DEFAULT ''",
    "period TEXT NOT NULL DEFAULT ''",
    "chairperson TEXT NOT NULL DEFAULT ''",
    "secretary TEXT NOT NULL DEFAULT ''",
    "status TEXT NOT NULL DEFAULT 'draft'",
  ]) {
    await db.execute('ALTER TABLE meetings ADD COLUMN IF NOT EXISTS $col');
  }
  // Older held meetings (with attendance recorded) are treated as closed.
  await db.execute(
      "UPDATE meetings SET status = 'closed' WHERE status = 'draft' AND attended > 0");
  await db.execute('CREATE TABLE IF NOT EXISTS meeting_attendance ('
      'meeting_id TEXT NOT NULL, member_id TEXT NOT NULL, '
      "status TEXT NOT NULL DEFAULT 'present', "
      'PRIMARY KEY (meeting_id, member_id))');
  await db.execute('CREATE TABLE IF NOT EXISTS meeting_minutes ('
      'id TEXT PRIMARY KEY, meeting_id TEXT NOT NULL, text TEXT NOT NULL, '
      'position INT NOT NULL DEFAULT 0)');
  await db.execute('CREATE TABLE IF NOT EXISTS meeting_actions ('
      'id TEXT PRIMARY KEY, meeting_id TEXT NOT NULL, task TEXT NOT NULL, '
      "responsible TEXT NOT NULL DEFAULT '', due_date BIGINT NOT NULL DEFAULT 0, "
      'done BOOLEAN NOT NULL DEFAULT FALSE)');
  // Bootstrap admins the first time only (if none exist yet): the office
  // bearers get the admin panel. Won't clobber roles you set later.
  await db.execute("UPDATE members SET role = 'admin' "
      "WHERE id IN ('M007', 'M001', 'M003') "
      "AND (SELECT COUNT(*) FROM members WHERE role = 'admin') = 0");
  await _migrateMoneyAndConstraints();
}

/// Brings an existing database up to the current money-precision and
/// data-integrity rules, in place and losslessly:
///   • money columns DOUBLE PRECISION -> NUMERIC (exact, no float drift);
///   • CHECK constraints on enum-like columns and positive amounts/shares;
///   • the foreign keys the meeting child tables and sessions were missing.
/// Every step is idempotent; a fresh schema.sql install already has all of this
/// and these calls simply no-op.
Future<void> _migrateMoneyAndConstraints() async {
  // --- Money columns -> NUMERIC ---
  const moneyCols = <String, List<String>>{
    'group_settings': [
      'share_value', 'social_fund_per_mtg', 'interest_earned',
      'meeting_expense', 'other_expense', 'opening_cash', 'opening_social_fund',
    ],
    'savings': ['amount'],
    'loans': ['principal'],
    'repayments': ['amount'],
    'fines': ['amount'],
    'meetings': ['collections', 'fines'],
  };
  for (final entry in moneyCols.entries) {
    for (final col in entry.value) {
      await _ensureNumeric(entry.key, col);
    }
  }
  // Rates/percentages are smaller-scale NUMERIC.
  await _ensureNumeric('group_settings', 'interest_rate_pct', 'NUMERIC(5,2)');
  await _ensureNumeric('loans', 'interest_rate', 'NUMERIC(5,2)');

  // --- CHECK constraints (enum-like values + positive amounts) ---
  await _addConstraint('members', 'chk_members_role',
      "CHECK (role IN ('admin', 'member'))");
  await _addConstraint('members', 'chk_members_shares', 'CHECK (shares >= 0)');
  await _addConstraint('savings', 'chk_savings_type',
      "CHECK (type IN ('regular', 'special', 'social'))");
  await _addConstraint('savings', 'chk_savings_amount', 'CHECK (amount > 0)');
  await _addConstraint('loans', 'chk_loans_status',
      "CHECK (status IN ('request', 'ongoing', 'paid', 'rejected'))");
  await _addConstraint('loans', 'chk_loans_principal', 'CHECK (principal > 0)');
  await _addConstraint(
      'loans', 'chk_loans_duration', 'CHECK (duration_months > 0)');
  await _addConstraint('loans', 'chk_loans_rate', 'CHECK (interest_rate >= 0)');
  await _addConstraint('repayments', 'chk_repay_amount', 'CHECK (amount > 0)');
  await _addConstraint('fines', 'chk_fines_amount', 'CHECK (amount > 0)');
  await _addConstraint('meetings', 'chk_meetings_status',
      "CHECK (status IN ('draft', 'open', 'closed'))");
  await _addConstraint('meetings', 'chk_meetings_collections',
      'CHECK (collections >= 0)');
  await _addConstraint('meetings', 'chk_meetings_fines', 'CHECK (fines >= 0)');
  await _addConstraint('meeting_attendance', 'chk_attendance_status',
      "CHECK (status IN ('present', 'absent', 'excused'))");
  await _addConstraint('sessions', 'chk_sessions_role',
      "CHECK (role IN ('admin', 'member'))");

  // --- Missing foreign keys (meeting children + sessions) ---
  await _addConstraint('meeting_attendance', 'fk_att_meeting',
      'FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE');
  await _addConstraint('meeting_attendance', 'fk_att_member',
      'FOREIGN KEY (member_id) REFERENCES members(id)');
  await _addConstraint('meeting_minutes', 'fk_min_meeting',
      'FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE');
  await _addConstraint('meeting_actions', 'fk_act_meeting',
      'FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE');
  await _addConstraint('agendas', 'fk_agenda_meeting',
      'FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE');
  await _addConstraint('sessions', 'fk_sessions_member',
      'FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE');

  // --- Indexes on common lookup columns (idempotent) ---
  const indexes = <String, String>{
    'idx_savings_member': 'savings(member_id)',
    'idx_savings_date': 'savings(date)',
    'idx_loans_member': 'loans(member_id)',
    'idx_loans_status': 'loans(status)',
    'idx_repayments_loan': 'repayments(loan_id)',
    'idx_repayments_date': 'repayments(date)',
    'idx_fines_member': 'fines(member_id)',
    'idx_attendance_member': 'meeting_attendance(member_id)',
    'idx_minutes_meeting': 'meeting_minutes(meeting_id)',
    'idx_actions_meeting': 'meeting_actions(meeting_id)',
    'idx_agendas_meeting': 'agendas(meeting_id)',
    'idx_sessions_member': 'sessions(member_id)',
  };
  for (final e in indexes.entries) {
    await db.execute('CREATE INDEX IF NOT EXISTS ${e.key} ON ${e.value}');
  }

  // --- Audit trail ---
  // A creation timestamp on each core table (existing rows get "now"; new rows
  // default to insert time). "Who created/edited/deleted what" lives in the
  // audit_events table below, written by every significant mutation.
  const nowMs = '(EXTRACT(EPOCH FROM now()) * 1000)::BIGINT';
  for (final t in const [
    'members', 'savings', 'loans', 'repayments', 'fines', 'meetings'
  ]) {
    await db.execute('ALTER TABLE $t ADD COLUMN IF NOT EXISTS '
        'created_at BIGINT NOT NULL DEFAULT $nowMs');
  }
  await db.execute('CREATE TABLE IF NOT EXISTS audit_events ('
      'id TEXT PRIMARY KEY, at BIGINT NOT NULL, '
      'actor_id TEXT NOT NULL DEFAULT \'\', '
      'actor_role TEXT NOT NULL DEFAULT \'\', '
      'action TEXT NOT NULL, entity TEXT NOT NULL, '
      'entity_id TEXT NOT NULL DEFAULT \'\', detail TEXT)');
  await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_at ON audit_events(at)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_audit_entity '
      'ON audit_events(entity, entity_id)');
}

/// The whole constitution lives in the `amendments` table so every article is
/// editable. The eight built-in articles are seeded ONCE (guarded by a flag in
/// group_settings) — so an admin's later edits/deletions are never overwritten
/// on restart.
Future<void> _seedConstitution() async {
  await db.execute('ALTER TABLE group_settings '
      'ADD COLUMN IF NOT EXISTS constitution_seeded BOOLEAN NOT NULL DEFAULT FALSE');
  final flag = await _rows(
      'SELECT constitution_seeded FROM group_settings WHERE id = 1');
  if (flag.isNotEmpty && flag.first['constitution_seeded'] == true) return;

  const articles = <List<String>>[
    ['A-membership', 'Uanachama',
      'Kikundi kina wanachama kati ya 15 na 30 wanaofahamiana, wanaoaminiana '
          'na waishio eneo moja.'],
    ['A-shares', 'Hisa',
      'Thamani ya hisa moja ni TZS 5,000. Kila mwanachama hununua hisa 1 hadi '
          '5 kila kikao. Hakuna anayeruhusiwa kumiliki hisa nyingi kupita kiasi.'],
    ['A-social', 'Mfuko wa Jamii',
      'Kila mwanachama huchangia TZS 1,000 kila kikao kwenye mfuko wa jamii. '
          'Mfuko huu husaidia wakati wa majanga na hauambatani na riba.'],
    ['A-loans', 'Mikopo',
      'Mwanachama anaweza kukopa hadi mara 3 ya thamani ya hisa zake. Riba ni '
          '10% kwa mwezi na marejesho hayazidi miezi 4. Wadhamini wawili '
          'wanahitajika.'],
    ['A-fines', 'Faini',
      'Faini hutozwa kwa kuchelewa kikaoni, kutohudhuria, na kuchelewesha '
          'marejesho. Fedha za faini huongezwa kwenye mfuko wa kukopeshana.'],
    ['A-meetings', 'Mikutano',
      'Vikao hufanyika kila wiki. Mahudhurio ni lazima; kutokuwepo bila udhuru '
          'kunatozwa faini.'],
    ['A-cycle', 'Mzunguko',
      'Mzunguko mmoja hudumu miezi 12. Mwishoni hisa na faida hugawanywa, kisha '
          'kikundi huanza mzunguko mpya.'],
    ['A-shareout', 'Mgawanyo wa Faida',
      'Mwishoni mwa mzunguko, kila mwanachama hurejeshewa thamani ya hisa zake '
          'pamoja na gawio la faida kulingana na idadi ya hisa.'],
  ];
  // Seed with early, increasing dates so the built-ins sort before any custom
  // amendments (which are dated when added).
  final base = DateTime(2024, 1, 1).millisecondsSinceEpoch;
  for (var i = 0; i < articles.length; i++) {
    await db.execute(
      Sql.named('INSERT INTO amendments (id, group_id, title, body, date) '
          "VALUES (@id, 'G-default', @t, @b, @d) ON CONFLICT (id) DO NOTHING"),
      parameters: {
        'id': articles[i][0],
        't': articles[i][1],
        'b': articles[i][2],
        'd': base + i * 60000,
      },
    );
  }
  await db
      .execute('UPDATE group_settings SET constitution_seeded = TRUE WHERE id = 1');
  stdout.writeln('Seeded ${articles.length} built-in constitution articles.');
}

// ------------------------------------------------------------ POST /amendments
Future<Response> _addAmendment(Request req) async {
  final b = await _body(req);
  await db.execute(
    Sql.named('INSERT INTO amendments (id, group_id, title, body, date) '
        'VALUES (@id, @g, @t, @bd, @d)'),
    parameters: {
      'id': _id('A'),
      'g': _gid(req),
      't': b['title'],
      'bd': b['body'],
      'd': DateTime.now().millisecondsSinceEpoch,
    },
  );
  return _json({'ok': true});
}

Future<Response> _updateAmendment(Request req) async {
  final b = await _body(req);
  await db.execute(
    Sql.named('UPDATE amendments SET title = @t, body = @bd '
        'WHERE id = @id AND group_id = @g'),
    parameters: {'id': b['id'], 't': b['title'], 'bd': b['body'], 'g': _gid(req)},
  );
  return _json({'ok': true});
}

Future<Response> _deleteAmendment(Request req) async {
  final b = await _body(req);
  await db.execute(
    Sql.named('DELETE FROM amendments WHERE id = @id AND group_id = @g'),
    parameters: {'id': b['id'], 'g': _gid(req)},
  );
  await _audit(req, 'delete', 'amendment', '${b['id']}');
  return _json({'ok': true});
}

// ------------------------------------------------------- meetings & agendas
/// The standard VICOBA/VSLA order of business every meeting follows. A new
/// meeting is pre-loaded with these steps so the officer just works down the
/// list and ticks each off.
const _standardAgenda = <String>[
  'Kusajili mahudhurio',                         // Register attendance
  'Kukusanya faini',                             // Collect fines
  'Kukusanya akiba',                             // Collect savings
  'Kushughulikia marejesho ya mikopo',           // Process loan repayments
  'Kukokotoa na kukusanya riba ya mikopo',       // Calculate & collect interest
  'Kupitia fedha zilizopo',                      // Review available funds
  'Kuidhinisha na kutoa mikopo mipya',           // Approve & disburse new loans
  'Kujadili masuala ya kikundi',                 // Discuss group business
  'Kufunga mkutano',                             // Close the meeting
];

/// Admin creates a new (draft/upcoming) meeting. The number auto-increments and
/// the attendance total defaults to the current membership. The meeting is
/// pre-loaded with the standard order of business.
Future<Response> _addMeeting(Request req) async {
  final gid = _gid(req);
  final b = await _body(req);
  final maxRow = await _rows(
      'SELECT COALESCE(MAX(number), 0) AS n FROM meetings WHERE group_id = @g',
      {'g': gid});
  final number = b['number'] != null
      ? _i(b['number'])
      : _i(maxRow.first['n']) + 1;
  final totalRow = await _rows(
      'SELECT COUNT(*) AS c FROM members WHERE group_id = @g', {'g': gid});
  final meetingId = _id('MT');
  await db.execute(
    Sql.named('INSERT INTO meetings (id, group_id, number, date, attended, '
        'total, agenda_items, decisions, collections, fines, title, '
        'start_time, location, period, chairperson, secretary, status) '
        "VALUES (@id, @g, @n, @d, 0, @t, 0, 0, 0, 0, @title, @st, @loc, @per, "
        "@chair, @sec, 'draft')"),
    parameters: {
      'id': meetingId,
      'g': gid,
      'n': number,
      'd': b['date'] != null
          ? _i(b['date'])
          : DateTime.now().millisecondsSinceEpoch,
      't': _i(totalRow.first['c']),
      'title': b['title'] ?? '',
      'st': b['startTime'] ?? '',
      'loc': b['location'] ?? '',
      'per': b['period'] ?? '',
      'chair': b['chairperson'] ?? '',
      'sec': b['secretary'] ?? '',
    },
  );
  for (var i = 0; i < _standardAgenda.length; i++) {
    await db.execute(
      Sql.named('INSERT INTO agendas (id, group_id, meeting_id, text, position, '
          'done) VALUES (@id, @g, @m, @t, @p, FALSE)'),
      parameters: {
        'id': '${meetingId}_$i',
        'g': gid,
        'm': meetingId,
        't': _standardAgenda[i],
        'p': i,
      },
    );
  }
  await _audit(req, 'create', 'meeting', meetingId, {'number': number});
  // Announce the new meeting to the whole group.
  final title = (b['title'] ?? '').toString();
  final when = b['date'] != null
      ? DateTime.fromMillisecondsSinceEpoch(_i(b['date']))
      : DateTime.now();
  final dateLabel =
      '${when.day}/${when.month}/${when.year}${(b['startTime'] ?? '').toString().isNotEmpty ? ' ${b['startTime']}' : ''}';
  await _notifyMembers(
    await _activeMemberIds(gid),
    title: 'New meeting scheduled',
    body: title.isNotEmpty
        ? '$title — $dateLabel'
        : 'Meeting #$number — $dateLabel',
    data: {'type': 'meeting_created', 'meetingId': meetingId},
  );
  return _json({'ok': true});
}

/// Admin records/edits a meeting's summary (attendance, decisions and the
/// collections/fines totals). Recording attendance (attended > 0) moves the
/// meeting from Upcoming to Past.
Future<Response> _updateMeeting(Request req) async {
  final b = await _body(req);
  await db.execute(
    Sql.named('UPDATE meetings SET date = @d, title = @title, '
        'start_time = @st, location = @loc, period = @per, '
        'chairperson = @chair, secretary = @sec, decisions = @de, '
        'collections = @c, fines = @f WHERE id = @id AND group_id = @g'),
    parameters: {
      'id': b['id'],
      'g': _gid(req),
      'd': _i(b['date']),
      'title': b['title'] ?? '',
      'st': b['startTime'] ?? '',
      'loc': b['location'] ?? '',
      'per': b['period'] ?? '',
      'chair': b['chairperson'] ?? '',
      'sec': b['secretary'] ?? '',
      'de': _i(b['decisions']),
      'c': _d(b['collections']),
      'f': _d(b['fines']),
    },
  );
  await _audit(req, 'update', 'meeting', '${b['id']}');
  return _json({'ok': true});
}

/// Moves a meeting through its lifecycle: draft -> open -> closed.
Future<Response> _setMeetingStatus(Request req) async {
  final b = await _body(req);
  await db.execute(
    Sql.named('UPDATE meetings SET status = @s WHERE id = @id AND group_id = @g'),
    parameters: {'id': b['id'], 's': b['status'], 'g': _gid(req)},
  );
  await _audit(req, 'status', 'meeting', '${b['id']}', {'status': b['status']});
  return _json({'ok': true});
}

/// Marks a member present/absent/excused for a meeting (upsert).
Future<Response> _setAttendance(Request req) async {
  final b = await _body(req);
  await db.execute(
    Sql.named('INSERT INTO meeting_attendance (group_id, meeting_id, member_id, '
        'status) VALUES (@g, @m, @mem, @s) '
        'ON CONFLICT (meeting_id, member_id) DO UPDATE SET status = @s'),
    parameters: {
      'g': _gid(req),
      'm': b['meetingId'],
      'mem': b['memberId'],
      's': b['status'],
    },
  );
  return _json({'ok': true});
}

// --------------------------------------------------------- minutes & actions
Future<Response> _addMinute(Request req) async {
  final b = await _body(req);
  final posResult = await db.execute(
    Sql.named('SELECT COALESCE(MAX(position), -1) AS p FROM meeting_minutes '
        'WHERE meeting_id = @m'),
    parameters: {'m': b['meetingId']},
  );
  await db.execute(
    Sql.named('INSERT INTO meeting_minutes (id, group_id, meeting_id, text, '
        'position) VALUES (@id, @g, @m, @t, @p)'),
    parameters: {
      'id': _id('MIN'),
      'g': _gid(req),
      'm': b['meetingId'],
      't': b['text'],
      'p': _i(posResult.first.toColumnMap()['p']) + 1,
    },
  );
  return _json({'ok': true});
}

Future<Response> _deleteMinute(Request req) async {
  final b = await _body(req);
  await db.execute(
      Sql.named('DELETE FROM meeting_minutes WHERE id = @id AND group_id = @g'),
      parameters: {'id': b['id'], 'g': _gid(req)});
  await _audit(req, 'delete', 'minute', '${b['id']}');
  return _json({'ok': true});
}

Future<Response> _addAction(Request req) async {
  final b = await _body(req);
  await db.execute(
    Sql.named('INSERT INTO meeting_actions (id, group_id, meeting_id, task, '
        'responsible, due_date, done) VALUES (@id, @g, @m, @t, @r, @d, FALSE)'),
    parameters: {
      'id': _id('ACT'),
      'g': _gid(req),
      'm': b['meetingId'],
      't': b['task'],
      'r': b['responsible'] ?? '',
      'd': _i(b['dueDate']),
    },
  );
  return _json({'ok': true});
}

Future<Response> _toggleAction(Request req) async {
  final b = await _body(req);
  await db.execute(
    Sql.named('UPDATE meeting_actions SET done = @done '
        'WHERE id = @id AND group_id = @g'),
    parameters: {'id': b['id'], 'done': b['done'] == true, 'g': _gid(req)},
  );
  return _json({'ok': true});
}

Future<Response> _deleteAction(Request req) async {
  final b = await _body(req);
  await db.execute(
      Sql.named('DELETE FROM meeting_actions WHERE id = @id AND group_id = @g'),
      parameters: {'id': b['id'], 'g': _gid(req)});
  await _audit(req, 'delete', 'action', '${b['id']}');
  return _json({'ok': true});
}

/// Adds one agenda item to a meeting (appended to the end of its agenda).
Future<Response> _addAgenda(Request req) async {
  final b = await _body(req);
  final posResult = await db.execute(
    Sql.named(
        'SELECT COALESCE(MAX(position), -1) AS p FROM agendas WHERE meeting_id = @m'),
    parameters: {'m': b['meetingId']},
  );
  final pos = _i(posResult.first.toColumnMap()['p']) + 1;
  await db.execute(
    Sql.named('INSERT INTO agendas (id, group_id, meeting_id, text, position) '
        'VALUES (@id, @g, @m, @t, @p)'),
    parameters: {
      'id': _id('AG'),
      'g': _gid(req),
      'm': b['meetingId'],
      't': b['text'],
      'p': pos,
    },
  );
  return _json({'ok': true});
}

/// Ticks an agenda step done/undone as the meeting is run.
Future<Response> _toggleAgenda(Request req) async {
  final b = await _body(req);
  await db.execute(
    Sql.named('UPDATE agendas SET done = @done WHERE id = @id AND group_id = @g'),
    parameters: {'id': b['id'], 'done': b['done'] == true, 'g': _gid(req)},
  );
  return _json({'ok': true});
}

Future<Response> _deleteAgenda(Request req) async {
  final b = await _body(req);
  await db.execute(
    Sql.named('DELETE FROM agendas WHERE id = @id AND group_id = @g'),
    parameters: {'id': b['id'], 'g': _gid(req)},
  );
  await _audit(req, 'delete', 'agenda', '${b['id']}');
  return _json({'ok': true});
}

// --------------------------------------------------------------- GET /snapshot
Future<Response> _snapshot(Request req) async {
  final gid = _gid(req);
  final g = {'g': gid};
  final settings =
      (await _rows('SELECT * FROM groups WHERE id = @g', g)).first;
  final members =
      await _rows('SELECT * FROM members WHERE group_id = @g ORDER BY name', g);
  final membershipRequests = await _rows(
      'SELECT * FROM membership_requests WHERE group_id = @g '
      'ORDER BY requested_on DESC',
      g);
  final allSavings = await _rows('SELECT * FROM savings WHERE group_id = @g', g);
  // Only CONFIRMED savings count toward balances/history; pending member-
  // submitted deposits are surfaced separately as `savingsRequests` and excluded
  // from every sum until an officer approves them.
  final savings = allSavings.where((s) => s['status'] != 'pending').toList();
  final pendingSavings =
      allSavings.where((s) => s['status'] == 'pending').toList();
  final allShares = await _rows('SELECT * FROM share_tx WHERE group_id = @g', g);
  // Only CONFIRMED purchases count toward owned shares / the fund; pending
  // member-submitted buys surface separately as `shareRequests`.
  final shareTx = allShares.where((s) => s['status'] != 'pending').toList();
  final pendingShares =
      allShares.where((s) => s['status'] == 'pending').toList();
  final loans = await _rows('SELECT * FROM loans WHERE group_id = @g', g);
  final repays =
      await _rows('SELECT * FROM repayments WHERE group_id = @g', g);
  final fines = await _rows('SELECT * FROM fines WHERE group_id = @g', g);
  final meetings = await _rows(
      'SELECT * FROM meetings WHERE group_id = @g ORDER BY number DESC', g);
  final officers =
      await _rows('SELECT * FROM officers WHERE group_id = @g ORDER BY id', g);
  final amendments =
      await _rows('SELECT * FROM amendments WHERE group_id = @g ORDER BY date', g);
  final agendas = await _rows(
      'SELECT * FROM agendas WHERE group_id = @g ORDER BY meeting_id, position',
      g);
  final attendance =
      await _rows('SELECT * FROM meeting_attendance WHERE group_id = @g', g);
  final minutes = await _rows(
      'SELECT * FROM meeting_minutes WHERE group_id = @g '
      'ORDER BY meeting_id, position',
      g);
  final actions = await _rows(
      'SELECT * FROM meeting_actions WHERE group_id = @g ORDER BY due_date', g);

  final nameById = {
    for (final m in members) m['id'] as String: m['name'] as String
  };
  final loanName = {
    for (final l in loans) l['id'] as String: l['member_name'] as String
  };

  double repaid(String loanId) => repays
      .where((r) => r['loan_id'] == loanId)
      .fold(0.0, (a, r) => a + _d(r['amount']));

  // Guarantors (names) per loan.
  final guarantorRows = await _rows(
      'SELECT loan_id, member_id FROM loan_guarantors WHERE group_id = @g', g);
  final guarantorsByLoan = <String, List<String>>{};
  for (final g in guarantorRows) {
    (guarantorsByLoan[g['loan_id'] as String] ??= [])
        .add(nameById[g['member_id']] ?? '');
  }
  // Lifecycle history per loan (request / approve / reject / disburse), oldest
  // first, from the audit trail — who did what, when.
  final loanEvents = await _rows(
      "SELECT entity_id, action, actor_id, at FROM audit_events "
      "WHERE entity = 'loan' ORDER BY at");
  final historyByLoan = <String, List<Map<String, dynamic>>>{};
  for (final e in loanEvents) {
    (historyByLoan[e['entity_id'] as String] ??= []).add({
      'action': e['action'],
      'actorName': nameById[e['actor_id']] ?? '',
      'date': _i(e['at']),
    });
  }

  // Derive loans (balance + effective status).
  final loanJson = loans.map((l) {
    final principal = _d(l['principal']);
    final rate = _d(l['interest_rate']);
    final months = _i(l['duration_months']);
    final totalDue = rules.loanTotalDue(principal, rate, months);
    final balance = rules.loanBalance(totalDue, repaid(l['id'] as String));
    final status = rules.effectiveLoanStatus(l['status'] as String, balance);
    return {
      'id': l['id'],
      'memberName': l['member_name'],
      'principal': principal,
      'balance': balance,
      'dueDate': _i(l['due_date']),
      'status': status,
      'interestRate': _d(l['interest_rate']),
      'durationMonths': _i(l['duration_months']),
      'guarantors': guarantorsByLoan[l['id']] ?? const <String>[],
      'history': historyByLoan[l['id']] ?? const <Map<String, dynamic>>[],
    };
  }).toList();

  // Derive members (savings, fines, loan balance, status).
  final memberJson = members.map((m) {
    final id = m['id'] as String;
    final name = m['name'] as String;
    final memSavings = savings
        .where((s) => s['member_id'] == id && s['type'] != 'social')
        .fold(0.0, (a, s) => a + _d(s['amount']));
    // A member's fines balance is what they still OWE — only unpaid penalties.
    final memFines = fines
        .where((f) => f['member_id'] == id && f['paid'] != true)
        .fold(0.0, (a, f) => a + _d(f['amount']));
    final loanBal = loanJson
        .where((l) => l['memberName'] == name && l['status'] == 'ongoing')
        .fold(0.0, (a, l) => a + (l['balance'] as double));
    return {
      'id': id,
      'name': name,
      'phone': m['phone'],
      'role': m['role'] ?? 'member',
      // Owned shares = opening allotment + confirmed purchases.
      'shares': _i(m['shares']) +
          shareTx
              .where((s) => s['member_id'] == id)
              .fold(0, (a, s) => a + _i(s['share_count'])),
      'status': loanBal > 0 ? 'borrower' : 'active',
      // Whether the member may sign in (admin can suspend/reactivate). Older
      // rows without the column read as active.
      'active': m['active'] != false,
      'savings': memSavings,
      'loanBalance': loanBal,
      'fines': memFines,
      'joinedOn': _i(m['joined_on']),
    };
  }).toList();

  // Group totals derived from the ledger.
  final savingsCollected = savings
      .where((s) => s['type'] != 'social')
      .fold(0.0, (a, s) => a + _d(s['amount']));
  final socialCollected = savings
      .where((s) => s['type'] == 'social')
      .fold(0.0, (a, s) => a + _d(s['amount']));
  final repaymentsCollected = repays.fold(0.0, (a, r) => a + _d(r['amount']));
  // "Collected" = penalties actually paid (real cash); unpaid ones are still
  // owed and don't count toward cash in hand.
  final finesCollected = fines
      .where((f) => f['paid'] == true)
      .fold(0.0, (a, f) => a + _d(f['amount']));
  final loansDisbursed = loans
      .where((l) => l['status'] != 'request' && l['status'] != 'rejected')
      .fold(0.0, (a, l) => a + _d(l['principal']));
  // Money members paid to buy shares (confirmed) — real cash into the fund.
  final shareCapitalCollected =
      shareTx.fold(0.0, (a, s) => a + _d(s['amount']));
  final cashInHand = rules.cashInHand(
        openingCash: _d(settings['opening_cash']),
        savings: savingsCollected,
        socialFund: socialCollected,
        repayments: repaymentsCollected,
        finesPaid: finesCollected,
        loansDisbursed: loansDisbursed,
        meetingExpense: _d(settings['meeting_expense']),
        otherExpense: _d(settings['other_expense']),
      ) +
      shareCapitalCollected;

  // Recent activity from the newest transactions.
  final acts = <(int, Map<String, dynamic>)>[];
  for (final s in savings) {
    acts.add((
      _i(s['date']),
      {
        'title': nameById[s['member_id']] ?? '',
        'amount': _d(s['amount']),
        'icon': 'savings'
      }
    ));
  }
  for (final r in repays) {
    acts.add((
      _i(r['date']),
      {
        'title': loanName[r['loan_id']] ?? '',
        'amount': _d(r['amount']),
        'icon': 'loan'
      }
    ));
  }
  for (final l in loans
      .where((l) => l['status'] != 'request' && l['status'] != 'rejected')) {
    acts.add((
      _i(l['disbursed_on']),
      {'title': l['member_name'], 'amount': _d(l['principal']), 'icon': 'loan'}
    ));
  }
  for (final f in fines) {
    acts.add((
      _i(f['date']),
      {
        'title': nameById[f['member_id']] ?? '',
        'amount': _d(f['amount']),
        'icon': 'fine'
      }
    ));
  }
  acts.sort((a, b) => b.$1.compareTo(a.$1));

  return _json({
    'groupName': settings['name'],
    'term': settings['term'],
    // The group's full editable rulebook (single source of truth for the app).
    'rules': _rulesJson(settings),
    'members': memberJson,
    'membershipRequests': membershipRequests
        .map((r) => {
              'id': r['id'],
              'name': r['name'],
              'phone': r['phone'],
              'shares': _i(r['shares']),
              'status': r['status'],
              'requestedOn': _i(r['requested_on']),
            })
        .toList(),
    'loans': loanJson,
    'savings': savings
        .map((s) => {
              'memberName': nameById[s['member_id']] ?? '',
              'amount': _d(s['amount']),
              'date': _i(s['date']),
              'method': s['method'],
              'type': s['type'],
            })
        .toList(),
    // Member-submitted deposits awaiting an officer's confirmation.
    'savingsRequests': pendingSavings
        .map((s) => {
              'id': s['id'],
              'memberId': s['member_id'],
              'memberName': nameById[s['member_id']] ?? '',
              'amount': _d(s['amount']),
              'date': _i(s['date']),
              'method': s['method'],
              'type': s['type'],
            })
        .toList(),
    // Member-submitted share purchases awaiting an officer's confirmation.
    'shareRequests': pendingShares
        .map((s) => {
              'id': s['id'],
              'memberId': s['member_id'],
              'memberName': nameById[s['member_id']] ?? '',
              'shareCount': _i(s['share_count']),
              'amount': _d(s['amount']),
              'date': _i(s['date']),
              'method': s['method'],
            })
        .toList(),
    'fines': fines
        .map((f) => {
              'id': f['id'],
              'memberName': nameById[f['member_id']] ?? '',
              'reason': f['reason'],
              'amount': _d(f['amount']),
              'date': _i(f['date']),
              'paid': f['paid'],
            })
        .toList(),
    'repayments': repays
        .map((r) => {
              'loanId': r['loan_id'],
              'memberName': loanName[r['loan_id']] ?? '',
              'amount': _d(r['amount']),
              'date': _i(r['date']),
              'method': r['method'] ?? 'cash',
            })
        .toList(),
    'meetings': meetings.map((m) {
      final mid = m['id'];
      final att = attendance.where((a) => a['meeting_id'] == mid).toList();
      final present = att.where((a) => a['status'] == 'present').length;
      return {
        'id': mid,
        'number': _i(m['number']),
        'date': _i(m['date']),
        // Attendance is derived from per-member records once any exist.
        'attended': att.isEmpty ? _i(m['attended']) : present,
        'total': att.isEmpty ? _i(m['total']) : members.length,
        'decisions': _i(m['decisions']),
        'collections': _d(m['collections']),
        'fines': _d(m['fines']),
        'title': m['title'] ?? '',
        'startTime': m['start_time'] ?? '',
        'location': m['location'] ?? '',
        'period': m['period'] ?? '',
        'chairperson': m['chairperson'] ?? '',
        'secretary': m['secretary'] ?? '',
        'status': m['status'] ?? 'draft',
        'agenda': agendas
            .where((a) => a['meeting_id'] == mid)
            .map((a) => {
                  'id': a['id'],
                  'text': a['text'],
                  'done': a['done'] == true,
                })
            .toList(),
        'attendance': att
            .map((a) => {
                  'memberId': a['member_id'],
                  'memberName': nameById[a['member_id']] ?? '',
                  'status': a['status'],
                })
            .toList(),
        'minutes': minutes
            .where((x) => x['meeting_id'] == mid)
            .map((x) => {'id': x['id'], 'text': x['text']})
            .toList(),
        'actions': actions
            .where((x) => x['meeting_id'] == mid)
            .map((x) => {
                  'id': x['id'],
                  'task': x['task'],
                  'responsible': x['responsible'] ?? '',
                  'dueDate': _i(x['due_date']),
                  'done': x['done'] == true,
                })
            .toList(),
      };
    }).toList(),
    'officers': officers
        .map((o) => {
              'id': o['id'],
              'name': o['member_name'],
              'role': o['role'],
              'phone': o['phone'],
            })
        .toList(),
    'amendments': amendments
        .map((a) => {
              'id': a['id'],
              'title': a['title'],
              'body': a['body'],
              'date': _i(a['date']),
            })
        .toList(),
    'activities': acts.take(12).map((e) => e.$2).toList(),
    'cashInHand': cashInHand,
    'socialFundBalance': _d(settings['opening_social_fund']) + socialCollected,
    'savingsCollected': savingsCollected,
    'repaymentsCollected': repaymentsCollected,
    'finesCollected': finesCollected,
    'loansDisbursed': loansDisbursed,
    'meetingExpense': _d(settings['meeting_expense']),
    'otherExpense': _d(settings['other_expense']),
    'interestEarned': _d(settings['interest_earned']),
    'shareValue': _d(settings['share_value']),
    'shareCapitalCollected': shareCapitalCollected,
    'meetingsHeld': _i(settings['meetings_held']),
  });
}

/// The group's full, editable rulebook, serialised for /snapshot. Keeps every
/// per-group rule the app reads in one place, so the client has a single source
/// of truth (mirrors the app's `GroupRules`). The legacy flat fields (e.g.
/// top-level `shareValue`) are kept alongside this for backward compatibility.
Map<String, dynamic> _rulesJson(Map<String, dynamic> g) => {
      'shareValue': _d(g['share_value']),
      'minShares': _i(g['min_shares']),
      'maxShares': _i(g['max_shares']),
      'socialFundPerMtg': _d(g['social_fund_per_mtg']),
      'interestRatePct': _d(g['interest_rate_pct']),
      'loanMultiplier': _i(g['loan_multiplier']),
      'loanDurationMonths': _i(g['loan_duration_months']),
      'maxRepaymentMonths': _i(g['max_repayment_months']),
      'requiredGuarantors': _i(g['required_guarantors']),
      'cycleMonths': _i(g['cycle_months']),
      'cycleMonthsElapsed': _i(g['cycle_months_elapsed']),
      'quorumPercent': _i(g['quorum_percent']),
      'meetingFrequency': (g['meeting_frequency'] ?? 'weekly').toString(),
      'meetingStartTime': (g['meeting_start_time'] ?? '10:00').toString(),
      'meetingLocation': (g['meeting_location'] ?? '').toString(),
      'fineTypes': _fineTypesList(g['fine_types']),
    };

/// Parses the stored fine-type catalogue (a JSON array of {name, amount}) into a
/// list, tolerating null/blank/legacy values.
List<Map<String, dynamic>> _fineTypesList(Object? raw) {
  if (raw == null) return const [];
  try {
    final decoded = raw is String ? jsonDecode(raw) : raw;
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => {'name': (e['name'] ?? '').toString(), 'amount': _d(e['amount'])})
        .toList();
  } catch (_) {
    return const [];
  }
}

// --------------------------------------------------------------- POST handlers
Future<Map<String, dynamic>> _body(Request req) async =>
    (jsonDecode(await req.readAsString()) as Map).cast<String, dynamic>();

/// POST /settings/rules — an admin edits their own group's rulebook (share value,
/// interest, loan limits, meeting cadence, quorum, fine types). Scoped to the
/// caller's group and admin-only. Only the editable rule columns are touched;
/// identity (name/term/leader) and derived ledger fields are left untouched.
Future<Response> _updateRules(Request req) async {
  final isAdmin = (req.context['role'] as String?) == 'admin';
  if (!isAdmin) return _json({'ok': false, 'error': 'admin_only'}, status: 403);
  final gid = _gid(req);
  final b = await _body(req);

  // Validate server-side so the rules can't be corrupted by a direct API call.
  final err = rules.validateRules(
    shareValue: _d(b['shareValue']),
    minShares: _i(b['minShares']),
    maxShares: _i(b['maxShares']),
    interestRatePct: _d(b['interestRatePct']),
    loanMultiplier: _i(b['loanMultiplier']),
    loanDurationMonths: _i(b['loanDurationMonths']),
    maxRepaymentMonths: _i(b['maxRepaymentMonths']),
    requiredGuarantors: _i(b['requiredGuarantors']),
    quorumPercent: _i(b['quorumPercent']),
  );
  if (err != null) return _json({'ok': false, 'error': err}, status: 400);

  // Normalise the fine catalogue: drop blank rows, keep name + amount only.
  final fineTypes = (b['fineTypes'] as List? ?? const [])
      .whereType<Map>()
      .map((e) =>
          {'name': (e['name'] ?? '').toString().trim(), 'amount': _d(e['amount'])})
      .where((e) => (e['name'] as String).isNotEmpty)
      .toList();

  await db.execute(
    Sql.named('UPDATE groups SET '
        'share_value = @shareValue, min_shares = @minShares, '
        'max_shares = @maxShares, social_fund_per_mtg = @socialFund, '
        'interest_rate_pct = @interest, loan_multiplier = @multiplier, '
        'loan_duration_months = @duration, max_repayment_months = @maxRepay, '
        'required_guarantors = @guarantors, cycle_months = @cycle, '
        'quorum_percent = @quorum, meeting_frequency = @freq, '
        'meeting_start_time = @startTime, meeting_location = @location, '
        'fine_types = @fineTypes WHERE id = @g'),
    parameters: {
      'shareValue': _d(b['shareValue']),
      'minShares': _i(b['minShares']),
      'maxShares': _i(b['maxShares']),
      'socialFund': _d(b['socialFundPerMtg']),
      'interest': _d(b['interestRatePct']),
      'multiplier': _i(b['loanMultiplier']),
      'duration': _i(b['loanDurationMonths']),
      'maxRepay': _i(b['maxRepaymentMonths']),
      'guarantors': _i(b['requiredGuarantors']),
      'cycle': _i(b['cycleMonths']),
      'quorum': _i(b['quorumPercent']),
      'freq': (b['meetingFrequency'] ?? 'weekly').toString(),
      'startTime': (b['meetingStartTime'] ?? '10:00').toString(),
      'location': (b['meetingLocation'] ?? '').toString(),
      'fineTypes': jsonEncode(fineTypes),
      'g': gid,
    },
  );
  await _audit(req, 'update', 'settings', gid);
  return _json({'ok': true});
}

Future<Response> _addMember(Request req) async {
  final gid = _gid(req);
  final b = await _body(req);
  final shares = _i(b['shares']);
  if (shares < 0) {
    return _json({'ok': false, 'error': 'Shares cannot be negative.'},
        status: 400);
  }
  // Prevent duplicate members: no two members in the same group may share a
  // phone number (compared leniently, last-9-digits, the same way login matches).
  final phone = (b['phone'] ?? '').toString();
  final phoneError = await _membershipPhoneError(gid, phone);
  if (phoneError != null) {
    return _json({'ok': false, 'error': phoneError}, status: 409);
  }
  // New members get a bcrypt-hashed PIN (defaults to '1234' if none supplied);
  // the plaintext column is left empty so nothing sensitive is stored.
  final pin = (b['pin'] ?? '1234').toString();
  final memberId = _id('M');
  await db.execute(
    Sql.named('INSERT INTO members (id, group_id, name, phone, shares, pin, '
        'pin_hash, joined_on) '
        'VALUES (@id, @g, @name, @phone, @shares, \'\', @ph, @joined)'),
    parameters: {
      'id': memberId,
      'g': gid,
      'name': b['name'],
      'phone': phone,
      'shares': shares,
      'ph': BCrypt.hashpw(pin.isEmpty ? '1234' : pin, BCrypt.gensalt()),
      'joined': DateTime.now().millisecondsSinceEpoch,
    },
  );
  await _audit(req, 'create', 'member', memberId,
      {'name': b['name'], 'phone': phone, 'shares': shares});
  return _json({'ok': true});
}

Future<Response> _requestMembership(Request req) async {
  final b = await _body(req);
  final name = (b['name'] ?? '').toString().trim();
  final phone = (b['phone'] ?? '').toString();
  final shares = _i(b['shares']);
  if (name.isEmpty) {
    return _json({'ok': false, 'error': 'Name is required.'}, status: 400);
  }
  if (shares < 0) {
    return _json({'ok': false, 'error': 'Shares cannot be negative.'},
        status: 400);
  }
  // This is a public request (no session), so it can't infer a group. Attach it
  // to a group id the client supplied, else the first active group.
  var gid = (b['groupId'] ?? '').toString();
  if (gid.isEmpty) {
    final g = await _rows(
        'SELECT id FROM groups WHERE active ORDER BY created_at LIMIT 1');
    if (g.isEmpty) {
      return _json({'ok': false, 'error': 'No group is accepting members.'},
          status: 400);
    }
    gid = g.first['id'] as String;
  }
  final phoneError = await _membershipPhoneError(gid, phone);
  if (phoneError != null) {
    return _json({'ok': false, 'error': phoneError}, status: 409);
  }
  final requestId = _id('MR');
  await db.execute(
    Sql.named('INSERT INTO membership_requests '
        '(id, group_id, name, phone, shares, status, requested_on) '
        "VALUES (@id, @g, @name, @phone, @shares, 'pending', @requested)"),
    parameters: {
      'id': requestId,
      'g': gid,
      'name': name,
      'phone': phone,
      'shares': shares,
      'requested': DateTime.now().millisecondsSinceEpoch,
    },
  );
  await _audit(req, 'request', 'membership_request', requestId,
      {'name': name, 'phone': phone, 'shares': shares});
  return _json({'ok': true});
}

Future<Response> _approveMembershipRequest(Request req) async {
  final gid = _gid(req);
  final b = await _body(req);
  final id = (b['id'] ?? '').toString();
  final rows = await db.execute(
    Sql.named("SELECT * FROM membership_requests "
        "WHERE id = @id AND status = 'pending' AND group_id = @g"),
    parameters: {'id': id, 'g': gid},
  );
  if (rows.isEmpty) return _json({'ok': true});
  final r = rows.first.toColumnMap();
  final phone = (r['phone'] ?? '').toString();
  final phoneError = await _membershipPhoneError(gid, phone, exceptId: id);
  if (phoneError != null) {
    return _json({'ok': false, 'error': phoneError}, status: 409);
  }

  final memberId = _id('M');
  await db.runTx((tx) async {
    await tx.execute(
      Sql.named('INSERT INTO members (id, group_id, name, phone, shares, pin, '
          'pin_hash, joined_on) '
          'VALUES (@id, @g, @name, @phone, @shares, \'\', @ph, @joined)'),
      parameters: {
        'id': memberId,
        'g': gid,
        'name': r['name'],
        'phone': phone,
        'shares': _i(r['shares']),
        'ph': BCrypt.hashpw('1234', BCrypt.gensalt()),
        'joined': DateTime.now().millisecondsSinceEpoch,
      },
    );
    await tx.execute(
      Sql.named("UPDATE membership_requests SET status = 'approved', "
          'decided_on = @now, decided_by = @by WHERE id = @id'),
      parameters: {
        'id': id,
        'now': DateTime.now().millisecondsSinceEpoch,
        'by': (req.context['memberId'] as String?) ?? '',
      },
    );
  });
  await _audit(req, 'approve', 'membership_request', id,
      {'memberId': memberId, 'phone': phone});
  await _audit(req, 'create', 'member', memberId,
      {'name': r['name'], 'phone': phone, 'shares': _i(r['shares'])});
  return _json({'ok': true});
}

Future<Response> _rejectMembershipRequest(Request req) async {
  final b = await _body(req);
  final id = (b['id'] ?? '').toString();
  await db.execute(
    Sql.named("UPDATE membership_requests SET status = 'rejected', "
        'decided_on = @now, decided_by = @by '
        "WHERE id = @id AND status = 'pending'"),
    parameters: {
      'id': id,
      'now': DateTime.now().millisecondsSinceEpoch,
      'by': (req.context['memberId'] as String?) ?? '',
    },
  );
  await _audit(req, 'reject', 'membership_request', id);
  return _json({'ok': true});
}

/// Admin: suspend or reactivate a member. A suspended member keeps all their
/// records but cannot log in; suspending also revokes any live sessions so the
/// member is signed out immediately rather than at token expiry.
Future<Response> _setMemberActive(Request req) async {
  final b = await _body(req);
  final id = (b['id'] ?? '').toString();
  final active = b['active'] == true;
  if (id.isEmpty) {
    return _json({'ok': false, 'error': 'Member id required.'}, status: 400);
  }
  final affected = await db.execute(
    Sql.named('UPDATE members SET active = @a WHERE id = @id AND group_id = @g'),
    parameters: {'a': active, 'id': id, 'g': _gid(req)},
  );
  if (affected.affectedRows == 0) {
    return _json({'ok': false, 'error': 'Member not found.'}, status: 404);
  }
  if (!active) {
    await db.execute(Sql.named('DELETE FROM sessions WHERE member_id = @id'),
        parameters: {'id': id});
  }
  await _audit(req, active ? 'activate' : 'suspend', 'member', id,
      {'active': active});
  return _json({'ok': true});
}

/// POST /members/delete — permanently remove a member and all of their records.
/// Refuses while the member still owes the group money (an outstanding loan
/// balance), so a live debt can't be erased by accident. FK references to a
/// member are not all ON DELETE CASCADE, so the child rows are cleared in a
/// single transaction, in dependency order, before the member row itself.
Future<Response> _deleteMember(Request req) async {
  final b = await _body(req);
  final id = (b['id'] ?? '').toString();
  if (id.isEmpty) {
    return _json({'ok': false, 'error': 'Member id required.'}, status: 400);
  }

  final exists = await db.execute(
    Sql.named('SELECT 1 FROM members WHERE id = @id AND group_id = @g'),
    parameters: {'id': id, 'g': _gid(req)},
  );
  if (exists.isEmpty) {
    return _json({'ok': false, 'error': 'Member not found.'}, status: 404);
  }

  // Block deletion while any non-request/rejected loan still has a balance.
  final loanRows = await db.execute(
    Sql.named("SELECT id, principal, interest_rate, duration_months FROM loans "
        "WHERE member_id = @id AND status NOT IN ('request', 'rejected')"),
    parameters: {'id': id},
  );
  var outstanding = 0.0;
  for (final row in loanRows) {
    final l = row.toColumnMap();
    final total = rules.loanTotalDue(
        _d(l['principal']), _d(l['interest_rate']), _i(l['duration_months']));
    final repaid = (await db.execute(
      Sql.named('SELECT COALESCE(SUM(amount), 0) AS s FROM repayments '
          'WHERE loan_id = @lid'),
      parameters: {'lid': l['id']},
    )).first.toColumnMap()['s'];
    outstanding += rules.loanBalance(total, _d(repaid));
  }
  if (outstanding > 0) {
    return _json(
        {'ok': false, 'error': 'delete_member_has_loan'}, status: 409);
  }

  await db.runTx((tx) async {
    // Repayments hang off the member's loans; clear them by loan id first.
    await tx.execute(
      Sql.named('DELETE FROM repayments WHERE loan_id IN '
          '(SELECT id FROM loans WHERE member_id = @id)'),
      parameters: {'id': id},
    );
    // Guarantee links where this member is the borrower OR a guarantor.
    await tx.execute(
      Sql.named('DELETE FROM loan_guarantors WHERE member_id = @id '
          'OR loan_id IN (SELECT id FROM loans WHERE member_id = @id)'),
      parameters: {'id': id},
    );
    await tx.execute(Sql.named('DELETE FROM loans WHERE member_id = @id'),
        parameters: {'id': id});
    await tx.execute(Sql.named('DELETE FROM savings WHERE member_id = @id'),
        parameters: {'id': id});
    await tx.execute(Sql.named('DELETE FROM share_tx WHERE member_id = @id'),
        parameters: {'id': id});
    await tx.execute(Sql.named('DELETE FROM fines WHERE member_id = @id'),
        parameters: {'id': id});
    await tx.execute(
        Sql.named('DELETE FROM meeting_attendance WHERE member_id = @id'),
        parameters: {'id': id});
    await tx.execute(Sql.named('DELETE FROM sessions WHERE member_id = @id'),
        parameters: {'id': id});
    await tx.execute(Sql.named('DELETE FROM members WHERE id = @id'),
        parameters: {'id': id});
  });

  await _audit(req, 'delete', 'member', id, {});
  return _json({'ok': true});
}

/// POST /officers/update — rename a leadership office bearer (by its officer id).
/// Admin-only via middleware.
Future<Response> _updateOfficerName(Request req) async {
  final b = await _body(req);
  final id = (b['id'] ?? '').toString();
  final name = (b['name'] ?? '').toString().trim();
  if (id.isEmpty) {
    return _json({'ok': false, 'error': 'Officer id required.'}, status: 400);
  }
  if (name.isEmpty) {
    return _json({'ok': false, 'error': 'name_required'}, status: 400);
  }
  final affected = await db.execute(
    Sql.named('UPDATE officers SET member_name = @name '
        'WHERE id = @id AND group_id = @g'),
    parameters: {'name': name, 'id': id, 'g': _gid(req)},
  );
  if (affected.affectedRows == 0) {
    return _json({'ok': false, 'error': 'Officer not found.'}, status: 404);
  }
  await _audit(req, 'update', 'officer', id, {'name': name});
  return _json({'ok': true});
}

/// POST /officers/add — appoint a leadership office bearer in this group.
/// Body: name, role (chairperson|secretary|treasurer|keyHolder|mobilizer),
/// phone. Admin-only via middleware.
Future<Response> _addOfficer(Request req) async {
  final gid = _gid(req);
  final b = await _body(req);
  final name = (b['name'] ?? '').toString().trim();
  final role = (b['role'] ?? '').toString().trim();
  final phone = (b['phone'] ?? '').toString().trim();
  const allowedRoles = {
    'chairperson',
    'secretary',
    'treasurer',
    'keyHolder',
    'mobilizer',
  };
  if (name.isEmpty) {
    return _json({'ok': false, 'error': 'name_required'}, status: 400);
  }
  if (!allowedRoles.contains(role)) {
    return _json({'ok': false, 'error': 'Role is required.'}, status: 400);
  }
  final existing = await db.execute(
    Sql.named('SELECT role, phone FROM officers WHERE group_id = @g'),
    parameters: {'g': gid},
  );
  final isAdmin = (req.context['role'] as String?) == 'admin';
  if (!isAdmin && existing.isNotEmpty) {
    return _json({'ok': false, 'error': 'admin_only'}, status: 403);
  }
  if (phone.isNotEmpty &&
      existing
          .any((r) => _normPhone(r.toColumnMap()['phone']) == _normPhone(phone))) {
    return _json({'ok': false, 'error': 'leader_already_assigned'},
        status: 409);
  }
  if (const {'chairperson', 'secretary', 'treasurer'}.contains(role) &&
      existing.any((r) => r.toColumnMap()['role'] == role)) {
    return _json({'ok': false, 'error': 'role_already_assigned'}, status: 409);
  }
  final groupMembers = await _rows(
      'SELECT id, phone FROM members WHERE group_id = @g', {'g': gid});
  Map<String, dynamic>? member;
  for (final m in groupMembers) {
    if (_normPhone(m['phone']) == _normPhone(phone)) {
      member = m;
      break;
    }
  }
  if (member == null) {
    return _json({'ok': false, 'error': 'Member not found.'}, status: 400);
  }
  final selectedMember = member;
  if (!isAdmin && selectedMember['id'] != req.context['memberId']) {
    return _json({'ok': false, 'error': 'admin_only'}, status: 403);
  }
  final id = _id('O');
  await db.runTx((tx) async {
    await tx.execute(
      Sql.named('INSERT INTO officers (id, group_id, member_name, role, phone) '
          'VALUES (@id, @g, @name, @role, @phone)'),
      parameters: {
        'id': id,
        'g': gid,
        'name': name,
        'role': role,
        'phone': phone,
      },
    );
    await tx.execute(
      Sql.named("UPDATE members SET role = 'admin' "
          'WHERE id = @m AND group_id = @g'),
      parameters: {'m': selectedMember['id'], 'g': gid},
    );
    await tx.execute(
      Sql.named("UPDATE sessions SET role = 'admin' "
          'WHERE member_id = @m AND group_id = @g'),
      parameters: {'m': selectedMember['id'], 'g': gid},
    );
  });
  await _audit(req, 'create', 'officer', id, {'name': name, 'role': role});
  return _json({'ok': true});
}

/// POST /officers/remove — remove an office bearer (by officer id) from this
/// group. Admin-only via middleware.
Future<Response> _removeOfficer(Request req) async {
  final b = await _body(req);
  final id = (b['id'] ?? '').toString();
  if (id.isEmpty) {
    return _json({'ok': false, 'error': 'Officer id required.'}, status: 400);
  }
  final affected = await db.execute(
    Sql.named('DELETE FROM officers WHERE id = @id AND group_id = @g'),
    parameters: {'id': id, 'g': _gid(req)},
  );
  if (affected.affectedRows == 0) {
    return _json({'ok': false, 'error': 'Officer not found.'}, status: 404);
  }
  await _audit(req, 'delete', 'officer', id, {});
  return _json({'ok': true});
}

Future<Response> _addSaving(Request req) async {
  final gid = _gid(req);
  final b = await _body(req);
  final isAdmin = (req.context['role'] as String?) == 'admin';
  final amount = _d(b['amount']);
  if (amount <= 0) {
    return _json({'ok': false, 'error': 'Amount must be greater than zero.'},
        status: 400);
  }
  // An officer records a confirmed saving for any member; a member can only
  // submit a PENDING deposit for themselves (their own session id), which an
  // officer must later approve before it counts toward any balance.
  final memberId =
      isAdmin ? b['memberId'] : (req.context['memberId'] as String?);
  if (memberId == null || '$memberId'.isEmpty) {
    return _json({'ok': false, 'error': 'Member is required.'}, status: 400);
  }
  final status = isAdmin ? 'confirmed' : 'pending';
  final id = _id('S');
  await db.execute(
    Sql.named('INSERT INTO savings (id, group_id, member_id, amount, type, '
        'method, date, status) VALUES (@id, @g, @m, @a, @t, @meth, @d, @s)'),
    parameters: {
      'id': id,
      'g': gid,
      'm': memberId,
      'a': amount,
      't': b['type'] ?? 'regular',
      'meth': b['method'] ?? 'Cash',
      'd': _i(b['date']),
      's': status,
    },
  );
  await _audit(req, status == 'pending' ? 'request' : 'create', 'saving', id,
      {'memberId': memberId, 'amount': amount, 'type': b['type']});
  return _json({'ok': true});
}

/// POST /savings/approve — an officer confirms a member's pending deposit, so it
/// starts counting toward balances. Admin-only, scoped to the officer's group.
Future<Response> _approveSaving(Request req) async {
  if ((req.context['role'] as String?) != 'admin') {
    return _json({'ok': false, 'error': 'admin_only'}, status: 403);
  }
  final b = await _body(req);
  await db.execute(
    Sql.named("UPDATE savings SET status = 'confirmed' "
        "WHERE id = @id AND group_id = @g AND status = 'pending'"),
    parameters: {'id': b['id'], 'g': _gid(req)},
  );
  await _audit(req, 'approve', 'saving', '${b['id']}');
  return _json({'ok': true});
}

/// POST /savings/reject — an officer declines a member's pending deposit. The
/// row is removed (an unconfirmed deposit has no ledger value); the audit trail
/// records the rejection. Admin-only, scoped to the officer's group.
Future<Response> _rejectSaving(Request req) async {
  if ((req.context['role'] as String?) != 'admin') {
    return _json({'ok': false, 'error': 'admin_only'}, status: 403);
  }
  final b = await _body(req);
  await db.execute(
    Sql.named("DELETE FROM savings "
        "WHERE id = @id AND group_id = @g AND status = 'pending'"),
    parameters: {'id': b['id'], 'g': _gid(req)},
  );
  await _audit(req, 'reject', 'saving', '${b['id']}');
  return _json({'ok': true});
}

/// POST /shares — record a share purchase. An officer records a confirmed
/// purchase for any member; a member may only submit a PENDING purchase for
/// themselves (their own session id), which an officer must approve before the
/// shares are owned and the money counts toward the fund. Mirrors [_addSaving].
Future<Response> _addShares(Request req) async {
  final gid = _gid(req);
  final b = await _body(req);
  final isAdmin = (req.context['role'] as String?) == 'admin';
  final shareCount = _i(b['shareCount']);
  if (shareCount <= 0) {
    return _json({'ok': false, 'error': 'Buy at least one share.'},
        status: 400);
  }
  final amount = _d(b['amount']);
  if (amount <= 0) {
    return _json({'ok': false, 'error': 'Amount must be greater than zero.'},
        status: 400);
  }
  final memberId =
      isAdmin ? b['memberId'] : (req.context['memberId'] as String?);
  if (memberId == null || '$memberId'.isEmpty) {
    return _json({'ok': false, 'error': 'Member is required.'}, status: 400);
  }
  final status = isAdmin ? 'confirmed' : 'pending';
  final id = _id('SH');
  await db.execute(
    Sql.named('INSERT INTO share_tx (id, group_id, member_id, share_count, '
        'amount, method, date, status) '
        'VALUES (@id, @g, @m, @c, @a, @meth, @d, @s)'),
    parameters: {
      'id': id,
      'g': gid,
      'm': memberId,
      'c': shareCount,
      'a': amount,
      'meth': b['method'] ?? 'Cash',
      'd': _i(b['date']),
      's': status,
    },
  );
  await _audit(req, status == 'pending' ? 'request' : 'create', 'share', id,
      {'memberId': memberId, 'shareCount': shareCount, 'amount': amount});
  return _json({'ok': true});
}

/// POST /shares/approve — an officer confirms a member's pending share purchase,
/// so it credits their owned shares and books the payment. Admin-only, scoped.
Future<Response> _approveShares(Request req) async {
  if ((req.context['role'] as String?) != 'admin') {
    return _json({'ok': false, 'error': 'admin_only'}, status: 403);
  }
  final b = await _body(req);
  await db.execute(
    Sql.named("UPDATE share_tx SET status = 'confirmed' "
        "WHERE id = @id AND group_id = @g AND status = 'pending'"),
    parameters: {'id': b['id'], 'g': _gid(req)},
  );
  await _audit(req, 'approve', 'share', '${b['id']}');
  return _json({'ok': true});
}

/// POST /shares/reject — an officer declines a member's pending share purchase.
/// The row is removed (an unconfirmed buy has no ledger value). Admin-only.
Future<Response> _rejectShares(Request req) async {
  if ((req.context['role'] as String?) != 'admin') {
    return _json({'ok': false, 'error': 'admin_only'}, status: 403);
  }
  final b = await _body(req);
  await db.execute(
    Sql.named("DELETE FROM share_tx "
        "WHERE id = @id AND group_id = @g AND status = 'pending'"),
    parameters: {'id': b['id'], 'g': _gid(req)},
  );
  await _audit(req, 'reject', 'share', '${b['id']}');
  return _json({'ok': true});
}

Future<Response> _addLoan(Request req) async {
  final gid = _gid(req);
  final b = await _body(req);
  final role = (req.context['role'] as String?) ?? 'member';
  final sessionMember = req.context['memberId'] as String?;
  // A non-admin may only apply for their OWN loan, and only as a pending
  // 'request' — they can't disburse to anyone or self-approve. Admins may
  // record a loan for any member with either status.
  final memberId = role == 'admin'
      ? b['memberId'] as String
      : (sessionMember ?? b['memberId'] as String);
  final rows = await db.execute(
    Sql.named('SELECT name, shares FROM members WHERE id = @id AND group_id = @g'),
    parameters: {'id': memberId, 'g': gid},
  );
  if (rows.isEmpty) {
    return _json({'ok': false, 'error': 'Member not found.'}, status: 400);
  }
  final member = rows.first.toColumnMap();
  final memberName = member['name'] as String;
  // A member's self-service application comes in as a 'request' (pending an
  // officer's approval); an officer disbursing a loan defaults to 'ongoing'.
  final status = role == 'admin'
      ? (b['status'] == 'request' ? 'request' : 'ongoing')
      : 'request';

  // Enforce the group's loan rules server-side, so they can't be bypassed by
  // calling the API directly. A pending 'request' isn't disbursing cash yet, so
  // the available-cash check only applies to an actual disbursement ('ongoing').
  final settings =
      (await _rows('SELECT * FROM groups WHERE id = @g', {'g': gid})).first;
  final guarantorIds =
      (b['guarantorIds'] as List? ?? const []).map((e) => '$e').toList();
  final err = rules.validateLoan(
    principal: _d(b['principal']),
    durationMonths: _i(b['durationMonths']),
    shares: _i(member['shares']),
    shareValue: _d(settings['share_value']),
    loanMultiplier: _i(settings['loan_multiplier']),
    maxRepaymentMonths: _i(settings['max_repayment_months']),
    requiredGuarantors: _i(settings['required_guarantors']),
    guarantorIds: guarantorIds,
    borrowerId: memberId,
    availableCash: status == 'ongoing' ? await _availableCash(gid) : 0,
    isDisbursement: status == 'ongoing',
  );
  if (err != null) return _json({'ok': false, 'error': err}, status: 400);

  final loanId = _id('L');
  await db.execute(
    Sql.named('INSERT INTO loans (id, group_id, member_id, member_name, '
        'principal, interest_rate, duration_months, due_date, status, '
        'disbursed_on) '
        'VALUES (@id, @g, @m, @mn, @p, @ir, @dm, @due, @s, @disb)'),
    parameters: {
      'id': loanId,
      'g': gid,
      'm': memberId,
      'mn': memberName,
      'p': _d(b['principal']),
      'ir': _d(b['interestRate']),
      'dm': _i(b['durationMonths']),
      'due': _i(b['dueDate']),
      's': status,
      'disb': DateTime.now().millisecondsSinceEpoch,
    },
  );
  for (final gy in guarantorIds) {
    await db.execute(
      Sql.named('INSERT INTO loan_guarantors (group_id, loan_id, member_id) '
          'VALUES (@g, @l, @m) ON CONFLICT DO NOTHING'),
      parameters: {'g': gid, 'l': loanId, 'm': gy},
    );
  }
  await _audit(req, status == 'ongoing' ? 'disburse' : 'request', 'loan', loanId,
      {'memberId': memberId, 'principal': _d(b['principal']), 'status': status});
  return _json({'ok': true});
}

/// Admin approves a pending request: the loan becomes 'ongoing' and is dated as
/// disbursed now (so it shows up in the cashbook/activity from this point).
Future<Response> _approveLoan(Request req) async {
  final gid = _gid(req);
  final b = await _body(req);
  final loanId = b['loanId'];
  final rows = await db.execute(
    Sql.named("SELECT principal, member_id FROM loans "
        "WHERE id = @id AND status = 'request' AND group_id = @g"),
    parameters: {'id': loanId, 'g': gid},
  );
  if (rows.isEmpty) {
    // Already handled (approved/rejected) or unknown — nothing to disburse.
    return _json({'ok': true});
  }
  // Approving disburses cash now, so enforce the same available-cash rule as a
  // direct disbursement.
  final loanRow = rows.first.toColumnMap();
  final principal = _d(loanRow['principal']);
  final borrowerId = (loanRow['member_id'] ?? '').toString();
  final cash = await _availableCash(gid);
  if (principal > cash) {
    return _json({
      'ok': false,
      'error': 'Not enough cash to disburse this loan — available ${_tzs(cash)}.'
    }, status: 400);
  }
  await db.execute(
    Sql.named("UPDATE loans SET status = 'ongoing', disbursed_on = @now "
        "WHERE id = @id AND status = 'request' AND group_id = @g"),
    parameters: {
      'id': loanId,
      'g': gid,
      'now': DateTime.now().millisecondsSinceEpoch,
    },
  );
  await _audit(req, 'approve', 'loan', '$loanId', {'principal': principal});
  // Let the borrower know their loan was approved and disbursed.
  await _notifyMembers(
    [borrowerId],
    title: 'Loan approved',
    body: 'Your loan of ${_tzs(principal)} has been approved and disbursed.',
    data: {'type': 'loan_approved', 'loanId': '$loanId'},
  );
  return _json({'ok': true});
}

/// Admin declines a pending request. We keep the row (status 'rejected') rather
/// than deleting it, so the history of the application is preserved.
Future<Response> _rejectLoan(Request req) async {
  final b = await _body(req);
  await db.execute(
    Sql.named("UPDATE loans SET status = 'rejected' "
        "WHERE id = @id AND status = 'request' AND group_id = @g"),
    parameters: {'id': b['loanId'], 'g': _gid(req)},
  );
  await _audit(req, 'reject', 'loan', '${b['loanId']}');
  return _json({'ok': true});
}

Future<Response> _addRepayment(Request req) async {
  final gid = _gid(req);
  final b = await _body(req);
  final id = _id('R');
  await db.execute(
    Sql.named('INSERT INTO repayments (id, group_id, loan_id, amount, method, '
        'date) VALUES (@id, @g, @l, @a, @meth, @d)'),
    parameters: {
      'id': id,
      'g': gid,
      'l': b['loanId'],
      'a': _d(b['amount']),
      'meth': b['method'] ?? 'cash',
      'd': _i(b['date']),
    },
  );
  await _audit(req, 'create', 'repayment', id,
      {'loanId': b['loanId'], 'amount': _d(b['amount'])});
  return _json({'ok': true});
}

Future<Response> _addFine(Request req) async {
  final b = await _body(req);
  // A penalty is created unpaid (owed) by default; an admin can mark it paid
  // up front by sending paid:true, or clear it later via /fines/pay.
  final id = _id('F');
  await db.execute(
    Sql.named('INSERT INTO fines (id, group_id, member_id, reason, amount, '
        'paid, date) VALUES (@id, @g, @m, @r, @a, @p, @d)'),
    parameters: {
      'id': id,
      'g': _gid(req),
      'm': b['memberId'],
      'r': b['reason'],
      'a': _d(b['amount']),
      'p': b['paid'] == true,
      'd': _i(b['date']),
    },
  );
  await _audit(req, 'create', 'fine', id, {
    'memberId': b['memberId'],
    'amount': _d(b['amount']),
    'reason': b['reason'],
    'paid': b['paid'] == true,
  });
  // Only notify for an outstanding (unpaid) fine — a fine recorded as already
  // paid is just bookkeeping the member is aware of.
  if (b['paid'] != true) {
    await _notifyMembers(
      [(b['memberId'] ?? '').toString()],
      title: 'New fine',
      body: '${_tzs(_d(b['amount']))} — ${(b['reason'] ?? '').toString()}',
      data: {'type': 'fine_issued', 'fineId': id},
    );
  }
  return _json({'ok': true});
}

/// Admin clears a penalty: marks the fine paid (the cash has been collected).
Future<Response> _payFine(Request req) async {
  final b = await _body(req);
  await db.execute(
    Sql.named('UPDATE fines SET paid = TRUE WHERE id = @id AND group_id = @g'),
    parameters: {'id': b['fineId'], 'g': _gid(req)},
  );
  await _audit(req, 'pay', 'fine', '${b['fineId']}');
  return _json({'ok': true});
}
