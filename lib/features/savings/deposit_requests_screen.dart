import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';

/// Officer approval screen: member-submitted deposits (status `pending`), each
/// with Approve / Reject. Approving confirms the deposit so it counts toward the
/// member's savings; rejecting discards it. Reached from the Savings screen.
class DepositRequestsScreen extends StatelessWidget {
  const DepositRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final requests = state.savingsRequests;

    return Scaffold(
      appBar: AppBar(title: Text(locale.t('deposit_requests'))),
      body: RefreshIndicator(
        onRefresh: () => state.refresh(),
        child: requests.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Icon(Icons.inbox_outlined,
                      size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    locale.t('no_deposit_requests'),
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
                    _RequestCard(deposit: requests[i], locale: locale),
              ),
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final SavingRequest deposit;
  final LocaleProvider locale;
  const _RequestCard({required this.deposit, required this.locale});

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
        ? await appState.approveSaving(widget.deposit.id)
        : await appState.rejectSaving(widget.deposit.id);
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(
      backgroundColor:
          error != null ? const Color(0xFFC0392B) : AppColors.primary,
      content: Text(error ??
          (approve
              ? locale.t('deposit_approved')
              : locale.t('deposit_rejected'))),
    ));
  }

  String _typeLabel(SavingType t, LocaleProvider l) => switch (t) {
        SavingType.regular => l.t('savings_regular'),
        SavingType.special => l.t('savings_special'),
        SavingType.social => l.t('savings_social'),
      };

  @override
  Widget build(BuildContext context) {
    final d = widget.deposit;
    final locale = widget.locale;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              MemberAvatar(initials: d.initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.memberName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(Fmt.tzs(d.amount),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13.5)),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _detail(locale.t('savings_type'),
                      _typeLabel(d.type, locale))),
              Expanded(
                  child: _detail(locale.t('payment_method'), d.method)),
              Expanded(
                  child: _detail(locale.t('date'), Fmt.date(d.requestedOn))),
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
}
