import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'adaptive_experience_profile.dart';
import 'adaptive_experience_state.dart';
import 'adaptive_motion_profile.dart';
import 'adaptive_theme_extension.dart';

/// Central deterministic resolver for Naviigo's bounded visual adaptation.
///
/// This class has no randomness, network calls, AI calls, or page-specific
/// rules. Its inputs are stable product boundaries and its outputs remain
/// inside the Naviigo brand token set.
class AdaptiveExperienceController {
  const AdaptiveExperienceController();

  AdaptiveExperienceState resolve(AdaptiveExperienceInputs inputs) {
    final category = _resolveCategory(inputs);
    final appearanceEnabled = inputs.preferences.adaptiveAppearanceEnabled;
    final profile = appearanceEnabled
        ? _resolveProfile(inputs.lifecycle, category, inputs.preferences)
        : AdaptiveExperienceProfile.brandBase;
    final theme = appearanceEnabled
        ? _themeFor(profile, inputs.destination)
        : AdaptiveThemeExtension.brandBase;
    final motion = _motionFor(
      profile,
      inputs.lifecycle,
      inputs.accessibility.reduceMotion,
    );

    return AdaptiveExperienceState(
      profile: profile,
      lifecycle: inputs.lifecycle,
      destinationCategory: category,
      theme: theme,
      motion: motion,
      adaptiveAppearanceEnabled: appearanceEnabled,
    );
  }

  AdaptiveDestinationCategory _resolveCategory(
    AdaptiveExperienceInputs inputs,
  ) {
    if (inputs.destination.category != AdaptiveDestinationCategory.neutral) {
      return inputs.destination.category;
    }
    return inputs.preferences.categoryHint;
  }

  AdaptiveExperienceProfile _resolveProfile(
    AdaptiveJourneyLifecycle lifecycle,
    AdaptiveDestinationCategory category,
    AdaptiveUserPreferenceProfile preferences,
  ) {
    switch (lifecycle) {
      case AdaptiveJourneyLifecycle.planning:
        return AdaptiveExperienceProfile.planning;
      case AdaptiveJourneyLifecycle.upcoming:
        return AdaptiveExperienceProfile.upcoming;
      case AdaptiveJourneyLifecycle.activeTrip:
        return AdaptiveExperienceProfile.activeTrip;
      case AdaptiveJourneyLifecycle.postTrip:
        return AdaptiveExperienceProfile.postTrip;
      case AdaptiveJourneyLifecycle.discover:
        break;
    }

    final style = (preferences.travelStyle ?? '').toLowerCase();
    if (style == 'relaxed' || style == 'slow' || style == 'leisure') {
      return AdaptiveExperienceProfile.relaxed;
    }
    if (category == AdaptiveDestinationCategory.culture ||
        category == AdaptiveDestinationCategory.heritage ||
        category == AdaptiveDestinationCategory.spiritual) {
      return AdaptiveExperienceProfile.discoverCulture;
    }
    if (category == AdaptiveDestinationCategory.adventure ||
        category == AdaptiveDestinationCategory.nature ||
        category == AdaptiveDestinationCategory.beach) {
      return AdaptiveExperienceProfile.discoverAdventure;
    }
    if (category == AdaptiveDestinationCategory.food ||
        category == AdaptiveDestinationCategory.social ||
        _isSocialGroup(preferences.preferredGroup)) {
      return AdaptiveExperienceProfile.discoverFoodSocial;
    }
    return AdaptiveExperienceProfile.brandBase;
  }

  bool _isSocialGroup(String? group) {
    final value = (group ?? '').toLowerCase();
    return value == 'couple' ||
        value == 'family' ||
        value == 'friends' ||
        value == 'large';
  }

  AdaptiveMotionProfile _motionFor(
    AdaptiveExperienceProfile profile,
    AdaptiveJourneyLifecycle lifecycle,
    bool reduceMotion,
  ) {
    if (reduceMotion) return AdaptiveMotionProfile.reduced;
    if (profile == AdaptiveExperienceProfile.activeTrip ||
        lifecycle == AdaptiveJourneyLifecycle.activeTrip) {
      return AdaptiveMotionProfile.activeTrip;
    }
    return AdaptiveMotionProfile.editorial;
  }

