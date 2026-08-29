import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';

class CreateLoanScreen extends StatefulWidget {
  const CreateLoanScreen({super.key});

  @override
  State<CreateLoanScreen> createState() => _CreateLoanScreenState();
}

class _CreateLoanScreenState extends State<CreateLoanScreen> {
  int _step = 0;
  Member? _member;
  Member? _guarantor1;
  Member? _guarantor2;
  DateTime _firstRepayment = DateTime.now().add(const Duration(days: 30));
  final _amount = TextEditingController(text: '300,000');
  final _interest = TextEditingController(text: '10');
  final _duration = TextEditingController(text: '3');
  final _purpose = TextEditingController(text: '');

  /// VICOBA loan limit: a member may borrow up to loanMultiplier× the value of
  /// the shares they hold, using this group's own configured rules.
  double get _maxLoan {
    final r = context.read<AppState>().rules;
    return (_member?.shares ?? 0) * r.shareValue * r.loanMultiplier;
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill the loan terms from this group's configured rules.
    final r = context.read<AppState>().rules;
    _interest.text = r.interestRatePct == r.interestRatePct.roundToDouble()
        ? '${r.interestRatePct.toInt()}'
        : '${r.interestRatePct}';
    _duration.text = '${r.loanDurationMonths}';
  }

  @override
  void dispose() {
    _amount.dispose();
    _interest.dispose();
    _duration.dispose();
    _purpose.dispose();
    super.dispose();
  }

  Future<void> _next(LocaleProvider locale) async {
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    final member = _member;
    final principal =
        double.tryParse(_amount.text.replaceAll(RegExp(r'[,\s]'), '')) ?? 0;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (member == null || principal <= 0) {
      messenger.showSnackBar(const SnackBar(
        backgroundColor: Color(0xFFC0392B),
        content: Text('Select a member and enter a valid amount.'),
      ));
      return;
    }
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
    final interestRate = double.tryParse(_interest.text.trim()) ?? 10;
    final duration = int.tryParse(_duration.text.trim()) ?? 3;
    final rateText = interestRate == interestRate.roundToDouble()
        ? '${interestRate.toInt()}%'
        : '$interestRate%';
    final appState = context.read<AppState>();

    final ok = await showConfirmSummary(
      context,
      title: locale.t('confirm_details'),
      rows: [
        (locale.t('member'), member.name),
        (locale.t('amount'), Fmt.tzs(principal)),
        (locale.t('interest_rate'), rateText),
        (locale.t('duration_months'), '$duration'),
        (locale.t('guarantors'), guarantorNames.isEmpty ? '—' : guarantorNames),
        (locale.t('due'), Fmt.date(_firstRepayment)),
        if (_purpose.text.trim().isNotEmpty)
          (locale.t('loan_purpose'), _purpose.text.trim()),
      ],
      confirmLabel: locale.t('confirm'),
      cancelLabel: locale.t('cancel'),
    );
    if (!ok || !mounted) return;

    // The server enforces the loan rules (limit, guarantors, available cash);
    // surface its verdict instead of assuming success.
    final error = await appState.giveLoan(
          memberId: member.id,
          principal: principal,
          interestRate: interestRate,
          durationMonths: duration,
          dueDate: _firstRepayment,
          guarantorIds: guarantors,
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
      content: Text('${locale.t('loan_disbursed')}: ${member.name}'),
    ));
    navigator.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final members = context.watch<AppState>().members;
    _member = pickMember(members, _member?.id);
    _guarantor1 ??= members.isNotEmpty ? members.first : null;
    _guarantor2 ??=
        members.length > 1 ? members[1] : (members.isNotEmpty ? members.first : null);
    final steps = [
      locale.t('loan_request'),
      locale.t('loan_approval'),
      locale.t('loan_disbursement'),
      locale.t('loan_disbursed'),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Text(locale.t('create_loan')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _StepIndicator(steps: steps, current: _step),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                LabeledField(
                  label: locale.t('member'),
                  child: AppDropdown<Member>(
                    value: _member,
                    items: members,
                    labelOf: (m) => m.name,
                    onChanged: (m) => setState(() => _member = m),
                  ),
                ),
                LabeledField(
                  label: locale.t('loan_amount'),
                  child: TextField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsSeparatorInputFormatter()]),
                ),
                Row(
                  children: [
                    Expanded(
                      child: LabeledField(
                        label: locale.t('interest_rate'),
                        child: TextField(
                            controller: _interest,
                            keyboardType: TextInputType.number),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: LabeledField(
                        label: locale.t('duration_months'),
                        child: TextField(
                            controller: _duration,
                            keyboardType: TextInputType.number),
                      ),
                    ),
                  ],
                ),
                LabeledField(
                  label: locale.t('first_repayment_date'),
                  child: AppDateField(
                      value: _firstRepayment,
                      onChanged: (d) => setState(() => _firstRepayment = d)),
                ),
                LabeledField(
                  label: locale.t('loan_purpose'),
                  child: TextField(controller: _purpose, maxLines: 2),
                ),
                Text(
                  locale.t('guarantors'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                LabeledField(
                  label: locale.t('guarantor_1'),
                  child: AppDropdown<Member>(
                    value: _guarantor1,
                    items: members,
                    labelOf: (m) => m.name,
                    onChanged: (m) => setState(() => _guarantor1 = m),
                  ),
                ),
                LabeledField(
                  label: locale.t('guarantor_2'),
                  child: AppDropdown<Member>(
                    value: _guarantor2,
                    items: members,
                    labelOf: (m) => m.name,
                    onChanged: (m) => setState(() => _guarantor2 = m),
                  ),
                ),
                const SizedBox(height: 4),
                HighlightBanner(
                  label:
                      '${locale.t('max_loan')} (${locale.t('based_on_shares')})',
                  value: Fmt.tzs(_maxLoan),
                  color: AppColors.shareOut,
                  background: AppColors.cardBlueBg,
                ),
                const SizedBox(height: 12),
                HighlightBanner(
                  label: locale.t('amount'),
                  value: 'TZS ${_amount.text}',
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ElevatedButton(
                onPressed: () => _next(locale),
                child: Text(_step < 3
                    ? locale.t('continue_label')
                    : locale.t('loan_disbursed')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final List<String> steps;
  final int current;

  const _StepIndicator({required this.steps, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i <= current
                      ? AppColors.primary
                      : AppColors.cardGreenBg,
                  shape: BoxShape.circle,
                ),
                child: i < current
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text('${i + 1}',
                        style: TextStyle(
                          color:
                              i <= current ? Colors.white : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        )),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 70,
                child: Text(
                  steps[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: i <= current
                        ? AppColors.primary
                        : AppColors.textMuted,
                    fontWeight:
                        i == current ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (i < steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: i < current ? AppColors.primary : AppColors.border,
              ),
            ),
        ],
      ],
    );
  }
}
