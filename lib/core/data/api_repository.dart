import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../state/app_state.dart';
import 'repository_base.dart';

/// Talks to the PostgreSQL-backed HTTP API. Implements the same [Repository]
/// contract as the offline Drift store, so the app is identical either way.
///
/// The backend returns JSON in the exact shape the models' `fromJson` factories
/// expect (epoch-millisecond dates, enum names), so parsing is trivial.
class ApiRepository implements Repository {
  ApiRepository(this.baseUrl, {http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  /// The bearer token from the last successful [login]. Sent on every request
  /// so the server can authenticate/authorize the caller. Null until login.
  String? _token;

  /// Adopts a pre-issued session token (e.g. one minted by the super admin's
  /// `/superadmin/open-group`) so this repository acts as that group's admin
  /// without a member login.
  void useSessionToken(String token) => _token = token;

  /// Hard cap on how long any single request may take. Without this, an
  /// unreachable server makes startup hang forever on a blank screen.
  static const _timeout = Duration(seconds: 8);

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  /// JSON headers plus the bearer token (when logged in).
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  @override
  Future<bool> ping() async {
    try {
      final res = await _client.get(_u('/health')).timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> seedIfEmpty() async {
    // The server seeds itself (or via schema.sql); ask it to ensure data.
    try {
      await _client.post(_u('/seed')).timeout(_timeout);
    } catch (_) {
      // Non-fatal: the schema may already be seeded.
    }
  }

  @override
  Future<AuthResult?> login({
    required String phone,
    required String password,
  }) async {
    final res = await _client
        .post(
          _u('/login'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone, 'password': password}),
        )
        .timeout(_timeout);
    // Credentials were right but the account is suspended: surface a distinct
    // error the app maps to a clear message (not the generic "wrong PIN").
    if (res.statusCode == 403) {
      throw const ApiException('account_inactive', statusCode: 403);
    }
    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (j['ok'] != true) return null;
    // Retain the token so every later request is authenticated.
    _token = j['token'] as String?;
    return AuthResult(
      memberId: j['memberId'] as String,
      name: (j['name'] as String?) ?? '',
      role: j['role'] == 'admin' ? MemberRole.admin : MemberRole.member,
      token: _token,
      // The server scopes the member to their group; surface it if provided.
      groupId: j['groupId'] as String?,
      groupName: j['groupName'] as String?,
    );
  }

  @override
  Future<OtpRequestResult> requestOtp({required String phone}) async {
    try {
      final res = await _client
          .post(
            _u('/otp/request'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone}),
          )
          .timeout(_timeout);
      final j = res.body.isNotEmpty
          ? jsonDecode(res.body) as Map<String, dynamic>
          : const <String, dynamic>{};
      if (res.statusCode == 200 && j['ok'] == true) {
        return OtpRequestResult(ok: true, devCode: j['devCode'] as String?);
      }
      // Map the server's error code to a locale key the UI can display.
      final error = (j['error'] as String?) ?? '';
      return OtpRequestResult(ok: false, errorKey: _otpErrorKey(error));
    } catch (_) {
      return const OtpRequestResult(ok: false, errorKey: 'connection_error');
    }
  }

  /// Translates an /otp/request error string into an app locale key.
  String _otpErrorKey(String serverError) => switch (serverError) {
        'too_soon' => 'otp_too_soon',
        'invalid_phone' => 'phone_required',
        _ => 'otp_send_failed',
      };

  @override
  Future<AuthResult?> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final res = await _client
        .post(
          _u('/otp/verify'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone, 'code': code}),
        )
        .timeout(_timeout);
    // Correct code but the account was suspended in the meantime.
    if (res.statusCode == 403) {
      throw const ApiException('account_inactive', statusCode: 403);
    }
    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (j['ok'] != true) return null;
    _token = j['token'] as String?;
    return AuthResult(
      memberId: j['memberId'] as String,
      name: (j['name'] as String?) ?? '',
      role: j['role'] == 'admin' ? MemberRole.admin : MemberRole.member,
      token: _token,
      groupId: j['groupId'] as String?,
      groupName: j['groupName'] as String?,
    );
  }

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {
    if (token.isEmpty || _token == null) return;
    try {
      await _client
          .post(
            _u('/devices/register'),
            headers: _headers,
            body: jsonEncode({'token': token, 'platform': platform}),
          )
          .timeout(_timeout);
    } catch (_) {
      // Non-fatal: the member just won't get push notifications this session.
    }
  }

  @override
  Future<void> unregisterDevice(String token) async {
    if (token.isEmpty || _token == null) return;
    try {
      await _client
          .post(
            _u('/devices/unregister'),
            headers: _headers,
            body: jsonEncode({'token': token}),
          )
          .timeout(_timeout);
    } catch (_) {
      // Non-fatal.
    }
  }

