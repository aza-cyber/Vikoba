import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data/repository_base.dart';
import '../../core/data/super_admin_api.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/state/groups_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';

/// Super-admin account management: list, add, reset-PIN, activate/deactivate and
/// remove the platform super admins stored in the database. Reached from the
/// groups panel. Only meaningful online (API mode); offline it shows a note.
class SuperAdminsScreen extends StatefulWidget {
  const SuperAdminsScreen({super.key});

  @override
  State<SuperAdminsScreen> createState() => _SuperAdminsScreenState();
}

class _SuperAdminsScreenState extends State<SuperAdminsScreen> {
  SuperAdminApi? _api;
  List<SuperAdmin> _admins = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = context.read<GroupsStore>().superAdminApi;
    _load();
  }

  Future<void> _load() async {
    final api = _api;
    if (api == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final admins = await api.list();
      if (!mounted) return;
      setState(() {
        _admins = admins;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : '$e';
        _loading = false;
      });
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFC0392B) : AppColors.primary,
    ));
  }

  /// Runs a mutating API call, showing its error message (if any) and reloading
  /// the list on success.
  Future<void> _mutate(Future<void> Function() action) async {
    try {
      await action();
      await _load();
    } catch (e) {
      if (!mounted) return;
      _snack(e is ApiException ? e.message : '$e', error: true);
    }
  }

  Future<void> _addDialog() async {
    final locale = context.read<LocaleProvider>();
    final user = TextEditingController();
    final pin = TextEditingController();
    final ok = await _credentialDialog(
      title: locale.t('add_admin'),
      usernameController: user,
      pinController: pin,
      showUsername: true,
    );
    if (ok == true) {
      await _mutate(() => _api!.add(user.text.trim(), pin.text.trim()));
    }
    user.dispose();
    pin.dispose();
  }

  Future<void> _resetPinDialog(SuperAdmin a) async {
    final locale = context.read<LocaleProvider>();
    final pin = TextEditingController();
    final ok = await _credentialDialog(
      title: '${locale.t('reset_pin')} — ${a.username}',
      pinController: pin,
      showUsername: false,
    );
    if (ok == true) {
      await _mutate(() => _api!.resetPin(a.id, pin.text.trim()));
    }
    pin.dispose();
  }

  Future<bool?> _credentialDialog({
    required String title,
    TextEditingController? usernameController,
    required TextEditingController pinController,
    required bool showUsername,
  }) {
    final locale = context.read<LocaleProvider>();
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showUsername) ...[
              TextField(
                controller: usernameController,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(labelText: locale.t('username')),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: showUsername ? locale.t('password') : locale.t('new_pin'),
                helperText: locale.t('pin_min_hint'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(locale.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(locale.t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(SuperAdmin a) async {
    final locale = context.read<LocaleProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(locale.t('remove_admin')),
        content: Text('${locale.t('remove_admin_q')}\n\n${a.username}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(locale.t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.fines),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(locale.t('delete')),
          ),
        ],
      ),
    );
    if (ok == true) await _mutate(() => _api!.remove(a.id));
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final offline = _api == null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(locale.t('manage_admins'))),
      floatingActionButton: offline
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: _addDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(locale.t('add_admin'),
                  style: const TextStyle(color: Colors.white)),
            ),
      body: _buildBody(locale, offline),
    );
  }

  Widget _buildBody(LocaleProvider locale, bool offline) {
    if (offline) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(locale.t('admins_offline_note'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted)),
        ),
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.fines)),
              const SizedBox(height: 12),
              TextButton(
                  onPressed: _load, child: Text(locale.t('retry'))),
            ],
          ),
        ),
      );
    }
    if (_admins.isEmpty) {
      return Center(
        child: Text(locale.t('no_admins'),
            style: const TextStyle(color: AppColors.textMuted)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          for (final a in _admins)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AdminCard(
                admin: a,
                locale: locale,
                onResetPin: () => _resetPinDialog(a),
                onToggle: () => _mutate(() => _api!.setActive(a.id, !a.active)),
                onRemove: () => _confirmRemove(a),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final SuperAdmin admin;
  final LocaleProvider locale;
  final VoidCallback onResetPin;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  const _AdminCard({
    required this.admin,
    required this.locale,
    required this.onResetPin,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cardGreenBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_outlined,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(admin.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                if (admin.createdAt > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                      '${locale.t('created_label')}: '
                      '${Fmt.date(DateTime.fromMillisecondsSinceEpoch(admin.createdAt))}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12.5)),
                ],
              ],
            ),
          ),
          StatusChip(
            label: admin.active
                ? locale.t('status_active')
                : locale.t('inactive'),
            color: admin.active ? AppColors.statusActive : AppColors.textMuted,
            background:
                admin.active ? AppColors.statusActiveBg : AppColors.border,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
            onSelected: (v) {
              switch (v) {
                case 'reset':
                  onResetPin();
                case 'toggle':
                  onToggle();
                case 'remove':
                  onRemove();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'reset', child: Text(locale.t('reset_pin'))),
              PopupMenuItem(
                  value: 'toggle',
                  child: Text(admin.active
                      ? locale.t('deactivate')
                      : locale.t('activate'))),
              PopupMenuItem(
                  value: 'remove',
                  child: Text(locale.t('remove_admin'),
                      style: const TextStyle(color: AppColors.fines))),
            ],
          ),
        ],
      ),
    );
  }
}
