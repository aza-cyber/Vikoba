import 'dart:convert';
import 'package:http/http.dart' as http;
import 'repository_base.dart';

/// One platform super-admin account, as returned by the backend registry.
class SuperAdmin {
  final String id;
  final String username;
  final bool active;
  final int createdAt;

  const SuperAdmin({
    required this.id,
    required this.username,
    required this.active,
    required this.createdAt,
  });

  factory SuperAdmin.fromJson(Map<String, dynamic> j) => SuperAdmin(
        id: j['id'] as String? ?? '',
        username: j['username'] as String? ?? '',
        active: j['active'] != false,
        createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
      );
}

/// Talks to the backend's `/superadmin/*` endpoints — the platform super-admin
/// registry that lives in PostgreSQL (login + account management). A successful
/// [login] retains the returned bearer token, which every management call sends.
///
/// Separate from [ApiRepository] on purpose: super admins are a platform-level
/// identity, not a group member, and this client is only used from the
/// super-admin panel.
class SuperAdminApi {
  SuperAdminApi(this.baseUrl, {http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? _token;

  static const _timeout = Duration(seconds: 8);

  /// Whether a super admin is currently signed in (a token is held).
  bool get isAuthenticated => _token != null;

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Authenticates against the DB-backed registry. Returns true and retains the
  /// session token on success; false on bad credentials or an unreachable
  /// server. Never throws.
  Future<bool> login(String username, String password) async {
    try {
      final res = await _client
          .post(
            _u('/superadmin/login'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(_timeout);
      if (res.statusCode != 200) return false;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      if (j['ok'] != true) return false;
      _token = j['token'] as String?;
      return _token != null;
    } catch (_) {
      return false;
    }
  }

  /// Revokes the current session server-side and clears the local token.
  Future<void> logout() async {
    final token = _token;
    _token = null;
    if (token == null) return;
    try {
      await _client
          .post(_u('/superadmin/logout'),
              headers: {'Authorization': 'Bearer $token'})
          .timeout(_timeout);
    } catch (_) {
      // Non-fatal: the session expires server-side regardless.
    }
  }

  /// All super-admin accounts (oldest first). Throws [ApiException] on failure.
  Future<List<SuperAdmin>> list() async {
    final res = await _client
        .get(_u('/superadmin/list'), headers: _headers)
        .timeout(_timeout);
    if (res.statusCode != 200) throw ApiException(_error(res), statusCode: res.statusCode);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return ((j['admins'] as List?) ?? const [])
        .map((e) => SuperAdmin.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> add(String username, String password) =>
      _post('/superadmin/add', {'username': username, 'password': password});

  Future<void> remove(String id) => _post('/superadmin/remove', {'id': id});

  Future<void> resetPin(String id, String password) =>
      _post('/superadmin/reset-pin', {'id': id, 'password': password});

  Future<void> setActive(String id, bool active) =>
      _post('/superadmin/toggle', {'id': id, 'active': active});

  // ---- Group registry (multi-tenant) ----

  /// All groups the platform manages (raw JSON maps; the store maps them to
  /// its own model). Throws [ApiException] on failure.
  Future<List<Map<String, dynamic>>> listGroups() async {
    final res = await _client
        .get(_u('/superadmin/groups'), headers: _headers)
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw ApiException(_error(res), statusCode: res.statusCode);
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return ((j['groups'] as List?) ?? const [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  /// Creates a group; returns its new id.
  Future<String> addGroup(String name, String term, String leader) async {
    final res = await _client
        .post(_u('/superadmin/groups/add'),
            headers: _headers,
            body: jsonEncode({'name': name, 'term': term, 'leader': leader}))
        .timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(_error(res), statusCode: res.statusCode);
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (j['id'] as String?) ?? '';
  }

  Future<void> updateGroup(
          String id, String name, String term, String leader) =>
      _post('/superadmin/groups/update',
          {'id': id, 'name': name, 'term': term, 'leader': leader});

  Future<void> toggleGroup(String id, bool active) =>
      _post('/superadmin/groups/toggle', {'id': id, 'active': active});

  Future<void> removeGroup(String id) =>
      _post('/superadmin/groups/remove', {'id': id});

  /// Opens a group for management: returns a group-scoped admin session token
  /// (and the group's name) the app uses to drive the normal member API.
  Future<({String token, String groupName})> openGroup(String groupId) async {
    final res = await _client
        .post(_u('/superadmin/open-group'),
            headers: _headers, body: jsonEncode({'groupId': groupId}))
        .timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(_error(res), statusCode: res.statusCode);
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      token: (j['token'] as String?) ?? '',
      groupName: (j['groupName'] as String?) ?? '',
    );
  }

  Future<void> _post(String path, Map<String, dynamic> body) async {
    final res = await _client
        .post(_u(path), headers: _headers, body: jsonEncode(body))
        .timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(_error(res), statusCode: res.statusCode);
    }
  }

  /// Extracts the server's `{"error": "…"}` message, or a generic fallback.
  String _error(http.Response res) {
    try {
      final j = jsonDecode(res.body);
      if (j is Map && j['error'] is String) return j['error'] as String;
    } catch (_) {
      // Body wasn't JSON — fall through.
    }
    return 'Request failed (${res.statusCode}).';
  }
}
