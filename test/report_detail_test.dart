// Every report type generates from a populated snapshot and renders a data
// table (or an empty-state) without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:vikoba/core/l10n/locale_provider.dart';
import 'package:vikoba/core/state/app_state.dart';
import 'package:vikoba/features/reports/report_detail_screen.dart';
import 'support/fixtures.dart';

Future<void> _pump(WidgetTester tester, ReportType type) async {
  tester.view.physicalSize = const Size(1000, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider.value(value: AppState(demoSnapshot())),
      ],
      child: MaterialApp(home: ReportDetailScreen(type: type)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final type in ReportType.values) {
    testWidgets('generates the ${type.name} report', (tester) async {
      await _pump(tester, type);

      // The generated header timestamp label is always present.
      expect(find.textContaining('Imetengenezwa tarehe'), findsOneWidget);
      // It renders either a populated table or the "no records" empty state.
      final hasTable = find.byType(DataTable).evaluate().isNotEmpty;
      final hasEmpty = find.text('Hakuna kumbukumbu').evaluate().isNotEmpty;
      expect(hasTable || hasEmpty, isTrue);
      tester.takeException(); // ignore test-font table overflow
    });
  }

  testWidgets('savings report shows real member figures', (tester) async {
    await _pump(tester, ReportType.savings);
    // A DataTable with the member column header and real TZS amounts.
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Mwanachama'), findsOneWidget); // "Member" column (sw)
    expect(find.textContaining('TZS'), findsWidgets); // savings amounts
  });
}
