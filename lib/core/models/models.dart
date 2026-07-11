/// Plain data models for the VICOBA app. These are serialized to JSON and
/// persisted on-device (see core/data/repository.dart) so the app works fully
/// offline. Field names map to the planned PostgreSQL tables (Users, Members,
/// Savings, Loans, Fines, Meetings, ...).
library;

enum MemberStatus { active, borrower }

/// Which panel a logged-in member sees: [admin] (office bearers — full group
/// management) or [member] (regular self-service: own savings/loans + requests).
enum MemberRole { admin, member }

enum LoanStatus { ongoing, paid, request, rejected }

enum TxnType { income, expense }

enum SavingType { regular, special, social }

/// VICOBA leadership roles. Key-holders (washika funguo) hold the three locks
/// of the cash box and are deliberately separate from the main office bearers.
enum OfficerRole { chairperson, secretary, treasurer, keyHolder, mobilizer }

/// Keeps the model layer free of Flutter imports — screens map this to icons.
enum IconKey { savings, loan, fine, meeting }

/// Resolves an enum from its [name], falling back to [fallback] for unknown or
/// null values (so older saved data never crashes the app).
T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

/// Returns the member matching [id] from [members], or the first member, or
/// null if the list is empty. Used by data-entry screens to keep the selected
/// member valid as the underlying list changes.
Member? pickMember(List<Member> members, String? id) {
  for (final m in members) {
    if (m.id == id) return m;
  }
  return members.isNotEmpty ? members.first : null;
}

/// Builds two-letter initials from a person's name (e.g. "Asha Juma" -> "AJ").
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  String firstChar(String s) => s.isEmpty ? '' : s.substring(0, 1);
  if (parts.length == 1) return firstChar(parts.first).toUpperCase();
  return (firstChar(parts.first) + firstChar(parts[1])).toUpperCase();
}

class Member {
  final String id;
  final String name;
  final String phone;
  final int shares;
  final MemberStatus status;
  final MemberRole role;
  final double savings;
  final double loanBalance;
  final double fines;
  final DateTime joinedOn;

  /// Whether the member may sign in. Admin can suspend (false) or reactivate
  /// (true) a member; a suspended member keeps all their records but is locked
  /// out at login. Defaults to active.
  final bool active;

  const Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.shares,
    required this.status,
    this.role = MemberRole.member,
    required this.savings,
    required this.loanBalance,
    required this.fines,
    required this.joinedOn,
    this.active = true,
  });

  String get initials => initialsOf(name);

  Member copyWith({
    int? shares,
    MemberStatus? status,
    double? savings,
    double? loanBalance,
    double? fines,
    bool? active,
  }) {
    return Member(
      id: id,
      name: name,
      phone: phone,
      shares: shares ?? this.shares,
      status: status ?? this.status,
      role: role,
      savings: savings ?? this.savings,
      loanBalance: loanBalance ?? this.loanBalance,
      fines: fines ?? this.fines,
      joinedOn: joinedOn,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'shares': shares,
        'status': status.name,
        'role': role.name,
        'savings': savings,
        'loanBalance': loanBalance,
        'fines': fines,
        'joinedOn': joinedOn.millisecondsSinceEpoch,
        'active': active,
      };

  factory Member.fromJson(Map<String, dynamic> j) => Member(
        id: j['id'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String,
        shares: (j['shares'] as num).toInt(),
        status: _enumByName(MemberStatus.values, j['status'], MemberStatus.active),
        role: _enumByName(MemberRole.values, j['role'], MemberRole.member),
        savings: (j['savings'] as num).toDouble(),
        loanBalance: (j['loanBalance'] as num).toDouble(),
        fines: (j['fines'] as num).toDouble(),
        joinedOn:
            DateTime.fromMillisecondsSinceEpoch((j['joinedOn'] as num).toInt()),
        active: j['active'] != false,
      );
}

enum MembershipRequestStatus { pending, approved, rejected }

class MembershipRequest {
  final String id;
  final String name;
  final String phone;
  final int shares;
  final MembershipRequestStatus status;
  final DateTime requestedOn;

  const MembershipRequest({
    required this.id,
    required this.name,
    required this.phone,
    required this.shares,
    required this.status,
    required this.requestedOn,
  });

  String get initials => initialsOf(name);

  factory MembershipRequest.fromJson(Map<String, dynamic> j) =>
      MembershipRequest(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        shares: (j['shares'] as num?)?.toInt() ?? 0,
        status: _enumByName(MembershipRequestStatus.values, j['status'],
            MembershipRequestStatus.pending),
        requestedOn: DateTime.fromMillisecondsSinceEpoch(
            (j['requestedOn'] as num?)?.toInt() ?? 0),
      );
}

/// A group office bearer (leadership / committee member).
class Officer {
  final String id;
  final String name;
  final OfficerRole role;
  final String phone;

  const Officer({
    this.id = '',
    required this.name,
    required this.role,
    required this.phone,
  });

  String get initials => initialsOf(name);

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'role': role.name, 'phone': phone};

  factory Officer.fromJson(Map<String, dynamic> j) => Officer(
        id: j['id'] as String? ?? '',
        name: j['name'] as String,
        role: _enumByName(OfficerRole.values, j['role'], OfficerRole.mobilizer),
        phone: j['phone'] as String,
      );
}

