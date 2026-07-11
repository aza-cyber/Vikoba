// Verifies per-group data isolation: each group's DriftRepository is its own
// store — a member added to one group does not appear in another.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vikoba/core/db/app_database.dart';
import 'package:vikoba/core/data/repository.dart';

DriftRepository _repo() =>
    DriftRepository(AppDatabase.forTesting(NativeDatabase.memory()));

void main() {
  test('a new group initialises empty, under its own name', () async {
    final repo = _repo();
    await repo.initGroup(name: 'Nyakato Group', term: '2026');
    final snap = await repo.loadSnapshot();

    expect(snap.groupName, 'Nyakato Group');
    expect(snap.term, '2026');
    expect(snap.members, isEmpty); // starts empty — admin builds it up
  });

  test('members added to one group do not leak into another', () async {
    final groupA = _repo();
    final groupB = _repo();
    await groupA.initGroup(name: 'Group A', term: '2026');
    await groupB.initGroup(name: 'Group B', term: '2026');

    await groupA.insertMember(name: 'Asha Juma', phone: '0700000001', shares: 3);

    final a = await groupA.loadSnapshot();
    final b = await groupB.loadSnapshot();

    expect(a.members.map((m) => m.name), contains('Asha Juma'));
    expect(b.members, isEmpty); // isolated: not visible in Group B
  });
}
