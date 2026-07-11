import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/layout.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';
import '../cashbook/cashbook_screen.dart';
import '../fines/fines_screen.dart';
import '../loans/create_loan_screen.dart';
import '../loans/repayment_screen.dart';
import '../savings/savings_screen.dart';
import '../shell/app_state_route.dart';
import 'attendance_screen.dart';
import 'meeting_detail_screen.dart' show showCloseMeetingDialog;

/// Where a step sits in the meeting flow. Only [done] states we can derive from
/// real data (attendance recorded, meeting closed) are shown as complete; the
/// rest stay actionable rather than faking progress.
enum _StepState { done, active, pending }

/// One entry in the 8-step "Meeting Progress" workflow.
class _Step {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final _StepState state;

  /// Null when the current user may not act on this step (non-admin / closed
  /// meeting) — the card then renders read-only.
  final VoidCallback? onTap;
  const _Step({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.state,
    required this.onTap,
  });
}

/// The desktop/web meeting view from the reference mockup: attendance stats, the
/// 8-step order of business (each wired to its real feature screen), a cash
/// summary, recent activity and upcoming meetings.
class MeetingWideView extends StatelessWidget {
  final Meeting meeting;

  /// True when the current user may act on the meeting (admin & not closed).
  final bool editable;

  const MeetingWideView({
    super.key,
    required this.meeting,
    required this.editable,
  });

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(appStateRoute(context, page));
  }

  List<_Step> _steps(
      BuildContext context, LocaleProvider locale, AppState state) {
    final closed = meeting.status == MeetingStatus.closed;
    _StepState st(bool done, {bool active = false}) => done
        ? _StepState.done
        : (active ? _StepState.active : _StepState.pending);

    // Only admins (on an open meeting) can act on a step; everyone else sees
    // the steps read-only.
    VoidCallback? act(VoidCallback cb) => editable ? cb : null;

    return [
      _Step(
        icon: Icons.groups_rounded,
        color: AppColors.primary,
        title: locale.t('attendance'),
        desc: locale.t('attendance_desc'),
        state: st(meeting.attendance.isNotEmpty, active: true),
        onTap: act(() => _open(context, AttendanceScreen(meetingId: meeting.id))),
      ),
      _Step(
        icon: Icons.gavel_rounded,
        color: AppColors.fines,
        title: locale.t('fines_title'),
        desc: locale.t('fines_desc'),
        state: st(false),
        onTap: act(() => _open(context, const FinesScreen())),
      ),
      _Step(
        icon: Icons.volunteer_activism_rounded,
        color: AppColors.meetings,
        title: locale.t('social_fund'),
        desc: locale.t('social_desc'),
        state: st(false),
        onTap: act(() => _open(context, const SavingsScreen())),
      ),
      _Step(
        icon: Icons.savings_rounded,
        color: AppColors.shareOut,
        title: locale.t('savings_shares'),
        desc: locale.t('savings_desc'),
        state: st(false),
        onTap: act(() => _open(context, const SavingsScreen())),
      ),
      _Step(
        icon: Icons.autorenew_rounded,
        color: AppColors.loans,
        title: locale.t('loan_repayments'),
        desc: locale.t('repay_desc'),
        state: st(false),
        onTap: act(() => _open(context, const RepaymentScreen())),
      ),
      _Step(
        icon: Icons.handshake_rounded,
        color: AppColors.primary,
        title: locale.t('new_loans'),
        desc: locale.t('newloan_desc'),
        state: st(false),
        onTap: act(() => _open(context, const CreateLoanScreen())),
      ),
      _Step(
        icon: Icons.receipt_long_rounded,
        color: AppColors.fines,
        title: locale.t('nav_expenses'),
        desc: locale.t('expenses_desc'),
        state: st(false),
        onTap: act(() => _open(context, const CashbookScreen())),
      ),
      _Step(
        icon: Icons.description_rounded,
        color: AppColors.meetings,
        title: locale.t('report_close'),
        desc: locale.t('report_desc'),
        state: st(closed),
        onTap: act(() => showCloseMeetingDialog(context, state, meeting, locale)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final steps = _steps(context, locale, state);

    return LayoutBuilder(
      builder: (context, c) {
        final showRail = c.maxWidth >= kRailBreakpoint;
        const railWidth = 320.0;
        const gap = 24.0;
        final mainWidth = showRail ? c.maxWidth - railWidth - gap : c.maxWidth;

        final main = _MainColumn(
          meeting: meeting,
          locale: locale,
          state: state,
          steps: steps,
          editable: editable,
          width: mainWidth - 40, // minus page padding
        );

        final rail = _RailColumn(meeting: meeting, locale: locale, state: state);

        if (!showRail) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [main, const SizedBox(height: 20), rail],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: SingleChildScrollView(child: main)),
              const SizedBox(width: gap),
              SizedBox(
                width: railWidth,
                child: SingleChildScrollView(child: rail),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --------------------------------------------------------------- main column
class _MainColumn extends StatelessWidget {
  final Meeting meeting;
  final LocaleProvider locale;
  final AppState state;
  final List<_Step> steps;
  final bool editable;
  final double width;

  const _MainColumn({
    required this.meeting,
    required this.locale,
    required this.state,
    required this.steps,
    required this.editable,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final statCols = width >= 640 ? 4 : 2;
    final stepCols = width >= 900
        ? 4
        : width >= 620
            ? 3
            : 2;
    final pct = (meeting.attendanceRate * 100).round();

    final stats = <Widget>[
      _StatCard(
          icon: Icons.groups_rounded,
          color: AppColors.primary,
          value: '${state.members.length}',
          label: locale.t('total_members')),
      _StatCard(
          icon: Icons.check_circle_rounded,
          color: AppColors.primary,
          value: '${meeting.presentCount}',
          label: locale.t('present')),
      _StatCard(
          icon: Icons.cancel_rounded,
          color: AppColors.fines,
          value: '${meeting.absentCount}',
          label: locale.t('absent')),
      _StatCard(
          icon: Icons.donut_large_rounded,
          color: AppColors.meetings,
          value: '$pct%',
          label: locale.t('attendance')),
    ];

    // First not-done step drives "Continue Meeting".
    final next = steps.where((s) => s.state != _StepState.done).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // meta line
        Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            _meta(Icons.calendar_today_outlined, Fmt.date(meeting.date)),
            if (meeting.startTime.isNotEmpty)
              _meta(Icons.schedule, meeting.startTime),
            if (meeting.location.isNotEmpty)
              _meta(Icons.place_outlined, meeting.location),
          ],
        ),
        const SizedBox(height: 18),
        _wrapGrid(width: width, cols: statCols, spacing: 14, children: stats),
        const SizedBox(height: 24),
        Text(locale.t('meeting_progress'),
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: AppColors.textSecondary)),
        const SizedBox(height: 14),
        _wrapGrid(
          width: width,
          cols: stepCols,
          spacing: 14,
          children: [
            for (var i = 0; i < steps.length; i++)
              _StepCard(number: i + 1, step: steps[i], locale: locale),
          ],
        ),
        if (editable && next.isNotEmpty) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: next.first.onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(locale.t('continue_meeting'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      );
}

/// Lays [children] out in [cols] equal columns using a Wrap, so each card is
/// free to size its own height (no fixed aspect ratio → no overflow).
Widget _wrapGrid({
  required double width,
  required int cols,
  required double spacing,
  required List<Widget> children,
}) {
  final itemWidth = (width - spacing * (cols - 1)) / cols;
  return Wrap(
    spacing: spacing,
    runSpacing: spacing,
    children: [
      for (final child in children)
        SizedBox(width: itemWidth > 0 ? itemWidth : width, child: child),
    ],
  );
}

// --------------------------------------------------------------- stat card
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- step card
class _StepCard extends StatelessWidget {
  final int number;
  final _Step step;
  final LocaleProvider locale;

  const _StepCard({
    required this.number,
    required this.step,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final (chipLabel, chipColor, chipBg, chipIcon) = switch (step.state) {
      _StepState.done => (
          locale.t('completed'),
          AppColors.statusPaid,
          AppColors.statusActiveBg,
          Icons.check_circle
        ),
      _StepState.active => (
          locale.t('in_progress'),
          AppColors.loans,
          AppColors.cardOrangeBg,
          Icons.hourglass_bottom
        ),
      _StepState.pending => (
          locale.t('pending'),
          AppColors.textMuted,
          AppColors.scaffold,
          Icons.schedule
        ),
    };

    return AppCard(
      onTap: step.onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: step.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(step.icon, color: step.color, size: 21),
              ),
              const Spacer(),
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.scaffold,
                  shape: BoxShape.circle,
                ),
                child: Text('$number',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(step.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(step.desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted, height: 1.3)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(chipIcon, size: 13, color: chipColor),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(chipLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: chipColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- right rail
class _RailColumn extends StatelessWidget {
  final Meeting meeting;
  final LocaleProvider locale;
  final AppState state;

  const _RailColumn({
    required this.meeting,
    required this.locale,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CashSummary(meeting: meeting, locale: locale, state: state),
        const SizedBox(height: 16),
        _RecentActivity(locale: locale, activities: state.activities),
        const SizedBox(height: 16),
        _UpcomingMeetings(
            locale: locale,
            meetings: state.upcomingMeetings
                .where((m) => m.id != meeting.id)
                .toList()),
      ],
    );
  }
}

class _CashSummary extends StatelessWidget {
  final Meeting meeting;
  final LocaleProvider locale;
  final AppState state;
  const _CashSummary(
      {required this.meeting, required this.locale, required this.state});

  @override
  Widget build(BuildContext context) {
    final income = meeting.collections + meeting.fines;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _railTitle(locale.t('cash_summary')),
          const SizedBox(height: 12),
          _row(locale.t('total_income'), Fmt.tzs(income),
              color: AppColors.moneyIn),
          _row(locale.t('collections'), Fmt.tzs(meeting.collections)),
          _row(locale.t('fines_title'), Fmt.tzs(meeting.fines)),
          const Divider(height: 22),
          _row(locale.t('cash_in_hand'), Fmt.tzs(state.cashInHand),
              bold: true, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: bold
                        ? AppColors.textPrimary
                        : AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 14.5 : 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final LocaleProvider locale;
  final List<Activity> activities;
  const _RecentActivity({required this.locale, required this.activities});

  @override
  Widget build(BuildContext context) {
    final items = activities.take(4).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _railTitle(locale.t('recent_activity')),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(locale.t('no_actions'),
                  style: const TextStyle(color: AppColors.textMuted)),
            )
          else
            for (final a in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: IconMapper.color(a.icon).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(IconMapper.icon(a.icon),
                          size: 15, color: IconMapper.color(a.icon)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(a.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    Text(Fmt.tzs(a.amount),
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _UpcomingMeetings extends StatelessWidget {
  final LocaleProvider locale;
  final List<Meeting> meetings;
  const _UpcomingMeetings({required this.locale, required this.meetings});

  @override
  Widget build(BuildContext context) {
    final items = meetings.take(2).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _railTitle(locale.t('upcoming_meetings')),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(locale.t('no_upcoming'),
                  style: const TextStyle(color: AppColors.textMuted)),
            )
          else
            for (final m in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.cardBlueBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.event_outlined,
                          size: 18, color: AppColors.meetings),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              m.title.isNotEmpty
                                  ? m.title
                                  : '${locale.t('meeting_no')} ${m.number}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                              '${Fmt.date(m.date)}'
                              '${m.startTime.isNotEmpty ? ' · ${m.startTime}' : ''}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

Widget _railTitle(String text) => Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: AppColors.textSecondary,
      ),
    );
