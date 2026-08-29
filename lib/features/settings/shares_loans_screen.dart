import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common.dart';

/// Edits this group's money & loan rules — the share price, social-fund
/// contribution, and the loan limits (multiplier, guarantors, repayment cap,
/// share bounds). Saved to the group's rulebook so each group runs its own.
class SharesLoansScreen extends StatefulWidget {
  const SharesLoansScreen({super.key});

  @override
  State<SharesLoansScreen> createState() => _SharesLoansScreenState();
}

class _SharesLoansScreenState extends State<SharesLoansScreen> {
  late final TextEditingController _shareValue;
  late final TextEditingController _socialFund;
  late final TextEditingController _multiplier;
  late final TextEditingController _guarantors;
  late final TextEditingController _maxRepayment;
  late final TextEditingController _minShares;
  late final TextEditingController _maxShares;

  @override
  void initState() {
    super.initState();
    final r = context.read<AppState>().rules;
    _shareValue = TextEditingController(text: _num(r.shareValue));
    _socialFund = TextEditingController(text: _num(r.socialFundPerMtg));
    _multiplier = TextEditingController(text: '${r.loanMultiplier}');
    _guarantors = TextEditingController(text: '${r.requiredGuarantors}');
    _maxRepayment = TextEditingController(text: '${r.maxRepaymentMonths}');
    _minShares = TextEditingController(text: '${r.minShares}');
    _maxShares = TextEditingController(text: '${r.maxShares}');
  }

  String _num(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  @override
  void dispose() {
    _shareValue.dispose();
    _socialFund.dispose();
    _multiplier.dispose();
    _guarantors.dispose();
    _maxRepayment.dispose();
    _minShares.dispose();
    _maxShares.dispose();
    super.dispose();
  }

  double _d(TextEditingController c, double fallback) =>
      double.tryParse(c.text.replaceAll(RegExp(r'[,\s]'), '')) ?? fallback;
  int _i(TextEditingController c, int fallback) =>
      int.tryParse(c.text.trim()) ?? fallback;

  Future<void> _save(LocaleProvider locale) async {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final r = app.rules;
    final error = await app.updateRules(r.copyWith(
      shareValue: _d(_shareValue, r.shareValue),
      socialFundPerMtg: _d(_socialFund, r.socialFundPerMtg),
      loanMultiplier: _i(_multiplier, r.loanMultiplier),
      requiredGuarantors: _i(_guarantors, r.requiredGuarantors),
      maxRepaymentMonths: _i(_maxRepayment, r.maxRepaymentMonths),
      minShares: _i(_minShares, r.minShares),
      maxShares: _i(_maxShares, r.maxShares),
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
    Widget field(String label, TextEditingController c) => LabeledField(
          label: label,
          child: TextField(
              controller: c, keyboardType: TextInputType.number),
        );

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(locale.t('shares_loans_settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          field(locale.t('share_value'), _shareValue),
          field(locale.t('social_fund'), _socialFund),
          field(locale.t('loan_multiplier'), _multiplier),
          field(locale.t('guarantors'), _guarantors),
          field(locale.t('max_repayment_months'), _maxRepayment),
          field(locale.t('min_shares'), _minShares),
          field(locale.t('max_shares'), _maxShares),
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
