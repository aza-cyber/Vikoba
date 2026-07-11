import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One configurable fine (its name and default amount in TZS).
class FineTypeSetting {
  final String name;
  final double amount;
  const FineTypeSetting(this.name, this.amount);

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};

  factory FineTypeSetting.fromJson(Map<String, dynamic> j) => FineTypeSetting(
        j['name'] as String? ?? '',
        (j['amount'] as num?)?.toDouble() ?? 0,
      );
}

enum MeetingFrequency { weekly, biweekly, monthly }

/// Group configuration the officers can edit (interest rate, fine types,
/// meeting defaults, quorum). Persisted on-device via [SharedPreferences] so it
/// survives restarts and works fully offline. These values drive defaults in the
/// loan, fines and meeting-creation screens.
class SettingsStore extends ChangeNotifier {
  static const _key = 'group_settings_v1';
  SharedPreferences? _prefs;

  double loanInterestRate; // % per month
  int loanDurationMonths;
  List<FineTypeSetting> fineTypes;
  MeetingFrequency meetingFrequency;
  String meetingStartTime; // 'HH:mm'
  String meetingLocation;
  int quorumPercent;

  SettingsStore._({
    required this.loanInterestRate,
    required this.loanDurationMonths,
    required this.fineTypes,
    required this.meetingFrequency,
    required this.meetingStartTime,
    required this.meetingLocation,
    required this.quorumPercent,
  });

  factory SettingsStore._defaults() => SettingsStore._(
        loanInterestRate: 10,
        loanDurationMonths: 3,
        fineTypes: const [
          FineTypeSetting('Kutohudhuria mkutano', 5000),
          FineTypeSetting('Kuchelewa malipo', 2000),
          FineTypeSetting('Nyingine', 1000),
        ],
        meetingFrequency: MeetingFrequency.weekly,
        meetingStartTime: '10:00',
        meetingLocation: '',
        quorumPercent: 50,
      );

  /// Loads persisted settings (falling back to sensible defaults). Never throws.
  static Future<SettingsStore> load() async {
    final store = SettingsStore._defaults();
    try {
      final prefs = await SharedPreferences.getInstance();
      store._prefs = prefs;
      final raw = prefs.getString(_key);
      if (raw != null) {
        store._applyJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {
      // Corrupt/unavailable prefs → keep defaults.
    }
    return store;
  }

  void _applyJson(Map<String, dynamic> j) {
    loanInterestRate =
        (j['loanInterestRate'] as num?)?.toDouble() ?? loanInterestRate;
    loanDurationMonths =
        (j['loanDurationMonths'] as num?)?.toInt() ?? loanDurationMonths;
    final ft = j['fineTypes'] as List?;
    if (ft != null) {
      fineTypes = ft
          .map((e) =>
              FineTypeSetting.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }
    meetingFrequency = MeetingFrequency.values.firstWhere(
        (f) => f.name == j['meetingFrequency'],
        orElse: () => meetingFrequency);
    meetingStartTime = j['meetingStartTime'] as String? ?? meetingStartTime;
    meetingLocation = j['meetingLocation'] as String? ?? meetingLocation;
    quorumPercent = (j['quorumPercent'] as num?)?.toInt() ?? quorumPercent;
  }

  Map<String, dynamic> _toJson() => {
        'loanInterestRate': loanInterestRate,
        'loanDurationMonths': loanDurationMonths,
        'fineTypes': [for (final f in fineTypes) f.toJson()],
        'meetingFrequency': meetingFrequency.name,
        'meetingStartTime': meetingStartTime,
        'meetingLocation': meetingLocation,
        'quorumPercent': quorumPercent,
      };

  Future<void> _persist() async {
    await _prefs?.setString(_key, jsonEncode(_toJson()));
    notifyListeners();
  }

  Future<void> setLoanTerms({double? rate, int? duration}) async {
    if (rate != null) loanInterestRate = rate;
    if (duration != null) loanDurationMonths = duration;
    await _persist();
  }

  Future<void> setFineTypes(List<FineTypeSetting> types) async {
    fineTypes = types;
    await _persist();
  }

  Future<void> setMeetingDefaults({
    MeetingFrequency? frequency,
    String? startTime,
    String? location,
    int? quorum,
  }) async {
    if (frequency != null) meetingFrequency = frequency;
    if (startTime != null) meetingStartTime = startTime;
    if (location != null) meetingLocation = location;
    if (quorum != null) quorumPercent = quorum;
    await _persist();
  }
}
