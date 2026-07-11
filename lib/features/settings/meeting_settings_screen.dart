import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/state/settings_store.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common.dart';

/// Edits meeting defaults: how often the group meets, the default start time and
/// location (pre-filled when creating a meeting) and the quorum threshold.
class MeetingSettingsScreen extends StatefulWidget {
  const MeetingSettingsScreen({super.key});

  @override
  State<MeetingSettingsScreen> createState() => _MeetingSettingsScreenState();
}

class _MeetingSettingsScreenState extends State<MeetingSettingsScreen> {
  late MeetingFrequency _freq;
  late TimeOfDay _time;
  late final TextEditingController _location;
  late final TextEditingController _quorum;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsStore>();
    _freq = s.meetingFrequency;
    _time = _parseTime(s.meetingStartTime);
    _location = TextEditingController(text: s.meetingLocation);
    _quorum = TextEditingController(text: '${s.quorumPercent}');
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 10,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );
  }

  String get _timeText =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _location.dispose();
    _quorum.dispose();
    super.dispose();
  }

  String _freqLabel(MeetingFrequency f, LocaleProvider l) => switch (f) {
        MeetingFrequency.weekly => l.t('freq_weekly'),
        MeetingFrequency.biweekly => l.t('freq_biweekly'),
        MeetingFrequency.monthly => l.t('freq_monthly'),
      };

  Future<void> _save(LocaleProvider locale) async {
    final messenger = ScaffoldMessenger.of(context);
    final quorum = int.tryParse(_quorum.text.trim())?.clamp(0, 100);
    await context.read<SettingsStore>().setMeetingDefaults(
          frequency: _freq,
          startTime: _timeText,
          location: _location.text.trim(),
          quorum: quorum,
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
        title: Text(locale.t('meeting_settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          LabeledField(
            label: locale.t('meeting_frequency'),
            child: AppDropdown<MeetingFrequency>(
              value: _freq,
              items: MeetingFrequency.values,
              labelOf: (f) => _freqLabel(f, locale),
              onChanged: (f) => setState(() => _freq = f ?? _freq),
            ),
          ),
          LabeledField(
            label: locale.t('default_time'),
            child: InkWell(
              onTap: () async {
                final picked =
                    await showTimePicker(context: context, initialTime: _time);
                if (picked != null) setState(() => _time = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.schedule,
                      size: 18, color: AppColors.textMuted),
                ),
                child: Text(_timeText),
              ),
            ),
          ),
          LabeledField(
            label: locale.t('default_location'),
            child: TextField(
              controller: _location,
              textCapitalization: TextCapitalization.words,
              decoration:
                  InputDecoration(hintText: locale.t('default_location')),
            ),
          ),
          LabeledField(
            label: locale.t('quorum_percent'),
            child: TextField(
                controller: _quorum, keyboardType: TextInputType.number),
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
