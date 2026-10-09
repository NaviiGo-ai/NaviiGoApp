import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Semantic theme tokens consumed by shared Flutter surfaces.
///
/// Adaptive values are selected from the fixed Naviigo palette. The immutable
/// brand colors and semantic status colors are always present and never
/// generated or replaced by user-specific colors.
@immutable
class AdaptiveThemeExtension extends ThemeExtension<AdaptiveThemeExtension> {
  final Color background;
  final Color surface;
  final Color surfaceWarm;
  final Color surfaceMuted;
  final Color accentEmphasis;
  final Color secondaryEmphasis;
  final Color journeyLineCompleted;
  final Color journeyLineActive;
  final Color journeyLineFuture;
  final Color journeyLineFutureBorder;
  final Color journeyLineHalo;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color primaryAction;
  final Color editorialBrown;
  final Color success;
  final Color warning;
  final Color error;
  final double cardRadius;
  final double buttonRadius;
  final double imageProminence;
  final double mapProminence;
  final double informationDensity;

  const AdaptiveThemeExtension({
    required this.background,
    required this.surface,
    required this.surfaceWarm,
    required this.surfaceMuted,
    required this.accentEmphasis,
    required this.secondaryEmphasis,
    required this.journeyLineCompleted,
    required this.journeyLineActive,
    required this.journeyLineFuture,
    required this.journeyLineFutureBorder,
    required this.journeyLineHalo,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primaryAction,
    required this.editorialBrown,
    required this.success,
    required this.warning,
    required this.error,
    required this.cardRadius,
    required this.buttonRadius,
    required this.imageProminence,
    required this.mapProminence,
    required this.informationDensity,
  });

  static const AdaptiveThemeExtension brandBase = AdaptiveThemeExtension(
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceWarm: AppColors.surfaceWarm,
    surfaceMuted: AppColors.surfaceMuted,
    accentEmphasis: AppColors.primary,
    secondaryEmphasis: AppColors.yellow,
    journeyLineCompleted: AppColors.primary,
    journeyLineActive: AppColors.primary,
    journeyLineFuture: AppColors.surfaceWarm,
    journeyLineFutureBorder: AppColors.borderStrong,
    journeyLineHalo: AppColors.primary,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    primaryAction: AppColors.primary,
    editorialBrown: AppColors.brown,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    cardRadius: 16,
    buttonRadius: 24,
    imageProminence: 1,
    mapProminence: 0.5,
    informationDensity: 1,
  );

