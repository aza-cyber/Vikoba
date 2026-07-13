import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';

/// Member self-service deposit: a member submits a savings deposit for their own
/// account. It is recorded as PENDING and only counts toward their savings once
/// an officer confirms it (see the officer's Deposit Requests screen).
class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  int _typeIndex = 0;
  int _methodIndex = 1; // default to mobile money for self-service deposits
  bool _submitting = false;
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit(LocaleProvider locale) async {
    final amount =
        double.tryParse(_amount.text.replaceAll(RegExp(r'[,\s]'), '')) ?? 0;
    if (amount <= 0) return;
    const types = [SavingType.regular, SavingType.special, SavingType.social];
    final typeLabels = [
      locale.t('savings_regular'),
      locale.t('savings_special'),
      locale.t('savings_social'),
    ];
    final methods = [
      locale.t('cash'),
      locale.t('mobile_money'),
      locale.t('bank')
    ];

    // Summarise the whole entry so the member can confirm before it's sent.
    final ok = await showConfirmSummary(
      context,
      title: locale.t('confirm_details'),
      rows: [
        (locale.t('amount'), Fmt.tzs(amount)),
        (locale.t('savings_type'), typeLabels[_typeIndex]),
        (locale.t('payment_method'), methods[_methodIndex]),
      ],
      confirmLabel: locale.t('confirm'),
      cancelLabel: locale.t('cancel'),
      note: locale.t('deposit_pending_note'),
    );
    if (!ok || !mounted) return;

    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final error = await context.read<AppState>().requestDeposit(
          amount: amount,
          type: types[_typeIndex],
          method: methods[_methodIndex],
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      messenger.showSnackBar(SnackBar(
          backgroundColor: const Color(0xFFC0392B), content: Text(error)));
      return;
    }
    messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.primary,
        content: Text(locale.t('deposit_submitted'))));
    navigator.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final savingsTypes = [
      locale.t('savings_regular'),
      locale.t('savings_special'),
      locale.t('savings_social'),
    ];
    final methods = [
      locale.t('cash'),
      locale.t('mobile_money'),
      locale.t('bank'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(locale.t('make_deposit'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          LabeledField(
            label: locale.t('amount'),
            child: TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
            ),
          ),
          LabeledField(
            label: locale.t('savings_type'),
            child: AppDropdown<int>(
              value: _typeIndex,
              items: List.generate(savingsTypes.length, (i) => i),
              labelOf: (i) => savingsTypes[i],
              onChanged: (i) => setState(() => _typeIndex = i ?? 0),
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
                  child: Text(locale.t('deposit_pending_note'),
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitting ? null : () => _submit(locale),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(locale.t('make_deposit')),
          ),
        ],
      ),
    );
  }
}
