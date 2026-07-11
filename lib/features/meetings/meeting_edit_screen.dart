import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common.dart';

/// Edit a meeting's details (title, date, time, location, period, chair /
/// secretary) and record its decisions/collections/fines summary. Attendance is
/// managed on its own screen; status is controlled from the detail page.
class MeetingEditScreen extends StatefulWidget {
  final Meeting meeting;
  const MeetingEditScreen({super.key, required this.meeting});

  @override
  State<MeetingEditScreen> createState() => _MeetingEditScreenState();
}

class _MeetingEditScreenState extends State<MeetingEditScreen> {
  late DateTime _date;
  late final TextEditingController _title;
  late final TextEditingController _startTime;
  late final TextEditingController _location;
  late final TextEditingController _period;
  late final TextEditingController _decisions;
  late final TextEditingController _collections;
  late final TextEditingController _fines;
  String? _chair;
  String? _secretary;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.meeting;
    _date = m.date;
    _title = TextEditingController(text: m.title);
    _startTime = TextEditingController(text: m.startTime);
    _location = TextEditingController(text: m.location);
    _period = TextEditingController(text: m.period);
    _decisions = TextEditingController(text: '${m.decisions}');
    _collections = TextEditingController(text: _money(m.collections));
    _fines = TextEditingController(text: _money(m.fines));
    _chair = m.chairperson.isEmpty ? null : m.chairperson;
    _secretary = m.secretary.isEmpty ? null : m.secretary;
  }

  static String _money(double v) => v == 0 ? '0' : v.toStringAsFixed(0);

  @override
  void dispose() {
    _title.dispose();
    _startTime.dispose();
    _location.dispose();
    _period.dispose();
    _decisions.dispose();
    _collections.dispose();
    _fines.dispose();
    super.dispose();
  }

  int _int(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(RegExp(r'[,\s]'), '')) ?? 0;
  double _double(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(RegExp(r'[,\s]'), '')) ?? 0;

  Future<void> _save(LocaleProvider locale) async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    await context.read<AppState>().updateMeeting(
          id: widget.meeting.id,
          date: _date,
          title: _title.text.trim(),
          startTime: _startTime.text.trim(),
          location: _location.text.trim(),
          period: _period.text.trim(),
          chairperson: _chair ?? '',
          secretary: _secretary ?? '',
          decisions: _int(_decisions),
          collections: _double(_collections),
          fines: _double(_fines),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(SnackBar(
      backgroundColor: AppColors.primary,
      content: Text(locale.t('meeting_updated')),
    ));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final names = context.watch<AppState>().members.map((m) => m.name).toList();

    return Scaffold(
      appBar: AppBar(
          title: Text('${locale.t('edit_meeting')} ${widget.meeting.number}')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                LabeledField(
                  label: locale.t('meeting_title'),
                  child: TextField(
                      controller: _title,
                      textCapitalization: TextCapitalization.sentences),
                ),
                Row(
                  children: [
                    Expanded(
                      child: LabeledField(
                        label: locale.t('date'),
                        child: AppDateField(
                            value: _date,
                            onChanged: (d) => setState(() => _date = d)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: LabeledField(
                        label: locale.t('start_time'),
                        child: TextField(
                            controller: _startTime,
                            decoration:
                                const InputDecoration(hintText: '10:00')),
                      ),
                    ),
                  ],
                ),
                LabeledField(
                  label: locale.t('location'),
                  child: TextField(
                      controller: _location,
                      textCapitalization: TextCapitalization.sentences),
                ),
                LabeledField(
                  label: locale.t('meeting_period'),
                  child: TextField(controller: _period),
                ),
                if (names.isNotEmpty) ...[
                  LabeledField(
                    label: locale.t('chairperson'),
                    child: AppDropdown<String>(
                      value: names.contains(_chair) ? _chair : null,
                      items: names,
                      labelOf: (n) => n,
                      hint: locale.t('chairperson'),
                      onChanged: (n) => setState(() => _chair = n),
                    ),
                  ),
                  LabeledField(
                    label: locale.t('secretary'),
                    child: AppDropdown<String>(
                      value: names.contains(_secretary) ? _secretary : null,
                      items: names,
                      labelOf: (n) => n,
                      hint: locale.t('secretary'),
                      onChanged: (n) => setState(() => _secretary = n),
                    ),
                  ),
                ],
                const Divider(height: 28),
                Text(locale.t('cash_summary'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 12),
                LabeledField(
                  label: locale.t('decisions'),
                  child: TextField(
                      controller: _decisions,
                      keyboardType: TextInputType.number),
                ),
                LabeledField(
                  label: '${locale.t('collections')} (TZS)',
                  child: TextField(
                      controller: _collections,
                      keyboardType: TextInputType.number),
                ),
                LabeledField(
                  label: '${locale.t('fines_title')} (TZS)',
                  child: TextField(
                      controller: _fines,
                      keyboardType: TextInputType.number),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ElevatedButton(
                onPressed: _saving ? null : () => _save(locale),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(locale.t('save')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
