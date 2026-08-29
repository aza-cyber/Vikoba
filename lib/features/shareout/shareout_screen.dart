import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';

/// Mgawanyo wa Faida / Share-Out — end-of-cycle distribution. Each member is
/// repaid their share value plus a dividend proportional to shares held.
class ShareOutScreen extends StatelessWidget {
  const ShareOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();

    final members = state.members;
    final totalShares = members.fold<int>(0, (sum, m) => sum + m.shares);
    final profit = state.distributableProfit;

    double dividendFor(int shares) =>
        totalShares == 0 ? 0 : profit * shares / totalShares;
    double payoutFor(int shares) =>
        shares * state.rules.shareValue + dividendFor(shares);

    final totalPayout =
        members.fold<double>(0, (sum, m) => sum + payoutFor(m.shares));

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(locale.t('shareout_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _CycleProgress(locale: locale),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Metric(
                    label: locale.t('share_capital'),
                    value: Fmt.tzs(state.shareCapital),
                    color: AppColors.savings,
                    bg: AppColors.cardGreenBg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Metric(
                    label: locale.t('interest_earned'),
                    value: Fmt.tzs(state.interestEarned),
                    color: AppColors.loans,
                    bg: AppColors.cardOrangeBg),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                    label: locale.t('fines_income'),
                    value: Fmt.tzs(state.finesCollected),
                    color: AppColors.fines,
                    bg: AppColors.cardRedBg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Metric(
                    label: locale.t('distributable_profit'),
                    value: Fmt.tzs(profit),
                    color: AppColors.shareOut,
                    bg: AppColors.shareOut.withValues(alpha: 0.10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          HighlightBanner(
            label: locale.t('total_payout'),
            value: Fmt.tzs(totalPayout),
            color: AppColors.shareOut,
            background: AppColors.shareOut.withValues(alpha: 0.10),
          ),
          const SizedBox(height: 22),
          SectionHeader(title: locale.t('per_member_payout')),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < members.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  _PayoutRow(
                    locale: locale,
                    name: members[i].name,
                    shares: members[i].shares,
                    dividend: dividendFor(members[i].shares),
                    payout: payoutFor(members[i].shares),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(locale.t('shareout_note'),
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}

class _CycleProgress extends StatelessWidget {
  final LocaleProvider locale;
  const _CycleProgress({required this.locale});

  @override
  Widget build(BuildContext context) {
    final rules = context.watch<AppState>().rules;
    final elapsed = rules.cycleMonthsElapsed;
    final total = rules.cycleMonths;
    final progress = total == 0 ? 0.0 : elapsed / total;
    final label = locale
        .t('month_of')
        .replaceFirst('{a}', '$elapsed')
        .replaceFirst('{b}', '$total');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(locale.t('cycle_progress'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.cardGreenBg,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _Metric({
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
                  fontSize: 15.5, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _PayoutRow extends StatelessWidget {
  final LocaleProvider locale;
  final String name;
  final int shares;
  final double dividend;
  final double payout;

  const _PayoutRow({
    required this.locale,
    required this.name,
    required this.shares,
    required this.dividend,
    required this.payout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          MemberAvatar(initials: initialsOf(name), size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                    '${locale.t('shares')}: $shares · '
                    '${locale.t('dividend')}: ${Fmt.tzs(dividend)}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11.5)),
              ],
            ),
          ),
          Text(Fmt.tzs(payout),
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.shareOut,
                  fontSize: 13.5)),
        ],
      ),
    );
  }
}
