import 'package:drift/drift.dart';

/// Drift table definitions. These are the durable source of truth on disk;
/// member/loan balances are NOT stored here — they are derived from the
/// transaction rows (savings, repayments, fines) when the snapshot is built.

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
