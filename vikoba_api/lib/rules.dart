/// Pure, I/O-free business logic for the VICOBA API.
///
/// Everything here is deterministic and dependency-light so it can be unit
/// tested directly (see `test/rules_test.dart`). `bin/server.dart` delegates to
/// these functions, so the tests exercise the same code the server runs.
library;

import 'dart:math';

// --------------------------------------------------------------- coercion
/// Money columns are NUMERIC, which the postgres driver decodes to a String (to
/// preserve precision). This coerces either representation — legacy DOUBLE
/// (num) or NUMERIC (String) — to a double. Without the String branch, every
/// NUMERIC balance would silently read as 0.
double coerceDouble(Object? v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

/// Coerces a numeric/string value to an int (0 for null/garbage).
int coerceInt(Object? v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

/// Whole-shilling money formatting for messages (TZS has no subunits).
String tzs(double v) => 'TZS ${v.toStringAsFixed(0)}';

// --------------------------------------------------------------- ids
final _rng = Random.secure();

/// An RFC-4122 version-4 (random) UUID, e.g. "3f2a1b4c-5d6e-4f70-8a91-...".
String uuidV4() {
  final b = List<int>.generate(16, (_) => _rng.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant 1
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).toList();
  return '${h.sublist(0, 4).join()}-${h.sublist(4, 6).join()}-'
      '${h.sublist(6, 8).join()}-${h.sublist(8, 10).join()}-'
      '${h.sublist(10).join()}';
}

/// A 256-bit cryptographically-random opaque token, hex-encoded (session tokens).
String randomToken() {
  final bytes = List<int>.generate(32, (_) => _rng.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// A cryptographically-random numeric one-time passcode of [digits] digits
/// (default 6), zero-padded so it is always exactly that length — e.g.
/// "042317". Used for SMS login verification.
String otpCode({int digits = 6}) {
  var bound = 1;
  for (var i = 0; i < digits; i++) {
    bound *= 10;
  }
  return _rng.nextInt(bound).toString().padLeft(digits, '0');
}

// --------------------------------------------------------------- loans
/// Flat monthly interest: a borrower owes principal + principal×rate%×months.
double loanTotalDue(double principal, double rate, int months) =>
    principal + principal * (rate / 100) * months;

/// Outstanding balance = total owed minus repayments, never below zero.
double loanBalance(double totalDue, double repaid) =>
    (totalDue - repaid).clamp(0, double.infinity).toDouble();

/// The status the app sees: 'request'/'rejected' are kept as-is; any other loan
/// is 'paid' once its balance hits zero, otherwise 'ongoing'.
String effectiveLoanStatus(String raw, double balance) =>
    (raw == 'request' || raw == 'rejected')
        ? raw
        : (balance <= 0 ? 'paid' : 'ongoing');

/// Enforces the group's loan rules. Returns a human-readable error message if
/// the loan is invalid, or null if it's allowed.
String? validateLoan({
  required double principal,
  required int durationMonths,
  required int shares,
  required double shareValue,
  required int loanMultiplier,
  required int maxRepaymentMonths,
  required int requiredGuarantors,
  required List<String> guarantorIds,
  required String borrowerId,
  required double availableCash,
  required bool isDisbursement,
}) {
  if (principal <= 0) return 'Loan amount must be greater than zero.';
  if (durationMonths <= 0) return 'Repayment duration must be at least 1 month.';
  if (durationMonths > maxRepaymentMonths) {
    return 'Repayment duration cannot exceed $maxRepaymentMonths months.';
  }
  if (shares <= 0) return 'This member holds no shares yet, so cannot borrow.';
  final maxLoan = shares * shareValue * loanMultiplier;
  if (principal > maxLoan) {
    return 'Loan exceeds this member\'s limit of ${tzs(maxLoan)} '
        '($loanMultiplier× the value of their shares).';
  }
  final distinct =
      guarantorIds.where((g) => g.isNotEmpty && g != borrowerId).toSet();
  if (distinct.length < requiredGuarantors) {
    return 'This loan needs at least $requiredGuarantors guarantor(s), '
        'other than the borrower.';
  }
  if (isDisbursement && principal > availableCash) {
    return 'Not enough cash to disburse this loan — available '
        '${tzs(availableCash)}.';
  }
  return null;
}

/// Validates a group's editable rulebook before it is persisted. Returns a
/// human-readable error if any value is out of range, or null if the whole set
/// is acceptable. Kept pure so `POST /settings/rules` and its tests share it.
String? validateRules({
  required double shareValue,
  required int minShares,
  required int maxShares,
  required double interestRatePct,
  required int loanMultiplier,
  required int loanDurationMonths,
  required int maxRepaymentMonths,
  required int requiredGuarantors,
  required int quorumPercent,
}) {
  if (shareValue <= 0) return 'Share value must be greater than zero.';
  if (minShares < 0 || maxShares < 0) return 'Share counts cannot be negative.';
  if (maxShares > 0 && minShares > maxShares) {
    return 'Minimum shares cannot exceed maximum shares.';
  }
  if (interestRatePct < 0) return 'Interest rate cannot be negative.';
  if (loanMultiplier <= 0) return 'Loan multiplier must be at least 1.';
  if (loanDurationMonths <= 0) return 'Loan duration must be at least 1 month.';
  if (maxRepaymentMonths <= 0) {
    return 'Maximum repayment period must be at least 1 month.';
  }
  if (requiredGuarantors < 0) return 'Required guarantors cannot be negative.';
  if (quorumPercent < 0 || quorumPercent > 100) {
    return 'Quorum must be between 0 and 100 percent.';
  }
  return null;
}

// --------------------------------------------------------------- csv
/// Builds an RFC-4180 CSV document from a header row and data rows. Values are
/// stringified; any value containing a comma, quote or newline is quoted and
/// its quotes doubled. Nulls become empty cells.
String toCsv(List<String> headers, List<List<Object?>> rows) {
  String cell(Object? v) {
    final s = v?.toString() ?? '';
    if (s.contains(RegExp('[",\n\r]'))) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  final buf = StringBuffer()..write('${headers.map(cell).join(',')}\r\n');
  for (final r in rows) {
    buf.write('${r.map(cell).join(',')}\r\n');
  }
  return buf.toString();
}

// --------------------------------------------------------------- cash
/// Cash currently in the box: opening cash + money in (savings, social fund,
/// repayments, fines actually paid) − money out (loans disbursed, expenses).
/// The single source of truth for both `/snapshot` and the disbursement guard.
double cashInHand({
  required double openingCash,
  required double savings,
  required double socialFund,
  required double repayments,
  required double finesPaid,
  required double loansDisbursed,
  required double meetingExpense,
  required double otherExpense,
}) =>
    openingCash +
    savings +
    socialFund +
    repayments +
    finesPaid -
    loansDisbursed -
    meetingExpense -
    otherExpense;
