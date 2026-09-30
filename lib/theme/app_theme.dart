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
  static const Color surfaceHigh = Color(0xFF243D6B);
  static const Color textPrimary = Color(0xFFF4FAFF);
  static const Color textSecondary = Color(0xFFAAC0DE);
  static const Color wall = Color(0xFF3A5A8A);
  static const Color locked = Color(0xFF3A4A66);
  static const Color glassFill = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x22FFFFFF);
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
          fontWeight: FontWeight.w900,
          fontSize: 44,
          letterSpacing: 1.5,
          height: 1.05,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 28,
          letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        labelSmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.background : AppColors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.locked,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }

  static BoxDecoration get screenBackground => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E2447), AppColors.background, Color(0xFF08152B)],
          stops: [0.0, 0.55, 1.0],
        ),
      );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryDark],
  );

  static const LinearGradient titleGradient = LinearGradient(
    colors: [AppColors.textPrimary, AppColors.accent],
  );

  /// Frosted card used by overlays, tiles, and the board frame.
  static BoxDecoration glassCard({double radius = 24, Color? borderColor}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF223B69), Color(0xFF152B52)],
      ),
      border: Border.all(color: borderColor ?? AppColors.glassBorder),
      boxShadow: const [
        BoxShadow(color: Color(0x55000000), blurRadius: 28, offset: Offset(0, 14)),
      ],
    );
  }

  static BoxDecoration chip({Color? fill, Color? borderColor}) {
    return BoxDecoration(
      color: fill ?? AppColors.glassFill,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: borderColor ?? AppColors.glassBorder),
    );
  }

  static const Duration shortAnim = Duration(milliseconds: 150);
  static const Duration mediumAnim = Duration(milliseconds: 250);
  static const Duration moveAnim = Duration(milliseconds: 130);
}
