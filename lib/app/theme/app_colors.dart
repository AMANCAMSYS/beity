import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF2E7D32); // Deep Green
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark = Color(0xFF005005);
  
  static const Color secondary = Color(0xFF4CAF50); // Fresh Green
  static const Color accent = Color(0xFFFF9800);    // Orange
  
  // Semantic Colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);
  
  // Background & Surface Colors - Light Mode
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Colors.white;
  static const Color dividerLight = Color(0xFFE0E0E0);
  
  // Background & Surface Colors - Dark Mode
  static const Color backgroundDark = Color(0xFF161A16); // Tinted dark grey to match green
  static const Color surfaceDark = Color(0xFF212621);
  static const Color dividerDark = Color(0xFF353C35);
  
  // Text Colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textHintLight = Color(0xFFBDBDBD);
  
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFAAAAAA);
  static const Color textHintDark = Color(0xFF6E6E6E);
}
