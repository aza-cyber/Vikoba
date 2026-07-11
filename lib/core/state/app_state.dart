import 'package:flutter/foundation.dart';
import '../config.dart';
import '../server_config.dart';
import '../data/api_repository.dart';
import '../data/repository_base.dart';
import '../models/models.dart';

/// An immutable, fully-computed view of the group at a point in time. Member
/// and loan balances here are already derived from the transaction rows by the
/// repository — the UI just reads them.
class Snapshot {
  final String groupName;
  final String term;
  final List<Member> members;
  final List<MembershipRequest> membershipRequests;
  final List<Loan> loans;
  final List<SavingEntry> savings;
  final List<Repayment> repayments;
  final List<Fine> fines;
  final List<Meeting> meetings;
  final List<Officer> officers;
  final List<Amendment> amendments;
  final List<Activity> activities;
  final double cashInHand;
  final double socialFundBalance;
  final double savingsCollected;
  final double repaymentsCollected;
  final double finesCollected;
  final double loansDisbursed;
  final double meetingExpense;
  final double otherExpense;
  final double interestEarned;
  final double shareValue;
  final int meetingsHeld;

  const Snapshot({
    required this.groupName,
    required this.term,
    required this.members,
    this.membershipRequests = const [],
    required this.loans,
    required this.savings,
    required this.repayments,
    required this.fines,
    required this.meetings,
    required this.officers,
    this.amendments = const [],
    required this.activities,
    required this.cashInHand,
    required this.socialFundBalance,
    required this.savingsCollected,
    required this.repaymentsCollected,
    required this.finesCollected,
    required this.loansDisbursed,
    required this.meetingExpense,
    required this.otherExpense,
    required this.interestEarned,
    required this.shareValue,
    required this.meetingsHeld,
  });

  /// An all-zero snapshot used when the backend can't be reached at startup, so
  /// the app still launches (with a retry) instead of hanging on a blank screen.
  factory Snapshot.empty() => const Snapshot(
        groupName: '',
        term: '',
        members: [],
        membershipRequests: [],
        loans: [],
        savings: [],
        repayments: [],
        fines: [],
        meetings: [],
        officers: [],
        activities: [],
        cashInHand: 0,
        socialFundBalance: 0,
        savingsCollected: 0,
        repaymentsCollected: 0,
        finesCollected: 0,
        loansDisbursed: 0,
        meetingExpense: 0,
        otherExpense: 0,
        interestEarned: 0,
        shareValue: 0,
        meetingsHeld: 0,
      );
}

/// The single source of truth the UI reads. It holds the latest [Snapshot] and
/// exposes the same getters the screens already use. Every mutation writes rows
/// to the database via [_repo], then reloads a fresh (re-derived) snapshot.
class AppState extends ChangeNotifier {
  AppState(this._snapshot, {Repository? repo, bool loadError = false})
      : _repo = repo,
        _loadError = loadError;

  Snapshot _snapshot;
  Repository? _repo;
  bool _loadError;

  // ---- Logged-in session (set by [login], cleared by [logout]) ----
  String? _sessionMemberId;
  MemberRole _sessionRole = MemberRole.member;

  /// True only when this session is the platform super admin managing a group
  /// (entered via the super-admin group workspace, see [enterAsAdmin]). Regular
  /// group admins are never super admins. Gates super-admin-only edits such as
  /// renaming leadership office bearers.
  bool _isSuperAdmin = false;

  /// The group this session was authenticated into. Online, the server returns
  /// it on login; offline it is implied by which group database matched. Prefer
  /// [sessionGroupName] for display, falling back to the snapshot's group name.
  String? _sessionGroupId;
  String? _sessionGroupName;

  /// True when the last snapshot load failed (e.g. the backend is unreachable).
  /// The UI shows a retry affordance instead of silently empty data.
  bool get connectionError => _loadError;

  String? _loginErrorKey;

  /// The l10n key describing why the last [login] failed — one of
  /// `connection_error`, `account_inactive`, or `login_failed`. Null after a
  /// successful login. Lets the login screen show a precise message.
  String? get loginErrorKey => _loginErrorKey;

