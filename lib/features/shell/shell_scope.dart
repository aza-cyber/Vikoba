import 'package:flutter/material.dart';

/// Exposes the shell's "menu" action to the screens rendered inside it, without
/// coupling those screens to [MainShell]. On phones the action opens the nav
/// drawer; on wide screens it collapses/expands the sidebar.
class MainShellScope extends InheritedWidget {
  final VoidCallback onMenu;

  const MainShellScope({
    super.key,
    required this.onMenu,
    required super.child,
  });

  static MainShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainShellScope>();

  @override
  bool updateShouldNotify(MainShellScope oldWidget) =>
      onMenu != oldWidget.onMenu;
}

/// An AppBar leading that adapts to context:
///  - inside the shell   → a ☰ button that opens/closes the navigation menu;
///  - a pushed route      → the standard back button;
///  - otherwise           → nothing.
class ShellLeading extends StatelessWidget {
  const ShellLeading({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = MainShellScope.maybeOf(context);
    if (scope != null) {
      return IconButton(
        icon: const Icon(Icons.menu),
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        onPressed: scope.onMenu,
      );
    }
    if (Navigator.of(context).canPop()) return const BackButton();
    return const SizedBox.shrink();
  }
}
