import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/core/adaptive/adaptive_experience_controller.dart';
import 'package:naviigo_app/core/adaptive/adaptive_experience_profile.dart';
import 'package:naviigo_app/core/adaptive/adaptive_experience_state.dart';
import 'package:naviigo_app/core/adaptive/adaptive_motion_profile.dart';
import 'package:naviigo_app/core/adaptive/adaptive_theme_extension.dart';
import 'package:naviigo_app/core/theme/app_colors.dart';
import 'package:naviigo_app/features/profile/domain/models/user_preferences_model.dart';

void main() {
  const controller = AdaptiveExperienceController();

  test('identical inputs resolve to an identical experience state', () {
    const inputs = AdaptiveExperienceInputs(
      preferences: AdaptiveUserPreferenceProfile(
        travelStyle: 'relaxed',
        interests: ['culture'],
      ),
      destination: AdaptiveDestinationContext(
        category: AdaptiveDestinationCategory.culture,
      ),
      lifecycle: AdaptiveJourneyLifecycle.discover,
    );

    expect(controller.resolve(inputs), controller.resolve(inputs));
  });

  test('missing preferences resolve to the brand base', () {
    final state = controller.resolve(const AdaptiveExperienceInputs());

    expect(state.profile, AdaptiveExperienceProfile.brandBase);
    expect(state.theme, AdaptiveThemeExtension.brandBase);
  });

  test('disabled adaptive appearance resolves to the standard brand theme', () {
    final state = controller.resolve(
      const AdaptiveExperienceInputs(
        preferences: AdaptiveUserPreferenceProfile(
          interests: ['adventure'],
          adaptiveAppearanceEnabled: false,
        ),
        lifecycle: AdaptiveJourneyLifecycle.activeTrip,
      ),
    );

    expect(state.profile, AdaptiveExperienceProfile.brandBase);
    expect(state.theme, AdaptiveThemeExtension.brandBase);
    expect(state.adaptiveAppearanceEnabled, isFalse);
  });

  test('active lifecycle resolves to the active trip profile', () {
    final state = controller.resolve(
      const AdaptiveExperienceInputs(
        lifecycle: AdaptiveJourneyLifecycle.activeTrip,
      ),
    );

    expect(state.profile, AdaptiveExperienceProfile.activeTrip);
    expect(state.motion, AdaptiveMotionProfile.activeTrip);
  });

  test('reduced motion uses the bounded reduced motion profile', () {
    final state = controller.resolve(
      const AdaptiveExperienceInputs(
        lifecycle: AdaptiveJourneyLifecycle.discover,
        accessibility: AdaptiveAccessibilityConstraints(reduceMotion: true),
      ),
    );

    expect(state.motion, AdaptiveMotionProfile.reduced);
    expect(state.motion.allowDecorativeMotion, isFalse);
    expect(state.motion.themeTransition.inMilliseconds, 1);
  });

  test('semantic status colors remain invariant across adaptive profiles', () {
    for (final category in AdaptiveDestinationCategory.values) {
      final state = controller.resolve(
        AdaptiveExperienceInputs(
          destination: AdaptiveDestinationContext(category: category),
          lifecycle: AdaptiveJourneyLifecycle.discover,
        ),
      );

      expect(state.theme.success, AppColors.success);
      expect(state.theme.warning, AppColors.warning);
      expect(state.theme.error, AppColors.error);
    }
  });

  test('resolved adaptive colors stay inside the Naviigo token palette', () {
    final approved = {
      AppColors.primary.toARGB32(),
      AppColors.primaryDark.toARGB32(),
      AppColors.yellow.toARGB32(),
      AppColors.brown.toARGB32(),
      AppColors.cream.toARGB32(),
      AppColors.teal.toARGB32(),
      AppColors.background.toARGB32(),
      AppColors.surface.toARGB32(),
      AppColors.surfaceWarm.toARGB32(),
      AppColors.surfaceMuted.toARGB32(),
      AppColors.textPrimary.toARGB32(),
      AppColors.textSecondary.toARGB32(),
      AppColors.textTertiary.toARGB32(),
      AppColors.border.toARGB32(),
      AppColors.borderStrong.toARGB32(),
      AppColors.success.toARGB32(),
      AppColors.warning.toARGB32(),
      AppColors.error.toARGB32(),
    };

    for (final lifecycle in AdaptiveJourneyLifecycle.values) {
      for (final category in AdaptiveDestinationCategory.values) {
        final theme = controller
            .resolve(
              AdaptiveExperienceInputs(
                lifecycle: lifecycle,
                destination: AdaptiveDestinationContext(category: category),
              ),
            )
            .theme;
        final colors = [
          theme.background,
          theme.surface,
          theme.surfaceWarm,
          theme.surfaceMuted,
          theme.accentEmphasis,
          theme.secondaryEmphasis,
          theme.journeyLineCompleted,
          theme.journeyLineActive,
          theme.journeyLineFuture,
          theme.journeyLineFutureBorder,
          theme.journeyLineHalo,
          theme.border,
          theme.borderStrong,
          theme.textPrimary,
          theme.textSecondary,
          theme.textTertiary,
          theme.primaryAction,
          theme.editorialBrown,
          theme.success,
          theme.warning,
          theme.error,
        ];

        for (final color in colors) {
          expect(
            approved.contains(color.toARGB32()),
            isTrue,
            reason: '$color is not approved',
          );
        }
      }
    }
  });

  test('lifecycle changes update the resolved profile', () {
    final discover = controller.resolve(const AdaptiveExperienceInputs());
    final active = controller.resolve(
      const AdaptiveExperienceInputs(
        lifecycle: AdaptiveJourneyLifecycle.activeTrip,
      ),
    );

    expect(discover.profile, isNot(active.profile));
    expect(active.isActiveTrip, isTrue);
  });

  test('repeated resolutions do not randomize the profile', () {
    const inputs = AdaptiveExperienceInputs(
      preferences: AdaptiveUserPreferenceProfile(preferredGroup: 'friends'),
    );
    final first = controller.resolve(inputs);

    for (var i = 0; i < 25; i++) {
      expect(controller.resolve(inputs), first);
    }
  });

  test(
    'adaptive appearance preference defaults safely and persists opt-out',
    () {
      const defaults = UserPreferencesModel();
      expect(defaults.adaptiveAppearanceEnabled, isTrue);
      expect(defaults.toMap(), isEmpty);

      const disabled = UserPreferencesModel(adaptiveAppearanceEnabled: false);
      expect(disabled.toMap()['adaptiveAppearanceEnabled'], isFalse);
      expect(
        UserPreferencesModel.fromMap(
          disabled.toMap(),
        ).adaptiveAppearanceEnabled,
        isFalse,
      );
    },
  );
}
