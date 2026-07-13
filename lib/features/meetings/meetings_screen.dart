import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';
import '../shell/app_state_route.dart';
import '../shell/shell_scope.dart';
import 'meeting_create_screen.dart';
import 'meeting_detail_screen.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  int _tab = 0; // 0 = Upcoming, 1 = Past

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final tabs = [locale.t('tab_upcoming'), locale.t('tab_past')];
    final meetings = _tab == 0 ? state.upcomingMeetings : state.pastMeetings;

    return Scaffold(
      appBar: AppBar(
        leading: const ShellLeading(),
        title: Text(locale.t('meetings_title')),
      ),
      floatingActionButton: state.isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: () => Navigator.of(context)
                  .push(appStateRoute(context, const MeetingCreateScreen())),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(locale.t('new_meeting'),
                  style: const TextStyle(color: Colors.white)),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _tab == i
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                        child: Text(
                          tabs[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight:
                                _tab == i ? FontWeight.w700 : FontWeight.w500,
                            color: _tab == i
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await state.refresh();
              },
              child: meetings.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        EmptyState(
                          icon: Icons.event_outlined,
                          title: _tab == 0
                              ? locale.t('no_upcoming')
                              : locale.t('no_past'),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      itemCount: meetings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) =>
                          _MeetingCard(meeting: meetings[i], locale: locale),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final LocaleProvider locale;
  const _MeetingCard({required this.meeting, required this.locale});

  @override
  Widget build(BuildContext context) {
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
    final upcoming = meeting.isUpcoming;
    return AppCard(
      onTap: () => Navigator.of(context).push(
        appStateRoute(context, MeetingDetailScreen(meetingId: meeting.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cardBlueBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_outlined,
                    color: AppColors.meetings, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        meeting.title.isNotEmpty
                            ? meeting.title
                            : '${locale.t('meeting_no')} ${meeting.number}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                        '${locale.t('meeting_no')} ${meeting.number} · '
                        '${Fmt.date(meeting.date)}'
                        '${meeting.startTime.isNotEmpty ? ' · ${meeting.startTime}' : ''}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12.5)),
                  ],
                ),
              ),
              StatusChip(
                  label: statusLabel,
                  color: statusColor,
                  background: statusBg),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _meta(Icons.list_alt_outlined,
                  '${meeting.agendaItems} ${locale.t('items')}'),
              const SizedBox(width: 16),
              if (upcoming)
                _meta(Icons.groups_outlined,
                    '${meeting.total} ${locale.t('nav_members')}')
              else
                _meta(Icons.how_to_reg_outlined,
                    '${meeting.attended}/${meeting.total}'),
              if (!upcoming) ...[
                const SizedBox(width: 16),
                _meta(Icons.savings_outlined, Fmt.tzs(meeting.collections)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
