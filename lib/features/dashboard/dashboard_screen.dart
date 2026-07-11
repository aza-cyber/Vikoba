import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';
import '../loans/loan_requests_screen.dart';
import '../shell/app_state_route.dart';
import '../shell/shell_scope.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        leading: const ShellLeading(),
        title: Text(locale.t('nav_dashboard')),
        actions: [
          _NotificationBell(count: state.loanRequests.length),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await state.refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
          children: [
            _GroupBanner(
                locale: locale, groupName: state.groupName, term: state.term),
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
                  label: locale.t('total_savings'),
                  value: Fmt.tzs(state.totalSavings),
                  icon: Icons.savings_outlined,
                  accent: AppColors.savings,
                  background: AppColors.cardGreenBg,
                ),
                SummaryCard(
                  label: locale.t('active_loans'),
                  value: Fmt.tzs(state.activeLoans),
                  icon: Icons.handshake_outlined,
                  accent: AppColors.loans,
                  background: AppColors.cardOrangeBg,
                ),
                SummaryCard(
                  label: locale.t('cash_in_hand'),
                  value: Fmt.tzs(state.cashInHand),
                  icon: Icons.account_balance_wallet_outlined,
                  accent: AppColors.savings,
                  background: AppColors.cardGreenBg,
                ),
                SummaryCard(
                  label: locale.t('members_count'),
                  value: '${state.membersCount}',
                  icon: Icons.groups_outlined,
                  accent: AppColors.meetings,
                  background: AppColors.cardBlueBg,
                ),
                SummaryCard(
                  label: locale.t('fines_collected'),
                  value: Fmt.tzs(state.finesCollected),
                  icon: Icons.gavel_outlined,
                  accent: AppColors.fines,
                  background: AppColors.cardRedBg,
                ),
                SummaryCard(
                  label: locale.t('meetings'),
                  value: '${state.meetingsHeld}',
                  icon: Icons.event_outlined,
                  accent: AppColors.meetings,
                  background: AppColors.cardBlueBg,
                ),
                SummaryCard(
                  label: locale.t('social_fund'),
                  value: Fmt.tzs(state.socialFundBalance),
                  icon: Icons.volunteer_activism_outlined,
                  accent: AppColors.savings,
                  background: AppColors.cardGreenBg,
                ),
                SummaryCard(
                  label: locale.t('share_capital'),
                  value: Fmt.tzs(state.shareCapital),
                  icon: Icons.pie_chart_outline,
                  accent: AppColors.shareOut,
                  background: AppColors.cardBlueBg,
                ),
              ],
            ),
            const SizedBox(height: 22),
            SectionHeader(
              title: locale.t('recent_activity'),
              actionLabel: locale.t('view_all'),
              onAction: () {},
            ),
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final recent = state.activities.take(6).toList();
              if (recent.isEmpty) {
                return const AppCard(
                  child: Center(child: Text('—')),
                );
              }
              return AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < recent.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, indent: 60, endIndent: 12),
                      _ActivityRow(activity: recent[i]),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// App-bar bell that surfaces pending loan requests: shows a red count badge
/// when any are waiting, and opens the approval screen on tap.
class _NotificationBell extends StatelessWidget {
  final int count;
  const _NotificationBell({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: IconButton(
        tooltip: context.read<LocaleProvider>().t('approvals_title'),
        onPressed: () => Navigator.of(context)
            .push(appStateRoute(context, const LoanRequestsScreen())),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none_rounded,
                color: AppColors.textPrimary),
            if (count > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
        ),
      ),
    );
  }
}

class _GroupBanner extends StatelessWidget {
  final LocaleProvider locale;
  final String groupName;
  final String term;
  const _GroupBanner(
      {required this.locale, required this.groupName, required this.term});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppLogo(width: 76, height: 46, borderColor: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${locale.t('group_label')}: $groupName',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${locale.t('term_label')}: $term',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final dynamic activity;
  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final icon = IconMapper.icon(activity.icon);
    final color = IconMapper.color(activity.icon);
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
            child: Text(activity.title as String,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
          Text(
            Fmt.tzs(activity.amount as num),
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}
