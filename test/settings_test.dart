// Verifies the settings store persists and that a settings screen actually
// updates it (so it can drive the loan/fines/meeting defaults).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vikoba/core/l10n/locale_provider.dart';
import 'package:vikoba/core/state/settings_store.dart';
import 'package:vikoba/features/settings/interest_rates_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('store has sane defaults and persists changes', () async {
    final store = await SettingsStore.load();
    expect(store.loanInterestRate, 10);
    expect(store.fineTypes.length, greaterThan(0));

    await store.setLoanTerms(rate: 12.5, duration: 4);
    expect(store.loanInterestRate, 12.5);

    // A fresh load reads the persisted value back.
    final reloaded = await SettingsStore.load();
    expect(reloaded.loanInterestRate, 12.5);
    expect(reloaded.loanDurationMonths, 4);
  });

  testWidgets('Interest Rates screen writes the new rate to the store',
      (tester) async {
    final store = await SettingsStore.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider.value(value: store),
        ],
        child: const MaterialApp(home: InterestRatesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Change the interest rate (first field) and save.
    await tester.enterText(find.byType(TextField).first, '18');
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();

    expect(store.loanInterestRate, 18);
  });
}
