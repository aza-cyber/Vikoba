import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common.dart';
import '../shell/app_state_route.dart';
import 'meeting_edit_screen.dart';
import 'meeting_wide_view.dart';

/// The meeting workspace: a status badge + open/close controls, then the
/// dashboard (attendance stats, the 8-step order of business wired to each
/// feature, cash summary, recent activity and upcoming meetings). Editing is
/// locked once the meeting is closed.
class MeetingDetailScreen extends StatelessWidget {
  final String meetingId;
  const MeetingDetailScreen({super.key, required this.meetingId});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final meeting = state.meetingById(meetingId);

    if (meeting == null) {
      return Scaffold(
        appBar: AppBar(title: Text(locale.t('meetings_title'))),
        body: Center(child: Text(locale.t('no_past'))),
      );
    }
    final isAdmin = state.isAdmin;
    final closed = meeting.status == MeetingStatus.closed;
    // Once a meeting is closed everything is read-only.
    final editable = isAdmin && !closed;

    final (statusLabel, statusColor, statusBg) = switch (meeting.status) {
      MeetingStatus.draft => (
          locale.t('status_draft'),
          AppColors.meetings,
          AppColors.cardBlueBg
        ),
      MeetingStatus.open => (
          locale.t('status_open'),
          AppColors.loans,
          AppColors.cardOrangeBg
        ),
      MeetingStatus.closed => (
          locale.t('status_held'),
          AppColors.statusPaid,
          AppColors.statusActiveBg
        ),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(meeting.title.isNotEmpty
            ? meeting.title
            : '${locale.t('meeting_no')} ${meeting.number}'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: StatusChip(
                label: statusLabel, color: statusColor, background: statusBg),
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: locale.t('edit_meeting'),
              onPressed: () => Navigator.of(context).push(
                appStateRoute(context, MeetingEditScreen(meeting: meeting)),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _StatusControls(
                  meeting: meeting, state: state, locale: locale),
            ),
          Expanded(
            child: MeetingWideView(meeting: meeting, editable: editable),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- status
class _StatusControls extends StatelessWidget {
  final Meeting meeting;
  final AppState state;
  final LocaleProvider locale;
  const _StatusControls(
      {required this.meeting, required this.state, required this.locale});

  @override
  Widget build(BuildContext context) {
    switch (meeting.status) {
      case MeetingStatus.draft:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () =>
                state.setMeetingStatus(meeting.id, MeetingStatus.open),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(locale.t('open_meeting')),
          ),
        );
      case MeetingStatus.open:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.fines),
            onPressed: () =>
                showCloseMeetingDialog(context, state, meeting, locale),
            icon: const Icon(Icons.lock_outline),
            label: Text(locale.t('close_meeting')),
          ),
        );
      case MeetingStatus.closed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.statusActiveBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock, color: AppColors.statusPaid, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(locale.t('meeting_closed_note'),
                    style: const TextStyle(
                        color: AppColors.statusPaid,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5)),
              ),
              TextButton(
                onPressed: () =>
                    state.setMeetingStatus(meeting.id, MeetingStatus.open),
                child: Text(locale.t('reopen')),
              ),
            ],
          ),
        );
    }
  }
}

/// Shows the "before closing" checklist and, if the meeting passes validation
/// (attendance recorded and all business completed), closes it. Shared by the
/// status control and the meeting dashboard's "Report & Close" step.
Future<void> showCloseMeetingDialog(BuildContext context, AppState state,
    Meeting meeting, LocaleProvider locale) async {
  final attendanceOk = meeting.attendance.isNotEmpty;
  final canClose = attendanceOk;

  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(locale.t('close_checklist')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CheckRow(ok: attendanceOk, label: locale.t('check_attendance')),
          const SizedBox(height: 14),
          Text(
            canClose ? locale.t('close_ready') : locale.t('close_blocked'),
            style: TextStyle(
                fontSize: 12.5,
                color: canClose ? AppColors.primary : AppColors.fines,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(locale.t('cancel')),
        ),
        ElevatedButton(
          onPressed:
              canClose ? () => Navigator.of(dialogContext).pop(true) : null,
          child: Text(locale.t('close_meeting')),
        ),
      ],
    ),
  );
  if (ok == true) {
    await state.setMeetingStatus(meeting.id, MeetingStatus.closed);
  }
}

class _CheckRow extends StatelessWidget {
  final bool ok;
  final String label;
  const _CheckRow({required this.ok, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(ok ? Icons.check_circle : Icons.cancel,
            color: ok ? AppColors.primary : AppColors.fines, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5))),
      ],
    );
  }
}
