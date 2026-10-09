import 'package:flutter/foundation.dart';

/// Stable lifecycle contexts that may influence presentation rhythm.
enum AdaptiveJourneyLifecycle {
  discover,
  planning,
  upcoming,
  activeTrip,
  postTrip,
}

/// Explicit destination categories understood by the adaptive system.
///
/// These values are presentation hints only. They do not replace the Website's
/// destination, recommendation, or personalization logic.
enum AdaptiveDestinationCategory {
  neutral,
  culture,
  heritage,
  nature,
  adventure,
  food,
  social,
  beach,
  spiritual,
}

extension AdaptiveDestinationCategoryParsing on AdaptiveDestinationCategory {
  static AdaptiveDestinationCategory fromExplicit(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) return AdaptiveDestinationCategory.neutral;
    if (value.contains('heritage') || value.contains('culture')) {
      return AdaptiveDestinationCategory.culture;
    }
    if (value.contains('spiritual') || value.contains('sacred')) {
      return AdaptiveDestinationCategory.spiritual;
    }
    if (value.contains('adventure') || value.contains('wildlife')) {
      return AdaptiveDestinationCategory.adventure;
    }
    if (value.contains('nature') || value.contains('mountain')) {
      return AdaptiveDestinationCategory.nature;
    }
    if (value.contains('food') || value.contains('culinary')) {
      return AdaptiveDestinationCategory.food;
    }
    if (value.contains('social') || value.contains('nightlife')) {
      return AdaptiveDestinationCategory.social;
    }
    if (value.contains('beach') || value.contains('coast')) {
      return AdaptiveDestinationCategory.beach;
    }
    return AdaptiveDestinationCategory.neutral;
  }
}

/// Weather/daylight context supplied by a real source when available.
///
/// Missing values deliberately remain null. The adaptive system never guesses
/// weather or local time to manufacture an atmosphere.
@immutable
class AdaptiveDestinationContext {
  final AdaptiveDestinationCategory category;
  final String? realWeatherCondition;
  final bool? isLocalNight;

  const AdaptiveDestinationContext({
    this.category = AdaptiveDestinationCategory.neutral,
    this.realWeatherCondition,
    this.isLocalNight,
  });

  const AdaptiveDestinationContext.neutral() : this();

  AdaptiveDestinationContext copyWith({
    AdaptiveDestinationCategory? category,
    String? realWeatherCondition,
    bool? isLocalNight,
  }) {
    return AdaptiveDestinationContext(
      category: category ?? this.category,
      realWeatherCondition: realWeatherCondition ?? this.realWeatherCondition,
      isLocalNight: isLocalNight ?? this.isLocalNight,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AdaptiveDestinationContext &&
        other.category == category &&
        other.realWeatherCondition == realWeatherCondition &&
        other.isLocalNight == isLocalNight;
  }

  @override
  int get hashCode => Object.hash(category, realWeatherCondition, isLocalNight);
}

/// Explicit user inputs that are safe for the visual system to consume.
@immutable
class AdaptiveUserPreferenceProfile {
  final String? travelStyle;
  final String? preferredGroup;
  final List<String> interests;
  final List<String> accessibilityNeeds;
  final bool adaptiveAppearanceEnabled;

  const AdaptiveUserPreferenceProfile({
    this.travelStyle,
    this.preferredGroup,
    this.interests = const [],
    this.accessibilityNeeds = const [],
    this.adaptiveAppearanceEnabled = true,
  });

  const AdaptiveUserPreferenceProfile.defaultProfile()
    : this(adaptiveAppearanceEnabled: true);

  AdaptiveDestinationCategory get categoryHint {
    for (final interest in interests) {
      final category = AdaptiveDestinationCategoryParsing.fromExplicit(
        interest,
      );
      if (category != AdaptiveDestinationCategory.neutral) return category;
    }
    return AdaptiveDestinationCategory.neutral;
  }

  @override
  bool operator ==(Object other) {
    return other is AdaptiveUserPreferenceProfile &&
        other.travelStyle == travelStyle &&
        other.preferredGroup == preferredGroup &&
        listEquals(other.interests, interests) &&
        listEquals(other.accessibilityNeeds, accessibilityNeeds) &&
        other.adaptiveAppearanceEnabled == adaptiveAppearanceEnabled;
  }

  @override
  int get hashCode => Object.hash(
    travelStyle,
    preferredGroup,
    Object.hashAll(interests),
    Object.hashAll(accessibilityNeeds),
    adaptiveAppearanceEnabled,
  );
}

/// Platform/user accessibility constraints supplied by the composition root.
@immutable
class AdaptiveAccessibilityConstraints {
  final bool reduceMotion;
  final bool highContrast;

  const AdaptiveAccessibilityConstraints({
    this.reduceMotion = false,
    this.highContrast = false,
  });

  @override
  bool operator ==(Object other) {
    return other is AdaptiveAccessibilityConstraints &&
        other.reduceMotion == reduceMotion &&
        other.highContrast == highContrast;
  }

  @override
  int get hashCode => Object.hash(reduceMotion, highContrast);
}

/// All inputs used by the deterministic controller.
@immutable
class AdaptiveExperienceInputs {
  final AdaptiveUserPreferenceProfile preferences;
  final AdaptiveJourneyLifecycle lifecycle;
  final AdaptiveDestinationContext destination;
  final AdaptiveAccessibilityConstraints accessibility;

  const AdaptiveExperienceInputs({
    this.preferences = const AdaptiveUserPreferenceProfile.defaultProfile(),
    this.lifecycle = AdaptiveJourneyLifecycle.discover,
    this.destination = const AdaptiveDestinationContext.neutral(),
    this.accessibility = const AdaptiveAccessibilityConstraints(),
  });

  @override
  bool operator ==(Object other) {
    return other is AdaptiveExperienceInputs &&
        other.preferences == preferences &&
        other.lifecycle == lifecycle &&
        other.destination == destination &&
        other.accessibility == accessibility;
  }

  @override
  int get hashCode =>
      Object.hash(preferences, lifecycle, destination, accessibility);
}
