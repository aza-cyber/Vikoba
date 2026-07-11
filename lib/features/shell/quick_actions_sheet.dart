import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../savings/savings_screen.dart';
import '../loans/create_loan_screen.dart';
import '../loans/repayment_screen.dart';
import '../fines/fines_screen.dart';
import 'app_state_route.dart';

void showQuickActions(BuildContext context) {
  final locale = context.read<LocaleProvider>();
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      Widget action(IconData icon, Color color, String label, Widget page) {
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
          onTap: () {
            Navigator.pop(sheetContext);
            Navigator.of(context).push(appStateRoute(context, page));
          },
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(locale.t('quick_actions'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              action(Icons.savings_outlined, AppColors.savings,
                  locale.t('savings_title'), const SavingsScreen()),
              action(Icons.handshake_outlined, AppColors.loans,
                  locale.t('create_loan'), const CreateLoanScreen()),
              action(Icons.payments_outlined, AppColors.primary,
                  locale.t('repayment_title'), const RepaymentScreen()),
              action(Icons.gavel_outlined, AppColors.fines,
                  locale.t('fines_title'), const FinesScreen()),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
    },
  );
}