  AdaptiveThemeExtension _themeFor(
    AdaptiveExperienceProfile profile,
    AdaptiveDestinationContext destination,
  ) {
    final base = AdaptiveThemeExtension.brandBase;
    final weatherSurface = _weatherSurface(destination);

    switch (profile) {
      case AdaptiveExperienceProfile.discoverCulture:
        return base.copyWith(
          surfaceWarm: weatherSurface ?? AppColors.cream,
          accentEmphasis: AppColors.brown,
          secondaryEmphasis: AppColors.primary,
          journeyLineCompleted: AppColors.brown,
          journeyLineActive: AppColors.brown,
          journeyLineHalo: AppColors.primary,
          cardRadius: 22,
          imageProminence: 1.15,
          mapProminence: 0.25,
          informationDensity: 0.8,
        );
      case AdaptiveExperienceProfile.discoverAdventure:
        return base.copyWith(
          surfaceWarm: weatherSurface ?? AppColors.surfaceWarm,
          accentEmphasis: AppColors.teal,
          secondaryEmphasis: AppColors.primary,
          journeyLineCompleted: AppColors.teal,
          journeyLineActive: AppColors.teal,
          journeyLineHalo: AppColors.teal,
          cardRadius: 20,
          imageProminence: 1.15,
          mapProminence: 0.85,
          informationDensity: 0.95,
        );
      case AdaptiveExperienceProfile.discoverFoodSocial:
        return base.copyWith(
          surfaceWarm: weatherSurface ?? AppColors.cream,
          accentEmphasis: AppColors.primary,
          secondaryEmphasis: AppColors.yellow,
          journeyLineCompleted: AppColors.primary,
          journeyLineActive: AppColors.primary,
          journeyLineHalo: AppColors.yellow,
          cardRadius: 18,
          imageProminence: 1.05,
          mapProminence: 0.45,
          informationDensity: 1.15,
        );
      case AdaptiveExperienceProfile.relaxed:
        return base.copyWith(
          surfaceWarm: weatherSurface ?? AppColors.surfaceWarm,
          accentEmphasis: AppColors.brown,
          secondaryEmphasis: AppColors.cream,
          cardRadius: 24,
          imageProminence: 0.95,
          mapProminence: 0.3,
          informationDensity: 0.75,
        );
      case AdaptiveExperienceProfile.planning:
        return base.copyWith(
          surfaceWarm: weatherSurface ?? AppColors.cream,
          accentEmphasis: AppColors.primary,
          secondaryEmphasis: AppColors.brown,
          cardRadius: 18,
          imageProminence: 0.9,
          mapProminence: 0.6,
          informationDensity: 1,
        );
      case AdaptiveExperienceProfile.upcoming:
        return base.copyWith(
          surfaceWarm: weatherSurface ?? AppColors.cream,
          accentEmphasis: AppColors.primary,
          secondaryEmphasis: AppColors.teal,
          cardRadius: 18,
          imageProminence: 1,
          mapProminence: 0.55,
          informationDensity: 1.05,
        );
      case AdaptiveExperienceProfile.activeTrip:
        return base.copyWith(
          surfaceWarm: weatherSurface ?? AppColors.surfaceWarm,
          accentEmphasis: AppColors.teal,
          secondaryEmphasis: AppColors.primary,
          journeyLineCompleted: AppColors.teal,
          journeyLineActive: AppColors.teal,
          journeyLineHalo: AppColors.teal,
          cardRadius: 16,
          imageProminence: 0.75,
          mapProminence: 0.8,
          informationDensity: 1.25,
        );
      case AdaptiveExperienceProfile.postTrip:
        return base.copyWith(
          background: AppColors.cream,
          surfaceWarm: AppColors.surfaceWarm,
          accentEmphasis: AppColors.brown,
          secondaryEmphasis: AppColors.primary,
          journeyLineCompleted: AppColors.brown,
          journeyLineActive: AppColors.brown,
          journeyLineFuture: AppColors.surfaceMuted,
          journeyLineHalo: AppColors.yellow,
          cardRadius: 22,
          imageProminence: 1.1,
          mapProminence: 0.2,
          informationDensity: 0.85,
        );
      case AdaptiveExperienceProfile.brandBase:
        return base.copyWith(surfaceWarm: weatherSurface ?? base.surfaceWarm);
    }
  }

  /// Weather changes only supporting warmth. Unknown conditions remain neutral.
  Color? _weatherSurface(AdaptiveDestinationContext destination) {
    if (destination.isLocalNight == true) return AppColors.surfaceMuted;
    final condition = (destination.realWeatherCondition ?? '').toLowerCase();
    if (condition.contains('rain') || condition.contains('storm')) {
      return AppColors.surfaceMuted;
    }
    return null;
  }
}
