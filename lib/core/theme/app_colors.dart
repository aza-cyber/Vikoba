import 'package:flutter/material.dart';

/// VICOBA brand palette, derived from the reference mockups.
class AppColors {
  AppColors._();

  // Brand greens
  static const Color primary = Color(0xFF1B8A4B);
  static const Color primaryDark = Color(0xFF14633A);
  static const Color primaryLight = Color(0xFF3BAE6B);

  // Backgrounds
  static const Color scaffold = Color(0xFFF6F8F7);
  static const Color surface = Colors.white;
  static const Color cardGreenBg = Color(0xFFEAF6EF);
  static const Color cardOrangeBg = Color(0xFFFDF3E6);
  static const Color cardRedBg = Color(0xFFFDEDEE);
  static const Color cardBlueBg = Color(0xFFEAF1FB);

  // Accents (used for category cards, chips, charts)
  static const Color savings = Color(0xFF1B8A4B);
  static const Color loans = Color(0xFFF59E0B);
  static const Color fines = Color(0xFFE05A5A);
  static const Color meetings = Color(0xFF3B82F6);
  static const Color shareOut = Color(0xFF8B5CF6);

  // Status chips
  static const Color statusActive = Color(0xFF1B8A4B);
  static const Color statusActiveBg = Color(0xFFE3F4EA);
  static const Color statusBorrower = Color(0xFFF59E0B);
  static const Color statusBorrowerBg = Color(0xFFFCEFD6);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusPaid = Color(0xFF1B8A4B);

  // Text
  static const Color textPrimary = Color(0xFF1A2B22);
  static const Color textSecondary = Color(0xFF6B7B73);
  static const Color textMuted = Color(0xFF9AA8A0);

  // Lines / dividers
  static const Color border = Color(0xFFE6ECE8);

  // Money movement
  static const Color moneyIn = Color(0xFF1B8A4B);
  static const Color moneyOut = Color(0xFFE05A5A);
}