  static AdaptiveThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<AdaptiveThemeExtension>() ?? brandBase;
  }

  @override
  AdaptiveThemeExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceWarm,
    Color? surfaceMuted,
    Color? accentEmphasis,
    Color? secondaryEmphasis,
    Color? journeyLineCompleted,
    Color? journeyLineActive,
    Color? journeyLineFuture,
    Color? journeyLineFutureBorder,
    Color? journeyLineHalo,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? primaryAction,
    Color? editorialBrown,
    Color? success,
    Color? warning,
    Color? error,
    double? cardRadius,
    double? buttonRadius,
    double? imageProminence,
    double? mapProminence,
    double? informationDensity,
  }) {
    return AdaptiveThemeExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceWarm: surfaceWarm ?? this.surfaceWarm,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      accentEmphasis: accentEmphasis ?? this.accentEmphasis,
      secondaryEmphasis: secondaryEmphasis ?? this.secondaryEmphasis,
      journeyLineCompleted: journeyLineCompleted ?? this.journeyLineCompleted,
      journeyLineActive: journeyLineActive ?? this.journeyLineActive,
      journeyLineFuture: journeyLineFuture ?? this.journeyLineFuture,
      journeyLineFutureBorder:
          journeyLineFutureBorder ?? this.journeyLineFutureBorder,
      journeyLineHalo: journeyLineHalo ?? this.journeyLineHalo,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      primaryAction: primaryAction ?? this.primaryAction,
      editorialBrown: editorialBrown ?? this.editorialBrown,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      cardRadius: cardRadius ?? this.cardRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      imageProminence: imageProminence ?? this.imageProminence,
      mapProminence: mapProminence ?? this.mapProminence,
      informationDensity: informationDensity ?? this.informationDensity,
    );
  }

  @override
  AdaptiveThemeExtension lerp(
    covariant AdaptiveThemeExtension? other,
    double t,
  ) {
    if (other == null) return this;
    return AdaptiveThemeExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceWarm: Color.lerp(surfaceWarm, other.surfaceWarm, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      accentEmphasis: Color.lerp(accentEmphasis, other.accentEmphasis, t)!,
      secondaryEmphasis: Color.lerp(
        secondaryEmphasis,
        other.secondaryEmphasis,
        t,
      )!,
      journeyLineCompleted: Color.lerp(
        journeyLineCompleted,
        other.journeyLineCompleted,
        t,
      )!,
      journeyLineActive: Color.lerp(
        journeyLineActive,
        other.journeyLineActive,
        t,
      )!,
      journeyLineFuture: Color.lerp(
        journeyLineFuture,
        other.journeyLineFuture,
        t,
      )!,
      journeyLineFutureBorder: Color.lerp(
        journeyLineFutureBorder,
        other.journeyLineFutureBorder,
        t,
      )!,
      journeyLineHalo: Color.lerp(journeyLineHalo, other.journeyLineHalo, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      primaryAction: Color.lerp(primaryAction, other.primaryAction, t)!,
      editorialBrown: Color.lerp(editorialBrown, other.editorialBrown, t)!,
      success: success,
      warning: warning,
      error: error,
      cardRadius: _lerp(cardRadius, other.cardRadius, t),
      buttonRadius: _lerp(buttonRadius, other.buttonRadius, t),
      imageProminence: _lerp(imageProminence, other.imageProminence, t),
      mapProminence: _lerp(mapProminence, other.mapProminence, t),
      informationDensity: _lerp(
        informationDensity,
        other.informationDensity,
        t,
      ),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool operator ==(Object other) {
    return other is AdaptiveThemeExtension &&
        other.background == background &&
        other.surface == surface &&
        other.surfaceWarm == surfaceWarm &&
        other.surfaceMuted == surfaceMuted &&
        other.accentEmphasis == accentEmphasis &&
        other.secondaryEmphasis == secondaryEmphasis &&
        other.journeyLineCompleted == journeyLineCompleted &&
        other.journeyLineActive == journeyLineActive &&
        other.journeyLineFuture == journeyLineFuture &&
        other.journeyLineFutureBorder == journeyLineFutureBorder &&
        other.journeyLineHalo == journeyLineHalo &&
        other.border == border &&
        other.borderStrong == borderStrong &&
        other.textPrimary == textPrimary &&
        other.textSecondary == textSecondary &&
        other.textTertiary == textTertiary &&
        other.primaryAction == primaryAction &&
        other.editorialBrown == editorialBrown &&
        other.success == success &&
        other.warning == warning &&
        other.error == error &&
        other.cardRadius == cardRadius &&
        other.buttonRadius == buttonRadius &&
        other.imageProminence == imageProminence &&
        other.mapProminence == mapProminence &&
        other.informationDensity == informationDensity;
  }

  @override
  int get hashCode => Object.hashAll([
    background,
    surface,
    surfaceWarm,
    surfaceMuted,
    accentEmphasis,
    secondaryEmphasis,
    journeyLineCompleted,
    journeyLineActive,
    journeyLineFuture,
    journeyLineFutureBorder,
    journeyLineHalo,
    border,
    borderStrong,
    textPrimary,
    textSecondary,
    textTertiary,
    primaryAction,
    editorialBrown,
    success,
    warning,
    error,
    cardRadius,
    buttonRadius,
    imageProminence,
    mapProminence,
    informationDensity,
  ]);
}
