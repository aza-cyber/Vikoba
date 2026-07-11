import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';

class RepaymentScreen extends StatefulWidget {
  /// When set, the loan is preselected (e.g. opened from a loan's detail page).
  final String? initialLoanId;
  const RepaymentScreen({super.key, this.initialLoanId});

  @override
  State<RepaymentScreen> createState() => _RepaymentScreenState();
}

class _RepaymentScreenState extends State<RepaymentScreen> {
  String? _loanId;
  DateTime _date = DateTime.now();
  int _methodIndex = 0;
  final _amount = TextEditingController(text: '200,000');

  @override
  void initState() {
    super.initState();
    _loanId = widget.initialLoanId;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double _remainingFor(Loan? loan) {
    if (loan == null) return 0;
    final paid = double.tryParse(_amount.text.replaceAll(RegExp(r'[,\s]'), '')) ?? 0;
    final r = loan.balance - paid;
    return r < 0 ? 0 : r;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final ongoing = state.ongoingLoans;
    final methods = [
      locale.t('cash'),
      locale.t('mobile_money'),
      locale.t('bank'),
    ];

    // Keep the selected loan valid against the current list.
    Loan? loan;
    for (final l in ongoing) {
      if (l.id == _loanId) loan = l;
    }
    loan ??= ongoing.isNotEmpty ? ongoing.first : null;
    _loanId = loan?.id;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(locale.t('repayment_title')),
      ),
      body: ongoing.isEmpty
          ? Center(
              child: Text(locale.t('tab_ongoing'),
                  style: const TextStyle(color: AppColors.textMuted)))
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          LabeledField(
            label: locale.t('member'),
            child: AppDropdown<Loan>(
              value: loan,
              items: ongoing,
              labelOf: (l) => l.memberName,
              onChanged: (l) => setState(() => _loanId = l!.id),
            ),
          ),
          LabeledField(
            label: locale.t('loan'),
            child: AppDropdown<Loan>(
              value: loan,
              items: ongoing,
              labelOf: (l) =>
                  '${Fmt.tzs(l.principal)} - ${Fmt.date(l.dueDate)}',
              onChanged: (l) => setState(() => _loanId = l!.id),
            ),
          ),
          LabeledField(
            label: locale.t('amount_due'),
            child: TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              onChanged: (_) => setState(() {}),
            ),
          ),
          LabeledField(
            label: locale.t('date'),
            child: AppDateField(
                value: _date, onChanged: (d) => setState(() => _date = d)),
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
          HighlightBanner(
            label: locale.t('remaining_balance'),
            value: Fmt.tzs(_remainingFor(loan)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _onSave(context, locale, loan, methods[_methodIndex]),
            child: Text(locale.t('save_repayment')),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave(BuildContext context, LocaleProvider locale, Loan? loan,
      String method) async {
    final amount =
        double.tryParse(_amount.text.replaceAll(RegExp(r'[,\s]'), '')) ?? 0;
    if (loan == null || amount <= 0) return;

    // Keep the chosen day but stamp the actual time of entry, so the
    // transaction history shows a real time instead of midnight.
    final now = DateTime.now();
    final when = DateTime(
        _date.year, _date.month, _date.day, now.hour, now.minute, now.second);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final error = await context.read<AppState>().repayLoan(
          loanId: loan.id,
          amount: amount,
          date: when,
          method: method,
        );
    if (!mounted) return;
    if (error != null) {
      messenger.showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFC0392B),
        content: Text(error),
      ));
      return;
    }
    messenger.showSnackBar(SnackBar(
      backgroundColor: AppColors.primary,
      content: Text('${locale.t('save_repayment')}: ${loan.memberName} — '
          '${Fmt.tzs(amount)}'),
    ));
    navigator.maybePop();
  }
}