  @override
  Future<void> endSession() async {
    final token = _token;
    _token = null;
    if (token == null) return;
    try {
      // Best-effort revoke on the server; the local token is already cleared.
      await _client
          .post(_u('/logout'), headers: {'Authorization': 'Bearer $token'})
          .timeout(_timeout);
    } catch (_) {
      // Non-fatal: the session will expire server-side regardless.
    }
  }

  @override
  Future<Snapshot> loadSnapshot() async {
    final res =
        await _client.get(_u('/snapshot'), headers: _headers).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('GET /snapshot failed: ${res.statusCode}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;

    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) =>
        ((j[key] as List?) ?? const [])
            .map((e) => f((e as Map).cast<String, dynamic>()))
            .toList();
    double d(String k) => (j[k] as num?)?.toDouble() ?? 0;

    return Snapshot(
      groupName: j['groupName'] as String? ?? '',
      term: j['term'] as String? ?? '',
      rules: GroupRules.fromJson(
          (j['rules'] as Map?)?.cast<String, dynamic>() ?? const {}),
      members: list('members', Member.fromJson),
      membershipRequests:
          list('membershipRequests', MembershipRequest.fromJson),
      savingsRequests: list('savingsRequests', SavingRequest.fromJson),
      loans: list('loans', Loan.fromJson),
      savings: list('savings', SavingEntry.fromJson),
      repayments: list('repayments', Repayment.fromJson),
      fines: list('fines', Fine.fromJson),
      meetings: list('meetings', Meeting.fromJson),
      officers: list('officers', Officer.fromJson),
      amendments: list('amendments', Amendment.fromJson),
      activities: list('activities', Activity.fromJson),
      cashInHand: d('cashInHand'),
      socialFundBalance: d('socialFundBalance'),
      savingsCollected: d('savingsCollected'),
      repaymentsCollected: d('repaymentsCollected'),
      finesCollected: d('finesCollected'),
      loansDisbursed: d('loansDisbursed'),
      meetingExpense: d('meetingExpense'),
      otherExpense: d('otherExpense'),
      interestEarned: d('interestEarned'),
      shareValue: d('shareValue'),
      meetingsHeld: (j['meetingsHeld'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> updateRules(GroupRules rules) =>
      _post('/settings/rules', rules.toJson());

  Future<void> _post(String path, Map<String, dynamic> body) async {
    final res = await _client.post(
      _u(path),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(_errorMessage(res), statusCode: res.statusCode);
    }
  }

  /// Extracts the server's `{"error": "…"}` message from a failed response,
  /// falling back to a generic message when the body isn't the expected shape.
  String _errorMessage(http.Response res) {
    try {
      final j = jsonDecode(res.body);
      if (j is Map && j['error'] is String) return j['error'] as String;
    } catch (_) {
      // Body wasn't JSON — fall through to the generic message.
    }
    return 'Request failed (${res.statusCode}).';
  }

  @override
  Future<void> insertMember({
    required String name,
    required String phone,
    required int shares,
  }) =>
      _post('/members', {'name': name, 'phone': phone, 'shares': shares});

  @override
  Future<void> requestMembership({
    required String name,
    required String phone,
    required int shares,
  }) =>
      _post('/membership-requests/apply',
          {'name': name, 'phone': phone, 'shares': shares});

  @override
  Future<void> approveMembershipRequest(String id) =>
      _post('/membership-requests/approve', {'id': id});

  @override
  Future<void> rejectMembershipRequest(String id) =>
      _post('/membership-requests/reject', {'id': id});

  @override
  Future<void> setMemberActive({required String id, required bool active}) =>
      _post('/members/status', {'id': id, 'active': active});

  @override
  Future<void> deleteMember(String id) => _post('/members/delete', {'id': id});

  @override
  Future<void> updateOfficerName({required String id, required String name}) =>
      _post('/officers/update', {'id': id, 'name': name});

  @override
  Future<void> addOfficer(
          {required String name, required String phone, required String role}) =>
      _post('/officers/add', {'name': name, 'phone': phone, 'role': role});

  @override
  Future<void> removeOfficer(String id) =>
      _post('/officers/remove', {'id': id});

  @override
  Future<void> insertSaving({
    required String memberId,
    required double amount,
    required DateTime date,
    required SavingType type,
    required String method,
    // The server decides pending-vs-confirmed from the caller's role (a member's
    // deposit is forced to pending + their own id), so asRequest isn't sent.
    bool asRequest = false,
  }) =>
      _post('/savings', {
        'memberId': memberId,
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'type': type.name,
        'method': method,
      });

  @override
  Future<void> approveSaving(String id) =>
      _post('/savings/approve', {'id': id});

  @override
  Future<void> rejectSaving(String id) => _post('/savings/reject', {'id': id});

  @override
  Future<void> insertLoan({
    required String memberId,
    required double principal,
    required double interestRate,
    required int durationMonths,
    required DateTime dueDate,
    List<String> guarantorIds = const [],
    bool asRequest = false,
  }) =>
      _post('/loans', {
        'memberId': memberId,
        'principal': principal,
        'interestRate': interestRate,
        'durationMonths': durationMonths,
        'dueDate': dueDate.millisecondsSinceEpoch,
        'guarantorIds': guarantorIds,
        if (asRequest) 'status': 'request',
      });

  @override
  Future<void> insertRepayment({
    required String loanId,
    required double amount,
    required DateTime date,
    String method = 'cash',
  }) =>
      _post('/repayments', {
        'loanId': loanId,
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'method': method,
      });

  @override
  Future<void> approveLoan(String loanId) =>
      _post('/loans/approve', {'loanId': loanId});

  @override
  Future<void> rejectLoan(String loanId) =>
      _post('/loans/reject', {'loanId': loanId});

  @override
  Future<void> insertFine({
    required String memberId,
    required String reason,
    required double amount,
    required DateTime date,
    bool paid = false,
  }) =>
      _post('/fines', {
        'memberId': memberId,
        'reason': reason,
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'paid': paid,
      });

  @override
  Future<void> payFine(String fineId) => _post('/fines/pay', {'fineId': fineId});

  @override
  Future<void> addAmendment({required String title, required String body}) =>
      _post('/amendments', {'title': title, 'body': body});

  @override
  Future<void> updateAmendment(
          {required String id,
          required String title,
          required String body}) =>
      _post('/amendments/update', {'id': id, 'title': title, 'body': body});

  @override
  Future<void> deleteAmendment(String id) =>
      _post('/amendments/delete', {'id': id});

  @override
  Future<void> createMeeting({
    required DateTime date,
    required String title,
    required String startTime,
    required String location,
    required String period,
    required String chairperson,
    required String secretary,
  }) =>
      _post('/meetings', {
        'date': date.millisecondsSinceEpoch,
        'title': title,
        'startTime': startTime,
        'location': location,
        'period': period,
        'chairperson': chairperson,
        'secretary': secretary,
      });

  @override
  Future<void> updateMeeting({
    required String id,
    required DateTime date,
    required String title,
    required String startTime,
    required String location,
    required String period,
    required String chairperson,
    required String secretary,
    required int decisions,
    required double collections,
    required double fines,
  }) =>
      _post('/meetings/update', {
        'id': id,
        'date': date.millisecondsSinceEpoch,
        'title': title,
        'startTime': startTime,
        'location': location,
        'period': period,
        'chairperson': chairperson,
        'secretary': secretary,
        'decisions': decisions,
        'collections': collections,
        'fines': fines,
      });

  @override
  Future<void> setMeetingStatus({required String id, required String status}) =>
      _post('/meetings/status', {'id': id, 'status': status});

  @override
  Future<void> setAttendance({
    required String meetingId,
    required String memberId,
    required String status,
  }) =>
      _post('/attendance',
          {'meetingId': meetingId, 'memberId': memberId, 'status': status});

  @override
  Future<void> addMinute({required String meetingId, required String text}) =>
      _post('/minutes', {'meetingId': meetingId, 'text': text});

  @override
  Future<void> deleteMinute(String id) => _post('/minutes/delete', {'id': id});

  @override
  Future<void> addAction({
    required String meetingId,
    required String task,
    required String responsible,
    required DateTime? dueDate,
  }) =>
      _post('/actions', {
        'meetingId': meetingId,
        'task': task,
        'responsible': responsible,
        'dueDate': dueDate?.millisecondsSinceEpoch ?? 0,
      });

  @override
  Future<void> toggleAction({required String id, required bool done}) =>
      _post('/actions/toggle', {'id': id, 'done': done});

  @override
  Future<void> deleteAction(String id) => _post('/actions/delete', {'id': id});

  @override
  Future<void> addAgenda({required String meetingId, required String text}) =>
      _post('/agendas', {'meetingId': meetingId, 'text': text});

  @override
  Future<void> toggleAgenda({required String id, required bool done}) =>
      _post('/agendas/toggle', {'id': id, 'done': done});

  @override
  Future<void> deleteAgenda(String id) => _post('/agendas/delete', {'id': id});
}