/// One entry in a loan's lifecycle history (from the audit trail): who did what,
/// when — e.g. requested, approved, rejected, disbursed.
class LoanEvent {
  final String action; // request | approve | reject | disburse
  final String actorName;
  final DateTime date;

  const LoanEvent({
    required this.action,
    required this.actorName,
    required this.date,
  });

  factory LoanEvent.fromJson(Map<String, dynamic> j) => LoanEvent(
        action: (j['action'] as String?) ?? '',
        actorName: (j['actorName'] as String?) ?? '',
        date: DateTime.fromMillisecondsSinceEpoch(
            (j['date'] as num?)?.toInt() ?? 0),
      );
}

class Loan {
  final String id;
  final String memberName;
  final double principal;
  final double balance;
  final DateTime dueDate;
  final LoanStatus status;
  final double interestRate;
  final int durationMonths;

  /// Names of the members guaranteeing this loan (wadhamini).
  final List<String> guarantors;

  /// The loan's lifecycle events, oldest first (request → approval, etc.).
  final List<LoanEvent> history;

  const Loan({
    required this.id,
    required this.memberName,
    required this.principal,
    required this.balance,
    required this.dueDate,
    required this.status,
    this.interestRate = 10,
    this.durationMonths = 3,
    this.guarantors = const [],
    this.history = const [],
  });

  /// Flat monthly interest charged over the loan's term:
  /// principal × rate% × months. (A 300,000 loan at 10%/month for 3 months
  /// earns 90,000 interest.)
  double get interest => principal * (interestRate / 100) * durationMonths;

  /// What the borrower must repay in total — principal plus all interest.
  double get totalDue => principal + interest;

  /// How much has been repaid so far (derived from [totalDue] and the
  /// outstanding [balance], which the repository computes from repayment rows).
  double get repaid => (totalDue - balance).clamp(0, totalDue).toDouble();

  /// Fraction of the total due that has been repaid, 0–1 (for progress bars).
  double get repaidFraction =>
      totalDue <= 0 ? 0 : (repaid / totalDue).clamp(0, 1).toDouble();

  /// True when an active loan has passed its due date with money still owing.
  bool get isOverdue =>
      status == LoanStatus.ongoing &&
      balance > 0 &&
      dueDate.isBefore(DateTime.now());

  /// Whole days past the due date (0 if not overdue).
  int get daysOverdue =>
      isOverdue ? DateTime.now().difference(dueDate).inDays : 0;

  /// Whole days until the due date (negative once past due).
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  Loan copyWith({double? balance, LoanStatus? status}) => Loan(
        id: id,
        memberName: memberName,
        principal: principal,
        balance: balance ?? this.balance,
        dueDate: dueDate,
        status: status ?? this.status,
        interestRate: interestRate,
        durationMonths: durationMonths,
        guarantors: guarantors,
        history: history,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberName': memberName,
        'principal': principal,
        'balance': balance,
        'dueDate': dueDate.millisecondsSinceEpoch,
        'status': status.name,
        'interestRate': interestRate,
        'durationMonths': durationMonths,
      };

