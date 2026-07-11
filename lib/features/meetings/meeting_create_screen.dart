import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/state/app_state.dart';
import '../../core/state/settings_store.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common.dart';

/// Step 1 of the meeting workflow: an officer creates a meeting (draft) with its
/// title, date, time, location, period and the chair/secretary running it.
class MeetingCreateScreen extends StatefulWidget {
  const MeetingCreateScreen({super.key});

  @override
  State<MeetingCreateScreen> createState() => _MeetingCreateScreenState();
}

class _MeetingCreateScreenState extends State<MeetingCreateScreen> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _period = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  String? _chair;
  String? _secretary;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from the group's meeting defaults.
    final s = context.read<SettingsStore>();
    _location.text = s.meetingLocation;
    final parts = s.meetingStartTime.split(':');
    _time = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 10,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _period.dispose();
    super.dispose();
  }

  String get _timeText =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  Future<void> _save(LocaleProvider locale) async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    await context.read<AppState>().createMeeting(
          date: _date,
          title: _title.text.trim(),
          startTime: _timeText,
          location: _location.text.trim(),
          period: _period.text.trim(),
          chairperson: _chair ?? '',
          secretary: _secretary ?? '',
        );
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(SnackBar(
      backgroundColor: AppColors.primary,
      content: Text(locale.t('meeting_created')),
    ));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final names = context.watch<AppState>().members.map((m) => m.name).toList();
    _chair ??= names.isNotEmpty ? names.first : null;
    _secretary ??= names.length > 1 ? names[1] : _chair;

    return Scaffold(
      appBar: AppBar(title: Text(locale.t('new_meeting'))),
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
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                        hintText: locale.t('meeting_title_hint')),
                  ),
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
                        child: InkWell(
                          onTap: () async {
                            final t = await showTimePicker(
                                context: context, initialTime: _time);
                            if (t != null) setState(() => _time = t);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              suffixIcon: Icon(Icons.access_time,
                                  size: 18, color: AppColors.textMuted),
                            ),
                            child: Text(_timeText),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                LabeledField(
                  label: locale.t('location'),
                  child: TextField(
                    controller: _location,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                LabeledField(
                  label: locale.t('meeting_period'),
                  child: TextField(
                    controller: _period,
                    decoration:
                        const InputDecoration(hintText: 'e.g. July 2024'),
                  ),
                ),
                LabeledField(
                  label: locale.t('chairperson'),
                  child: AppDropdown<String>(
                    value: _chair,
                    items: names,
                    labelOf: (n) => n,
                    onChanged: (n) => setState(() => _chair = n),
                  ),
                ),
                LabeledField(
                  label: locale.t('secretary'),
                  child: AppDropdown<String>(
                    value: _secretary,
                    items: names,
                    labelOf: (n) => n,
                    onChanged: (n) => setState(() => _secretary = n),
                  ),
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
                    : Text(locale.t('create_meeting')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
