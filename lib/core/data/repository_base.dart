import '../models/models.dart';
import '../state/app_state.dart';

/// Thrown by [ApiRepository] when the server rejects a request with a message
/// (e.g. a validation rule like "Loan exceeds this member's limit…"). Carries
/// the human-readable [message] so the UI can show exactly why it failed. The
/// offline (Drift) repository does not throw this.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, {this.statusCode = 0});
  @override
  String toString() => message;
}

/// The identity returned by a successful [Repository.login]: who the member is
/// and which panel (admin vs member) they should see.
class AuthResult {
  final String memberId;
  final String name;
  final MemberRole role;

  /// The session token to send as `Authorization: Bearer <token>` on later
  /// requests (online/API mode). Null in offline mode, where there is no server.
  final String? token;

  /// Which group this member was authenticated into. Online, the server scopes
  /// the member to a single group and may return its id/name here so the app
  /// can display it authoritatively. Offline, the group is implied by which
  /// database matched, so these are typically null.
  final String? groupId;
  final String? groupName;

  const AuthResult({
    required this.memberId,
    required this.name,
    required this.role,
    this.token,
    this.groupId,
    this.groupName,
  });
}

/// The storage contract the app depends on. Both [DriftRepository] (offline
/// SQLite) and ApiRepository (online PostgreSQL via an HTTP backend) implement
/// this, so the rest of the app never needs to know which one is in use.
abstract class Repository {
  /// Ensures sample/initial data exists (no-op if already populated).
  Future<void> seedIfEmpty();

  /// Lightweight, unauthenticated reachability check used at startup (before
  /// login) to decide whether to show the connection banner. Returns true if
  /// the backend answered. Offline mode always returns true.
  Future<bool> ping();

  /// Authenticates a member by phone + password/PIN. Returns their identity and
  /// role (and, online, a session token) on success, or null if the credentials
  /// don't match. On success the repository also retains the token internally so
  /// subsequent calls are authenticated.
  Future<AuthResult?> login({required String phone, required String password});

  /// Ends the current session: revokes the token server-side (online) and clears
  /// it locally so later calls are no longer authenticated. Never throws.
  Future<void> endSession();

  /// Reads everything back as a fully-derived snapshot.
  Future<Snapshot> loadSnapshot();

  Future<void> insertMember({
    required String name,
    required String phone,
    required int shares,
  });

  Future<void> requestMembership({
    required String name,
    required String phone,
    required int shares,
  });

  Future<void> approveMembershipRequest(String id);

  Future<void> rejectMembershipRequest(String id);

  /// Admin: suspends ([active] == false) or reactivates a member. A suspended
  /// member keeps their records but can no longer log in.
  Future<void> setMemberActive({required String id, required bool active});

  /// Admin: permanently removes a member and all of their records (savings,
  /// loans, repayments, fines, guarantees, officer post). Irreversible — unlike
  /// [setMemberActive], nothing is kept.
  Future<void> deleteMember(String id);

  /// Super-admin: renames a leadership office bearer (identified by its officer
  /// row [id]). Only the platform super admin may change who leads a group.
  Future<void> updateOfficerName({required String id, required String name});

  /// Super-admin: appoints a leadership office bearer. [role] is an
  /// [OfficerRole] name (chairperson|secretary|treasurer|keyHolder|mobilizer).
  Future<void> addOfficer(
      {required String name, required String phone, required String role});

  /// Super-admin: removes an office bearer (by officer row [id]).
  Future<void> removeOfficer(String id);

  Future<void> insertSaving({
    required String memberId,
    required double amount,
    required DateTime date,
    required SavingType type,
    required String method,
  });

  Future<void> insertLoan({
    required String memberId,
    required double principal,
    required double interestRate,
    required int durationMonths,
    required DateTime dueDate,
    List<String> guarantorIds,
    // When true the loan is recorded as a pending 'request' (a member applying
    // for a loan) instead of an 'ongoing' disbursement (an officer giving one).
    bool asRequest,
  });

  Future<void> insertRepayment({
    required String loanId,
    required double amount,
    required DateTime date,
    String method,
  });

  /// Approves a pending loan request (status request -> ongoing).
  Future<void> approveLoan(String loanId);

  /// Rejects a pending loan request (status request -> rejected; row kept).
  Future<void> rejectLoan(String loanId);

  Future<void> insertFine({
    required String memberId,
    required String reason,
    required double amount,
    required DateTime date,
    // New penalties default to unpaid (owed); set true to record one already
    // paid. Clear an outstanding one later with [payFine].
    bool paid,
  });

  /// Marks an outstanding penalty as paid (cleared).
  Future<void> payFine(String fineId);

  /// Adds a new constitution amendment.
  Future<void> addAmendment({required String title, required String body});

  /// Edits an existing amendment's title/body.
  Future<void> updateAmendment(
      {required String id, required String title, required String body});

  /// Removes an amendment.
  Future<void> deleteAmendment(String id);

  /// Creates a new (draft) meeting with the given details.
  Future<void> createMeeting({
    required DateTime date,
    required String title,
    required String startTime,
    required String location,
    required String period,
    required String chairperson,
    required String secretary,
  });

  /// Edits a meeting's details (metadata + decisions/collections/fines).
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
  });

  /// Moves a meeting through draft -> open -> closed.
  Future<void> setMeetingStatus({required String id, required String status});

  /// Marks a member's attendance for a meeting.
  Future<void> setAttendance({
    required String meetingId,
    required String memberId,
    required String status,
  });

  Future<void> addMinute({required String meetingId, required String text});
  Future<void> deleteMinute(String id);

  Future<void> addAction({
    required String meetingId,
    required String task,
    required String responsible,
    required DateTime? dueDate,
  });
  Future<void> toggleAction({required String id, required bool done});
  Future<void> deleteAction(String id);

  /// Adds an agenda item to a meeting.
  Future<void> addAgenda({required String meetingId, required String text});

  /// Ticks an agenda step done/undone.
  Future<void> toggleAgenda({required String id, required bool done});

  /// Removes an agenda item.
  Future<void> deleteAgenda(String id);
}
