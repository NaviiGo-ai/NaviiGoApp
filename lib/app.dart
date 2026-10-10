import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/adaptive/adaptive_experience_profile.dart';
import 'core/adaptive/adaptive_motion_profile.dart';
import 'core/adaptive/adaptive_experience_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/profile/presentation/providers/user_provider.dart';
import 'features/trips/presentation/providers/trip_provider.dart';

class NaviiGoApp extends ConsumerWidget {
  const NaviiGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final preferences = ref.watch(safeAdaptivePreferencesProvider);
    final activeTrip = ref.watch(activeTripProvider);
    final lifecycle = ref.watch(adaptiveJourneyLifecycleProvider);
    final destinationCategory = AdaptiveDestinationCategoryParsing.fromExplicit(
      activeTrip?.form['purpose']?.toString(),
    );
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ??
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations;
    final experience = ref.watch(
      adaptiveExperienceProvider(
        AdaptiveExperienceInputs(
          preferences: AdaptiveUserPreferenceProfile(
            travelStyle: preferences.travelStyle,
            preferredGroup: preferences.preferredGroup,
            interests: preferences.interests,
            accessibilityNeeds: preferences.accessibilityNeeds,
            adaptiveAppearanceEnabled: preferences.adaptiveAppearanceEnabled,
          ),
          lifecycle: lifecycle,
          destination: AdaptiveDestinationContext(
            category: destinationCategory,
          ),
          accessibility: AdaptiveAccessibilityConstraints(
            reduceMotion: reduceMotion,
          ),
        ),
      ),
    );

    // Standard layout size reference design for scaling (e.g., iPhone 13/14 Pro dimensions)
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'NaviiGo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(adaptive: experience.theme),
          darkTheme: AppTheme.darkTheme(adaptive: experience.theme),
          themeMode: ThemeMode
              .light, // Default to warm paper Naviigo editorial aesthetic
          themeAnimationDuration: experience.motion.themeTransition,
          themeAnimationCurve: Curves.easeOutQuart,
          builder: (context, child) => AdaptiveMotionScope(
            profile: experience.motion,
            child: child ?? const SizedBox.shrink(),
          ),
          restorationScopeId: 'naviigo',
          routerConfig: router,
        );
      },
    );
  }
}
