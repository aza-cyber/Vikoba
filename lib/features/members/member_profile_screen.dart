import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';

class MemberProfileScreen extends StatefulWidget {
  final Member member;
  const MemberProfileScreen({super.key, required this.member});

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    // Always show the latest figures for this member.
    final m = state.memberById(widget.member.id) ?? widget.member;
    final tabs = [
      locale.t('summary'),
      locale.t('nav_savings'),
      locale.t('nav_loans'),
      locale.t('fines_title'),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(locale.t('member_profile')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(
            children: [
              MemberAvatar(initials: m.initials, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${locale.t('phone')}: ${Fmt.phone(m.phone)}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    Text(
                        '${locale.t('member_since')}: ${Fmt.date(m.joinedOn)}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _TabBar(tabs: tabs, current: _tab, onTap: (i) => setState(() => _tab = i)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                    label: locale.t('nav_savings'),
                    value: Fmt.tzs(m.savings),
                    color: AppColors.savings,
                    bg: AppColors.cardGreenBg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                    label: locale.t('nav_loans'),
                    value: Fmt.tzs(m.loanBalance),
                    color: AppColors.loans,
                    bg: AppColors.cardOrangeBg),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                    label: locale.t('fines_title'),
                    value: Fmt.tzs(m.fines),
                    color: AppColors.fines,
                    bg: AppColors.cardRedBg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                    label: locale.t('shares'),
                    value: '${m.shares}',
                    color: AppColors.meetings,
                    bg: AppColors.cardBlueBg),
              ),
            ],
          ),
          // Admins can suspend/reactivate a member's login here.
          if (state.isAdmin) ...[
            const SizedBox(height: 16),
            AppCard(
              child: Row(
                children: [
                  Icon(
                      m.active
                          ? Icons.verified_user_outlined
                          : Icons.block_outlined,
                      color: m.active ? AppColors.savings : AppColors.fines),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(locale.t('account_status'),
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          m.active
                              ? locale.t('status_active')
                              : locale.t('status_suspended'),
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color:
                                  m.active ? AppColors.savings : AppColors.fines),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _toggleActive(context, m, locale),
                    style: TextButton.styleFrom(
                        foregroundColor:
                            m.active ? AppColors.fines : AppColors.primary),
                    child: Text(m.active
                        ? locale.t('suspend_member')
                        : locale.t('reactivate_member')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _confirmDelete(context, m, locale),
              icon: const Icon(Icons.delete_outline, size: 20),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.fines,
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.fines),
              ),
              label: Text(locale.t('delete_member')),
            ),
          ],
          const SizedBox(height: 22),
          SectionHeader(title: locale.t('transaction_history')),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            final rows = _historyFor(state, m, locale);
            if (rows.isEmpty) {
              return AppCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(locale.t('no_transactions'),
                        style: const TextStyle(color: AppColors.textMuted)),
                  ),
                ),
              );
            }
            return AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: 60, endIndent: 12),
                    rows[i],
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Admin action: suspend (with confirmation) or reactivate this member.
  Future<void> _toggleActive(
      BuildContext context, Member m, LocaleProvider locale) async {
    final messenger = ScaffoldMessenger.of(context);
    final appState = context.read<AppState>();
    if (m.active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(locale.t('suspend_member')),
          content: Text(locale.t('suspend_confirm')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dctx, false),
                child: Text(locale.t('cancel'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(90, 44),
                  backgroundColor: AppColors.fines),
              onPressed: () => Navigator.pop(dctx, true),
              child: Text(locale.t('suspend_member')),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    final error = await appState.setMemberActive(m.id, !m.active);
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(
      backgroundColor:
          error != null ? const Color(0xFFC0392B) : AppColors.primary,
      content: Text(error ??
          locale.t(m.active
              ? 'member_suspended_msg'
              : 'member_reactivated_msg')),
    ));
  }

  /// Admin action: permanently delete this member (with confirmation). On
  /// success, leaves the profile and returns to the members list.
  Future<void> _confirmDelete(
      BuildContext context, Member m, LocaleProvider locale) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final appState = context.read<AppState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(locale.t('delete_member')),
        content: Text('${m.name}\n\n${locale.t('delete_member_confirm')}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: Text(locale.t('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(90, 44),
                backgroundColor: AppColors.fines),
            onPressed: () => Navigator.pop(dctx, true),
            child: Text(locale.t('delete_member')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await appState.deleteMember(m.id);
    if (!context.mounted) return;
    if (error != null) {
      // The returned string may be a known message key (e.g. the outstanding-
      // loan guard) or a raw backend message. locale.t() translates the former
      // and passes the latter straight through (unknown keys fall back to self).
      messenger.showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFC0392B),
        content: Text(locale.t(error)),
      ));
      return;
    }
    navigator.pop();
    messenger.showSnackBar(SnackBar(
      backgroundColor: AppColors.primary,
      content: Text(locale.t('member_deleted_msg')),
    ));
  }

  /// Builds the member's full transaction history newest-first, filtered by the
  /// selected tab: Summary (0) shows everything, Savings (1) only savings,
  /// Loans (2) loan disbursements + repayments, Fines (3) only fines. Each row
  /// carries the exact date and time and, for savings, the type and method.
  List<Widget> _historyFor(AppState state, Member m, LocaleProvider locale) {
    final entries = <(DateTime, Widget)>[];
    final showSavings = _tab == 0 || _tab == 1;
    final showLoans = _tab == 0 || _tab == 2;
    final showFines = _tab == 0 || _tab == 3;

    if (showSavings) {
      for (final s in state.savings.where((s) => s.memberName == m.name)) {
        final label = switch (s.type) {
          SavingType.social => locale.t('social_fund'),
          SavingType.special => locale.t('savings_special'),
          SavingType.regular => locale.t('savings_regular'),
        };
        entries.add((
          s.date,
          _historyRow(Icons.savings_outlined, AppColors.savings, label,
              Fmt.dateTime(s.date), s.amount,
              subtitle: s.method),
        ));
      }
    }
    if (showFines) {
      for (final f in state.fines.where((f) => f.memberName == m.name)) {
        entries.add((
          f.date,
          _historyRow(Icons.gavel_outlined, AppColors.fines, f.reason,
              Fmt.dateTime(f.date), -f.amount),
        ));
      }
    }
    if (showLoans) {
      for (final l in state.loans.where((l) => l.memberName == m.name)) {
        entries.add((
          l.dueDate,
          _historyRow(Icons.handshake_outlined, AppColors.loans,
              locale.t('loan'), Fmt.dateTime(l.dueDate), l.principal),
        ));
      }
      for (final r in state.repayments.where((r) => r.memberName == m.name)) {
        entries.add((
          r.date,
          _historyRow(Icons.payments_outlined, AppColors.savings,
              locale.t('loan_repayment'), Fmt.dateTime(r.date), r.amount,
              subtitle: r.method),
        ));
      }
    }

    entries.sort((a, b) => b.$1.compareTo(a.$1));
    return entries.map((e) => e.$2).toList();
  }

  Widget _historyRow(
      IconData icon, Color color, String title, String when, num amount,
      {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                Text(when,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Text(
            Fmt.signed(amount),
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: amount >= 0 ? AppColors.moneyIn : AppColors.moneyOut),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final List<String> tabs;
  final int current;
  final ValueChanged<int> onTap;

  const _TabBar(
      {required this.tabs, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardGreenBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: current == i ? AppColors.surface : null,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    tabs[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          current == i ? FontWeight.w700 : FontWeight.w500,
                      color: current == i
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  color: color.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
