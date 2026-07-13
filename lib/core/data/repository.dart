import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import '../db/app_database.dart';
import '../models/models.dart' as mdl;
import '../state/app_state.dart';
import 'group_defaults.dart';
import 'repository_base.dart';

/// Bridges the SQLite database and the app's [Snapshot]. Writes go in as rows;
/// reads come back as a fully-derived snapshot (balances computed from rows).
///
/// Drift generates row classes named `Member`, `Loan`, `Fine`, `Meeting`,
/// `Officer` — same names as our domain models — so the models are imported
/// under the `mdl` prefix and the bare names here mean the database rows.
class DriftRepository implements Repository {
  DriftRepository(this.db);
  final AppDatabase db;

  // ---------------------------------------------------------------- seeding
  /// Bootstraps a fresh install (offline mode) with the real group and its
  /// first admin only — no sample members/loans/meetings. Everything else is
  /// entered by users. No-op once any member exists.
  @override
  Future<void> seedIfEmpty() async {
    if (!await db.isEmpty) return;
    await initGroup(name: 'Vijana Group', term: 'Jan 2026 - Dec 2026');
    await db.into(db.members).insert(
          MembersCompanion.insert(
            id: 'admin',
            name: 'Azigard Chaula',
            phone: const Value('0741735909'),
            shares: const Value(0),
            joinedOn: DateTime.now(),
          ),
        );
    // Office-bearer row so the admin is recognised as an admin at login
    // (offline login derives the admin role from the officers table).
    await db.into(db.officers).insert(
          OfficersCompanion.insert(
            id: 'O-admin',
            memberName: 'Azigard Chaula',
            role: 'chairperson',
            phone: const Value('0741735909'),
          ),
        );
  }

  /// Initialises a brand-new group with just its settings row (name/term +
  /// default rules) and NO members, so the group starts empty and the admin
  /// builds it up. No-op if the group already has a settings row.
  Future<void> initGroup({required String name, required String term}) async {
    final existing = await db.select(db.groupSettings).get();
    if (existing.isNotEmpty) return;
    await db.into(db.groupSettings).insert(
          GroupSettingsCompanion.insert(
            id: const Value(1),
            name: name,
            term: term,
            shareValue: const Value(GroupDefaults.shareValue),
            socialFundPerMtg: const Value(GroupDefaults.socialFundPerMeeting),
            interestRatePct: const Value(GroupDefaults.monthlyInterestRate),
            loanMultiplier: const Value(GroupDefaults.loanMultiplier),
            maxRepaymentMonths: const Value(GroupDefaults.maxRepaymentMonths),
            requiredGuarantors: const Value(GroupDefaults.requiredGuarantors),
            minShares: const Value(GroupDefaults.minSharesPerMeeting),
            maxShares: const Value(GroupDefaults.maxSharesPerMeeting),
            cycleMonths: const Value(GroupDefaults.cycleMonths),
            cycleMonthsElapsed: const Value(0),
            meetingsHeld: const Value(0),
            interestEarned: const Value(0),
            meetingExpense: const Value(0),
            otherExpense: const Value(0),
            openingCash: const Value(0),
            openingSocialFund: const Value(0),
          ),
        );
  }

  // Offline mode has no server, so it is always "reachable" and there is no
  // session token to revoke.
  @override
  Future<bool> ping() async => true;

  @override
  Future<void> endSession() async {}

  // --------------------------------------------------------------- login
  /// Offline login. The local schema has no PIN column, so this accepts the
  /// shared demo PIN ('1234') for any member matched by phone, and derives the
  /// admin role from the officers table (office bearers run the group). The
  /// online [ApiRepository] does real per-member PIN + role checks.
  @override
  Future<AuthResult?> login({
    required String phone,
    required String password,
  }) async {
    if (password.trim() != '1234') return null;
    final target = _normPhone(phone);
    if (target.isEmpty) return null;
    final memberRows = await db.select(db.members).get();
    Member? me;
    for (final m in memberRows) {
      if (_normPhone(m.phone) == target) {
        me = m;
        break;
      }
    }
    if (me == null) return null;
    final officerRows = await db.select(db.officers).get();
    const bearer = {'chairperson', 'secretary', 'treasurer'};
    final isAdmin = officerRows
        .any((o) => o.memberName == me!.name && bearer.contains(o.role));
    return AuthResult(
      memberId: me.id,
      name: me.name,
      role: isAdmin ? mdl.MemberRole.admin : mdl.MemberRole.member,
    );
  }

