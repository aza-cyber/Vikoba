import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';
import '../shell/shell_scope.dart';

class CashbookScreen extends StatelessWidget {
  const CashbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        leading: const ShellLeading(),
        title: Text(locale.t('cashbook_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          HighlightBanner(
            label: locale.t('cash_in_hand'),
            value: Fmt.tzs(state.cashInHand),
          ),
          const SizedBox(height: 18),
          _Section(
            title: locale.t('income'),
            rows: [
              (locale.t('nav_savings'), state.savingsCollected, true),
              (locale.t('report_repayments'), state.repaymentsCollected, true),
              (locale.t('fines_title'), state.finesCollected, true),
            ],
            total: (locale.t('total_income'), state.totalIncome),
            totalColor: AppColors.moneyIn,
          ),
          const SizedBox(height: 16),
          _Section(
            title: locale.t('expenses'),
            rows: [
              (locale.t('loans_disbursed'), state.loansDisbursed, false),
              (locale.t('meeting_expense'), state.meetingExpense, false),
              (locale.t('other_expense'), state.otherExpense, false),
            ],
            total: (locale.t('total_expenses'), state.totalExpense),
            totalColor: AppColors.moneyOut,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardGreenBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(locale.t('current_balance'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.primaryDark)),
                Text(Fmt.tzs(state.cashInHand),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<(String, double, bool)> rows;
  final (String, double) total;
  final Color totalColor;

  const _Section({
    required this.title,
    required this.rows,
    required this.total,
    required this.totalColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.$1,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)),
                  Text(Fmt.tzs(r.$2),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(total.$1,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14.5)),
                Text(Fmt.tzs(total.$2),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: totalColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
