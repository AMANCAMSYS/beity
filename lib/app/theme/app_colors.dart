import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors: calm teal, soft sage, and a restrained warm accent.
  static const Color primary = Color(0xFF0E5F5A);
  static const Color primaryLight = Color(0xFF5FAEA7);
  static const Color primaryDark = Color(0xFF063E3A);
  static const Color primaryContainer = Color(0xFFE1F2EF);
  static const Color primaryContainerDark = Color(0xFF123D39);

  static const Color secondary = Color(0xFF6C7A4F);
  static const Color secondaryLight = Color(0xFFDDE6CF);
  static const Color secondaryDark = Color(0xFF3E4A2E);
  static const Color accent = Color(0xFFC66A32);
  static const Color accentLight = Color(0xFFF6E3D6);
  static const Color accentDark = Color(0xFF7F3D1D);

  // Semantic Colors
  static const Color error = Color(0xFFC2413A);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color success = Color(0xFF2D8A6E);
  static const Color successContainer = Color(0xFFDDF3EA);
  static const Color warning = Color(0xFFB87514);
  static const Color warningContainer = Color(0xFFFFE8C2);
  static const Color info = Color(0xFF2F6F8F);
  static const Color infoContainer = Color(0xFFDCEEF6);

  // Domain Colors
  static const Color shoppingActive = Color(0xFFE4F4EF);
  static const Color shoppingActiveDark = Color(0xFF113C37);
  static const Color purchasedMuted = Color(0xFFEEF1ED);
  static const Color purchasedMutedDark = Color(0xFF22312D);

  // Background & Surface Colors - Light Mode
  static const Color backgroundLight = Color(0xFFF7F8F4);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceElevatedLight = Color(0xFFFBFCFA);
  static const Color surfaceVariantLight = Color(0xFFEEF2EE);
  static const Color dividerLight = Color(0xFFD8DED7);

  // Background & Surface Colors - Dark Mode
  static const Color backgroundDark = Color(0xFF101816);
  static const Color surfaceDark = Color(0xFF18211F);
  static const Color surfaceElevatedDark = Color(0xFF1E2926);
  static const Color surfaceVariantDark = Color(0xFF22312D);
  static const Color dividerDark = Color(0xFF2B3A36);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF17231F);
  static const Color textSecondaryLight = Color(0xFF5F6F68);
  static const Color textHintLight = Color(0xFF8B9892);

  static const Color textPrimaryDark = Color(0xFFF1F6F3);
  static const Color textSecondaryDark = Color(0xFFB7C4BE);
  static const Color textHintDark = Color(0xFF7D8C86);

  // Helpers
  static Color shoppingActiveFor(Brightness brightness) =>
      brightness == Brightness.dark ? shoppingActiveDark : shoppingActive;

  static Color purchasedMutedFor(Brightness brightness) =>
      brightness == Brightness.dark ? purchasedMutedDark : purchasedMuted;

  static Color textPrimaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;

  static Color textSecondaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;

  static Color textHintFor(Brightness brightness) =>
      brightness == Brightness.dark ? textHintDark : textHintLight;

  static Color dividerFor(Brightness brightness) =>
      brightness == Brightness.dark ? dividerDark : dividerLight;

  static Color surfaceFor(Brightness brightness) =>
      brightness == Brightness.dark ? surfaceDark : surfaceLight;

  static Color backgroundFor(Brightness brightness) =>
      brightness == Brightness.dark ? backgroundDark : backgroundLight;
}
