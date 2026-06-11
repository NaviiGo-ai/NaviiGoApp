import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 &&
      MediaQuery.sizeOf(context).width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1200;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200 && desktop != null) {
      return desktop!;
    } else if (width >= 600 && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

// Spacing Utilities built on ScreenUtil to make padding and margins responsive.
class AppSpacing {
  AppSpacing._();

  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 16.h;
  static double get lg => 24.h;
  static double get xl => 32.h;
  static double get xxl => 48.h;

  static double get xsW => 4.w;
  static double get smW => 8.w;
  static double get mdW => 16.w;
  static double get lgW => 24.w;
  static double get xlW => 32.w;
  static double get xxlW => 48.w;

  static SizedBox get heightXs => SizedBox(height: xs);
  static SizedBox get heightSm => SizedBox(height: sm);
  static SizedBox get heightMd => SizedBox(height: md);
  static SizedBox get heightLg => SizedBox(height: lg);
  static SizedBox get heightXl => SizedBox(height: xl);

  static SizedBox get widthXs => SizedBox(width: xsW);
  static SizedBox get widthSm => SizedBox(width: smW);
  static SizedBox get widthMd => SizedBox(width: mdW);
  static SizedBox get widthLg => SizedBox(width: lgW);
  static SizedBox get widthXl => SizedBox(width: xlW);
}