  factory Loan.fromJson(Map<String, dynamic> j) => Loan(
        id: j['id'] as String,
        memberName: j['memberName'] as String,
        principal: (j['principal'] as num).toDouble(),
        balance: (j['balance'] as num).toDouble(),
        dueDate:
            DateTime.fromMillisecondsSinceEpoch((j['dueDate'] as num).toInt()),
        status: _enumByName(LoanStatus.values, j['status'], LoanStatus.ongoing),
        interestRate: (j['interestRate'] as num?)?.toDouble() ?? 10,
        durationMonths: (j['durationMonths'] as num?)?.toInt() ?? 3,
        guarantors: ((j['guarantors'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        history: ((j['history'] as List?) ?? const [])
            .map((e) => LoanEvent.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

/// One repayment made against a loan. Kept as its own row so each loan's
/// repayment history (and the running deduction from its balance) is preserved.
class Repayment {
  final String loanId;
  final String memberName;
  final double amount;
  final DateTime date;
  final String method;

  const Repayment({
    required this.loanId,
    required this.memberName,
    required this.amount,
    required this.date,
    this.method = 'cash',
  });

  Map<String, dynamic> toJson() => {
        'loanId': loanId,
        'memberName': memberName,
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'method': method,
      };

  factory Repayment.fromJson(Map<String, dynamic> j) => Repayment(
        loanId: j['loanId'] as String? ?? '',
        memberName: j['memberName'] as String? ?? '',
        amount: (j['amount'] as num).toDouble(),
        date: DateTime.fromMillisecondsSinceEpoch((j['date'] as num).toInt()),
        method: j['method'] as String? ?? 'cash',
      );
}

class SavingEntry {
  final String memberName;
  final double amount;
  final DateTime date;
  final String method;
  final SavingType type;

  const SavingEntry({
    required this.memberName,
    required this.amount,
    required this.date,
    required this.method,
    this.type = SavingType.regular,
  });

  Map<String, dynamic> toJson() => {
        'memberName': memberName,
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'method': method,
        'type': type.name,
      };

  factory SavingEntry.fromJson(Map<String, dynamic> j) => SavingEntry(
        memberName: j['memberName'] as String,
        amount: (j['amount'] as num).toDouble(),
        date: DateTime.fromMillisecondsSinceEpoch((j['date'] as num).toInt()),
        method: j['method'] as String,
        type: _enumByName(SavingType.values, j['type'], SavingType.regular),
      );
}

class Fine {
  final String id;
  final String memberName;
  final String reason;
  final double amount;
  final DateTime date;
  final bool paid;

  const Fine({
    this.id = '',
    required this.memberName,
    required this.reason,
    required this.amount,
    required this.date,
    this.paid = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberName': memberName,
        'reason': reason,
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'paid': paid,
      };

  factory Fine.fromJson(Map<String, dynamic> j) => Fine(
        id: j['id'] as String? ?? '',
        memberName: j['memberName'] as String,
        reason: j['reason'] as String,
        amount: (j['amount'] as num).toDouble(),
        date: DateTime.fromMillisecondsSinceEpoch((j['date'] as num).toInt()),
        paid: j['paid'] as bool? ?? false,
      );
}

/// Where a meeting is in its lifecycle.
enum MeetingStatus { draft, open, closed }

/// How a member attended a meeting.
enum AttendanceStatus { present, absent, excused }

/// A member's attendance for a meeting.
class Attendance {
  final String memberId;
  final String memberName;
  final AttendanceStatus status;

  const Attendance({
    required this.memberId,
    required this.memberName,
    required this.status,
  });

  factory Attendance.fromJson(Map<String, dynamic> j) => Attendance(
        memberId: j['memberId'] as String? ?? '',
        memberName: j['memberName'] as String? ?? '',
        status: _enumByName(
            AttendanceStatus.values, j['status'], AttendanceStatus.present),
      );
}

/// A minute note (topic discussed / decision recorded).
class MinuteItem {
  final String id;
  final String text;
  const MinuteItem({required this.id, required this.text});

  factory MinuteItem.fromJson(Map<String, dynamic> j) => MinuteItem(
        id: j['id'] as String? ?? '',
        text: j['text'] as String? ?? '',
      );
}

/// A follow-up action item with a responsible person and due date.
class ActionItem {
  final String id;
  final String task;
  final String responsible;
  final DateTime? dueDate;
  final bool done;

  const ActionItem({
    required this.id,
    required this.task,
    required this.responsible,
    required this.dueDate,
    required this.done,
  });

  factory ActionItem.fromJson(Map<String, dynamic> j) {
    final due = (j['dueDate'] as num?)?.toInt() ?? 0;
    return ActionItem(
      id: j['id'] as String? ?? '',
      task: j['task'] as String? ?? '',
      responsible: j['responsible'] as String? ?? '',
      dueDate: due > 0 ? DateTime.fromMillisecondsSinceEpoch(due) : null,
      done: j['done'] as bool? ?? false,
    );
  }
}

/// One agenda item / step drafted for a meeting, ticked off as it's completed.
class AgendaItem {
  final String id;
  final String text;
  final bool done;

  const AgendaItem({required this.id, required this.text, this.done = false});

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'done': done};

  factory AgendaItem.fromJson(Map<String, dynamic> j) => AgendaItem(
        id: j['id'] as String? ?? '',
        text: j['text'] as String? ?? '',
        done: j['done'] as bool? ?? false,
      );
}

class Meeting {
  final String id;
  final int number;
  final DateTime date;
  final int attended;
  final int total;
  final int decisions;
  final double collections;
  final double fines;
  final String title;
  final String startTime;
  final String location;
  final String period;
  final String chairperson;
  final String secretary;
  final MeetingStatus status;
  final List<AgendaItem> agenda;
  final List<Attendance> attendance;
  final List<MinuteItem> minutes;
  final List<ActionItem> actions;

  const Meeting({
    this.id = '',
    required this.number,
    required this.date,
    required this.attended,
    required this.total,
    required this.decisions,
    required this.collections,
    required this.fines,
    this.title = '',
    this.startTime = '',
    this.location = '',
    this.period = '',
    this.chairperson = '',
    this.secretary = '',
    this.status = MeetingStatus.closed,
    this.agenda = const [],
    this.attendance = const [],
    this.minutes = const [],
    this.actions = const [],
  });

  double get attendanceRate => total == 0 ? 0 : attended / total;

  /// Number of agenda items (driven by the drafted list).
  int get agendaItems => agenda.length;

  /// A meeting is "upcoming" (current business) until it is closed.
  bool get isUpcoming => status != MeetingStatus.closed;

  int get presentCount =>
      attendance.where((a) => a.status == AttendanceStatus.present).length;
  int get absentCount =>
      attendance.where((a) => a.status == AttendanceStatus.absent).length;
  int get excusedCount =>
      attendance.where((a) => a.status == AttendanceStatus.excused).length;

  /// Quorum is reached when at least half the members are present.
  bool quorumReached(int membersCount) =>
      membersCount > 0 && presentCount * 2 >= membersCount;

  factory Meeting.fromJson(Map<String, dynamic> j) => Meeting(
        id: j['id'] as String? ?? '',
        number: (j['number'] as num).toInt(),
        date: DateTime.fromMillisecondsSinceEpoch((j['date'] as num).toInt()),
        attended: (j['attended'] as num).toInt(),
        total: (j['total'] as num).toInt(),
        decisions: (j['decisions'] as num).toInt(),
        collections: (j['collections'] as num).toDouble(),
        fines: (j['fines'] as num).toDouble(),
        title: j['title'] as String? ?? '',
        startTime: j['startTime'] as String? ?? '',
        location: j['location'] as String? ?? '',
        period: j['period'] as String? ?? '',
        chairperson: j['chairperson'] as String? ?? '',
        secretary: j['secretary'] as String? ?? '',
        status: _enumByName(
            MeetingStatus.values, j['status'], MeetingStatus.draft),
        agenda: ((j['agenda'] as List?) ?? const [])
            .map((e) => AgendaItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        attendance: ((j['attendance'] as List?) ?? const [])
            .map((e) => Attendance.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        minutes: ((j['minutes'] as List?) ?? const [])
            .map((e) => MinuteItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        actions: ((j['actions'] as List?) ?? const [])
            .map((e) => ActionItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

/// A constitution amendment — a rule change the group adds or edits over time
/// (the eight built-in articles are defined in the app's string table).
class Amendment {
  final String id;
  final String title;
  final String body;
  final DateTime date;

  const Amendment({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'date': date.millisecondsSinceEpoch,
      };

  factory Amendment.fromJson(Map<String, dynamic> j) => Amendment(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        date: DateTime.fromMillisecondsSinceEpoch((j['date'] as num).toInt()),
      );
}

class Transaction {
  final String label;
  final double amount;
  final DateTime date;
  final TxnType type;

  const Transaction({
    required this.label,
    required this.amount,
    required this.date,
    required this.type,
  });
}

class Activity {
  final String title;
  final double amount;
  final IconKey icon;

  const Activity({
    required this.title,
    required this.amount,
    required this.icon,
  });

  Map<String, dynamic> toJson() =>
      {'title': title, 'amount': amount, 'icon': icon.name};

  factory Activity.fromJson(Map<String, dynamic> j) => Activity(
        title: j['title'] as String,
        amount: (j['amount'] as num).toDouble(),
        icon: _enumByName(IconKey.values, j['icon'], IconKey.savings),
      );
}
