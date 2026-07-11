import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../shell/app_state_route.dart';
import '../shell/shell_scope.dart';
import 'report_detail_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    final reports = <(IconData, Color, String, ReportType)>[
      (Icons.savings_outlined, AppColors.savings, locale.t('report_savings'),
          ReportType.savings),
      (Icons.handshake_outlined, AppColors.loans, locale.t('report_loans'),
          ReportType.loans),
      (Icons.payments_outlined, AppColors.primary,
          locale.t('report_repayments'), ReportType.repayments),
      (Icons.gavel_outlined, AppColors.fines, locale.t('report_fines'),
          ReportType.fines),
      (Icons.event_outlined, AppColors.meetings, locale.t('report_meetings'),
          ReportType.meetings),
      (Icons.menu_book_outlined, AppColors.primaryDark,
          locale.t('report_cashbook'), ReportType.cashbook),
      (Icons.card_giftcard_outlined, AppColors.shareOut,
          locale.t('report_shareout'), ReportType.shareout),
      (Icons.groups_outlined, AppColors.meetings, locale.t('report_members'),
          ReportType.members),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const ShellLeading(),
        title: Text(locale.t('reports_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 2),
            child: Text(locale.t('tap_report_hint'),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          for (final r in reports) ...[
            _ReportRow(
              icon: r.$1,
              color: r.$2,
              label: r.$3,
              onTap: () => Navigator.of(context)
                  .push(appStateRoute(context, ReportDetailScreen(type: r.$4))),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ReportRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14.5)),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
