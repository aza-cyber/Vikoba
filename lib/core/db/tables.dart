import 'package:drift/drift.dart';

/// Drift table definitions. These are the durable source of truth on disk;
/// member/loan balances are NOT stored here — they are derived from the
/// transaction rows (savings, repayments, fines) when the snapshot is built.

/// The fine-type catalogue a fresh group starts with, as a JSON array of
/// {name, amount}. Stored in [GroupSettings.fineTypes]; editable per group.
const kDefaultFineTypesJson =
    '[{"name":"Kutohudhuria mkutano","amount":5000},'
    '{"name":"Kuchelewa malipo","amount":2000},'
    '{"name":"Nyingine","amount":1000}]';

/// Single-row table holding the group identity + constitution/rule settings.
class GroupSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get name => text()();
  TextColumn get term => text()();
  RealColumn get shareValue => real().withDefault(const Constant(5000))();
  RealColumn get socialFundPerMtg => real().withDefault(const Constant(1000))();
  RealColumn get interestRatePct => real().withDefault(const Constant(10))();
  IntColumn get loanMultiplier => integer().withDefault(const Constant(3))();
  IntColumn get maxRepaymentMonths => integer().withDefault(const Constant(4))();
  IntColumn get requiredGuarantors => integer().withDefault(const Constant(2))();
  IntColumn get minShares => integer().withDefault(const Constant(1))();
  IntColumn get maxShares => integer().withDefault(const Constant(5))();
  IntColumn get cycleMonths => integer().withDefault(const Constant(12))();
  IntColumn get cycleMonthsElapsed =>
      integer().withDefault(const Constant(6))();
  IntColumn get meetingsHeld => integer().withDefault(const Constant(0))();
  RealColumn get interestEarned => real().withDefault(const Constant(0))();
  RealColumn get meetingExpense => real().withDefault(const Constant(0))();
  RealColumn get otherExpense => real().withDefault(const Constant(0))();
  RealColumn get openingCash => real().withDefault(const Constant(0))();
  RealColumn get openingSocialFund => real().withDefault(const Constant(0))();
  // Rule fields the app used to keep device-global; now per-group so two groups
  // can run different loan/meeting/fine rules. fineTypes is a JSON array.
  IntColumn get loanDurationMonths => integer().withDefault(const Constant(3))();
  IntColumn get quorumPercent => integer().withDefault(const Constant(50))();
  TextColumn get meetingFrequency =>
      text().withDefault(const Constant('weekly'))();
  TextColumn get meetingStartTime =>
      text().withDefault(const Constant('10:00'))();
  TextColumn get meetingLocation => text().withDefault(const Constant(''))();
  TextColumn get fineTypes =>
      text().withDefault(const Constant(kDefaultFineTypesJson))();

  @override
  Set<Column> get primaryKey => {id};
}

class Members extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().withDefault(const Constant(''))();
  IntColumn get shares => integer().withDefault(const Constant(0))();
  DateTimeColumn get joinedOn => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Savings extends Table {
  TextColumn get id => text()();
  TextColumn get memberId => text()();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // regular | special | social
  TextColumn get method => text()();
  DateTimeColumn get date => dateTime()();
  // confirmed (counts toward balances) | pending (a member-submitted deposit
  // awaiting an officer's approval). Officer-recorded savings are confirmed.
  TextColumn get status => text().withDefault(const Constant('confirmed'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Loans extends Table {
  TextColumn get id => text()();
  TextColumn get memberId => text()();
  TextColumn get memberName => text()();
  RealColumn get principal => real()();
  RealColumn get interestRate => real().withDefault(const Constant(10))();
  IntColumn get durationMonths => integer().withDefault(const Constant(3))();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get status => text()(); // request | ongoing | paid
  TextColumn get purpose => text().withDefault(const Constant(''))();
  DateTimeColumn get disbursedOn => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Repayments extends Table {
  TextColumn get id => text()();
  TextColumn get loanId => text()();
  RealColumn get amount => real()();
  TextColumn get method => text().withDefault(const Constant('cash'))();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Fines extends Table {
  TextColumn get id => text()();
  TextColumn get memberId => text()();
  TextColumn get reason => text()();
  RealColumn get amount => real()();
  BoolColumn get paid => boolean().withDefault(const Constant(true))();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Meetings extends Table {
  TextColumn get id => text()();
  IntColumn get number => integer()();
  DateTimeColumn get date => dateTime()();
  IntColumn get attended => integer().withDefault(const Constant(0))();
  IntColumn get total => integer().withDefault(const Constant(0))();
  IntColumn get agendaItems => integer().withDefault(const Constant(0))();
  IntColumn get decisions => integer().withDefault(const Constant(0))();
  RealColumn get collections => real().withDefault(const Constant(0))();
  RealColumn get fines => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Officers extends Table {
  TextColumn get id => text()();
  TextColumn get memberName => text()();
  TextColumn get role => text()();
  TextColumn get phone => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// The two guarantors (wadhamini) backing each loan (many-to-many).
class LoanGuarantors extends Table {
  TextColumn get loanId => text()();
  TextColumn get memberId => text()();

  @override
  Set<Column> get primaryKey => {loanId, memberId};
}
