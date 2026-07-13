import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';

/// Uongozi / Leadership — shows the office bearers, the three key-holders
/// (washika funguo) with the three-lock cash box, and the mobilizers.
class LeadershipScreen extends StatelessWidget {
  const LeadershipScreen({super.key});

  /// Admin: prompts for a new name and renames the office bearer.
  Future<void> _editOfficer(BuildContext context, Officer officer) async {
    final locale = context.read<LocaleProvider>();
    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(text: officer.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(locale.t('edit_leader')),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration:
              InputDecoration(labelText: roleLabel(locale, officer.role)),
          onSubmitted: (v) => Navigator.pop(dctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: Text(locale.t('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(90, 44)),
            onPressed: () => Navigator.pop(dctx, controller.text.trim()),
            child: Text(locale.t('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.isEmpty || newName == officer.name) return;

    final error = await appState.updateOfficerName(officer.id, newName);
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(
      backgroundColor:
          error != null ? const Color(0xFFC0392B) : AppColors.primary,
      content:
          Text(error != null ? locale.t(error) : locale.t('leader_renamed')),
    ));
  }

  /// Admin: appoints an office bearer by picking a member and a role.
  Future<void> _addOfficer(BuildContext context) async {
    final locale = context.read<LocaleProvider>();
    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    // Force a fresh snapshot; on newly opened groups it's possible the
    // current UI state is stale and still reports `members.isEmpty`.
    await appState.refresh();
    if (!context.mounted) return;
    var members = appState.members;
    if (members.isEmpty) {
      if (appState.isAdmin) {
        final created = await _createFirstMember(context);
        if (created == null) return;
        if (!context.mounted) return;
        members = appState.members;
      }
    }
    if (members.isEmpty) {
      messenger.showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFC0392B),
        content: Text(locale.t('add_members_first')),
      ));
      return;
    }

    final officers = appState.officers;
    final assignedPhones = officers.map((o) => Fmt.phone(o.phone)).toSet();
    final bootstrapSelfOnly = !appState.isAdmin && officers.isEmpty;
    final selectableMembers =
        bootstrapSelfOnly && appState.currentMember != null
            ? [appState.currentMember!]
            : members;
    final availableMembers = selectableMembers
        .where((m) => !assignedPhones.contains(Fmt.phone(m.phone)))
        .toList();
    if (availableMembers.isEmpty) {
      messenger.showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFC0392B),
        content: Text(locale.t('all_members_are_leaders')),
      ));
      return;
    }

