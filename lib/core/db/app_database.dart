import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  GroupSettings,
  Members,
  Savings,
  ShareTx,
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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2: per-group rule fields moved onto group_settings (was device-wide
          // SharedPreferences). Add the new columns; their table defaults seed
          // sensible values on existing rows.
          if (from < 2) {
            await m.addColumn(groupSettings, groupSettings.loanDurationMonths);
            await m.addColumn(groupSettings, groupSettings.quorumPercent);
            await m.addColumn(groupSettings, groupSettings.meetingFrequency);
            await m.addColumn(groupSettings, groupSettings.meetingStartTime);
            await m.addColumn(groupSettings, groupSettings.meetingLocation);
            await m.addColumn(groupSettings, groupSettings.fineTypes);
          }
          // v3: member self-service deposits. Savings gain a status; existing
          // rows default to 'confirmed' so no balance moves.
          if (from < 3) {
            await m.addColumn(savings, savings.status);
          }
          // v4: paid share ownership. A new table records share purchases;
          // owned shares are derived by adding confirmed purchases to each
          // member's opening share count. No existing data changes.
          if (from < 4) {
            await m.createTable(shareTx);
          }
        },
      );

  Future<bool> get isEmpty async {
    final count = await (selectOnly(members)..addColumns([members.id.count()]))
        .map((row) => row.read(members.id.count()))
        .getSingle();
    return (count ?? 0) == 0;
  }
}
