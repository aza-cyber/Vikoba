import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/config.dart';
import 'core/server_config.dart';
import 'core/data/api_repository.dart';
import 'core/data/repository.dart';
import 'core/data/repository_base.dart';
import 'core/db/app_database.dart';
import 'core/l10n/locale_provider.dart';
import 'core/state/app_state.dart';
import 'core/state/groups_store.dart';
import 'core/state/settings_store.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';

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
  final settings = await SettingsStore.load();
  final groups = await GroupsStore.load(
      seedName: appState.groupName, seedTerm: appState.term);
  runApp(VicobaApp(appState: appState, settings: settings, groups: groups));
}

class VicobaApp extends StatelessWidget {
  final AppState appState;
  final SettingsStore settings;
  final GroupsStore groups;
  const VicobaApp({
    super.key,
    required this.appState,
    required this.settings,
    required this.groups,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: settings),
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
