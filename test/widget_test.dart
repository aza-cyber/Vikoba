// Basic smoke test: the app boots to the login screen without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vikoba/core/state/app_state.dart';
import 'package:vikoba/core/state/groups_store.dart';
import 'package:vikoba/main.dart';

void main() {
  testWidgets('App boots and shows the login screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final groups = await GroupsStore.load();
    await tester.pumpWidget(VicobaApp(
        appState: AppState(Snapshot.empty()), groups: groups));
    await tester.pumpAndSettle();

    // The login screen exposes a language toggle and a phone field.
    expect(find.byType(TextField), findsWidgets);
    expect(find.byIcon(Icons.language), findsOneWidget);
  });
}
