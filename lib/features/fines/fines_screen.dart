import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';
import '../shell/shell_scope.dart';

class FinesScreen extends StatefulWidget {
  const FinesScreen({super.key});

  @override
  State<FinesScreen> createState() => _FinesScreenState();
}

class _FinesScreenState extends State<FinesScreen> {
  Member? _member;
  DateTime _date = DateTime.now();
  int _typeIndex = 0;
  int _methodIndex = 0;
  bool _paidNow = false;
  final _amount = TextEditingController(text: '5,000');

  @override
  void initState() {
    super.initState();
    final types = context.read<AppState>().rules.fineTypes;
    if (types.isNotEmpty) _amount.text = Fmt.number(types.first.amount);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final members = state.members;
    _member = pickMember(members, _member?.id);

    final fineTypes = state.rules.fineTypes.isNotEmpty
        ? state.rules.fineTypes
        : [FineType(locale.t('fine_other'), 0)];
    if (_typeIndex >= fineTypes.length) _typeIndex = 0;
    final methods = [
      locale.t('cash'),
      locale.t('mobile_money'),
      locale.t('bank'),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const ShellLeading(),
        title: Text(locale.t('fines_title')),
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
            label: locale.t('fine_type'),
            child: AppDropdown<int>(
              value: _typeIndex,
              items: List.generate(fineTypes.length, (i) => i),
              labelOf: (i) => fineTypes[i].name,
              onChanged: (i) => setState(() {
                _typeIndex = i ?? 0;
                _amount.text = Fmt.number(fineTypes[_typeIndex].amount);
              }),
            ),
          ),
          LabeledField(
            label: locale.t('amount'),
            child: TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()]),
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
          const SizedBox(height: 4),
          SwitchListTile.adaptive(
            value: _paidNow,
            onChanged: (v) => setState(() => _paidNow = v),
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primary,
            title: Text(locale.t('paid_now')),
            subtitle: Text(locale.t('paid_now_hint'),
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
          ),
          const SizedBox(height: 8),
          HighlightBanner(
            label: '${locale.t('total_fines_of')} ${_member?.name ?? ''}',
            value: Fmt.tzs(_member?.fines ?? 0),
            color: AppColors.fines,
            background: AppColors.cardRedBg,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _onSave(context, locale, fineTypes),
            child: Text(locale.t('save_fine')),
          ),
          const SizedBox(height: 28),
          const Divider(height: 1),
          const SizedBox(height: 16),
          SectionHeader(title: locale.t('members_with_penalties')),
          const SizedBox(height: 12),
          _MembersWithPenalties(state: state, locale: locale),
        ],
      ),
    );
  }

  Future<void> _onSave(BuildContext context, LocaleProvider locale,
      List<FineType> fineTypes) async {
    final member = _member;
    final amount =
        double.tryParse(_amount.text.replaceAll(RegExp(r'[,\s]'), '')) ?? 0;
    if (member == null || amount <= 0) return;

    // Capture context-derived objects before the confirm dialog's async gap.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final appState = context.read<AppState>();

    final ok = await showConfirmSummary(
      context,
      title: locale.t('confirm_details'),
      rows: [
        (locale.t('member'), member.name),
        (locale.t('fine_name'), fineTypes[_typeIndex].name),
        (locale.t('amount'), Fmt.tzs(amount)),
        (locale.t('date'), Fmt.date(_date)),
        (locale.t('paid_now'), _paidNow ? locale.t('yes') : locale.t('no')),
      ],
      confirmLabel: locale.t('confirm'),
      cancelLabel: locale.t('cancel'),
    );
    if (!ok || !mounted) return;

    // Keep the chosen day but stamp the actual time of entry, so the
    // transaction history shows a real time instead of midnight.
    final now = DateTime.now();
    final when = DateTime(
        _date.year, _date.month, _date.day, now.hour, now.minute, now.second);

    final error = await appState.addFine(
          memberId: member.id,
          reason: fineTypes[_typeIndex].name,
          amount: amount,
          date: when,
          paid: _paidNow,
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
      backgroundColor: AppColors.fines,
      content: Text(
          '${locale.t('save_fine')}: ${member.name} — ${Fmt.tzs(amount)}'),
    ));
    navigator.maybePop();
  }
}

/// Lists each member who currently owes penalties, with their total outstanding
/// amount. Tapping a member expands to their individual penalties, each with a
/// button to clear it once paid.
class _MembersWithPenalties extends StatelessWidget {
  final AppState state;
  final LocaleProvider locale;
  const _MembersWithPenalties({required this.state, required this.locale});

  @override
  Widget build(BuildContext context) {
    final fines = state.outstandingFines;
    if (fines.isEmpty) {
      return AppCard(
        child: EmptyState(
          icon: Icons.check_circle_outline_rounded,
          title: locale.t('no_outstanding'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        ),
      );
    }

    // Group the outstanding penalties by member, ordered by who owes the most.
    final byMember = <String, List<Fine>>{};
    for (final f in fines) {
      byMember.putIfAbsent(f.memberName, () => []).add(f);
    }
    final members = byMember.entries.toList()
      ..sort((a, b) {
        double total(List<Fine> l) => l.fold(0.0, (s, f) => s + f.amount);
        return total(b.value).compareTo(total(a.value));
      });

    return Column(
      children: [
        for (final entry in members) ...[
          _MemberPenaltyTile(
            name: entry.key,
            fines: entry.value,
            locale: locale,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MemberPenaltyTile extends StatelessWidget {
  final String name;
  final List<Fine> fines;
  final LocaleProvider locale;
  const _MemberPenaltyTile(
      {required this.name, required this.fines, required this.locale});

  @override
  Widget build(BuildContext context) {
    final total = fines.fold(0.0, (s, f) => s + f.amount);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Hide the default ExpansionTile dividers for a cleaner card.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          leading: MemberAvatar(initials: initialsOf(name), color: AppColors.fines),
          title: Text(name,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          subtitle: Text(
            '${fines.length} ${locale.t('penalties_count')}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Fmt.tzs(total),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.fines,
                      fontSize: 13.5)),
              const Icon(Icons.expand_more,
                  size: 18, color: AppColors.textMuted),
            ],
          ),
          children: [
            const Divider(height: 1),
            for (final f in fines) _FineRow(fine: f, locale: locale),
          ],
        ),
      ),
    );
  }
}

class _FineRow extends StatelessWidget {
  final Fine fine;
  final LocaleProvider locale;
  const _FineRow({required this.fine, required this.locale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fine.reason,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(Fmt.date(fine.date),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Text(Fmt.tzs(fine.amount),
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.fines,
                  fontSize: 13.5)),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 0),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final error = await context.read<AppState>().payFine(fine.id);
              messenger.showSnackBar(SnackBar(
                backgroundColor:
                    error != null ? const Color(0xFFC0392B) : AppColors.primary,
                content: Text(error ??
                    '${locale.t('penalty_cleared')}: ${fine.memberName}'),
              ));
            },
            child: Text(locale.t('mark_paid')),
          ),
        ],
      ),
    );
  }
}
