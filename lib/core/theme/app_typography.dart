import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Official Naviigo Typography Scale
/// Epilogue: Large titles, destination names, chapter headings, editorial moments
/// Plus Jakarta Sans: Body, buttons, labels, forms, navigation, metadata
class AppTypography {
  AppTypography._();

  // Epilogue styles (Editorial & Display)
  static TextStyle get epilogue => GoogleFonts.epilogue();

  // Plus Jakarta Sans styles (UI & Body)
  static TextStyle get plusJakartaSans => GoogleFonts.plusJakartaSans();

  // Display Hero: For opening destination & story splash
  static TextStyle displayHero({Color color = AppColors.textPrimary}) =>
      GoogleFonts.epilogue(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.8,
        height: 1.12,
      );

  // Editorial Title: Chapter headings, Day headers, Mastheads
  static TextStyle editorialTitle({Color color = AppColors.textPrimary}) =>
      GoogleFonts.epilogue(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.4,
        height: 1.2,
      );

  // Section Title: Major section groupings
  static TextStyle sectionTitle({Color color = AppColors.textPrimary}) =>
      GoogleFonts.epilogue(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.2,
        height: 1.25,
      );

  // Trip Title: Card headers & waypoint summaries
  static TextStyle tripTitle({Color color = AppColors.textPrimary}) =>
      GoogleFonts.epilogue(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.2,
      );

  // Eyebrow / Overline: Category tags, step labels, context overline
  static TextStyle eyebrow({Color color = AppColors.primary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.4,
      );

  // Body Large: Primary lead text
  static TextStyle bodyLarge({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        letterSpacing: 0.1,
        height: 1.45,
      );

  // Body Medium: Standard app body copy
  static TextStyle bodyMedium({Color color = AppColors.textSecondary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        letterSpacing: 0.1,
        height: 1.4,
      );

  // Body Small / Caption
  static TextStyle bodySmall({Color color = AppColors.textSecondary}) =>
      caption(color: color);

  // Button: Primary/Secondary actions
  static TextStyle button({Color color = Colors.white}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.4,
      );

  // Caption / Utility: Subtle metadata & counters
  static TextStyle caption({Color color = AppColors.textSecondary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.2,
      );

  // Micro Metadata: Timestamps, distance, badges
  static TextStyle micro({Color color = AppColors.textTertiary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.5,
      );

  // Complete Material TextTheme mapping
  static TextTheme textTheme({Color defaultColor = AppColors.textPrimary}) {
    return TextTheme(
      displayLarge: displayHero(color: defaultColor),
      displayMedium: editorialTitle(color: defaultColor),
      titleLarge: sectionTitle(color: defaultColor),
      titleMedium: tripTitle(color: defaultColor),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: defaultColor,
      ),
      bodyLarge: bodyLarge(color: defaultColor),
      bodyMedium: bodyMedium(
        color: defaultColor == Colors.white
            ? Colors.white70
            : AppColors.textSecondary,
      ),
      bodySmall: caption(
        color: defaultColor == Colors.white
            ? Colors.white60
            : AppColors.textSecondary,
      ),
      labelLarge: button(color: defaultColor),
      labelMedium: caption(color: defaultColor),
      labelSmall: micro(color: defaultColor),
    );
  }
}
