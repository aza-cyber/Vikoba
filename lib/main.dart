import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config.dart';
import 'core/server_config.dart';
import 'core/data/api_repository.dart';
import 'core/data/repository.dart';
import 'core/data/repository_base.dart';
import 'core/db/app_database.dart';
import 'core/l10n/locale_provider.dart';
import 'core/models/models.dart';
import 'core/state/app_state.dart';
import 'core/state/groups_store.dart';
import 'core/services/push_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';

/// One-time migration of the old device-global settings (the retired
/// `SettingsStore`, key `group_settings_v1` in SharedPreferences) into the
/// group's rulebook. Offline only: online, the backend group row is the
/// authoritative source, so pushing a device-wide blob could clobber a group's
/// real rules. Best-effort and idempotent — the old key is removed once folded
/// in, so it never runs twice, and any failure just leaves the defaults.
Future<void> _migrateLegacySettings(AppState appState) async {
  if (Config.useApi) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    const key = 'group_settings_v1';
    final raw = prefs.getString(key);
    if (raw == null) return;
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final ft = j['fineTypes'] as List?;
    final merged = appState.rules.copyWith(
      interestRatePct: (j['loanInterestRate'] as num?)?.toDouble(),
      loanDurationMonths: (j['loanDurationMonths'] as num?)?.toInt(),
      meetingFrequency: j['meetingFrequency'] as String?,
      meetingStartTime: j['meetingStartTime'] as String?,
      meetingLocation: j['meetingLocation'] as String?,
      quorumPercent: (j['quorumPercent'] as num?)?.toInt(),
      fineTypes: ft
          ?.map((e) => FineType.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
    await appState.updateRules(merged);
    await prefs.remove(key);
  } catch (_) {
    // Best-effort: a failed migration just leaves the group's current rules.
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  // Pick the storage backend: offline SQLite (default) or the online API. In
  // online mode the address is read from on-device storage (editable on the
  // login screen) so switching Wi-Fi doesn't require a rebuild.
  final Repository repository = Config.useApi
      ? ApiRepository(await ServerConfig.load())
      : DriftRepository(AppDatabase());
  final appState = await AppState.open(repository);
  // One-time: fold any pre-existing device-global settings into this group's
  // rulebook (offline only — see the helper). Harmless no-op once migrated.
  await _migrateLegacySettings(appState);
  final groups = await GroupsStore.load(
      seedName: appState.groupName, seedTerm: appState.term);
  runApp(VicobaApp(appState: appState, groups: groups));

  // Best-effort: initialise push notifications AFTER the first frame, never
  // before. Firebase's getToken()/requestPermission() can block indefinitely on
  // a device with no google-services.json, so awaiting this ahead of runApp
  // would leave the app on a blank screen. Fire-and-forget keeps startup
  // instant; push simply stays off until Firebase is configured. Only
  // meaningful in online mode, where the backend can actually send them.
  if (Config.useApi) {
    unawaited(PushService.instance.init());
  }
}

class VicobaApp extends StatelessWidget {
  final AppState appState;
  final GroupsStore groups;
  const VicobaApp({
    super.key,
    required this.appState,
    required this.groups,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: groups),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, locale, _) {
          return MaterialApp(
            title: 'VICOBA',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            locale: locale.locale,
            supportedLocales: LocaleProvider.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Material/Cupertino widgets fall back to English; our own UI text
            // is fully translated through LocaleProvider.t().
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
