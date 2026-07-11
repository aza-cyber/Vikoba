import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/state/settings_store.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common.dart';

/// Edits the loan terms that drive the "Give Loan" form defaults: the monthly
/// interest rate and the default repayment duration.
class InterestRatesScreen extends StatefulWidget {
  const InterestRatesScreen({super.key});

  @override
  State<InterestRatesScreen> createState() => _InterestRatesScreenState();
}

class _InterestRatesScreenState extends State<InterestRatesScreen> {
  late final TextEditingController _rate;
  late final TextEditingController _duration;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsStore>();
    _rate = TextEditingController(text: _trim(s.loanInterestRate));
    _duration = TextEditingController(text: '${s.loanDurationMonths}');
  }

  String _trim(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  @override
  void dispose() {
    _rate.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _save(LocaleProvider locale) async {
    final messenger = ScaffoldMessenger.of(context);
    await context.read<SettingsStore>().setLoanTerms(
          rate: double.tryParse(_rate.text.trim()),
          duration: int.tryParse(_duration.text.trim()),
        );
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.primary,
        content: Text(locale.t('settings_saved'))));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(locale.t('interest_rates')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          LabeledField(
            label: locale.t('loan_interest_rate'),
            child: TextField(
                controller: _rate, keyboardType: TextInputType.number),
          ),
          LabeledField(
            label: locale.t('duration_months'),
            child: TextField(
                controller: _duration, keyboardType: TextInputType.number),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _save(locale),
            icon: const Icon(Icons.save_outlined),
            label: Text(locale.t('save')),
          ),
        ],
      ),
    );
  }
}