  /// SMS sign-in requires a backend to send the text, which the offline store
  /// has no way to do — so both OTP methods report unavailable. The login screen
  /// only offers the SMS option in online (API) mode, so these aren't reached in
  /// normal use; they exist to satisfy the [Repository] contract.
  @override
  Future<OtpRequestResult> requestOtp({required String phone}) async =>
      const OtpRequestResult(ok: false, errorKey: 'otp_unavailable');

  @override
  Future<AuthResult?> verifyOtp({
    required String phone,
    required String code,
  }) async =>
      null;

  /// No backend to push from in offline mode — device registration is a no-op.
  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {}

  @override
  Future<void> unregisterDevice(String token) async {}

  /// Last 9 digits of a phone number — see the API's `_normPhone`.
  static String _normPhone(String p) {
    final digits = p.replaceAll(RegExp(r'\D'), '');
    return digits.length > 9 ? digits.substring(digits.length - 9) : digits;
  }

  // ------------------------------------------------------------- snapshot
  @override
  Future<Snapshot> loadSnapshot() async {
    final settings = await db.select(db.groupSettings).getSingle();
    final memberRows = await db.select(db.members).get();
    final allSavingRows = await db.select(db.savings).get();
    // Only CONFIRMED savings count toward balances/history; member-submitted
    // pending deposits surface separately as savingsRequests until approved.
    final savingRows =
        allSavingRows.where((s) => s.status != 'pending').toList();
    final pendingSavingRows =
        allSavingRows.where((s) => s.status == 'pending').toList();
    final loanRows = await db.select(db.loans).get();
    final repayRows = await db.select(db.repayments).get();
    final fineRows = await db.select(db.fines).get();
    final meetingRows = await db.select(db.meetings).get();
    final officerRows = await db.select(db.officers).get();

    final nameById = {for (final m in memberRows) m.id: m.name};
    final loanMemberName = {for (final l in loanRows) l.id: l.memberName};

    double sumSavings(String memberId, {required bool social}) => savingRows
        .where((s) =>
            s.memberId == memberId &&
            (social ? s.type == 'social' : s.type != 'social'))
        .fold(0.0, (sum, s) => sum + s.amount);
    // A member's fines balance is only what they still OWE (unpaid penalties).
    double sumFines(String memberId) => fineRows
        .where((f) => f.memberId == memberId && !f.paid)
        .fold(0.0, (sum, f) => sum + f.amount);
    double repaidFor(String loanId) => repayRows
        .where((r) => r.loanId == loanId)
        .fold(0.0, (sum, r) => sum + r.amount);

    // Derive each loan's outstanding balance + effective status.
    final loans = loanRows.map((l) {
      // Flat monthly interest: principal × rate% × months; the balance is the
      // total owed (principal + interest) minus repayments.
      final totalDue =
          l.principal + l.principal * (l.interestRate / 100) * l.durationMonths;
      final balance =
          (totalDue - repaidFor(l.id)).clamp(0, double.infinity).toDouble();
      final status = l.status == mdl.LoanStatus.request.name
          ? mdl.LoanStatus.request
          : l.status == mdl.LoanStatus.rejected.name
              ? mdl.LoanStatus.rejected
              : (balance <= 0 ? mdl.LoanStatus.paid : mdl.LoanStatus.ongoing);
      return mdl.Loan(
        id: l.id,
        memberName: l.memberName,
        principal: l.principal,
        balance: balance,
        dueDate: l.dueDate,
        status: status,
        interestRate: l.interestRate,
        durationMonths: l.durationMonths,
      );
    }).toList();

    final members = memberRows.map((m) {
      final loanBal = loans
          .where(
              (l) => l.memberName == m.name && l.status == mdl.LoanStatus.ongoing)
          .fold(0.0, (sum, l) => sum + l.balance);
      return mdl.Member(
        id: m.id,
        name: m.name,
        phone: m.phone,
        shares: m.shares,
        status: loanBal > 0 ? mdl.MemberStatus.borrower : mdl.MemberStatus.active,
        savings: sumSavings(m.id, social: false),
        loanBalance: loanBal,
        fines: sumFines(m.id),
        joinedOn: m.joinedOn,
      );
    }).toList();

    final savings = savingRows
        .map((s) => mdl.SavingEntry(
              memberName: nameById[s.memberId] ?? s.memberId,
              amount: s.amount,
              date: s.date,
              method: s.method,
              type: _savingType(s.type),
            ))
        .toList();

    final repayments = repayRows
        .map((r) => mdl.Repayment(
              loanId: r.loanId,
              memberName: loanMemberName[r.loanId] ?? '',
              amount: r.amount,
              date: r.date,
              method: r.method,
            ))
        .toList();

    final fines = fineRows
        .map((f) => mdl.Fine(
              id: f.id,
              memberName: nameById[f.memberId] ?? f.memberId,
              reason: f.reason,
              amount: f.amount,
              date: f.date,
              paid: f.paid,
            ))
        .toList();

    final meetings = meetingRows
        .map((m) => mdl.Meeting(
              id: m.id,
              number: m.number,
              date: m.date,
              attended: m.attended,
              total: m.total,
              decisions: m.decisions,
              collections: m.collections,
              fines: m.fines,
            ))
        .toList();

    final officers = officerRows
        .map((o) => mdl.Officer(
              id: o.id,
              name: o.memberName,
              role: _officerRole(o.role),
              phone: o.phone,
            ))
        .toList();

    final savingsCollected = savingRows
        .where((s) => s.type != 'social')
        .fold(0.0, (a, s) => a + s.amount);
    final socialCollected = savingRows
        .where((s) => s.type == 'social')
        .fold(0.0, (a, s) => a + s.amount);
    final repaymentsCollected = repayRows.fold(0.0, (a, r) => a + r.amount);
    final finesCollected =
        fineRows.where((f) => f.paid).fold(0.0, (a, f) => a + f.amount);
    final loansDisbursed = loanRows
        .where((l) =>
            l.status != mdl.LoanStatus.request.name &&
            l.status != mdl.LoanStatus.rejected.name)
        .fold(0.0, (a, l) => a + l.principal);
    final cashInHand = settings.openingCash +
        savingsCollected +
        socialCollected +
        repaymentsCollected +
        finesCollected -
        loansDisbursed -
        settings.meetingExpense -
        settings.otherExpense;

    // Recent activity derived from the newest transactions.
    final acts = <(DateTime, mdl.Activity)>[];
    for (final s in savingRows) {
      acts.add((
        s.date,
        mdl.Activity(
            title: nameById[s.memberId] ?? '',
            amount: s.amount,
            icon: mdl.IconKey.savings)
      ));
    }
    for (final r in repayRows) {
      acts.add((
        r.date,
        mdl.Activity(
            title: loanMemberName[r.loanId] ?? '',
            amount: r.amount,
            icon: mdl.IconKey.loan)
      ));
    }
    for (final l in loanRows.where((l) =>
        l.status != mdl.LoanStatus.request.name &&
        l.status != mdl.LoanStatus.rejected.name)) {
      acts.add((
        l.disbursedOn,
        mdl.Activity(
            title: l.memberName, amount: l.principal, icon: mdl.IconKey.loan)
      ));
    }
    for (final f in fineRows) {
      acts.add((
        f.date,
        mdl.Activity(
            title: nameById[f.memberId] ?? '',
            amount: f.amount,
            icon: mdl.IconKey.fine)
      ));
    }
    acts.sort((a, b) => b.$1.compareTo(a.$1));

    final savingsRequests = pendingSavingRows
        .map((s) => mdl.SavingRequest(
              id: s.id,
              memberId: s.memberId,
              memberName: nameById[s.memberId] ?? s.memberId,
              amount: s.amount,
              type: _savingType(s.type),
              method: s.method,
              requestedOn: s.date,
            ))
        .toList();

    return Snapshot(
      groupName: settings.name,
      term: settings.term,
      rules: _rulesFrom(settings),
      members: members,
      membershipRequests: const [],
      savingsRequests: savingsRequests,
      loans: loans,
      savings: savings,
      repayments: repayments,
      fines: fines,
      meetings: meetings,
      officers: officers,
      activities: acts.take(12).map((e) => e.$2).toList(),
      cashInHand: cashInHand,
      socialFundBalance: settings.openingSocialFund + socialCollected,
      savingsCollected: savingsCollected,
      repaymentsCollected: repaymentsCollected,
      finesCollected: finesCollected,
      loansDisbursed: loansDisbursed,
      meetingExpense: settings.meetingExpense,
      otherExpense: settings.otherExpense,
      interestEarned: settings.interestEarned,
      shareValue: settings.shareValue,
      meetingsHeld: settings.meetingsHeld,
    );
  }

