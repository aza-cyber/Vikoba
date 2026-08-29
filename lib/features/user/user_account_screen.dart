import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';
import '../auth/login_screen.dart';
import '../constitution/constitution_screen.dart';
import '../leadership/leadership_screen.dart';
import '../meetings/meetings_screen.dart';
import '../shell/app_state_route.dart';
import '../shell/main_shell.dart';

/// The member panel's account tab: the member's profile summary, read-only
/// group information (leadership, constitution, meetings), language toggle and
/// logout. Members can view how the group is run but cannot manage it.
class UserAccountScreen extends StatelessWidget {
  const UserAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final me = state.currentMember;

    final modules = <_Module>[
      _Module(Icons.groups_2_outlined, AppColors.primary, locale.t('leadership'),
          const LeadershipScreen()),
      _Module(Icons.menu_book_outlined, AppColors.meetings,
          locale.t('constitution'), const ConstitutionScreen()),
      _Module(Icons.event_outlined, AppColors.meetings,
          locale.t('meetings_title'), const MeetingsScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(locale.t('my_account'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (me != null)
            AppCard(
              child: Row(
                children: [
                  MemberAvatar(initials: me.initials, size: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(me.name,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text('${locale.t('phone')}: ${Fmt.phone(me.phone)}',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                        Text(
                            '${locale.t('member_since')}: ${Fmt.date(me.joinedOn)}',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          SectionHeader(title: locale.t('group_info')),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              for (final m in modules)
                _ModuleTile(
                  module: m,
                  onTap: () =>
                      Navigator.of(context).push(appStateRoute(context, m.page)),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingRow(
            icon: Icons.language,
            label: locale.t('language'),
            trailing: Text(locale.isSwahili ? 'Kiswahili' : 'English',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
            onTap: () => locale.toggle(),
          ),
          // Admins land here when they flip into the member panel; give them a
          // one-tap way back to the management surface. Regular members are not
          // admins, so this row stays hidden for them.
          if (state.isAdmin) ...[
            const SizedBox(height: 10),
            _SettingRow(
              icon: Icons.admin_panel_settings_outlined,
              label: locale.t('switch_to_admin_view'),
              color: AppColors.primary,
              onTap: () => switchShell(context, const MainShell()),
            ),
          ],
          const SizedBox(height: 10),
          _SettingRow(
            icon: Icons.logout,
            label: locale.t('logout'),
            color: AppColors.fines,
            onTap: () {
              context.read<AppState>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(locale.t('demo_notice'),
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _Module {
  final IconData icon;
  final Color color;
  final String label;
  final Widget page;
  _Module(this.icon, this.color, this.label, this.page);
}

class _ModuleTile extends StatelessWidget {
  final _Module module;
  final VoidCallback onTap;
  const _ModuleTile({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: module.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(module.icon, color: module.color, size: 24),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  module.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final Color? color;
  final VoidCallback onTap;

  const _SettingRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: c, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: c, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
