import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config.dart';
import '../../core/data/api_repository.dart';
import '../../core/data/repository.dart';
import '../../core/db/app_database.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/server_config.dart';
import '../../core/state/app_state.dart';
import '../../core/state/groups_store.dart';
import '../../core/theme/app_colors.dart';
import '../shell/main_shell.dart';

/// Opens one VICOBA group and hosts the full admin app ([MainShell]) on top of
/// it, so the super admin can manage that group's members, savings, loans,
/// meetings, etc. Online, it asks the backend for a group-scoped admin session
/// and drives the real API; offline, each group is a separate SQLite file.
class GroupWorkspace extends StatefulWidget {
  final VikobaGroup group;
  const GroupWorkspace({super.key, required this.group});

  @override
  State<GroupWorkspace> createState() => _GroupWorkspaceState();
}

class _GroupWorkspaceState extends State<GroupWorkspace> {
  late final GroupsStore _groups = context.read<GroupsStore>();
  AppState? _state;
  AppDatabase? _db;
  String? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final AppState state;
      if (Config.useApi) {
        // Online: the backend mints a group-scoped admin session; we drive the
        // real API with it, so all of this group's data is the live database.
        final api = _groups.superAdminApi;
        if (api == null) throw StateError('Not signed in as super admin.');
        final opened = await api.openGroup(widget.group.id);
        final repo = ApiRepository(await ServerConfig.load())
          ..useSessionToken(opened.token);
        final snap = await repo.loadSnapshot();
        state = AppState(snap, repo: repo)..enterAsAdmin(superAdmin: true);
      } else {
        // Offline: each group is its own isolated SQLite file.
        final db = AppDatabase.named('vikoba_grp_${widget.group.id}');
        final repo = DriftRepository(db);
        await repo.initGroup(name: widget.group.name, term: widget.group.term);
        final snap = await repo.loadSnapshot();
        state = AppState(snap, repo: repo)..enterAsAdmin(superAdmin: true);
        _db = db;
        // Keep the registry's member count in sync with the group's real data.
        if (snap.members.length != widget.group.membersCount) {
          await _groups
              .update(widget.group.copyWith(membersCount: snap.members.length));
        }
      }

      if (!mounted) {
        await _db?.close();
        return;
      }
      setState(() => _state = state);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _db?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.group.name)),
        body: Center(child: Text(_error!)),
      );
    }
    if (_state == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.group.name)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider<AppState>.value(
      value: _state!,
      child: Scaffold(
        body: Column(
          children: [
            Material(
              color: AppColors.primaryDark,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        tooltip: locale.t('vikoba_groups'),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(locale.t('managing'),
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 11)),
                            Text(widget.group.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Expanded(child: MainShell()),
          ],
        ),
      ),
    );
  }
}
