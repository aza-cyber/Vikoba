import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/state/app_state.dart';
import '../../widgets/common.dart';
import 'dashboard_screen.dart' show ActivityRow;

/// The full group activity feed — the "View all" destination from the
/// dashboard's Recent Activity card. The dashboard shows only the latest few;
/// this lists every activity in the current snapshot.
class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final activities = state.activities;

    return Scaffold(
      appBar: AppBar(title: Text(locale.t('activity_history'))),
      body: RefreshIndicator(
        onRefresh: () async {
          await state.refresh();
        },
        child: activities.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 72),
                  EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: locale.t('no_activity_yet'),
                    subtitle: locale.t('no_activity_hint'),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        for (var i = 0; i < activities.length; i++) ...[
                          if (i > 0)
                            const Divider(
                                height: 1, indent: 60, endIndent: 12),
                          ActivityRow(activity: activities[i]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
