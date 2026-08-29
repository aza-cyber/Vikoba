import 'package:test/test.dart';
import 'package:vikoba_api/rules.dart';

void main() {
  group('coerceDouble (money read as NUMERIC-string or DOUBLE)', () {
    test('parses NUMERIC strings, num, null and garbage', () {
      expect(coerceDouble('5000.00'), 5000.0);
      expect(coerceDouble('1234567.89'), 1234567.89);
      expect(coerceDouble(5000.0), 5000.0);
      expect(coerceDouble(250), 250.0);
      expect(coerceDouble(null), 0.0);
      expect(coerceDouble(''), 0.0);
      expect(coerceDouble('nonsense'), 0.0);
    });
  });

  group('coerceInt', () {
    test('parses num, string, null', () {
      expect(coerceInt(3), 3);
      expect(coerceInt('4'), 4);
      expect(coerceInt(2.9), 2);
      expect(coerceInt(null), 0);
    });
  });

  group('uuidV4', () {
    final re = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
    test('is a well-formed, unique v4', () {
      final seen = <String>{};
      for (var i = 0; i < 5000; i++) {
        final u = uuidV4();
        expect(re.hasMatch(u), isTrue, reason: u);
        seen.add(u);
      }
      expect(seen.length, 5000);
    });
    test('randomToken is 64 hex chars', () {
      expect(randomToken(), matches(RegExp(r'^[0-9a-f]{64}$')));
    });
  });

  group('otpCode (SMS login passcode)', () {
    test('is always exactly the requested number of digits (zero-padded)', () {
      final re = RegExp(r'^\d{6}$');
      var sawLeadingZero = false;
      for (var i = 0; i < 5000; i++) {
        final code = otpCode();
        expect(re.hasMatch(code), isTrue, reason: code);
        if (code.startsWith('0')) sawLeadingZero = true;
      }
      // Over 5000 draws we should hit at least one code in the 0xxxxx range,
      // proving small numbers are padded rather than truncated.
      expect(sawLeadingZero, isTrue);
    });
    test('honours a custom digit count', () {
      expect(otpCode(digits: 4), matches(RegExp(r'^\d{4}$')));
    });
  });

  group('loan balance & status', () {
    test('flat interest: 100k @ 10% x 3 months owes 130k', () {
      expect(loanTotalDue(100000, 10, 3), 130000);
    });
    test('balance never goes below zero', () {
      expect(loanBalance(130000, 40000), 90000);
      expect(loanBalance(130000, 200000), 0);
    });
    test('effective status follows balance, keeps request/rejected', () {
      expect(effectiveLoanStatus('request', 90000), 'request');
      expect(effectiveLoanStatus('rejected', 90000), 'rejected');
      expect(effectiveLoanStatus('ongoing', 90000), 'ongoing');
      expect(effectiveLoanStatus('ongoing', 0), 'paid');
    });
  });

  group('cashInHand', () {
    test('opening + inflows - outflows', () {
      // 10000 + (5000 + 1000 + 2000 + 500) - (3000 + 200 + 100) = 15200
      expect(
        cashInHand(
          openingCash: 10000,
          savings: 5000,
          socialFund: 1000,
          repayments: 2000,
          finesPaid: 500,
          loansDisbursed: 3000,
          meetingExpense: 200,
          otherExpense: 100,
        ),
        15200,
      );
    });
  });

  group('toCsv', () {
    test('renders header + rows', () {
      final csv = toCsv(['a', 'b'], [
        [1, 2],
        [3, 4]
      ]);
      expect(csv, 'a,b\r\n1,2\r\n3,4\r\n');
    });
    test('quotes commas, quotes and newlines; null -> empty', () {
      final csv = toCsv(['name', 'note'], [
        ['Doe, John', 'says "hi"'],
        [null, 'line1\nline2'],
      ]);
      expect(csv,
          'name,note\r\n"Doe, John","says ""hi"""\r\n,"line1\nline2"\r\n');
    });
  });

  group('validateLoan', () {
    // 10 shares x 5000 x 3 = 150,000 limit; 2 guarantors; max 4 months.
    String? call({
      double principal = 100000,
      int durationMonths = 3,
      int shares = 10,
      List<String> guarantors = const ['B', 'C'],
      String borrower = 'A',
      double cash = 1000000,
      bool disburse = true,
    }) =>
        validateLoan(
          principal: principal,
          durationMonths: durationMonths,
          shares: shares,
          shareValue: 5000,
          loanMultiplier: 3,
          maxRepaymentMonths: 4,
          requiredGuarantors: 2,
          guarantorIds: guarantors,
          borrowerId: borrower,
          availableCash: cash,
          isDisbursement: disburse,
        );

    test('a valid loan passes', () => expect(call(), isNull));
    test('rejects zero principal', () => expect(call(principal: 0), isNotNull));
    test('allows exactly the limit', () => expect(call(principal: 150000), isNull));
    test('rejects over the limit', () => expect(call(principal: 150001), isNotNull));
    test('rejects zero duration', () => expect(call(durationMonths: 0), isNotNull));
    test('rejects over max duration', () => expect(call(durationMonths: 5), isNotNull));
    test('rejects a member with no shares', () => expect(call(shares: 0), isNotNull));
    test('rejects too few guarantors', () => expect(call(guarantors: ['B']), isNotNull));
    test('discounts the borrower as guarantor',
        () => expect(call(guarantors: ['A', 'B']), isNotNull));
    test('discounts duplicate guarantors',
        () => expect(call(guarantors: ['B', 'B']), isNotNull));
    test('rejects disbursing more than available cash',
        () => expect(call(principal: 100000, cash: 50000), isNotNull));
    test('a pending request ignores the cash check',
        () => expect(call(principal: 100000, cash: 50000, disburse: false), isNull));
  });

  group('validateRules', () {
    String? call({
      double shareValue = 5000,
      int minShares = 1,
      int maxShares = 5,
      double interestRatePct = 10,
      int loanMultiplier = 3,
      int loanDurationMonths = 3,
      int maxRepaymentMonths = 4,
      int requiredGuarantors = 2,
      int quorumPercent = 50,
    }) =>
        validateRules(
          shareValue: shareValue,
          minShares: minShares,
          maxShares: maxShares,
          interestRatePct: interestRatePct,
          loanMultiplier: loanMultiplier,
          loanDurationMonths: loanDurationMonths,
          maxRepaymentMonths: maxRepaymentMonths,
          requiredGuarantors: requiredGuarantors,
          quorumPercent: quorumPercent,
        );

    test('a sane rulebook passes', () => expect(call(), isNull));
    test('rejects a zero share value',
        () => expect(call(shareValue: 0), isNotNull));
    test('rejects a negative interest rate',
        () => expect(call(interestRatePct: -1), isNotNull));
    test('rejects a zero loan multiplier',
        () => expect(call(loanMultiplier: 0), isNotNull));
    test('rejects min shares above max shares',
        () => expect(call(minShares: 6, maxShares: 5), isNotNull));
    test('rejects a zero repayment cap',
        () => expect(call(maxRepaymentMonths: 0), isNotNull));
    test('rejects quorum above 100',
        () => expect(call(quorumPercent: 101), isNotNull));
    test('rejects negative quorum',
        () => expect(call(quorumPercent: -1), isNotNull));
  });
}
