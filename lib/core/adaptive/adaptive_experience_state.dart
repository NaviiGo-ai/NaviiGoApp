import 'package:flutter/foundation.dart';

import 'adaptive_experience_profile.dart';
import 'adaptive_motion_profile.dart';
import 'adaptive_theme_extension.dart';

enum AdaptiveExperienceProfile {
  brandBase,
  discoverCulture,
  discoverAdventure,
  discoverFoodSocial,
  relaxed,
  planning,
  upcoming,
  activeTrip,
  postTrip,
}

@immutable
class AdaptiveExperienceState {
  final AdaptiveExperienceProfile profile;
  final AdaptiveJourneyLifecycle lifecycle;
  final AdaptiveDestinationCategory destinationCategory;
  final AdaptiveThemeExtension theme;
  final AdaptiveMotionProfile motion;
  final bool adaptiveAppearanceEnabled;

  const AdaptiveExperienceState({
    required this.profile,
    required this.lifecycle,
    required this.destinationCategory,
    required this.theme,
    required this.motion,
    required this.adaptiveAppearanceEnabled,
  });

  bool get isActiveTrip => lifecycle == AdaptiveJourneyLifecycle.activeTrip;

  @override
  bool operator ==(Object other) {
    return other is AdaptiveExperienceState &&
        other.profile == profile &&
        other.lifecycle == lifecycle &&
        other.destinationCategory == destinationCategory &&
        other.theme == theme &&
        other.motion == motion &&
        other.adaptiveAppearanceEnabled == adaptiveAppearanceEnabled;
  }

  @override
  int get hashCode => Object.hash(
    profile,
    lifecycle,
    destinationCategory,
    theme,
    motion,
    adaptiveAppearanceEnabled,
  );
}
