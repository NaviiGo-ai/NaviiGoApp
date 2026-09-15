import 'package:flutter/material.dart';

/// Official Naviigo Brand Design Tokens
/// Source: Naviigo Website Brand System & Mobile Design Tokens
class AppColors {
  AppColors._();

  // Core Brand Colors
  static const Color primary = Color(0xFFEC6426); // Primary Action Orange
  static const Color primaryDark = Color(0xFFC84F18); // Pressed/Dark Orange
  static const Color yellow = Color(0xFFF8A91F); // Accent Highlight / Stars
  static const Color secondary = yellow;
  static const Color brown = Color(0xFF632713); // Editorial Depth / Mastheads
  static const Color cream = Color(
    0xFFFDE3CF,
  ); // Warm Material / Pills / Highlights
  static const Color warmCream = cream;
  static const Color teal = Color(
    0xFF00666A,
  ); // Live State / Genuine Travel / Safe Status

  // Neutral & Atmosphere Palette
  static const Color background = Color(0xFFFDF8F5); // Warm Paper Atmosphere
  static const Color canvas = background;
  static const Color surface = Color(0xFFFFFFFF); // Clean Card/Sheet Surface
  static const Color surfaceWarm = Color(
    0xFFF8F2EC,
  ); // Subtle Warm Paper Container
  static const Color surfaceMuted = Color(0xFFF1EAE2); // Elevated Surface

  // Typography Colors
  static const Color textPrimary = Color(0xFF24323A); // Editorial Dark Charcoal
  static const Color textSecondary = Color(0xFF6E7A82); // Muted Editorial Grey
  static const Color textTertiary = Color(0xFF9EAAB2); // Micro-metadata
  static const Color textInverse = Color(0xFFFFFFFF); // On dark/photo overlays

  // Borders & Dividers
  static const Color border = Color(0xFFEFE6DD); // Subtle Hairline Border
  static const Color borderStrong = Color(
    0xFFDCCFC4,
  ); // Focused / Emphasized Border

  // Semantic Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Intentional Shadows (Soft, Warm, Minimal - No Heavy FinTech Drops)
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF632713).withAlpha((0.04 * 255).round()),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: const Color(0xFF24323A).withAlpha((0.08 * 255).round()),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
