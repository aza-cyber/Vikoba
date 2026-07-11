import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';
import '../cashbook/cashbook_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../fines/fines_screen.dart';
import '../loans/loans_screen.dart';
import '../meetings/meetings_screen.dart';
import '../members/members_screen.dart';
import '../reports/reports_screen.dart';
import '../savings/savings_screen.dart';
import '../settings/settings_screen.dart';
import 'app_state_route.dart';
import 'more_screen.dart';
import 'quick_actions_sheet.dart';
import 'shell_scope.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Bottom-nav index (Dashboard, Members, Savings, Loans, More).
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Pull the freshest group data when the panel opens, so figures another
    // device changed (e.g. a member's loan request) show up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().refresh();
    });
  }

  void _select(int i) {
    setState(() => _index = i);
    context.read<AppState>().refresh();
  }

  /// Drawer tap: destinations that map to a bottom-nav tab switch the tab; the
  /// rest are pushed as their own screen (like the "More" grid).
  void _onDrawerSelect(int wideIndex) {
    Navigator.of(context).pop(); // close the drawer
    const wideToTab = {0: 0, 1: 1, 3: 2, 4: 3};
    final tab = wideToTab[wideIndex];
    if (tab != null) {
      _select(tab);
      return;
    }
    Navigator.of(context).push(appStateRoute(context, _widePages[wideIndex]));
  }

  // Phone tabs — unchanged. "More" holds the remaining modules.
  final _pages = const [
    DashboardScreen(),
    MembersScreen(),
    SavingsScreen(),
    LoansScreen(),
    MoreScreen(),
  ];

  // Full destination set for the wide sidebar / phone drawer, in mockup order.
  static const _widePages = <Widget>[
    DashboardScreen(),
    MembersScreen(),
    MeetingsScreen(),
    SavingsScreen(),
    LoansScreen(),
    FinesScreen(),
    ReportsScreen(),
    CashbookScreen(),
    SettingsScreen(),
  ];

  List<_NavItem> _navItems(LocaleProvider locale) => [
        _NavItem(Icons.home_rounded, locale.t('nav_dashboard')),
        _NavItem(Icons.groups_rounded, locale.t('nav_members')),
        _NavItem(Icons.event_rounded, locale.t('meetings_title')),
        _NavItem(Icons.savings_rounded, locale.t('nav_savings')),
        _NavItem(Icons.handshake_rounded, locale.t('nav_loans')),
        _NavItem(Icons.gavel_rounded, locale.t('fines_title')),
        _NavItem(Icons.bar_chart_rounded, locale.t('reports_title')),
        _NavItem(Icons.receipt_long_rounded, locale.t('nav_expenses')),
        _NavItem(Icons.settings_rounded, locale.t('settings_title')),
      ];

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    // Watched so the Loans badge updates the moment a request comes in / is cleared.
    final pendingRequests = context.watch<AppState>().loanRequests.length;

    final bottomItems = [
      _NavItem(Icons.home_rounded, locale.t('nav_dashboard')),
      _NavItem(Icons.groups_rounded, locale.t('nav_members')),
      _NavItem(Icons.savings_rounded, locale.t('nav_savings')),
      _NavItem(Icons.handshake_rounded, locale.t('nav_loans')),
      _NavItem(Icons.apps_rounded, locale.t('nav_more')),
    ];

    // Highlight the drawer entry matching the active bottom tab (if any).
    const tabToWide = {0: 0, 1: 1, 2: 3, 3: 4};
    final drawerSelected = tabToWide[_index] ?? -1;

    return MainShellScope(
      onMenu: () => _scaffoldKey.currentState?.openDrawer(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: _Sidebar(
            items: _navItems(locale),
            selected: drawerSelected,
            onSelect: _onDrawerSelect,
            drawerMode: true,
          ),
        ),
        body: IndexedStack(index: _index, children: _pages),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          elevation: 2,
          onPressed: () => showQuickActions(context),
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          color: AppColors.surface,
          height: 66,
          padding: EdgeInsets.zero,
          shape: const CircularNotchedRectangle(),
          notchMargin: 7,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < bottomItems.length; i++) ...[
                if (i == 2) const SizedBox(width: 48), // gap for the FAB notch
                _NavButton(
                  item: bottomItems[i],
                  selected: _index == i,
                  onTap: () => _select(i),
                  // The Loans tab (index 3) shows a badge of pending requests.
                  badge: i == 3 ? pendingRequests : 0,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

// --------------------------------------------------------------- sidebar
/// The navigation menu: brand header, destination list, a Group Balance card
/// and a Sync button. Used as a persistent sidebar on wide screens and inside a
/// [Drawer] on phones ([drawerMode]).
class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final bool drawerMode;

  const _Sidebar({
    required this.items,
    required this.selected,
    required this.onSelect,
    this.drawerMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();

    return Container(
      width: drawerMode ? null : 248,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: drawerMode
            ? null
            : const Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Brand ----
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Row(
                children: [
                  const AppLogo(
                      width: 58, height: 40, borderColor: AppColors.border),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(locale.t('app_name'),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.0)),
                      const Text('App',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),

            // ---- Destinations ----
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (var i = 0; i < items.length; i++)
                    _SidebarTile(
                      item: items[i],
                      selected: i == selected,
                      onTap: () => onSelect(i),
                    ),
                ],
              ),
            ),

            // ---- Group balance card ----
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(locale.t('group_balance'),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('💼 ', style: TextStyle(fontSize: 15)),
                        Expanded(
                          child: Text(Fmt.tzs(state.cashInHand),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    Divider(
                        height: 22,
                        color: Colors.white.withValues(alpha: 0.18)),
                    Text(locale.t('total_savings'),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(Fmt.tzs(state.totalSavings),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),

            // ---- Sync ----
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: OutlinedButton.icon(
                onPressed: () => context.read<AppState>().refresh(),
                icon: const Icon(Icons.cloud_sync_outlined, size: 18),
                label: Text(locale.t('sync_data')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(item.icon, color: fg, size: 21),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: fg,
                          fontSize: 14.5,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(item.icon, color: color, size: 24),
                if (badge > 0)
                  Positioned(
                    right: -7,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 15),
                      decoration: BoxDecoration(
                        color: AppColors.fines,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AppColors.surface, width: 1.5),
                      ),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