  /// The id of the member who is currently logged in, or null if signed out.
  String? get sessionMemberId => _sessionMemberId;

  /// Whether the logged-in member sees the admin panel.
  ///
  /// Chairperson is an admin by default, even if an older backend/local record
  /// still reports their login role as a regular member.
  bool get isAdmin =>
      _sessionRole == MemberRole.admin || _currentMemberIsChairperson;

  /// Whether this session is the platform super admin (managing a group through
  /// the super-admin workspace). Only then are super-admin-only controls shown.
  bool get isSuperAdmin => _isSuperAdmin;

  /// The id of the group this session belongs to, if known (online). Null
  /// offline, where the group is implied by the matched database.
  String? get sessionGroupId => _sessionGroupId;

  /// The name of the group this session belongs to — the login-time group name
  /// if the backend supplied one, else the loaded snapshot's group name.
  String get sessionGroupName =>
      (_sessionGroupName?.isNotEmpty ?? false) ? _sessionGroupName! : groupName;

  /// The full record of the logged-in member (latest derived figures), or null.
  Member? get currentMember =>
      _sessionMemberId == null ? null : memberById(_sessionMemberId!);

  /// Authenticates against the backend and, on success, starts a session.
  /// Returns the role to route to, or null if the credentials were rejected
  /// (or the backend was unreachable). Never throws.
  Future<MemberRole?> login({
    required String phone,
    required String password,
  }) async {
    final repo = _repo;
    if (repo == null) {
      _loginErrorKey = 'login_failed';
      return null;
    }
    try {
      final auth = await repo.login(phone: phone, password: password);
      if (auth == null) {
        // Reached the server, but it rejected the phone/PIN.
        _loginErrorKey = 'login_failed';
        return null;
      }
      _sessionMemberId = auth.memberId;
      _sessionRole = auth.role;
      _sessionGroupId = auth.groupId;
      _sessionGroupName = auth.groupName;
      // The ledger is protected: it can only be loaded once we hold a session
      // token, so we fetch it here (not at startup) before showing the panels.
      await _reload();
      _loginErrorKey = null;
      notifyListeners();
      return isAdmin ? MemberRole.admin : MemberRole.member;
    } on ApiException catch (e) {
      // 403 => credentials fine but the account is suspended.
      _loginErrorKey =
          e.statusCode == 403 ? 'account_inactive' : 'login_failed';
      return null;
    } catch (_) {
      // Timeout / socket error => the server couldn't be reached.
      _loginErrorKey = 'connection_error';
      return null;
    }
  }

  /// Ends the current session: revokes the token server-side and clears the
  /// in-memory session and cached ledger so nothing leaks after sign-out.
  Future<void> logout() async {
    await _repo?.endSession();
    _sessionMemberId = null;
    _sessionRole = MemberRole.member;
    _isSuperAdmin = false;
    _sessionGroupId = null;
    _sessionGroupName = null;
    _snapshot = Snapshot.empty();
    notifyListeners();
  }

  /// Enters this (group) state with admin rights, without a member login. Used
  /// when the super-admin drills into a group to manage it directly.
  void enterAsAdmin({bool superAdmin = false}) {
    _sessionRole = MemberRole.admin;
    _isSuperAdmin = superAdmin;
    notifyListeners();
  }

  /// Builds a repository-backed AppState: seeds on first run, then loads a
  /// snapshot. Works with either the offline (Drift) or online (API) repository.
  ///
  /// Never throws: if the backend can't be reached, it returns an empty-snapshot
  /// AppState flagged with [connectionError] so the app still launches.
  static Future<AppState> open(Repository repo) async {
    try {
      await repo.seedIfEmpty();
      if (Config.useApi) {
        // Online: the ledger is behind authentication, so we do NOT load it
        // here (there is no session yet). We only check reachability for the
        // login screen's connection banner; the snapshot loads after login.
        final reachable = await repo.ping();
        return AppState(Snapshot.empty(), repo: repo, loadError: !reachable);
      }
      // Offline: the local store needs no auth, so load it straight away.
      final snap = await repo.loadSnapshot();
      return AppState(snap, repo: repo);
    } catch (_) {
      return AppState(Snapshot.empty(), repo: repo, loadError: true);
    }
  }