    Member? selectedMember = availableMembers.first;
    OfficerRole selectedRole = _firstAvailableRole(officers);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(locale.t('add_leader')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LabeledField(
                  label: locale.t('member'),
                  child: AppDropdown<Member>(
                    value: selectedMember,
                    items: availableMembers,
                    labelOf: (m) => m.name,
                    onChanged: (m) => setDialogState(() => selectedMember = m),
                  ),
                ),
                LabeledField(
                  label: locale.t('role'),
                  child: AppDropdown<OfficerRole>(
                    value: selectedRole,
                    items: OfficerRole.values,
                    labelOf: (r) => roleLabel(locale, r),
                    onChanged: (r) =>
                        setDialogState(() => selectedRole = r ?? selectedRole),
                  ),
                ),
                if (_roleIsTaken(officers, selectedRole)) ...[
                  const SizedBox(height: 2),
                  Text(
                    locale.t('role_already_assigned'),
                    style:
                        const TextStyle(color: AppColors.fines, fontSize: 12.5),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dctx, false),
                child: Text(locale.t('cancel'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(90, 44)),
              onPressed: _roleIsTaken(officers, selectedRole)
                  ? null
                  : () => Navigator.pop(dctx, true),
              child: Text(locale.t('save')),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || selectedMember == null) return;

    final m = selectedMember!;
    if (officers.any((o) => Fmt.phone(o.phone) == Fmt.phone(m.phone))) {
      messenger.showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFC0392B),
        content: Text(locale.t('leader_already_assigned')),
      ));
      return;
    }
    if (_roleIsTaken(officers, selectedRole)) {
      messenger.showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFC0392B),
        content: Text(locale.t('role_already_assigned')),
      ));
      return;
    }
    final error = await appState.addOfficer(
        name: m.name, phone: m.phone, role: selectedRole);
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(
      backgroundColor:
          error != null ? const Color(0xFFC0392B) : AppColors.primary,
      content: Text(error != null ? locale.t(error) : locale.t('leader_added')),
    ));
  }

  Future<Member?> _createFirstMember(BuildContext context) async {
    final locale = context.read<LocaleProvider>();
    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '0');
    final sharesCtrl = TextEditingController(text: '1');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(locale.t('add_member')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: locale.t('member')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [TzPhoneInputFormatter()],
                decoration:
                    InputDecoration(labelText: locale.t('phone_number')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sharesCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: locale.t('shares')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(locale.t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(90, 44)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(locale.t('save')),
          ),
        ],
      ),
    );

    if (saved != true) {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      sharesCtrl.dispose();
      return null;
    }

    final name = nameCtrl.text.trim();
    final phone = Fmt.phone(phoneCtrl.text);
    final shares = int.tryParse(sharesCtrl.text.trim()) ?? 1;
    nameCtrl.dispose();
    phoneCtrl.dispose();
    sharesCtrl.dispose();
    if (name.isEmpty) return null;

    final error = await appState.addMember(
      name: name,
      phone: phone,
      shares: shares,
    );
    if (!context.mounted) return null;
    if (error != null) {
      messenger.showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFC0392B),
        content: Text(error),
      ));
      return null;
    }
    await appState.refresh();
    if (!context.mounted) return null;
    for (final member in appState.members) {
      if (Fmt.phone(member.phone) == phone) return member;
    }
    return appState.members.isNotEmpty ? appState.members.first : null;
  }

  /// Admin: removes an office bearer (with confirmation).
  Future<void> _confirmRemoveOfficer(
      BuildContext context, Officer officer) async {
    final locale = context.read<LocaleProvider>();
    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(locale.t('remove_leader')),
        content:
            Text('${officer.name}\n\n${locale.t('remove_leader_confirm')}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: Text(locale.t('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(90, 44),
                backgroundColor: AppColors.fines),
            onPressed: () => Navigator.pop(dctx, true),
            child: Text(locale.t('remove_leader')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await appState.removeOfficer(officer.id);
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(
      backgroundColor:
          error != null ? const Color(0xFFC0392B) : AppColors.primary,
      content:
          Text(error != null ? locale.t(error) : locale.t('leader_removed')),
    ));
  }

  static String roleLabel(LocaleProvider locale, OfficerRole role) {
    switch (role) {
      case OfficerRole.chairperson:
        return locale.t('role_chairperson');
      case OfficerRole.secretary:
        return locale.t('role_secretary');
      case OfficerRole.treasurer:
        return locale.t('role_treasurer');
      case OfficerRole.keyHolder:
        return locale.t('role_keyholder');
      case OfficerRole.mobilizer:
        return locale.t('role_mobilizer');
    }
  }

  static bool _singleSeatRole(OfficerRole role) =>
      role == OfficerRole.chairperson ||
      role == OfficerRole.secretary ||
      role == OfficerRole.treasurer;

  static bool _roleIsTaken(List<Officer> officers, OfficerRole role) =>
      _singleSeatRole(role) && officers.any((o) => o.role == role);

  static OfficerRole _firstAvailableRole(List<Officer> officers) {
    for (final role in const [
      OfficerRole.chairperson,
      OfficerRole.secretary,
      OfficerRole.treasurer,
      OfficerRole.keyHolder,
      OfficerRole.mobilizer,
    ]) {
      if (!_roleIsTaken(officers, role)) return role;
    }
    return OfficerRole.keyHolder;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final officers = state.officers;
    final canEdit = state.isAdmin;
    final bearers = officers
        .where((o) =>
            o.role == OfficerRole.chairperson ||
            o.role == OfficerRole.secretary ||
            o.role == OfficerRole.treasurer)
        .toList();
    final keyHolders =
        officers.where((o) => o.role == OfficerRole.keyHolder).toList();
    final mobilizers =
        officers.where((o) => o.role == OfficerRole.mobilizer).toList();
    final addLeader = canEdit ? () => _addOfficer(context) : null;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(locale.t('leadership_title')),
        actions: [
          if (addLeader != null)
            IconButton(
              tooltip: locale.t('add_leader'),
              onPressed: addLeader,
              icon: const Icon(Icons.person_add_alt_1),
            ),
        ],
      ),
      floatingActionButton: addLeader == null
          ? null
          : FloatingActionButton.extended(
              onPressed: addLeader,
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(locale.t('add_leader')),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          SectionHeader(title: locale.t('office_bearers')),
          const SizedBox(height: 12),
          if (bearers.isEmpty)
            _EmptyLeadershipSection(
              text: locale.t('no_leaders_in_section'),
              actionLabel: addLeader == null ? null : locale.t('add_leader'),
              onAction: addLeader,
            )
          else
            for (final o in bearers) ...[
              _OfficerRow(
                  officer: o,
                  locale: locale,
                  onEdit: canEdit && o.id.isNotEmpty
                      ? () => _editOfficer(context, o)
                      : null,
                  onRemove: canEdit && o.id.isNotEmpty
                      ? () => _confirmRemoveOfficer(context, o)
                      : null),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 12),
          SectionHeader(title: locale.t('key_holders')),
          const SizedBox(height: 12),
          _ThreeLockCard(locale: locale),
          const SizedBox(height: 12),
          if (keyHolders.isEmpty)
            _EmptyLeadershipSection(
              text: locale.t('no_leaders_in_section'),
              actionLabel: addLeader == null ? null : locale.t('add_leader'),
              onAction: addLeader,
            )
          else
            for (final o in keyHolders) ...[
              _OfficerRow(
                  officer: o,
                  locale: locale,
                  onEdit: canEdit && o.id.isNotEmpty
                      ? () => _editOfficer(context, o)
                      : null,
                  onRemove: canEdit && o.id.isNotEmpty
                      ? () => _confirmRemoveOfficer(context, o)
                      : null),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 12),
          SectionHeader(title: locale.t('mobilizers')),
          const SizedBox(height: 12),
          if (mobilizers.isEmpty)
            _EmptyLeadershipSection(
              text: locale.t('no_leaders_in_section'),
              actionLabel: addLeader == null ? null : locale.t('add_leader'),
              onAction: addLeader,
            )
          else
            for (final o in mobilizers) ...[
              _OfficerRow(
                  officer: o,
                  locale: locale,
                  onEdit: canEdit && o.id.isNotEmpty
                      ? () => _editOfficer(context, o)
                      : null,
                  onRemove: canEdit && o.id.isNotEmpty
                      ? () => _confirmRemoveOfficer(context, o)
                      : null),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _OfficerRow extends StatelessWidget {
  final Officer officer;
  final LocaleProvider locale;

  /// Rename this officer. Passed only for admins; null hides the action.
  final VoidCallback? onEdit;

  /// Remove this officer. Passed only for admins; null hides the action.
  final VoidCallback? onRemove;

  const _OfficerRow(
      {required this.officer,
      required this.locale,
      this.onEdit,
      this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isKeyHolder = officer.role == OfficerRole.keyHolder;
    final canManage = onEdit != null || onRemove != null;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          MemberAvatar(
            initials: officer.initials,
            color: isKeyHolder ? AppColors.shareOut : AppColors.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(officer.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(Fmt.phone(officer.phone),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
          StatusChip(
            label: LeadershipScreen.roleLabel(locale, officer.role),
            color: isKeyHolder ? AppColors.shareOut : AppColors.primary,
            background: isKeyHolder
                ? AppColors.shareOut.withValues(alpha: 0.12)
                : AppColors.cardGreenBg,
          ),
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  size: 20, color: AppColors.textMuted),
              onSelected: (v) {
                if (v == 'edit') onEdit?.call();
                if (v == 'remove') onRemove?.call();
              },
              itemBuilder: (_) => [
                if (onEdit != null)
                  PopupMenuItem(
                      value: 'edit', child: Text(locale.t('edit_leader'))),
                if (onRemove != null)
                  PopupMenuItem(
                      value: 'remove',
                      child: Text(locale.t('remove_leader'),
                          style: const TextStyle(color: AppColors.fines))),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptyLeadershipSection extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyLeadershipSection({
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardGreenBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_add_alt_1,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13.5)),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 10),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 18),
              label: Text(actionLabel!),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThreeLockCard extends StatelessWidget {
  final LocaleProvider locale;
  const _ThreeLockCard({required this.locale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.shareOut.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.shareOut.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, color: AppColors.shareOut),
              const SizedBox(width: 10),
              Expanded(
                child: Text(locale.t('three_lock_box'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.shareOut)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.vpn_key,
                    color: AppColors.shareOut.withValues(alpha: 0.8), size: 26),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(locale.t('three_lock_desc'),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}
