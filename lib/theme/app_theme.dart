import 'package:flutter/material.dart';

/// Centralized visual identity for MazeDrop: water/drop themed, clean, modern.
class AppColors {
  static const Color background = Color(0xFF0B1D3A);
  static const Color backgroundLight = Color(0xFF14294F);
  static const Color primary = Color(0xFF2EC4F1);
  static const Color primaryDark = Color(0xFF1B8FC4);
  static const Color accent = Color(0xFF6EE7D8);
  static const Color danger = Color(0xFFFF5C6C);
  static const Color gold = Color(0xFFFFC64B);
  static const Color surface = Color(0xFF1B2E52);
  static const Color textPrimary = Color(0xFFF4FAFF);
  static const Color textSecondary = Color(0xFFAAC0DE);
  static const Color wall = Color(0xFF3A5A8A);
  static const Color locked = Color(0xFF3A4A66);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 40,
          letterSpacing: 1.2,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
    );
  }

  static BoxDecoration get screenBackground => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.background, AppColors.backgroundLight],
        ),
      );

  static const Duration shortAnim = Duration(milliseconds: 150);
  static const Duration mediumAnim = Duration(milliseconds: 250);
  static const Duration moveAnim = Duration(milliseconds: 130);
}
