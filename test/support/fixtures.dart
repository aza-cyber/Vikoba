import 'package:vikoba/core/models/models.dart';
import 'package:vikoba/core/state/app_state.dart';

/// A small populated snapshot for tests that need real-looking data (e.g. the
/// report generator). Kept in the test tree — the app itself ships no samples.
Snapshot demoSnapshot() => Snapshot(
      groupName: 'Test Group',
      term: '2026',
      members: [
        Member(
          id: 'M1',
          name: 'Asha Juma',
          phone: '0700000001',
          shares: 10,
          status: MemberStatus.active,
          savings: 500000,
          loanBalance: 0,
          fines: 0,
          joinedOn: DateTime(2024, 1, 1),
        ),
        Member(
          id: 'M2',
          name: 'John Mollel',
          phone: '0700000002',
          shares: 8,
          status: MemberStatus.active,
          savings: 300000,
          loanBalance: 0,
          fines: 0,
          joinedOn: DateTime(2024, 2, 1),
        ),
      ],
      loans: const [],
      savings: const [],
      repayments: const [],
      fines: const [],
      meetings: const [],
      officers: const [],
      activities: const [],
      cashInHand: 800000,
      socialFundBalance: 0,
      savingsCollected: 800000,
      repaymentsCollected: 0,
      finesCollected: 0,
      loansDisbursed: 0,
      meetingExpense: 0,
      otherExpense: 0,
      interestEarned: 0,
      shareValue: 5000,
      meetingsHeld: 0,
    );
