import 'package:flutter/material.dart';
import '../adaptive/adaptive_theme_extension.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Naviigo Theme Configuration
/// Primary: Warm Paper / Editorial Aesthetic
class AppTheme {
  AppTheme._();

  static ThemeData lightTheme({AdaptiveThemeExtension? adaptive}) {
    final tokens = adaptive ?? AdaptiveThemeExtension.brandBase;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: tokens.background,
      primaryColor: tokens.primaryAction,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.yellow,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: AppTypography.textTheme(defaultColor: tokens.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: tokens.textPrimary),
        titleTextStyle: TextStyle(
          color: tokens.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primaryAction,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.buttonRadius),
          ),
          textStyle: AppTypography.button(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          side: BorderSide(color: tokens.borderStrong, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.buttonRadius),
          ),
          textStyle: AppTypography.button(color: tokens.textPrimary),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 24,
      ),
      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }

  // Dark theme aligned with editorial depth (dark brown/charcoal instead of generic cyber cyan/neon)
  static ThemeData darkTheme({AdaptiveThemeExtension? adaptive}) {
    final tokens = adaptive ?? AdaptiveThemeExtension.brandBase;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF191D20),
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.yellow,
        surface: Color(0xFF22272B),
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: AppTypography.textTheme(defaultColor: Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF22272B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withAlpha((0.08 * 255).round()),
            width: 1,
          ),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }
}
