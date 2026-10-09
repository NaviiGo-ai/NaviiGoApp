import 'package:flutter/widgets.dart';

import '../motion/nav_motion.dart';

/// Bounded motion output for an adaptive experience.
@immutable
class AdaptiveMotionProfile {
  final Duration themeTransition;
  final Duration heroReveal;
  final Duration sectionReveal;
  final Duration cardTransition;
  final double energy;
  final bool allowDecorativeMotion;

  const AdaptiveMotionProfile({
    required this.themeTransition,
    required this.heroReveal,
    required this.sectionReveal,
    required this.cardTransition,
    required this.energy,
    required this.allowDecorativeMotion,
  });

  static const AdaptiveMotionProfile editorial = AdaptiveMotionProfile(
    themeTransition: NavMotion.editorial,
    heroReveal: NavMotion.editorial,
    sectionReveal: NavMotion.standard,
    cardTransition: NavMotion.fast,
    energy: 0.65,
    allowDecorativeMotion: true,
  );

  static const AdaptiveMotionProfile activeTrip = AdaptiveMotionProfile(
    themeTransition: Duration(milliseconds: 350),
    heroReveal: NavMotion.fast,
    sectionReveal: NavMotion.fast,
    cardTransition: NavMotion.instant,
    energy: 0.2,
    allowDecorativeMotion: false,
  );

  static const AdaptiveMotionProfile reduced = AdaptiveMotionProfile(
    themeTransition: Duration(milliseconds: 1),
    heroReveal: Duration(milliseconds: 1),
    sectionReveal: Duration(milliseconds: 1),
    cardTransition: Duration(milliseconds: 1),
    energy: 0.0,
    allowDecorativeMotion: false,
  );

  @override
  bool operator ==(Object other) {
    return other is AdaptiveMotionProfile &&
        other.themeTransition == themeTransition &&
        other.heroReveal == heroReveal &&
        other.sectionReveal == sectionReveal &&
        other.cardTransition == cardTransition &&
        other.energy == energy &&
        other.allowDecorativeMotion == allowDecorativeMotion;
  }

  @override
  int get hashCode => Object.hash(
    themeTransition,
    heroReveal,
    sectionReveal,
    cardTransition,
    energy,
    allowDecorativeMotion,
  );
}

class AdaptiveMotionScope extends InheritedWidget {
  final AdaptiveMotionProfile profile;

  const AdaptiveMotionScope({
    super.key,
    required this.profile,
    required super.child,
  });

  static AdaptiveMotionProfile? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AdaptiveMotionScope>()
        ?.profile;
  }

  @override
  bool updateShouldNotify(AdaptiveMotionScope oldWidget) {
    return oldWidget.profile != profile;
  }
}
