import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';
import '../shell/app_state_route.dart';
import 'deposit_screen.dart';

/// The home screen of the member (user) panel: a personal dashboard showing the
/// logged-in member's own savings, loan balance, fines, shares and history.
class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final me = state.currentMember;

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.t('nav_dashboard')),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.notifications_none_rounded,
                color: AppColors.textPrimary),
          ),
        ],
      ),
      body: me == null
          ? Center(child: Text(locale.t('login_failed')))
          : RefreshIndicator(
              onRefresh: () async {
                await state.refresh();
              },
              child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
              children: [
                _Greeting(locale: locale, member: me, group: state.groupName),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    SummaryCard(
                      label: locale.t('my_savings'),
                      value: Fmt.tzs(me.savings),
                      icon: Icons.savings_outlined,
                      accent: AppColors.savings,
                      background: AppColors.cardGreenBg,
                    ),
                    SummaryCard(
                      label: locale.t('my_loan_balance'),
                      value: Fmt.tzs(me.loanBalance),
                      icon: Icons.handshake_outlined,
                      accent: AppColors.loans,
                      background: AppColors.cardOrangeBg,
                    ),
                    SummaryCard(
                      label: locale.t('my_fines'),
                      value: Fmt.tzs(me.fines),
                      icon: Icons.gavel_outlined,
                      accent: AppColors.fines,
                      background: AppColors.cardRedBg,
                    ),
                    SummaryCard(
                      label: locale.t('shares'),
                      value: '${me.shares}',
                      icon: Icons.pie_chart_outline,
                      accent: AppColors.shareOut,
                      background: AppColors.cardBlueBg,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                HighlightBanner(
                  label:
                      '${locale.t('max_loan')} (${locale.t('based_on_shares')})',
                  value: Fmt.tzs(me.shares *
                      state.rules.shareValue *
                      state.rules.loanMultiplier),
                  color: AppColors.shareOut,
                  background: AppColors.cardBlueBg,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .push(appStateRoute(context, const DepositScreen())),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(locale.t('make_deposit')),
                  ),
                ),
                if (state.myPendingDeposits.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  SectionHeader(title: locale.t('pending_deposits')),
                  const SizedBox(height: 8),
                  for (final d in state.myPendingDeposits)
                    _PendingDepositTile(deposit: d, locale: locale),
                ],
                const SizedBox(height: 22),
                SectionHeader(title: locale.t('recent_activity')),
                const SizedBox(height: 12),
                _History(state: state, member: me, locale: locale),
              ],
              ),
            ),
    );
  }
}

/// A member's own pending deposit, shown on their dashboard until an officer
/// confirms or rejects it.
class _PendingDepositTile extends StatelessWidget {
  final SavingRequest deposit;
  final LocaleProvider locale;
  const _PendingDepositTile({required this.deposit, required this.locale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded,
                size: 20, color: AppColors.meetings),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Fmt.tzs(deposit.amount),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('${deposit.method} · ${Fmt.date(deposit.requestedOn)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            StatusChip(
              label: locale.t('pending'),
              color: AppColors.meetings,
              background: AppColors.cardBlueBg,
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final LocaleProvider locale;
  final Member member;
  final String group;
  const _Greeting(
      {required this.locale, required this.member, required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Text(member.initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${locale.t('welcome_user')}, ${member.name}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(group,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The member's own transactions (savings, fines, loans), newest first.
class _History extends StatelessWidget {
  final AppState state;
  final Member member;
  final LocaleProvider locale;
  const _History(
      {required this.state, required this.member, required this.locale});

  @override
  Widget build(BuildContext context) {
    final entries = <(DateTime, Widget)>[];

    for (final s in state.savings.where((s) => s.memberName == member.name)) {
      final label = switch (s.type) {
        SavingType.social => locale.t('social_fund'),
        SavingType.special => locale.t('savings_special'),
        SavingType.regular => locale.t('savings_regular'),
      };
      entries.add((
        s.date,
        _row(Icons.savings_outlined, AppColors.savings, label,
            Fmt.date(s.date), s.amount),
      ));
    }
    for (final f in state.fines.where((f) => f.memberName == member.name)) {
      entries.add((
        f.date,
        _row(Icons.gavel_outlined, AppColors.fines, f.reason, Fmt.date(f.date),
            -f.amount),
      ));
    }
    for (final l in state.loans.where((l) => l.memberName == member.name)) {
      entries.add((
        l.dueDate,
        _row(Icons.handshake_outlined, AppColors.loans, locale.t('loan'),
            Fmt.date(l.dueDate), l.principal),
      ));
    }

    entries.sort((a, b) => b.$1.compareTo(a.$1));
    final rows = entries.take(10).map((e) => e.$2).toList();
    if (rows.isEmpty) {
      return const AppCard(child: Center(child: Text('—')));
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 60, endIndent: 12),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, Color color, String title, String date,
      num amount) {
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
                Text(date,
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
