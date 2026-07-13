// Verifies the per-group rulebook (GroupRules): it has sane defaults, survives a
// JSON round-trip, and the offline repository persists edits so they drive the
// loan/fines/meeting defaults per group.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vikoba/core/data/repository.dart';
import 'package:vikoba/core/db/app_database.dart';
import 'package:vikoba/core/models/models.dart';

DriftRepository _repo() =>
    DriftRepository(AppDatabase.forTesting(NativeDatabase.memory()));

void main() {
  test('GroupRules has sane defaults and survives a JSON round-trip', () {
    final r = GroupRules.defaults();
    expect(r.interestRatePct, 10);
    expect(r.shareValue, 5000);
    expect(r.loanMultiplier, 3);
    expect(r.fineTypes.length, greaterThan(0));

    final back = GroupRules.fromJson(r.toJson());
    expect(back.interestRatePct, r.interestRatePct);
    expect(back.loanMultiplier, r.loanMultiplier);
    expect(back.meetingFrequency, r.meetingFrequency);
    expect(back.fineTypes.length, r.fineTypes.length);
    expect(back.fineTypes.first.name, r.fineTypes.first.name);
  });

  test('offline repository persists an updated rulebook', () async {
    final repo = _repo();
    await repo.initGroup(name: 'Test Group', term: '2026');

    final before = await repo.loadSnapshot();
    expect(before.rules.interestRatePct, 10);

    await repo.updateRules(before.rules.copyWith(
      interestRatePct: 12.5,
      loanDurationMonths: 4,
      fineTypes: const [FineType('Kuchelewa', 3000)],
    ));

    // A fresh snapshot reads the persisted rules back.
    final after = await repo.loadSnapshot();
    expect(after.rules.interestRatePct, 12.5);
    expect(after.rules.loanDurationMonths, 4);
    expect(after.rules.fineTypes.single.name, 'Kuchelewa');
    expect(after.rules.fineTypes.single.amount, 3000);
  });

  test('two groups can hold different rules independently', () async {
    final groupA = _repo();
    final groupB = _repo();
    await groupA.initGroup(name: 'A', term: '2026');
    await groupB.initGroup(name: 'B', term: '2026');

    final a = await groupA.loadSnapshot();
    await groupA.updateRules(a.rules.copyWith(interestRatePct: 20));

    expect((await groupA.loadSnapshot()).rules.interestRatePct, 20);
    // Group B is untouched, still on the default.
    expect((await groupB.loadSnapshot()).rules.interestRatePct, 10);
  });
}
