import 'package:flutter/widgets.dart';

/// Width at/above which the app switches from the phone (bottom-nav) layout to
/// the desktop/web (sidebar + multi-column) layout shown in the reference
/// mockups. Kept in one place so the shell and the individual screens agree.
const double kWideBreakpoint = 900;

/// Width at/above which a screen can afford a secondary right-hand rail
/// (e.g. the meeting cash summary / recent activity panels) beside its content.
const double kRailBreakpoint = 1040;

bool isWide(BuildContext context) =>
    MediaQuery.of(context).size.width >= kWideBreakpoint;
