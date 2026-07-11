import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../server_config.dart';
import '../data/super_admin_api.dart';

/// One VICOBA group in the super-admin registry.
class VikobaGroup {
  final String id;
  final String name;
  final String term;
  final String leader;
  final int membersCount;
  final bool active;

  const VikobaGroup({
    required this.id,
    required this.name,
    required this.term,
    required this.leader,
    required this.membersCount,
    required this.active,
  });

  VikobaGroup copyWith({
    String? name,
    String? term,
    String? leader,
    int? membersCount,
    bool? active,
  }) =>
      VikobaGroup(
        id: id,
        name: name ?? this.name,
        term: term ?? this.term,
        leader: leader ?? this.leader,
        membersCount: membersCount ?? this.membersCount,
        active: active ?? this.active,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'term': term,
        'leader': leader,
        'membersCount': membersCount,
        'active': active,
      };

  factory VikobaGroup.fromJson(Map<String, dynamic> j) => VikobaGroup(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        term: j['term'] as String? ?? '',
        leader: j['leader'] as String? ?? '',
        membersCount: (j['membersCount'] as num?)?.toInt() ?? 0,
        active: j['active'] as bool? ?? true,
      );
}

/// The super-admin registry of VICOBA groups (add/remove/enable), persisted on
/// the device via [SharedPreferences]. This is a directory of groups; per-group
/// data isolation is a separate (backend) concern.
class GroupsStore extends ChangeNotifier {
  static const _key = 'vikoba_groups_v1';

  /// Super-admin credentials used at the login screen to reach this panel.
  static const superAdminUser = 'superadmin';
  static const superAdminPin = '0000';

  SharedPreferences? _prefs;
  List<VikobaGroup> groups;

  GroupsStore._(this.groups);

  /// Loads the saved registry. If it's empty and a [seedName] is given, seeds a
  /// first entry from the current group so the panel isn't blank on first run.
  static Future<GroupsStore> load({String? seedName, String? seedTerm}) async {
    var groups = <VikobaGroup>[];
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        groups = (jsonDecode(raw) as List)
            .map((e) => VikobaGroup.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      }
    } catch (_) {
      // Unavailable/corrupt prefs → start empty.
    }
    final store = GroupsStore._(groups).._prefs = prefs;
    if (groups.isEmpty && seedName != null && seedName.trim().isNotEmpty) {
      await store.add(
          name: seedName.trim(), term: seedTerm ?? '', leader: '', membersCount: 0);
    }
    return store;
  }

  /// The authenticated super-admin client (online mode only), set by a
  /// successful [authenticateSuperAdmin]. The management screen uses it to
  /// list/add/remove accounts. Null offline or before a super-admin login.
  SuperAdminApi? _superAdminApi;
  SuperAdminApi? get superAdminApi => _superAdminApi;

  /// The offline fallback credential check (compiled-in default). Used only when
  /// the app is built without the API ([Config.useApi] == false); online, super
  /// admins are authenticated against the database via [authenticateSuperAdmin].
  bool isSuperAdmin(String user, String pin) =>
      user.trim().toLowerCase() == superAdminUser && pin.trim() == superAdminPin;

  /// Authenticates a super admin. In API mode this checks the PostgreSQL-backed
  /// `super_admins` registry and, on success, retains an authenticated
  /// [SuperAdminApi] for account management. In offline builds it falls back to
  /// the compiled-in default ([isSuperAdmin]). Returns true if authenticated.
  Future<bool> authenticateSuperAdmin(String user, String pin) async {
    if (Config.useApi) {
      final api = SuperAdminApi(await ServerConfig.load());
      final ok = await api.login(user.trim(), pin.trim());
      _superAdminApi = ok ? api : null;
      // Online, the group registry lives in the backend — load it now that we
      // hold a super-admin token.
      if (ok) await refreshFromBackend();
      return ok;
    }
    return isSuperAdmin(user, pin);
  }

  /// Online only: reloads the group list from the backend. No-op offline or
  /// before a super-admin login. Never throws (leaves the cache as-is on error).
  Future<void> refreshFromBackend() async {
    final api = _superAdminApi;
    if (!Config.useApi || api == null) return;
    try {
      final raw = await api.listGroups();
      groups = raw
          .map((e) => VikobaGroup.fromJson(e))
          .toList();
      notifyListeners();
    } catch (_) {
      // Keep whatever we had; the panel can retry.
    }
  }

  /// Clears the super-admin session (revokes the token server-side, online).
  Future<void> signOutSuperAdmin() async {
    final api = _superAdminApi;
    _superAdminApi = null;
    await api?.logout();
  }

  int get activeCount => groups.where((g) => g.active).length;

  String _newId() => 'g${DateTime.now().microsecondsSinceEpoch}';

  Future<void> add({
    required String name,
    required String term,
    required String leader,
    required int membersCount,
  }) async {
    if (name.trim().isEmpty) return;
    final api = _superAdminApi;
    if (Config.useApi && api != null) {
      await api.addGroup(name.trim(), term.trim(), leader.trim());
      await refreshFromBackend();
      return;
    }
    groups = [
      ...groups,
      VikobaGroup(
        id: _newId(),
        name: name.trim(),
        term: term.trim(),
        leader: leader.trim(),
        membersCount: membersCount,
        active: true,
      ),
    ];
    await _persist();
  }

  Future<void> update(VikobaGroup group) async {
    final api = _superAdminApi;
    if (Config.useApi && api != null) {
      await api.updateGroup(group.id, group.name, group.term, group.leader);
      await refreshFromBackend();
      return;
    }
    groups = [
      for (final g in groups) g.id == group.id ? group : g,
    ];
    await _persist();
  }

  Future<void> remove(String id) async {
    final api = _superAdminApi;
    if (Config.useApi && api != null) {
      await api.removeGroup(id);
      await refreshFromBackend();
      return;
    }
    groups = [
      for (final g in groups)
        if (g.id != id) g,
    ];
    await _persist();
  }

  Future<void> toggleActive(String id) async {
    final api = _superAdminApi;
    if (Config.useApi && api != null) {
      final current = groups.firstWhere((g) => g.id == id,
          orElse: () => throw StateError('group not found'));
      await api.toggleGroup(id, !current.active);
      await refreshFromBackend();
      return;
    }
    groups = [
      for (final g in groups) g.id == id ? g.copyWith(active: !g.active) : g,
    ];
    await _persist();
  }

  Future<void> _persist() async {
    await _prefs?.setString(
        _key, jsonEncode([for (final g in groups) g.toJson()]));
    notifyListeners();
  }
}
