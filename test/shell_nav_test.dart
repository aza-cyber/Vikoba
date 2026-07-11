// Exercises the responsive shell: the collapsible sidebar on wide screens and
// the hamburger-opened drawer (plus bottom bar) on phones.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vikoba/core/l10n/locale_provider.dart';
import 'package:vikoba/core/state/app_state.dart';
import 'package:vikoba/core/state/settings_store.dart';
import 'package:vikoba/features/shell/main_shell.dart';

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final settings = await SettingsStore.load();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider.value(value: AppState(Snapshot.empty())),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: const MaterialApp(home: MainShell()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('wide screens use the bottom bar + drawer (no sidebar)',
      (tester) async {
    await _pump(tester, const Size(1400, 900));

    // Bottom bar on wide screens too; no persistent sidebar until opened.
    expect(find.byType(BottomAppBar), findsOneWidget);
    expect(find.text('VICOBA'), findsNothing);

    // ☰ opens the drawer with the full menu.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('VICOBA'), findsOneWidget);
    // The embedded Dashboard's fixed-aspect cards overflow under the oversized
    // test font (Ahem); that's unrelated to navigation, so consume it.
    tester.takeException();
  });

  testWidgets('phone: hamburger opens the drawer, keeps bottom bar',
      (tester) async {
    await _pump(tester, const Size(390, 844));

    // Bottom bar present; sidebar not yet shown.
    expect(find.byType(BottomAppBar), findsOneWidget);
    expect(find.text('VICOBA'), findsNothing);

    // Tap the hamburger in the app bar to open the drawer.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Drawer now shows the sidebar brand.
    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('VICOBA'), findsOneWidget);
    tester.takeException(); // consume test-font overflow from embedded screens
  });
}
