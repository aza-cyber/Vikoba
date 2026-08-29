import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';

/// Member self-service share purchase: a member buys shares for their own
/// account, paying the group's share price per share. It is recorded as PENDING
/// and only credits their owned shares (and the group fund) once an officer
/// confirms it (see the officer's Share Requests screen). Mirrors [DepositScreen].
class BuySharesScreen extends StatefulWidget {
  const BuySharesScreen({super.key});

  @override
  State<BuySharesScreen> createState() => _BuySharesScreenState();
}

class _BuySharesScreenState extends State<BuySharesScreen> {
  int _count = 1;
  int _methodIndex = 1; // default to mobile money for self-service payments
  bool _submitting = false;

  Future<void> _submit(LocaleProvider locale, double shareValue) async {
    if (_count <= 0) return;
    final methods = [
      locale.t('cash'),
      locale.t('mobile_money'),
      locale.t('bank'),
    ];
    final cost = _count * shareValue;

    // Summarise the whole purchase so the member can confirm before it's sent.
    final ok = await showConfirmSummary(
      context,
      title: locale.t('confirm_details'),
      rows: [
        (locale.t('number_of_shares'), '$_count'),
        (locale.t('share_price'), Fmt.tzs(shareValue)),
        (locale.t('total_cost'), Fmt.tzs(cost)),
        (locale.t('payment_method'), methods[_methodIndex]),
      ],
      confirmLabel: locale.t('confirm'),
      cancelLabel: locale.t('cancel'),
      note: locale.t('share_purchase_pending_note'),
    );
    if (!ok || !mounted) return;

    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final error = await context.read<AppState>().requestShares(
          shareCount: _count,
          method: methods[_methodIndex],
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      messenger.showSnackBar(SnackBar(
          backgroundColor: const Color(0xFFC0392B), content: Text(locale.t(error))));
      return;
    }
    messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.primary,
        content: Text(locale.t('share_request_submitted'))));
    navigator.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final shareValue = state.rules.shareValue;
    final me = state.currentMember;
    final cost = _count * shareValue;
    final methods = [
      locale.t('cash'),
      locale.t('mobile_money'),
      locale.t('bank'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(locale.t('buy_shares'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (me != null)
            HighlightBanner(
              label: '${locale.t('shares_owned')} · ${me.name}',
              value: '${me.shares}',
              color: AppColors.shareOut,
              background: AppColors.cardBlueBg,
            ),
          const SizedBox(height: 16),
          LabeledField(
            label: locale.t('number_of_shares'),
            child: _CountStepper(
              count: _count,
              onChanged: (v) => setState(() => _count = v),
            ),
          ),
          LabeledField(
            label: locale.t('payment_method'),
            child: AppDropdown<int>(
              value: _methodIndex,
              items: List.generate(methods.length, (i) => i),
              labelOf: (i) => methods[i],
              onChanged: (i) => setState(() => _methodIndex = i ?? 0),
            ),
          ),
          const SizedBox(height: 8),
          // Live cost = shares × the current share price.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBlueBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_count × ${Fmt.tzs(shareValue)}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12.5)),
                      const SizedBox(height: 2),
                      Text(locale.t('total_cost'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
                Text(Fmt.tzs(cost),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.shareOut)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBlueBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 18, color: AppColors.meetings),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(locale.t('share_purchase_pending_note'),
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitting ? null : () => _submit(locale, shareValue),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(locale.t('buy_shares')),
          ),
        ],
      ),
    );
  }
}

/// A simple −/+ quantity stepper for the number of shares (minimum 1).
class _CountStepper extends StatelessWidget {
  final int count;
  final ValueChanged<int> onChanged;
  const _CountStepper({required this.count, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: count > 1 ? () => onChanged(count - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          Expanded(
            child: Text('$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          IconButton(
            onPressed: () => onChanged(count + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