  /// Re-fetches the snapshot (used by the connection-error retry). Returns true
  /// on success. Never throws.
  Future<bool> refresh() async {
    await _reload();
    return !_loadError;
  }

  /// Points the app at a different backend address at runtime (online/API mode
  /// only), persists it for next launch, and reloads. Returns true if the new
  /// address responded. Used by the login screen's server-address field so a
  /// Wi-Fi change doesn't require rebuilding the APK.
  Future<bool> setServerUrl(String url) async {
    if (!Config.useApi) return false;
    final normalized = await ServerConfig.save(url);
    _repo = ApiRepository(normalized);
    // This is used on the login screen before signing in, so we only test
    // reachability (the ledger requires a session and loads after login). A
    // successful ping clears the connection banner.
    final reachable = await (_repo?.ping() ?? Future.value(false));
    _loadError = !reachable;
    notifyListeners();
    return reachable;
  }

  Future<void> _reload() async {
    final repo = _repo;
    if (repo == null) return;
    try {
      _snapshot = await repo.loadSnapshot();
      _loadError = false;
    } catch (_) {
      _loadError = true;
    }
    notifyListeners();
  }

  /// Runs a mutation, then reloads the snapshot. Returns null on success, or a
  /// human-readable error message the UI can show (e.g. a server validation
  /// rule) when the mutation was rejected. Never throws.
  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
    await _reload();
    return null;
  }

  // ---- Read-only views (unchanged API for the screens) ----
  String get groupName => _snapshot.groupName;
  String get term => _snapshot.term;
  List<Member> get members => _snapshot.members;
  List<MembershipRequest> get membershipRequests =>
      _snapshot.membershipRequests;
  List<Loan> get loans => _snapshot.loans;
  List<SavingEntry> get savings => _snapshot.savings;
  List<Repayment> get repayments => _snapshot.repayments;
  List<Fine> get fines => _snapshot.fines;
  List<Meeting> get meetings => _snapshot.meetings;
  List<Officer> get officers => _snapshot.officers;
  List<Amendment> get amendments => _snapshot.amendments;
  List<Activity> get activities => _snapshot.activities;

  double get cashInHand => _snapshot.cashInHand;
  double get socialFundBalance => _snapshot.socialFundBalance;
  double get savingsCollected => _snapshot.savingsCollected;
  double get repaymentsCollected => _snapshot.repaymentsCollected;
  double get finesCollected => _snapshot.finesCollected;
  double get loansDisbursed => _snapshot.loansDisbursed;
  double get meetingExpense => _snapshot.meetingExpense;
  double get otherExpense => _snapshot.otherExpense;
  double get interestEarned => _snapshot.interestEarned;
  int get meetingsHeld => _snapshot.meetingsHeld;

  List<Loan> get ongoingLoans =>
      _snapshot.loans.where((l) => l.status == LoanStatus.ongoing).toList();

  /// Pending loan applications awaiting an officer's approval.
  List<Loan> get loanRequests =>
      _snapshot.loans.where((l) => l.status == LoanStatus.request).toList();

  List<MembershipRequest> get pendingMembershipRequests => _snapshot
      .membershipRequests
      .where((r) => r.status == MembershipRequestStatus.pending)
      .toList();

  /// This loan's repayments, newest first — its repayment history.
  List<Repayment> repaymentsForLoan(String loanId) {
    final list = _snapshot.repayments.where((r) => r.loanId == loanId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double get totalSavings =>
      _snapshot.members.fold(0.0, (sum, m) => sum + m.savings);
  double get activeLoans => _snapshot.loans
      .where((l) => l.status == LoanStatus.ongoing)
      .fold(0.0, (s, l) => s + l.balance);
  int get membersCount => _snapshot.members.length;
  int get totalShares => _snapshot.members.fold(0, (sum, m) => sum + m.shares);
  double get shareCapital => totalShares * _snapshot.shareValue;
  double get distributableProfit => interestEarned + finesCollected;
  double get totalIncome =>
      savingsCollected + repaymentsCollected + finesCollected;
  double get totalExpense => loansDisbursed + meetingExpense + otherExpense;

  Member? memberById(String id) {
    for (final m in _snapshot.members) {
      if (m.id == id) return m;
    }
    return null;
  }

  bool get _currentMemberIsChairperson {
    final me = currentMember;
    if (me == null) return false;
    final myPhone = _normPhone(me.phone);
    for (final officer in _snapshot.officers) {
      if (officer.role != OfficerRole.chairperson) continue;
      if (myPhone.isNotEmpty && _normPhone(officer.phone) == myPhone) {
        return true;
      }
      if (officer.name.trim().toLowerCase() == me.name.trim().toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  static String _normPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length > 9 ? digits.substring(digits.length - 9) : digits;
  }

  // ---- Mutations: write rows, then re-derive the snapshot ----

  Future<String?> addMember({
    required String name,
    required String phone,
    required int shares,
  }) async {
    if (_repo == null) return 'Not connected.';
    if (name.trim().isEmpty) return 'Name is required.';
    return _run(() => _repo!
        .insertMember(name: name.trim(), phone: phone.trim(), shares: shares));
  }

  Future<String?> requestMembership({
    required String name,
    required String phone,
    required int shares,
  }) async {
    if (_repo == null) return 'Not connected.';
    if (name.trim().isEmpty) return 'Name is required.';
    try {
      await _repo!.requestMembership(
        name: name.trim(),
        phone: phone.trim(),
        shares: shares,
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> approveMembershipRequest(String id) async {
    if (_repo == null) return 'Not connected.';
    return _run(() => _repo!.approveMembershipRequest(id));
  }

  Future<String?> rejectMembershipRequest(String id) async {
    if (_repo == null) return 'Not connected.';
    return _run(() => _repo!.rejectMembershipRequest(id));
  }

  /// Admin: suspend or reactivate a member's login. Returns null on success or
  /// an error message the caller can show.
  Future<String?> setMemberActive(String id, bool active) async {
    if (_repo == null) return 'Not connected.';
    return _run(() => _repo!.setMemberActive(id: id, active: active));
  }

  /// Admin: permanently deletes a member and all their records. Refuses while
  /// the member still owes the group money (an outstanding loan balance), so a
  /// live debt can't be erased by accident. Returns null on success or an error
  /// message for the caller to show.
  Future<String?> deleteMember(String id) async {
    if (_repo == null) return 'Not connected.';
    final member = memberById(id);
    if (member != null && member.loanBalance > 0) {
      return 'delete_member_has_loan';
    }
    return _run(() => _repo!.deleteMember(id));
  }

  /// Admin: renames a leadership office bearer. Guarded here as well as in the
  /// UI so the restriction holds even if a caller slips through.
  /// Returns null on success or an error message key for the caller to show.
  Future<String?> updateOfficerName(String officerId, String name) async {
    if (_repo == null) return 'Not connected.';
    if (!isAdmin) return 'admin_only';
    if (name.trim().isEmpty) return 'name_required';
    return _run(() => _repo!.updateOfficerName(id: officerId, name: name.trim()));
  }

  /// Admin: appoints an office bearer for this group. Guarded here as well as
  /// in the UI. Returns null on success or an error message key.
  Future<String?> addOfficer({
    required String name,
    required String phone,
    required OfficerRole role,
  }) async {
    if (_repo == null) return 'Not connected.';
    if (!isAdmin && _snapshot.officers.isNotEmpty) return 'admin_only';
    if (name.trim().isEmpty) return 'name_required';
    final error = await _run(() => _repo!
        .addOfficer(name: name.trim(), phone: phone.trim(), role: role.name));
    if (error == null && currentMember != null) {
      final currentPhone = currentMember!.phone.replaceAll(RegExp(r'\D'), '');
      final assignedPhone = phone.replaceAll(RegExp(r'\D'), '');
      if (currentPhone.endsWith(assignedPhone) ||
          assignedPhone.endsWith(currentPhone)) {
        _sessionRole = MemberRole.admin;
        notifyListeners();
      }
    }
    return error;
  }

  /// Admin: removes an office bearer from this group.
  Future<String?> removeOfficer(String officerId) async {
    if (_repo == null) return 'Not connected.';
    if (!isAdmin) return 'admin_only';
    return _run(() => _repo!.removeOfficer(officerId));
  }

  Future<String?> addSaving({
    required String memberId,
    required double amount,
    required DateTime date,
    required SavingType type,
    required String method,
  }) async {
    if (_repo == null) return 'Not connected.';
    if (amount <= 0) return 'Amount must be greater than zero.';
    return _run(() => _repo!.insertSaving(
        memberId: memberId,
        amount: amount,
        date: date,
        type: type,
        method: method));
  }

  Future<String?> giveLoan({
    required String memberId,
    required double principal,
    required double interestRate,
    required int durationMonths,
    required DateTime dueDate,
    List<String> guarantorIds = const [],
  }) async {
    if (_repo == null) return 'Not connected.';
    if (principal <= 0) return 'Loan amount must be greater than zero.';
    return _run(() => _repo!.insertLoan(
          memberId: memberId,
          principal: principal,
          interestRate: interestRate,
          durationMonths: durationMonths,
          dueDate: dueDate,
          guarantorIds: guarantorIds,
        ));
  }

  /// A member applies for a loan for themselves. Recorded as a pending
  /// 'request' for an officer to approve/disburse later.
  Future<String?> requestLoan({
    required String memberId,
    required double principal,
    required double interestRate,
    required int durationMonths,
    required DateTime dueDate,
    List<String> guarantorIds = const [],
  }) async {
    if (_repo == null) return 'Not connected.';
    if (principal <= 0) return 'Loan amount must be greater than zero.';
    return _run(() => _repo!.insertLoan(
          memberId: memberId,
          principal: principal,
          interestRate: interestRate,
          durationMonths: durationMonths,
          dueDate: dueDate,
          guarantorIds: guarantorIds,
          asRequest: true,
        ));
  }

  /// Officer approves a pending request: the loan becomes an active (ongoing)
  /// disbursement.
  Future<String?> approveLoan(String loanId) async {
    if (_repo == null) return 'Not connected.';
    return _run(() => _repo!.approveLoan(loanId));
  }

  /// Officer declines a pending request. The row is kept (as 'rejected') so the
  /// application history is preserved.
  Future<String?> rejectLoan(String loanId) async {
    if (_repo == null) return 'Not connected.';
    return _run(() => _repo!.rejectLoan(loanId));
  }

  Future<String?> repayLoan({
    required String loanId,
    required double amount,
    required DateTime date,
    String method = 'cash',
  }) async {
    if (_repo == null) return 'Not connected.';
    if (amount <= 0) return 'Amount must be greater than zero.';
    return _run(() => _repo!.insertRepayment(
        loanId: loanId, amount: amount, date: date, method: method));
  }

  Future<String?> addFine({
    required String memberId,
    required String reason,
    required double amount,
    required DateTime date,
    bool paid = false,
  }) async {
    if (_repo == null) return 'Not connected.';
    if (amount <= 0) return 'Amount must be greater than zero.';
    return _run(() => _repo!.insertFine(
        memberId: memberId,
        reason: reason,
        amount: amount,
        date: date,
        paid: paid));
  }

  /// Clears an outstanding penalty (marks the fine paid).
  Future<String?> payFine(String fineId) async {
    if (_repo == null) return 'Not connected.';
    return _run(() => _repo!.payFine(fineId));
  }

  // ---- Constitution amendments (admin-managed) ----

  Future<void> addAmendment(
      {required String title, required String body}) async {
    if (_repo == null || title.trim().isEmpty || body.trim().isEmpty) return;
    await _repo!.addAmendment(title: title.trim(), body: body.trim());
    await _reload();
  }

  Future<void> updateAmendment(
      {required String id, required String title, required String body}) async {
    if (_repo == null || title.trim().isEmpty || body.trim().isEmpty) return;
    await _repo!
        .updateAmendment(id: id, title: title.trim(), body: body.trim());
    await _reload();
  }

  Future<void> deleteAmendment(String id) async {
    if (_repo == null) return;
    await _repo!.deleteAmendment(id);
    await _reload();
  }

  // ---- Meetings & agendas (admin prepares drafts) ----

  /// Upcoming meetings (not yet held), soonest first.
  List<Meeting> get upcomingMeetings {
    final list = _snapshot.meetings.where((m) => m.isUpcoming).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// Past (held) meetings, most recent first.
  List<Meeting> get pastMeetings {
    final list = _snapshot.meetings.where((m) => !m.isUpcoming).toList();
    list.sort((a, b) => b.number.compareTo(a.number));
    return list;
  }

  Meeting? meetingById(String id) {
    for (final m in _snapshot.meetings) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<void> createMeeting({
    required DateTime date,
    String title = '',
    String startTime = '',
    String location = '',
    String period = '',
    String chairperson = '',
    String secretary = '',
  }) async {
    if (_repo == null) return;
    await _repo!.createMeeting(
      date: date,
      title: title,
      startTime: startTime,
      location: location,
      period: period,
      chairperson: chairperson,
      secretary: secretary,
    );
    await _reload();
  }

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
  }) async {
    if (_repo == null) return;
    await _repo!.updateMeeting(
      id: id,
      date: date,
      title: title,
      startTime: startTime,
      location: location,
      period: period,
      chairperson: chairperson,
      secretary: secretary,
      decisions: decisions,
      collections: collections,
      fines: fines,
    );
    await _reload();
  }

  Future<void> setMeetingStatus(String id, MeetingStatus status) async {
    if (_repo == null) return;
    await _repo!.setMeetingStatus(id: id, status: status.name);
    await _reload();
  }

  Future<void> setAttendance({
    required String meetingId,
    required String memberId,
    required AttendanceStatus status,
  }) async {
    if (_repo == null) return;
    await _repo!.setAttendance(
        meetingId: meetingId, memberId: memberId, status: status.name);
    await _reload();
  }

  Future<void> addMinute(
      {required String meetingId, required String text}) async {
    if (_repo == null || text.trim().isEmpty) return;
    await _repo!.addMinute(meetingId: meetingId, text: text.trim());
    await _reload();
  }

  Future<void> deleteMinute(String id) async {
    if (_repo == null) return;
    await _repo!.deleteMinute(id);
    await _reload();
  }

  Future<void> addAction({
    required String meetingId,
    required String task,
    String responsible = '',
    DateTime? dueDate,
  }) async {
    if (_repo == null || task.trim().isEmpty) return;
    await _repo!.addAction(
        meetingId: meetingId,
        task: task.trim(),
        responsible: responsible.trim(),
        dueDate: dueDate);
    await _reload();
  }

  Future<void> toggleAction({required String id, required bool done}) async {
    if (_repo == null) return;
    await _repo!.toggleAction(id: id, done: done);
    await _reload();
  }

  Future<void> deleteAction(String id) async {
    if (_repo == null) return;
    await _repo!.deleteAction(id);
    await _reload();
  }

  Future<void> addAgenda(
      {required String meetingId, required String text}) async {
    if (_repo == null || text.trim().isEmpty) return;
    await _repo!.addAgenda(meetingId: meetingId, text: text.trim());
    await _reload();
  }

  Future<void> toggleAgenda({required String id, required bool done}) async {
    if (_repo == null) return;
    await _repo!.toggleAgenda(id: id, done: done);
    await _reload();
  }

  Future<void> deleteAgenda(String id) async {
    if (_repo == null) return;
    await _repo!.deleteAgenda(id);
    await _reload();
  }

  /// All unpaid penalties across the group, newest first.
  List<Fine> get outstandingFines {
    final list = _snapshot.fines.where((f) => !f.paid).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}
