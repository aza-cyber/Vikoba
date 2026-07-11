import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../meetings/meetings_screen.dart';
import '../user/user_account_screen.dart';
import '../user/user_dashboard_screen.dart';
import '../user/user_loans_screen.dart';

/// The member (user) panel shell: a regular member's self-service view — their
/// own dashboard, their loans (with the ability to apply), and an account tab
/// with read-only group info and logout. The richer management surface lives in
/// the admin shell ([MainShell]).
class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Refresh on open so repayments/approvals an officer made are reflected.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().refresh();
    });
  }

  void _select(int i) {
    setState(() => _index = i);
    context.read<AppState>().refresh();
  }

  final _pages = const [
    UserDashboardScreen(),
    UserLoansScreen(),
    MeetingsScreen(),
    UserAccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.cardGreenBg,
        onDestinationSelected: _select,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: locale.t('nav_dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.handshake_outlined),
            selectedIcon: const Icon(Icons.handshake_rounded),
            label: locale.t('my_loans'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_outlined),
            selectedIcon: const Icon(Icons.event_rounded),
            label: locale.t('meetings_title'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: locale.t('my_account'),
          ),
        ],
      ),
    );
  }
}