  /// Builds the group's [mdl.GroupRules] from its settings row, decoding the
  /// stored fine-type JSON (falling back to defaults if it's blank/corrupt).
  mdl.GroupRules _rulesFrom(GroupSetting s) {
    List<mdl.FineType> fineTypes;
    try {
      final decoded = jsonDecode(s.fineTypes) as List;
      fineTypes = decoded
          .map((e) => mdl.FineType.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      fineTypes = mdl.GroupRules.defaults().fineTypes;
    }
    return mdl.GroupRules(
      shareValue: s.shareValue,
      minShares: s.minShares,
      maxShares: s.maxShares,
      socialFundPerMtg: s.socialFundPerMtg,
      interestRatePct: s.interestRatePct,
      loanMultiplier: s.loanMultiplier,
      loanDurationMonths: s.loanDurationMonths,
      maxRepaymentMonths: s.maxRepaymentMonths,
      requiredGuarantors: s.requiredGuarantors,
      cycleMonths: s.cycleMonths,
      cycleMonthsElapsed: s.cycleMonthsElapsed,
      quorumPercent: s.quorumPercent,
      meetingFrequency: s.meetingFrequency,
      meetingStartTime: s.meetingStartTime,
      meetingLocation: s.meetingLocation,
      fineTypes: fineTypes,
    );
  }

  @override
  Future<void> updateRules(mdl.GroupRules rules) async {
    await (db.update(db.groupSettings)..where((g) => g.id.equals(1))).write(
      GroupSettingsCompanion(
        shareValue: Value(rules.shareValue),
        minShares: Value(rules.minShares),
        maxShares: Value(rules.maxShares),
        socialFundPerMtg: Value(rules.socialFundPerMtg),
        interestRatePct: Value(rules.interestRatePct),
        loanMultiplier: Value(rules.loanMultiplier),
        loanDurationMonths: Value(rules.loanDurationMonths),
        maxRepaymentMonths: Value(rules.maxRepaymentMonths),
        requiredGuarantors: Value(rules.requiredGuarantors),
        cycleMonths: Value(rules.cycleMonths),
        quorumPercent: Value(rules.quorumPercent),
        meetingFrequency: Value(rules.meetingFrequency),
        meetingStartTime: Value(rules.meetingStartTime),
        meetingLocation: Value(rules.meetingLocation),
        fineTypes:
            Value(jsonEncode([for (final f in rules.fineTypes) f.toJson()])),
      ),
    );
  }

  // ------------------------------------------------------------- inserts
  static final _rng = Random.secure();

  /// A globally-unique, non-guessable row id: a short type prefix + a v4 UUID
  /// (e.g. "M-3f2a1b4c-..."). Matches the online API's id scheme, replacing the
  /// old timestamp ids that could collide under rapid inserts.
  String _id(String prefix) {
    final b = List<int>.generate(16, (_) => _rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // variant 1
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).toList();
    return '$prefix-${h.sublist(0, 4).join()}-${h.sublist(4, 6).join()}-'
        '${h.sublist(6, 8).join()}-${h.sublist(8, 10).join()}-'
        '${h.sublist(10).join()}';
  }

  @override
  Future<void> insertMember({
    required String name,
    required String phone,
    required int shares,
  }) {
    return db.into(db.members).insert(MembersCompanion.insert(
          id: _id('M'),
          name: name,
          phone: Value(phone),
          shares: Value(shares),
          joinedOn: DateTime.now(),
        ));
  }

  @override
  Future<void> requestMembership({
    required String name,
    required String phone,
    required int shares,
  }) {
    return insertMember(name: name, phone: phone, shares: shares);
  }

  @override
  Future<void> approveMembershipRequest(String id) async {}

  @override
  Future<void> rejectMembershipRequest(String id) async {}

  @override
  Future<void> setMemberActive(
      {required String id, required bool active}) async {
    // Offline (single-device) mode has no login gating, so suspension is a
    // no-op here; the online backend enforces it.
  }

  @override
  Future<void> deleteMember(String id) async {
    // Remove the member and everything that references them, in one atomic
    // transaction so no orphan rows (or half-deleted history) can survive.
    await db.transaction(() async {
      // Repayments hang off the member's loans, so clear them by loan id first.
      final loanIds = await (db.selectOnly(db.loans)
            ..addColumns([db.loans.id])
            ..where(db.loans.memberId.equals(id)))
          .map((r) => r.read(db.loans.id)!)
          .get();
      if (loanIds.isNotEmpty) {
        await (db.delete(db.repayments)
              ..where((r) => r.loanId.isIn(loanIds)))
            .go();
      }
      await (db.delete(db.loanGuarantors)..where((g) => g.memberId.equals(id)))
          .go();
      await (db.delete(db.loans)..where((l) => l.memberId.equals(id))).go();
      await (db.delete(db.savings)..where((s) => s.memberId.equals(id))).go();
      await (db.delete(db.fines)..where((f) => f.memberId.equals(id))).go();
      await (db.delete(db.members)..where((m) => m.id.equals(id))).go();
    });
  }

  @override
  Future<void> updateOfficerName(
      {required String id, required String name}) async {
    await (db.update(db.officers)..where((o) => o.id.equals(id)))
        .write(OfficersCompanion(memberName: Value(name)));
  }

  @override
  Future<void> addOfficer(
      {required String name, required String phone, required String role}) async {
    await db.into(db.officers).insert(OfficersCompanion.insert(
          id: _id('O'),
          memberName: name,
          role: role,
          phone: Value(phone),
        ));
  }

  @override
  Future<void> removeOfficer(String id) async {
    await (db.delete(db.officers)..where((o) => o.id.equals(id))).go();
  }

  @override
  Future<void> insertSaving({
    required String memberId,
    required double amount,
    required DateTime date,
    required mdl.SavingType type,
    required String method,
    bool asRequest = false,
  }) {
    return db.into(db.savings).insert(SavingsCompanion.insert(
          id: _id('S'),
          memberId: memberId,
          amount: amount,
          type: type.name,
          method: method,
          date: date,
          status: Value(asRequest ? 'pending' : 'confirmed'),
        ));
  }

  @override
  Future<void> approveSaving(String id) async {
    await (db.update(db.savings)
          ..where((s) => s.id.equals(id) & s.status.equals('pending')))
        .write(const SavingsCompanion(status: Value('confirmed')));
  }

  @override
  Future<void> rejectSaving(String id) async {
    await (db.delete(db.savings)
          ..where((s) => s.id.equals(id) & s.status.equals('pending')))
        .go();
  }

  @override
  Future<void> insertLoan({
    required String memberId,
    required double principal,
    required double interestRate,
    required int durationMonths,
    required DateTime dueDate,
    List<String> guarantorIds = const [],
    bool asRequest = false,
  }) async {
    final member = await (db.select(db.members)
          ..where((m) => m.id.equals(memberId)))
        .getSingleOrNull();
    final loanId = _id('L');
    await db.into(db.loans).insert(LoansCompanion.insert(
          id: loanId,
          memberId: memberId,
          memberName: member?.name ?? '',
          principal: principal,
          interestRate: Value(interestRate),
          durationMonths: Value(durationMonths),
          dueDate: dueDate,
          status: (asRequest ? mdl.LoanStatus.request : mdl.LoanStatus.ongoing)
              .name,
          disbursedOn: DateTime.now(),
        ));
    for (final g in guarantorIds) {
      await db.into(db.loanGuarantors).insert(
            LoanGuarantorsCompanion.insert(loanId: loanId, memberId: g),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  @override
  Future<void> insertRepayment({
    required String loanId,
    required double amount,
    required DateTime date,
    String method = 'cash',
  }) {
    return db.into(db.repayments).insert(RepaymentsCompanion.insert(
          id: _id('R'),
          loanId: loanId,
          amount: amount,
          method: Value(method),
          date: date,
        ));
  }

  @override
  Future<void> approveLoan(String loanId) async {
    await (db.update(db.loans)
          ..where((l) =>
              l.id.equals(loanId) &
              l.status.equals(mdl.LoanStatus.request.name)))
        .write(LoansCompanion(
      status: Value(mdl.LoanStatus.ongoing.name),
      disbursedOn: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> rejectLoan(String loanId) async {
    await (db.update(db.loans)
          ..where((l) =>
              l.id.equals(loanId) &
              l.status.equals(mdl.LoanStatus.request.name)))
        .write(LoansCompanion(status: Value(mdl.LoanStatus.rejected.name)));
  }

  @override
  Future<void> insertFine({
    required String memberId,
    required String reason,
    required double amount,
    required DateTime date,
    bool paid = false,
  }) {
    return db.into(db.fines).insert(FinesCompanion.insert(
          id: _id('F'),
          memberId: memberId,
          reason: reason,
          amount: amount,
          paid: Value(paid),
          date: date,
        ));
  }

  @override
  Future<void> payFine(String fineId) async {
    await (db.update(db.fines)..where((f) => f.id.equals(fineId)))
        .write(const FinesCompanion(paid: Value(true)));
  }

  // Constitution amendments are an online-only feature (the offline SQLite
  // store has no amendments table). The app runs in API mode, so these are
  // no-ops here; loadSnapshot returns no amendments offline.
  @override
  Future<void> addAmendment({required String title, required String body}) async {}

  @override
  Future<void> updateAmendment(
      {required String id, required String title, required String body}) async {}

  @override
  Future<void> deleteAmendment(String id) async {}

  // Dynamic meeting agendas are an online-only feature (no offline agendas
  // table). The app runs in API mode, so these are no-ops here.
  @override
  Future<void> createMeeting({
    required DateTime date,
    required String title,
    required String startTime,
    required String location,
    required String period,
    required String chairperson,
    required String secretary,
  }) async {}

  @override
  Future<void> updateMeeting({
    required String id,
    required DateTime date,
    required String title,
    required String startTime,
    required String location,
    required String period,
    required String chairperson,
    required String secretary,
    required int decisions,
    required double collections,
    required double fines,
  }) async {}

  @override
  Future<void> setMeetingStatus(
      {required String id, required String status}) async {}

  @override
  Future<void> setAttendance({
    required String meetingId,
    required String memberId,
    required String status,
  }) async {}

  @override
  Future<void> addMinute(
      {required String meetingId, required String text}) async {}

  @override
  Future<void> deleteMinute(String id) async {}

  @override
  Future<void> addAction({
    required String meetingId,
    required String task,
    required String responsible,
    required DateTime? dueDate,
  }) async {}

  @override
  Future<void> toggleAction({required String id, required bool done}) async {}

  @override
  Future<void> deleteAction(String id) async {}

  @override
  Future<void> addAgenda(
      {required String meetingId, required String text}) async {}

  @override
  Future<void> toggleAgenda({required String id, required bool done}) async {}

  @override
  Future<void> deleteAgenda(String id) async {}

  // ------------------------------------------------------------- helpers
  static mdl.SavingType _savingType(String s) {
    for (final t in mdl.SavingType.values) {
      if (t.name == s) return t;
    }
    return mdl.SavingType.regular;
  }

  static mdl.OfficerRole _officerRole(String s) {
    for (final r in mdl.OfficerRole.values) {
      if (r.name == s) return r;
    }
    return mdl.OfficerRole.mobilizer;
  }
}
