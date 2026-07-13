import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';
import '../shell/app_state_route.dart';
import '../shell/shell_scope.dart';
import 'import_members_screen.dart';
import 'member_profile_screen.dart';
import 'membership_requests_screen.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final members = state.members
        .where((m) => m.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: const ShellLeading(),
        title: Text(locale.t('members_title')),
        actions: [
          IconButton(
            tooltip: locale.t('import_members'),
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: () => Navigator.of(context)
                .push(appStateRoute(context, const ImportMembersScreen())),
          ),
          IconButton(
            tooltip: locale.t('membership_requests'),
            onPressed: () => Navigator.of(context)
                .push(appStateRoute(context, const MembershipRequestsScreen())),
            icon: _BadgeIcon(count: state.pendingMembershipRequests.length),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          heroTag: 'addMember',
          backgroundColor: AppColors.primary,
          onPressed: () => _showAddMember(context, locale),
          icon: const Icon(Icons.person_add_alt, color: Colors.white),
          label: Text(locale.t('add_member'),
              style: const TextStyle(color: Colors.white)),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: locale.t('search_member'),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.tune, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: members.isEmpty
                ? EmptyState(
                    icon: _query.isEmpty
                        ? Icons.groups_outlined
                        : Icons.search_off_rounded,
                    title: _query.isEmpty
                        ? locale.t('no_members_yet')
                        : locale.t('no_matches'),
                    actionLabel:
                        _query.isEmpty ? locale.t('add_member') : null,
                    onAction: _query.isEmpty
                        ? () => _showAddMember(context, locale)
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _MemberTile(member: members[i], locale: locale),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddMember(
      BuildContext context, LocaleProvider locale) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '0');
    final sharesCtrl = TextEditingController(text: '1');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(locale.t('add_member')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      InputDecoration(labelText: locale.t('member')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  // Allow a +255 or 0 prefix, but cap the national number at 9
                  // digits. Saved normalized to the 9-digit form via Fmt.phone.
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
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(locale.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final shares = int.tryParse(sharesCtrl.text.trim()) ?? 0;
                final messenger = ScaffoldMessenger.of(context);
                // Server may reject (e.g. duplicate phone) — only close the
                // dialog and report success if it actually succeeded.
                final error = await context.read<AppState>().addMember(
                      name: name,
                      phone: Fmt.phone(phoneCtrl.text),
                      shares: shares,
                    );
                if (!dialogContext.mounted) return;
                if (error != null) {
                  messenger.showSnackBar(SnackBar(
                    backgroundColor: const Color(0xFFC0392B),
                    content: Text(error),
                  ));
                  return;
                }
                Navigator.pop(dialogContext);
                messenger.showSnackBar(SnackBar(
                  backgroundColor: AppColors.primary,
                  content: Text('${locale.t('add_member')}: $name'),
                ));
              },
              child: Text(locale.t('save')),
            ),
          ],
        );
      },
    );
    nameCtrl.dispose();
    phoneCtrl.dispose();
    sharesCtrl.dispose();
  }
}

class _BadgeIcon extends StatelessWidget {
  final int count;
  const _BadgeIcon({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.how_to_reg_outlined, color: AppColors.textPrimary),
        if (count > 0)
          Positioned(
            right: -7,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16),
              decoration: BoxDecoration(
                color: AppColors.fines,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1.2),
              ),
            ),
          ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Member member;
  final LocaleProvider locale;

  const _MemberTile({required this.member, required this.locale});

  @override
  Widget build(BuildContext context) {
    final isBorrower = member.status == MemberStatus.borrower;
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => Navigator.of(context)
          .push(appStateRoute(context, MemberProfileScreen(member: member))),
      child: Row(
        children: [
          MemberAvatar(initials: member.initials),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 3),
                Text('${locale.t('phone')}: ${Fmt.phone(member.phone)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12.5)),
                const SizedBox(height: 2),
                Text('${locale.t('shares')}: ${member.shares}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
          StatusChip(
            label: isBorrower
                ? locale.t('status_borrower')
                : locale.t('status_active'),
            color: isBorrower
                ? AppColors.statusBorrower
                : AppColors.statusActive,
            background: isBorrower
                ? AppColors.statusBorrowerBg
                : AppColors.statusActiveBg,
          ),
        ],
      ),
    );
  }
}
