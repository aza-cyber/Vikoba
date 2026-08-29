import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';

/// The member self-service loan application. The borrower is the logged-in
/// member (fixed); the form collects amount, terms and two guarantors, then
/// files a pending 'request' for an officer to approve in the admin panel.
class RequestLoanScreen extends StatefulWidget {
  const RequestLoanScreen({super.key});

  @override
  State<RequestLoanScreen> createState() => _RequestLoanScreenState();
}

class _RequestLoanScreenState extends State<RequestLoanScreen> {
  Member? _guarantor1;
  Member? _guarantor2;
  DateTime _firstRepayment = DateTime.now().add(const Duration(days: 30));
  final _amount = TextEditingController(text: '300,000');
  final _duration = TextEditingController(text: '3');
  final _purpose = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    _duration.dispose();
    _purpose.dispose();
    super.dispose();
  }

  Future<void> _submit(LocaleProvider locale, Member me) async {
    final principal =
        double.tryParse(_amount.text.replaceAll(RegExp(r'[,\s]'), '')) ?? 0;
    if (principal <= 0) return;
    final guarantors = <String>[
      if (_guarantor1 != null) _guarantor1!.id,
      if (_guarantor2 != null && _guarantor2!.id != _guarantor1?.id)
        _guarantor2!.id,
    ];
    final guarantorNames = [
      if (_guarantor1 != null) _guarantor1!.name,
      if (_guarantor2 != null && _guarantor2!.id != _guarantor1?.id)
        _guarantor2!.name,
    ].join(', ');
    final app = context.read<AppState>();
    final duration =
        int.tryParse(_duration.text.trim()) ?? app.rules.loanDurationMonths;

    final ok = await showConfirmSummary(
      context,
      title: locale.t('confirm_details'),
      rows: [
        (locale.t('amount'), Fmt.tzs(principal)),
        (locale.t('duration_months'), '$duration'),
        (locale.t('guarantors'), guarantorNames.isEmpty ? '—' : guarantorNames),
        (locale.t('due'), Fmt.date(_firstRepayment)),
      ],
      confirmLabel: locale.t('confirm'),
      cancelLabel: locale.t('cancel'),
    );
    if (!ok || !mounted) return;

    setState(() => _submitting = true);
    final error = await app.requestLoan(
          memberId: me.id,
          principal: principal,
          interestRate: app.rules.interestRatePct,
          durationMonths: duration,
          dueDate: _firstRepayment,
          guarantorIds: guarantors,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFC0392B),
        content: Text(error),
      ));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.primary,
      content: Text(locale.t('loan_requested')),
    ));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final me = state.currentMember;
    // Guarantors are other members (a borrower can't guarantee their own loan).
    final others = state.members.where((m) => m.id != me?.id).toList();
    _guarantor1 ??= others.isNotEmpty ? others.first : null;
    _guarantor2 ??= others.length > 1 ? others[1] : _guarantor1;
    final maxLoan =
        (me?.shares ?? 0) * state.rules.shareValue * state.rules.loanMultiplier;

    return Scaffold(
      appBar: AppBar(title: Text(locale.t('request_loan'))),
      body: me == null
          ? Center(child: Text(locale.t('login_failed')))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      HighlightBanner(
                        label: locale.t('member'),
                        value: me.name,
                      ),
                      const SizedBox(height: 16),
                      LabeledField(
                        label: locale.t('loan_amount'),
                        child: TextField(
                            controller: _amount,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              ThousandsSeparatorInputFormatter()
                            ]),
                      ),
                      LabeledField(
                        label: locale.t('duration_months'),
                        child: TextField(
                            controller: _duration,
                            keyboardType: TextInputType.number),
                      ),
                      LabeledField(
                        label: locale.t('first_repayment_date'),
                        child: AppDateField(
                            value: _firstRepayment,
                            onChanged: (d) =>
                                setState(() => _firstRepayment = d)),
                      ),
                      LabeledField(
                        label: locale.t('loan_purpose'),
                        child: TextField(controller: _purpose, maxLines: 2),
                      ),
                      LabeledField(
                        label: locale.t('guarantor_1'),
                        child: AppDropdown<Member>(
                          value: _guarantor1,
                          items: others,
                          labelOf: (m) => m.name,
                          onChanged: (m) => setState(() => _guarantor1 = m),
                        ),
                      ),
                      LabeledField(
                        label: locale.t('guarantor_2'),
                        child: AppDropdown<Member>(
                          value: _guarantor2,
                          items: others,
                          labelOf: (m) => m.name,
                          onChanged: (m) => setState(() => _guarantor2 = m),
                        ),
                      ),
                      HighlightBanner(
                        label:
                            '${locale.t('max_loan')} (${locale.t('based_on_shares')})',
                        value: Fmt.tzs(maxLoan),
                        color: AppColors.shareOut,
                        background: AppColors.cardBlueBg,
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: ElevatedButton(
                      onPressed:
                          _submitting ? null : () => _submit(locale, me),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(locale.t('submit_request')),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
