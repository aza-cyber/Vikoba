import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';
import '../loans/loan_detail_screen.dart';
import '../shell/app_state_route.dart';
import 'request_loan_screen.dart';

/// The member panel's loans tab: the member's own loans (including pending
/// requests), with a button to apply for a new one.
class UserLoansScreen extends StatelessWidget {
  const UserLoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final me = state.currentMember;
    final myLoans = me == null
        ? <Loan>[]
        : state.loans.where((l) => l.memberName == me.name).toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

    return Scaffold(
      appBar: AppBar(title: Text(locale.t('my_loans'))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.of(context)
            .push(appStateRoute(context, const RequestLoanScreen())),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(locale.t('request_loan'),
            style: const TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await state.refresh();
        },
        child: myLoans.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 160),
                  _Empty(locale: locale),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                itemCount: myLoans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _LoanCard(loan: myLoans[i], locale: locale),
              ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final LocaleProvider locale;
  const _Empty({required this.locale});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.handshake_outlined,
              size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(locale.t('no_loans'),
              style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Loan loan;
  final LocaleProvider locale;
  const _LoanCard({required this.loan, required this.locale});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (loan.status) {
      LoanStatus.ongoing => (
          locale.t('tab_ongoing'),
          AppColors.statusBorrower,
          AppColors.statusBorrowerBg
        ),
      LoanStatus.paid => (
          locale.t('completed'),
          AppColors.statusPaid,
          AppColors.statusActiveBg
        ),
      LoanStatus.request => (
          locale.t('pending_approval'),
          AppColors.statusPending,
          AppColors.statusBorrowerBg
        ),
      LoanStatus.rejected => (
          locale.t('status_rejected'),
          AppColors.fines,
          AppColors.cardRedBg
        ),
    };

    return AppCard(
      onTap: () => Navigator.of(context)
          .push(appStateRoute(context, LoanDetailScreen(loanId: loan.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(Fmt.tzs(loan.principal),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              StatusChip(label: label, color: color, background: bg),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Stat(
                    label: locale.t('balance'), value: Fmt.tzs(loan.balance)),
              ),
              Expanded(
                child: _Stat(
                    label: locale.t('total_due'),
                    value: Fmt.tzs(loan.totalDue)),
              ),
              Expanded(
                child: _Stat(
                    label: locale.t('due'), value: Fmt.date(loan.dueDate)),
              ),
            ],
          ),
          if (loan.isOverdue) ...[
            const SizedBox(height: 10),
            OverdueLabel(
                text: '${locale.t('overdue_by')} ${loan.daysOverdue} '
                    '${locale.t('days')}'),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 11.5)),
        const SizedBox(height: 3),
        Text(value,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
      ],
    );
  }
}
