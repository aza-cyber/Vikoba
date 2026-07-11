import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  GroupSettings,
  Members,
  Savings,
  Loans,
  Repayments,
  Fines,
  Meetings,
  Officers,
  LoanGuarantors,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'vikoba'));

  /// Opens (or creates) a named database file — one per VICOBA group, so each
  /// group's members/loans/savings live in their own isolated store.
  AppDatabase.named(String name) : super(driftDatabase(name: name));

  /// Test/in-memory constructor (used by widget tests).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  Future<bool> get isEmpty async {
    final count = await (selectOnly(members)..addColumns([members.id.count()]))
        .map((row) => row.read(members.id.count()))
        .getSingle();
    return (count ?? 0) == 0;
  }
}
