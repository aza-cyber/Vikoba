import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common.dart';
import '../auth/login_screen.dart';
import '../cashbook/cashbook_screen.dart';
import '../constitution/constitution_screen.dart';
import '../fines/fines_screen.dart';
import '../leadership/leadership_screen.dart';
import '../meetings/meetings_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../shareout/shareout_screen.dart';
import '../user/user_account_screen.dart';
import '../user/user_loans_screen.dart';
import 'app_state_route.dart';
import 'user_shell.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();

    final modules = <_Module>[
      _Module(Icons.groups_2_outlined, AppColors.primary,
          locale.t('leadership'), const LeadershipScreen()),
      _Module(Icons.menu_book_outlined, AppColors.meetings,
          locale.t('constitution'), const ConstitutionScreen()),
      _Module(Icons.gavel_outlined, AppColors.fines, locale.t('fines_title'),
          const FinesScreen()),
      _Module(Icons.event_outlined, AppColors.meetings,
          locale.t('meetings_title'), const MeetingsScreen()),
      _Module(Icons.account_balance_wallet_outlined, AppColors.primary,
          locale.t('cashbook_title'), const CashbookScreen()),
      _Module(Icons.bar_chart_rounded, AppColors.loans,
          locale.t('reports_title'), const ReportsScreen()),
      _Module(Icons.card_giftcard_outlined, AppColors.shareOut,
          locale.t('shareout'), const ShareOutScreen()),
      if (state.currentMember != null)
        _Module(Icons.person_outline_rounded, AppColors.primary,
            locale.t('my_account'), const UserAccountScreen()),
      if (state.currentMember != null)
        _Module(Icons.handshake_outlined, AppColors.loans, locale.t('my_loans'),
            const UserLoansScreen()),
      _Module(Icons.settings_outlined, AppColors.textSecondary,
          locale.t('settings_title'), const SettingsScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(locale.t('nav_more'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const AppLogo(width: 76, height: 48, borderColor: Colors.white),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.groupName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('${locale.t('term_label')}: ${state.term}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
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
                  onTap: () => Navigator.of(context)
                      .push(appStateRoute(context, m.page)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingRow(
            icon: Icons.language,
            label: locale.t('language'),
            trailing: Text(locale.isSwahili ? 'Kiswahili' : 'English',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
            onTap: () => locale.toggle(),
          ),
          // Let an admin who is also a member flip to their own member panel to
          // manage their personal account, then flip back.
          if (state.currentMember != null) ...[
            const SizedBox(height: 10),
            _SettingRow(
              icon: Icons.swap_horiz_rounded,
              label: locale.t('switch_to_member_view'),
              color: AppColors.primary,
              onTap: () => switchShell(context, const UserShell()),
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
