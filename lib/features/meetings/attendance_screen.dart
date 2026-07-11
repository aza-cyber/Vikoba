import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common.dart';

/// Step 2: register each member as Present / Absent / Excused. Present count,
/// totals and quorum update live.
class AttendanceScreen extends StatelessWidget {
  final String meetingId;
  const AttendanceScreen({super.key, required this.meetingId});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final meeting = state.meetingById(meetingId);
    final members = state.members;

    if (meeting == null) {
      return Scaffold(
        appBar: AppBar(title: Text(locale.t('attendance'))),
        body: const SizedBox.shrink(),
      );
    }

    final byMember = {for (final a in meeting.attendance) a.memberId: a.status};
    final present = meeting.presentCount;
    final quorum = meeting.quorumReached(members.length);

    return Scaffold(
      appBar: AppBar(title: Text(locale.t('attendance'))),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardGreenBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Stat(
                      label: locale.t('present'),
                      value: '$present / ${members.length}'),
                ),
                Expanded(
                  child: _Stat(
                      label: locale.t('absent'),
                      value: '${meeting.absentCount}'),
                ),
                Expanded(
                  child: _Stat(
                      label: locale.t('excused'),
                      value: '${meeting.excusedCount}'),
                ),
                _QuorumChip(reached: quorum, locale: locale),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final m = members[i];
                final status = byMember[m.id] ?? AttendanceStatus.present;
                return AppCard(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    children: [
                      MemberAvatar(initials: m.initials, size: 38),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(m.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13.5)),
                      ),
                      _AttendanceToggle(
                        status: status,
                        onChanged: (s) => state.setAttendance(
                            meetingId: meetingId,
                            memberId: m.id,
                            status: s),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceToggle extends StatelessWidget {
  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onChanged;
  const _AttendanceToggle({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(AttendanceStatus s, String label, Color color) {
      final on = status == s;
      return GestureDetector(
        onTap: () => onChanged(s),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: on ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: on ? Colors.white : AppColors.textSecondary)),
        ),
      );
    }

    final locale = context.read<LocaleProvider>();
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.scaffold,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(AttendanceStatus.present, locale.t('present_short'),
              AppColors.primary),
          seg(AttendanceStatus.absent, locale.t('absent_short'),
              AppColors.fines),
          seg(AttendanceStatus.excused, locale.t('excused_short'),
              AppColors.loans),
        ],
      ),
    );
  }
}

class _QuorumChip extends StatelessWidget {
  final bool reached;
  final LocaleProvider locale;
  const _QuorumChip({required this.reached, required this.locale});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(reached ? Icons.verified : Icons.error_outline,
            color: reached ? AppColors.primary : AppColors.fines, size: 22),
        const SizedBox(height: 3),
        Text(
          '${locale.t('quorum')}: ${reached ? locale.t('yes') : locale.t('no')}',
          style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: reached ? AppColors.primary : AppColors.fines),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.primary)),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11.5)),
      ],
    );
  }
}
