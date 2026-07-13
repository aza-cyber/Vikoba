import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common.dart';

/// Edits this group's loan terms (monthly interest rate + default repayment
/// duration). Saved to the group's rulebook, so each group can set its own.
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
    final r = context.read<AppState>().rules;
    _rate = TextEditingController(text: _trim(r.interestRatePct));
    _duration = TextEditingController(text: '${r.loanDurationMonths}');
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
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final error = await app.updateRules(app.rules.copyWith(
      interestRatePct: double.tryParse(_rate.text.trim()) ?? app.rules.interestRatePct,
      loanDurationMonths:
          int.tryParse(_duration.text.trim()) ?? app.rules.loanDurationMonths,
    ));
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
        backgroundColor: error == null ? AppColors.primary : AppColors.fines,
        content: Text(error ?? locale.t('settings_saved'))));
    if (error == null) Navigator.of(context).maybePop();
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
