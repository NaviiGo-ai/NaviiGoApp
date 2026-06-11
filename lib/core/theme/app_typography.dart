import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  // Outfit for headings & premium titles
  static TextStyle get headingStyle => GoogleFonts.outfit();
  
  // Inter for clean, readable UI text and metrics
  static TextStyle get bodyStyle => GoogleFonts.inter();

  static TextTheme textTheme(Color textColor) {
    return TextTheme(
      displayLarge: headingStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: -0.5,
      ),
      displayMedium: headingStyle.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      titleLarge: headingStyle.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: headingStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodyLarge: bodyStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textColor,
        letterSpacing: 0.15,
      ),
      bodyMedium: bodyStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      labelLarge: bodyStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.5,
      ),
    );
  }
}
