// Verifies member self-service deposits: a pending deposit is excluded from all
// balances until an officer approves it, then counts; rejecting discards it.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vikoba/core/data/repository.dart';
import 'package:vikoba/core/db/app_database.dart';
import 'package:vikoba/core/models/models.dart';

DriftRepository _repo() =>
    DriftRepository(AppDatabase.forTesting(NativeDatabase.memory()));

Future<String> _seedMember(DriftRepository repo) async {
  await repo.initGroup(name: 'G', term: '2026');
  await repo.insertMember(name: 'Asha Juma', phone: '0700000001', shares: 2);
  final snap = await repo.loadSnapshot();
  return snap.members.first.id;
}

void main() {
  test('a pending deposit is excluded from balances until approved', () async {
    final repo = _repo();
    final memberId = await _seedMember(repo);

    await repo.insertSaving(
      memberId: memberId,
      amount: 50000,
      date: DateTime(2026, 3, 1),
      type: SavingType.regular,
      method: 'Mobile',
      asRequest: true,
    );

    final pending = await repo.loadSnapshot();
    expect(pending.savingsRequests, hasLength(1));
    expect(pending.members.first.savings, 0); // not counted yet
    expect(pending.savingsCollected, 0);
    expect(pending.cashInHand, 0);

    // Officer approves it → now it counts.
    await repo.approveSaving(pending.savingsRequests.first.id);

    final approved = await repo.loadSnapshot();
    expect(approved.savingsRequests, isEmpty);
    expect(approved.members.first.savings, 50000);
    expect(approved.savingsCollected, 50000);
    expect(approved.cashInHand, 50000);
  });

  test('a rejected deposit is discarded and never counts', () async {
    final repo = _repo();
    final memberId = await _seedMember(repo);

    await repo.insertSaving(
      memberId: memberId,
      amount: 30000,
      date: DateTime(2026, 3, 2),
      type: SavingType.regular,
      method: 'Cash',
      asRequest: true,
    );
    final pending = await repo.loadSnapshot();
    await repo.rejectSaving(pending.savingsRequests.first.id);

    final after = await repo.loadSnapshot();
    expect(after.savingsRequests, isEmpty);
    expect(after.members.first.savings, 0);
    expect(after.savingsCollected, 0);
  });

  test('an officer-recorded saving is confirmed immediately', () async {
    final repo = _repo();
    final memberId = await _seedMember(repo);

    await repo.insertSaving(
      memberId: memberId,
      amount: 20000,
      date: DateTime(2026, 3, 3),
      type: SavingType.regular,
      method: 'Cash',
    ); // asRequest defaults to false

    final snap = await repo.loadSnapshot();
    expect(snap.savingsRequests, isEmpty);
    expect(snap.members.first.savings, 20000);
  });
}
