import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';

/// Admin approval screen: lists loan applications members have submitted and are
/// waiting on (status `request`), each with Approve / Reject. Reached from the
/// dashboard notification bell and the Loans nav badge.
class LoanRequestsScreen extends StatelessWidget {
  const LoanRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final requests = state.loanRequests;

    return Scaffold(
      appBar: AppBar(title: Text(locale.t('approvals_title'))),
      body: RefreshIndicator(
        onRefresh: () => state.refresh(),
        child: requests.isEmpty
            ? ListView(
                // ListView (not Center) so pull-to-refresh still works when empty.
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Icon(Icons.inbox_outlined,
                      size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    locale.t('no_pending_requests'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) =>
                    _RequestCard(loan: requests[i], locale: locale),
              ),
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final Loan loan;
  final LocaleProvider locale;
  const _RequestCard({required this.loan, required this.locale});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _busy = false;

  Future<void> _act(bool approve) async {
    final locale = widget.locale;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final appState = context.read<AppState>();
    final error = approve
        ? await appState.approveLoan(widget.loan.id)
        : await appState.rejectLoan(widget.loan.id);
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(
      backgroundColor:
          error != null ? const Color(0xFFC0392B) : AppColors.primary,
      content: Text(error ??
          (approve
              ? locale.t('loan_approved')
              : locale.t('status_rejected'))),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.loan;
    final locale = widget.locale;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              MemberAvatar(initials: _initials(l.memberName)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.memberName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(Fmt.tzs(l.principal),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13.5)),
                  ],
                ),
              ),
              StatusChip(
                label: locale.t('loan_request'),
                color: AppColors.meetings,
                background: AppColors.cardBlueBg,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _detail(locale.t('interest_rate'),
                      '${l.interestRate == l.interestRate.roundToDouble() ? l.interestRate.toInt() : l.interestRate}%')),
              Expanded(
                  child: _detail(locale.t('duration_months'),
                      '${l.durationMonths}')),
              Expanded(child: _detail(locale.t('due'), Fmt.date(l.dueDate))),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.fines),
                    onPressed: () => _act(false),
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(locale.t('reject')),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary),
                    onPressed: () => _act(true),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(locale.t('approve')),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
        ],
      );

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }
}
