import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../constitution/constitution_screen.dart';
import '../leadership/leadership_screen.dart';
import '../shell/app_state_route.dart';
import '../shell/shell_scope.dart';
import 'backup_screen.dart';
import 'fine_types_screen.dart';
import 'interest_rates_screen.dart';
import 'meeting_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: const ShellLeading(),
        title: Text(locale.t('settings_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _group(locale.t('settings_group')),
          _SettingsCard(items: [
            (
              Icons.info_outline,
              locale.t('group_info'),
              () => Navigator.of(context)
                  .push(appStateRoute(context, const ConstitutionScreen())),
            ),
            (Icons.calendar_month_outlined, locale.t('vicoba_term'), null),
            (
              Icons.gavel_outlined,
              locale.t('fine_types_settings'),
              () => Navigator.of(context)
                  .push(appStateRoute(context, const FineTypesScreen())),
            ),
            (
              Icons.percent_outlined,
              locale.t('interest_rates'),
              () => Navigator.of(context)
                  .push(appStateRoute(context, const InterestRatesScreen())),
            ),
            (
              Icons.event_outlined,
              locale.t('meeting_settings'),
              () => Navigator.of(context)
                  .push(appStateRoute(context, const MeetingSettingsScreen())),
            ),
          ]),
          const SizedBox(height: 18),
          _group(locale.t('settings_users')),
          _SettingsCard(items: [
            (
              Icons.admin_panel_settings_outlined,
              locale.t('roles_permissions'),
              () => Navigator.of(context)
                  .push(appStateRoute(context, const LeadershipScreen())),
            ),
            (
              Icons.security_outlined,
              locale.t('security'),
              () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: AppColors.primary,
                  content: Text(locale.t('coming_soon')))),
            ),
            (
              Icons.account_balance_outlined,
              locale.t('backup'),
              () => Navigator.of(context)
                  .push(appStateRoute(context, const BackupScreen())),
            ),
          ]),
          const SizedBox(height: 18),
          _group(locale.t('language')),
          _SettingsCard(items: [
            (
              Icons.language,
              locale.isSwahili ? 'Kiswahili' : 'English',
              () => locale.toggle(),
            ),
          ]),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context)
                .push(appStateRoute(context, const BackupScreen())),
            icon: const Icon(Icons.backup_outlined),
            label: Text(locale.t('backup_now')),
          ),
        ],
      ),
    );
  }

  Widget _group(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
        child: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textSecondary)),
      );
}

class _SettingsCard extends StatelessWidget {
  final List<(IconData, String, VoidCallback?)> items;
  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 56),
            ListTile(
              leading: Icon(items[i].$1, color: AppColors.primary, size: 22),
              title: Text(items[i].$2,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14.5)),
              trailing:
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: items[i].$3 ?? () {},
            ),
          ],
        ],
      ),
    );
  }
}
