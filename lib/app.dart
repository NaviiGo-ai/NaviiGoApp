import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

class NaviiGoApp extends StatelessWidget {
  const NaviiGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Standard layout size reference design for scaling (e.g., iPhone 13/14 Pro dimensions)
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'NaviiGo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark, // Default to dark premium aesthetic
          routerConfig: appRouter,
        );
      },
    );
  }
}
