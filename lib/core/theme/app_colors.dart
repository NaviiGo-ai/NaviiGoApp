import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark Theme Colors (Primary Choice for NaviiGo)
  static const Color darkBg = Color(0xFF0F111A);
  static const Color darkSurface = Color(0xFF161926);
  static const Color darkCard = Color(0xFF1E2235);
  
  // Light Theme Colors (Clean, Premium, High Contrast)
  static const Color lightBg = Color(0xFFF7F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFEFF1F8);

  // Brand Accents
  static const Color primary = Color(0xFF6366F1); // Royal Indigo
  static const Color secondary = Color(0xFFEC4899); // Electric Pink
  static const Color accent = Color(0xFF06B6D4); // Cyber Cyan
  
  // Functional Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  
  // Gradients for Premium Glassmorphic feel
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient cyberGradient = LinearGradient(
    colors: [accent, primary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static Gradient darkGlassGradient = LinearGradient(
    colors: [
      Colors.white.withOpacity(0.08),
      Colors.white.withOpacity(0.03),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Gradient lightGlassGradient = LinearGradient(
    colors: [
      Colors.white.withOpacity(0.7),
      Colors.white.withOpacity(0.4),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 16,
      spreadRadius: -4,
      offset: Offset(0, 8),
    ),
  ];
}
