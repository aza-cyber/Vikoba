import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/state/groups_store.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common.dart';
import '../auth/login_screen.dart';
import 'group_workspace.dart';
import 'super_admins_screen.dart';

/// Super-admin panel: a registry of VICOBA groups the platform manages. Add,
/// edit, enable/disable and remove groups. Reached via the super-admin login.
class GroupsAdminScreen extends StatelessWidget {
  const GroupsAdminScreen({super.key});

  Future<void> _openForm(BuildContext context, {VikobaGroup? existing}) async {
    final locale = context.read<LocaleProvider>();
    final store = context.read<GroupsStore>();
    final name = TextEditingController(text: existing?.name ?? '');
    final term = TextEditingController(text: existing?.term ?? '');
    final leader = TextEditingController(text: existing?.leader ?? '');
    final members = TextEditingController(
        text: existing == null ? '' : '${existing.membersCount}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(locale.t(existing == null ? 'add_group' : 'edit_group')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: locale.t('group_name')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: term,
                decoration: InputDecoration(labelText: locale.t('term_label')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: leader,
                textCapitalization: TextCapitalization.words,
                decoration:
                    InputDecoration(labelText: locale.t('group_leader')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: members,
                keyboardType: TextInputType.number,
                decoration:
                    InputDecoration(labelText: locale.t('members_count')),
              ),
            ],
          ),
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

    if (ok == true) {
      final count = int.tryParse(members.text.trim()) ?? 0;
      if (existing == null) {
        await store.add(
          name: name.text,
          term: term.text,
          leader: leader.text,
          membersCount: count,
        );
      } else {
        await store.update(existing.copyWith(
          name: name.text.trim(),
          term: term.text.trim(),
          leader: leader.text.trim(),
          membersCount: count,
        ));
      }
    }
    name.dispose();
    term.dispose();
    leader.dispose();
    members.dispose();
  }

  Future<void> _confirmRemove(BuildContext context, VikobaGroup group) async {
    final locale = context.read<LocaleProvider>();
    final store = context.read<GroupsStore>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(locale.t('remove_group')),
        content: Text('${locale.t('remove_group_q')}\n\n${group.name}'),
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
    if (ok == true) await store.remove(group.id);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final store = context.watch<GroupsStore>();
    final groups = store.groups;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.t('vikoba_groups')),
            Text(locale.t('super_admin'),
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: locale.t('manage_admins'),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SuperAdminsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: locale.t('logout'),
            onPressed: () async {
              // Revoke the super-admin session (server-side, online) before
              // returning to the login screen.
              await context.read<GroupsStore>().signOutSuperAdmin();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(locale.t('add_group'),
            style: const TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  label: locale.t('total_groups'),
                  value: '${groups.length}',
                  icon: Icons.diversity_3,
                  accent: AppColors.primary,
                  background: AppColors.cardGreenBg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  label: locale.t('active_groups'),
                  value: '${store.activeCount}',
                  icon: Icons.check_circle_outline,
                  accent: AppColors.meetings,
                  background: AppColors.cardBlueBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Center(
                child: Text(locale.t('no_groups'),
                    style: const TextStyle(color: AppColors.textMuted)),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 2),
              child: Text(locale.t('open_group_hint'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ),
            for (final g in groups)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GroupCard(
                  group: g,
                  locale: locale,
                  onOpen: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => GroupWorkspace(group: g))),
                  onEdit: () => _openForm(context, existing: g),
                  onToggle: () => store.toggleActive(g.id),
                  onRemove: () => _confirmRemove(context, g),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final VikobaGroup group;
  final LocaleProvider locale;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  const _GroupCard({
    required this.group,
    required this.locale,
    required this.onOpen,
    required this.onEdit,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppLogo(
                  width: 58, height: 40, borderColor: AppColors.border),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    if (group.term.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('${locale.t('term_label')}: ${group.term}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12.5)),
                    ],
                  ],
                ),
              ),
              StatusChip(
                label: group.active
                    ? locale.t('status_active')
                    : locale.t('inactive'),
                color:
                    group.active ? AppColors.statusActive : AppColors.textMuted,
                background:
                    group.active ? AppColors.statusActiveBg : AppColors.border,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      onEdit();
                    case 'toggle':
                      onToggle();
                    case 'remove':
                      onRemove();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'edit', child: Text(locale.t('edit_group'))),
                  PopupMenuItem(
                      value: 'toggle',
                      child: Text(group.active
                          ? locale.t('deactivate')
                          : locale.t('activate'))),
                  PopupMenuItem(
                      value: 'remove',
                      child: Text(locale.t('remove_group'),
                          style: const TextStyle(color: AppColors.fines))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (group.leader.isNotEmpty) ...[
                const Icon(Icons.person_outline,
                    size: 15, color: AppColors.textMuted),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(group.leader,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 14),
              ],
              const Icon(Icons.groups_outlined,
                  size: 15, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text('${group.membersCount} ${locale.t('members_count')}',
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}
