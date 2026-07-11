import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';
import '../shell/app_state_route.dart';
import 'repayment_screen.dart';

/// Full lifecycle view of a single loan: terms, the running balance (principal
/// minus repayments), its status, and the complete repayment history. Officers
/// can approve/reject a pending request or record a repayment from here.
class LoanDetailScreen extends StatelessWidget {
  final String loanId;
  const LoanDetailScreen({super.key, required this.loanId});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    Loan? loan;
    for (final l in state.loans) {
      if (l.id == loanId) loan = l;
    }
    if (loan == null) {
      return Scaffold(
        appBar: AppBar(title: Text(locale.t('loan_details'))),
        body: Center(child: Text(locale.t('no_loans'))),
      );
    }
    final l = loan;
    final history = state.repaymentsForLoan(l.id);
    final (label, color, bg) = _statusStyle(l.status, locale);

    return Scaffold(
      appBar: AppBar(title: Text(locale.t('loan_details'))),
      body: RefreshIndicator(
        onRefresh: () async {
          await state.refresh();
        },
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              MemberAvatar(initials: initialsOf(l.memberName), size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.memberName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(Fmt.tzs(l.principal),
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              StatusChip(label: label, color: color, background: bg),
            ],
          ),
          const SizedBox(height: 14),
          if (l.isOverdue) _OverdueBanner(days: l.daysOverdue, locale: locale),
          if (l.isOverdue) const SizedBox(height: 14),
          // Repaid-vs-total-due progress: the running deduction.
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(locale.t('repaid_so_far'),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12.5)),
                    Text('${Fmt.tzs(l.repaid)} / ${Fmt.tzs(l.totalDue)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: l.repaidFraction,
                    minHeight: 9,
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                        child: _Stat(
                            label: locale.t('loan_amount_short'),
                            value: Fmt.tzs(l.principal))),
                    Expanded(
                        child: _Stat(
                            label:
                                '${locale.t('interest')} (${l.interestRate.toStringAsFixed(0)}%×${l.durationMonths})',
                            value: Fmt.tzs(l.interest))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _Stat(
                            label: locale.t('total_due'),
                            value: Fmt.tzs(l.totalDue))),
                    Expanded(
                        child: _Stat(
                            label: locale.t('balance'),
                            value: Fmt.tzs(l.balance))),
                    Expanded(
                        child: _Stat(
                            label: locale.t('due'),
                            value: Fmt.date(l.dueDate))),
                  ],
                ),
              ],
            ),
          ),
          // ---- Guarantors (visible to member and admin) ----
          if (l.guarantors.isNotEmpty) ...[
            const SizedBox(height: 18),
            SectionHeader(title: locale.t('guarantors')),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < l.guarantors.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: 56, endIndent: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          MemberAvatar(
                              initials: initialsOf(l.guarantors[i]), size: 34),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(l.guarantors[i],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                          const Icon(Icons.verified_user_outlined,
                              size: 18, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          // ---- Officer actions ----
          if (state.isAdmin && l.status == LoanStatus.request)
            _ApproveReject(loanId: l.id, locale: locale),
          if (state.isAdmin && l.status == LoanStatus.ongoing)
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                appStateRoute(context, RepaymentScreen(initialLoanId: l.id)),
              ),
              icon: const Icon(Icons.payments_outlined),
              label: Text(locale.t('record_repayment')),
            ),
          const SizedBox(height: 18),
          // ---- Loan lifecycle history (requested / approved / rejected) ----
          if (l.history.isNotEmpty) ...[
            SectionHeader(title: locale.t('loan_history')),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < l.history.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: 56, endIndent: 12),
                    _LoanEventRow(event: l.history[i], locale: locale),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          SectionHeader(title: locale.t('repayment_history')),
          const SizedBox(height: 12),
          if (history.isEmpty)
            const AppCard(child: Center(child: Text('—')))
          else
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < history.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: 56, endIndent: 12),
                    _RepaymentRow(repayment: history[i], locale: locale),
                  ],
                ],
              ),
            ),
        ],
      ),
      ),
    );
  }

  (String, Color, Color) _statusStyle(LoanStatus s, LocaleProvider locale) {
    return switch (s) {
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
          AppColors.meetings,
          AppColors.cardBlueBg
        ),
      LoanStatus.rejected => (
          locale.t('status_rejected'),
          AppColors.fines,
          AppColors.cardRedBg
        ),
    };
  }
}

class _ApproveReject extends StatelessWidget {
  final String loanId;
  final LocaleProvider locale;
  const _ApproveReject({required this.loanId, required this.locale});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.fines,
              side: const BorderSide(color: AppColors.fines),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              await context.read<AppState>().rejectLoan(loanId);
              if (context.mounted) Navigator.of(context).maybePop();
            },
            icon: const Icon(Icons.close),
            label: Text(locale.t('reject')),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final error =
                  await context.read<AppState>().approveLoan(loanId);
              if (!context.mounted) return;
              if (error != null) {
                messenger.showSnackBar(SnackBar(
                  backgroundColor: const Color(0xFFC0392B),
                  content: Text(error),
                ));
                return;
              }
              messenger.showSnackBar(SnackBar(
                backgroundColor: AppColors.primary,
                content: Text(locale.t('loan_approved')),
              ));
              navigator.maybePop();
            },
            icon: const Icon(Icons.check),
            label: Text(locale.t('approve')),
          ),
        ),
      ],
    );
  }
}

/// One row in the loan's lifecycle timeline (requested / approved / rejected /
/// disbursed) with the acting member and the date, from the audit trail.
class _LoanEventRow extends StatelessWidget {
  final LoanEvent event;
  final LocaleProvider locale;
  const _LoanEventRow({required this.event, required this.locale});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, String label) = switch (event.action) {
      'request' => (
          Icons.outbox_outlined,
          AppColors.meetings,
          locale.t('evt_requested')
        ),
      'approve' => (
          Icons.check_circle_outline,
          AppColors.primary,
          locale.t('evt_approved')
        ),
      'disburse' => (
          Icons.payments_outlined,
          AppColors.primary,
          locale.t('evt_disbursed')
        ),
      'reject' => (
          Icons.cancel_outlined,
          AppColors.fines,
          locale.t('evt_rejected')
        ),
      _ => (Icons.history, AppColors.textMuted, event.action),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                if (event.actorName.isNotEmpty)
                  Text(event.actorName,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Text(Fmt.date(event.date),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _RepaymentRow extends StatelessWidget {
  final Repayment repayment;
  final LocaleProvider locale;
  const _RepaymentRow({required this.repayment, required this.locale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.payments_outlined,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Fmt.date(repayment.date),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(repayment.method,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Text('+${Fmt.number(repayment.amount)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.moneyIn)),
        ],
      ),
    );
  }
}

class _OverdueBanner extends StatelessWidget {
  final int days;
  final LocaleProvider locale;
  const _OverdueBanner({required this.days, required this.locale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardRedBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fines.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.fines, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${locale.t('overdue')} — ${locale.t('overdue_by')} $days ${locale.t('days')}',
              style: const TextStyle(
                  color: AppColors.fines,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
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
            style:
                const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
        const SizedBox(height: 3),
        Text(value,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
      ],
    );
  }
}
