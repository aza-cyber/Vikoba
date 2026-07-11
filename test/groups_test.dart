// Super-admin group registry: store operations, credentials, and the panel.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vikoba/core/l10n/locale_provider.dart';
import 'package:vikoba/core/state/groups_store.dart';
import 'package:vikoba/features/superadmin/groups_admin_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('registry seeds, adds, removes and persists', () async {
    final store = await GroupsStore.load(seedName: 'Nyakato Group', seedTerm: '2026');
    expect(store.groups.length, 1);
    expect(store.groups.first.name, 'Nyakato Group');

    await store.add(
        name: 'Mwanza Group', term: '2026', leader: 'Asha', membersCount: 20);
    expect(store.groups.length, 2);
    expect(store.activeCount, 2);

    final mwanza = store.groups.last;
    await store.toggleActive(mwanza.id);
    expect(store.activeCount, 1);

    await store.remove(mwanza.id);
    expect(store.groups.length, 1);

    // Persisted: a fresh load sees the same single group (no re-seed).
    final reloaded = await GroupsStore.load(seedName: 'ignored');
    expect(reloaded.groups.length, 1);
    expect(reloaded.groups.first.name, 'Nyakato Group');
  });

  test('super-admin credentials', () async {
    final store = await GroupsStore.load();
    expect(store.isSuperAdmin('superadmin', '0000'), isTrue);
    expect(store.isSuperAdmin(' SuperAdmin ', '0000'), isTrue); // lenient case
    expect(store.isSuperAdmin('superadmin', '1234'), isFalse);
    expect(store.isSuperAdmin('someone', '0000'), isFalse);
  });

  testWidgets('panel lists the registered groups', (tester) async {
    final store = await GroupsStore.load(seedName: 'Nyakato Group');
    await store.add(
        name: 'Mwanza Group', term: '2026', leader: 'Asha', membersCount: 20);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider.value(value: store),
        ],
        child: const MaterialApp(home: GroupsAdminScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nyakato Group'), findsOneWidget);
    expect(find.text('Mwanza Group'), findsOneWidget);
    expect(find.text('2'), findsWidgets); // total groups stat
    tester.takeException(); // consume any test-font overflow
  });
}
