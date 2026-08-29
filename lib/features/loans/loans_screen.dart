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
import 'create_loan_screen.dart';
import 'loan_detail_screen.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final statuses = [
      LoanStatus.ongoing,
      LoanStatus.paid,
      LoanStatus.request,
    ];
    final tabs = [
      locale.t('tab_ongoing'),
      locale.t('tab_paid'),
      locale.t('tab_requests'),
    ];
    // The Requests tab also surfaces rejected applications, so the decision
    // history stays visible.
    final loans = _tab == 2
        ? state.loans
            .where((l) =>
                l.status == LoanStatus.request ||
                l.status == LoanStatus.rejected)
            .toList()
        : state.loans.where((l) => l.status == statuses[_tab]).toList();

    return Scaffold(
      appBar: AppBar(
        leading: const ShellLeading(),
        title: Text(locale.t('loans_title')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _tab == i
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                        child: Text(
                          tabs[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: _tab == i
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _tab == i
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await state.refresh();
              },
              child: loans.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        EmptyState(
                          icon: Icons.handshake_outlined,
                          title: _tab == 0
                              ? locale.t('no_ongoing_loans')
                              : _tab == 1
                                  ? locale.t('no_paid_loans')
                                  : locale.t('no_loan_requests'),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      itemCount: loans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          _LoanTile(loan: loans[i], locale: locale),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          onPressed: () => Navigator.of(context)
              .push(appStateRoute(context, const CreateLoanScreen())),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(locale.t('give_loan'),
              style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class _LoanTile extends StatelessWidget {
  final Loan loan;
  final LocaleProvider locale;

  const _LoanTile({required this.loan, required this.locale});

  @override
  Widget build(BuildContext context) {
    final (chipLabel, chipColor, chipBg) = switch (loan.status) {
      LoanStatus.ongoing => (
          locale.t('tab_ongoing'),
          AppColors.statusPending,
          AppColors.statusBorrowerBg
        ),
      LoanStatus.paid => (
          locale.t('completed'),
          AppColors.statusPaid,
          AppColors.statusActiveBg
        ),
      LoanStatus.request => (
          locale.t('loan_request'),
          AppColors.meetings,
          AppColors.cardBlueBg
        ),
      LoanStatus.rejected => (
          locale.t('status_rejected'),
          AppColors.fines,
          AppColors.cardRedBg
        ),
    };

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context)
          .push(appStateRoute(context, LoanDetailScreen(loanId: loan.id))),
      child: Column(
        children: [
          Row(
            children: [
              MemberAvatar(initials: _initials(loan.memberName)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loan.memberName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(Fmt.tzs(loan.principal),
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5)),
                  ],
                ),
              ),
              StatusChip(
                  label: chipLabel, color: chipColor, background: chipBg),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _detail(locale.t('balance'), Fmt.tzs(loan.balance)),
              ),
              Expanded(
                child: _detail(locale.t('due'), Fmt.date(loan.dueDate)),
              ),
            ],
          ),
          if (loan.isOverdue) ...[
            const SizedBox(height: 8),
            OverdueLabel(
                text: '${locale.t('overdue_by')} ${loan.daysOverdue} '
                    '${locale.t('days')}'),
          ],
          // Quick approve / reject for pending applications.
          if (loan.status == LoanStatus.request) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.fines),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final error =
                          await context.read<AppState>().rejectLoan(loan.id);
                      messenger.showSnackBar(SnackBar(
                        backgroundColor: error != null
                            ? const Color(0xFFC0392B)
                            : AppColors.primary,
                        content: Text(error ?? locale.t('status_rejected')),
                      ));
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(locale.t('reject')),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final error =
                          await context.read<AppState>().approveLoan(loan.id);
                      messenger.showSnackBar(SnackBar(
                        backgroundColor: error != null
                            ? const Color(0xFFC0392B)
                            : AppColors.primary,
                        content:
                            Text(error ?? locale.t('loan_approved')),
                      ));
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(locale.t('approve')),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13.5)),
        ],
      );

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }
}
