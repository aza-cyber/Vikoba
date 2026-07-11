import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';
import '../shell/shell_scope.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  Member? _member;
  DateTime _date = DateTime.now();
  int _typeIndex = 0;
  int _methodIndex = 0;
  final _amount = TextEditingController(text: '50,000');
  final _note = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final members = state.members;
    // Keep the selected member pointing at the latest snapshot (or the first).
    _member = pickMember(members, _member?.id);

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
      appBar: AppBar(
        leading: const ShellLeading(),
        title: Text(locale.t('savings_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
            label: locale.t('date'),
            child: AppDateField(
                value: _date, onChanged: (d) => setState(() => _date = d)),
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
            label: locale.t('amount'),
            child: TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
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
          LabeledField(
            label: locale.t('note_optional'),
            child: TextField(
              controller: _note,
              decoration: InputDecoration(
                hintText: '${locale.t('savings_regular')} ${Fmt.date(_date)}',
              ),
            ),
          ),
          const SizedBox(height: 8),
          HighlightBanner(
            label: '${locale.t('current_savings_of')} ${_member?.name ?? ''}',
            value: Fmt.tzs(_member?.savings ?? 0),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _onSave(context, locale),
            child: Text(locale.t('save_savings')),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave(BuildContext context, LocaleProvider locale) async {
    final member = _member;
    final amount =
        double.tryParse(_amount.text.replaceAll(RegExp(r'[,\s]'), '')) ?? 0;
    if (member == null || amount <= 0) return;

    const types = [SavingType.regular, SavingType.special, SavingType.social];
    final methods = [locale.t('cash'), locale.t('mobile_money'), locale.t('bank')];

    // Record the chosen calendar day but stamp the actual time of entry, so the
    // transaction history shows a real time instead of midnight for back-dated
    // (date-picked) savings.
    final now = DateTime.now();
    final when = DateTime(
        _date.year, _date.month, _date.day, now.hour, now.minute, now.second);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final error = await context.read<AppState>().addSaving(
          memberId: member.id,
          amount: amount,
          date: when,
          type: types[_typeIndex],
          method: methods[_methodIndex],
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
      content: Text('${locale.t('save_savings')}: ${member.name} — '
          '${Fmt.tzs(amount)}'),
    ));
    navigator.maybePop();
  }
}
