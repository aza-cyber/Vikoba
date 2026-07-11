/// Default VICOBA group configuration (the constitution rules) applied to a new
/// group. These are real, editable defaults — not sample data. Actual members,
/// savings, loans, meetings etc. are all entered by users.
class GroupDefaults {
  GroupDefaults._();

  static const double shareValue = 5000; // TZS per share
  static const int minSharesPerMeeting = 1;
  static const int maxSharesPerMeeting = 5;
  static const double socialFundPerMeeting = 1000; // TZS per member per meeting
  static const double monthlyInterestRate = 10; // % per month on loans
  static const int loanMultiplier = 3; // borrow up to 3x your share value
  static const int maxRepaymentMonths = 4;
  static const int requiredGuarantors = 2;
  static const int cycleMonths = 12; // one VICOBA cycle
  static const int cycleMonthsElapsed = 0; // a fresh cycle starts at 0
  static const int minMembers = 15;
  static const int maxMembers = 30;
}
