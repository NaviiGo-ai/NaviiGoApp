import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'nav_motion.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ENVIRONMENTAL ATMOSPHERE (§13, §51)
///
/// Where you are and what the weather is doing should tint the *supporting*
/// surfaces — never the brand. Primary orange, brown mastheads and typography
/// contrast stay fixed; only background, container warmth and photo overlays
/// drift. The shift is slow (see [NavMotion.atmospheric]) because it is
/// atmosphere, not feedback.
///
/// [neutral] is the honest default: when Naviigo has no real weather or
/// location context for a screen, it does not guess a mood — it renders the
/// brand base.
///
/// Safety surfaces must pass `enabled: false` (§13, §40) — an emergency screen
/// needs maximum, unchanging contrast, not atmosphere.
/// ─────────────────────────────────────────────────────────────────────────────
enum NavEnvironment {
  /// No environment context available. Brand base. Never fabricated.
  neutral,

  /// Cool cream / teal support tone.
  cold,

  /// Warm cream / clay.
  warm,

  /// Brighter, airier treatment.
  hot,

  /// Cooler, muted supporting surfaces.
  rain,

  /// Deeper supporting surfaces.
  night,
}

/// The set of supporting colours an environment tints. Deliberately small —
/// every additional tintable token is another way for the brand to drift.
@immutable
class NavPalette {
  final Color background;
  final Color surfaceWarm;
  final Color overlay;
  final Color accent;

  const NavPalette({
    required this.background,
    required this.surfaceWarm,
    required this.overlay,
    required this.accent,
  });

  static const NavPalette _neutral = NavPalette(
    background: AppColors.background,
    surfaceWarm: AppColors.surfaceWarm,
    overlay: Colors.black,
    accent: AppColors.primary,
  );

  static const Map<NavEnvironment, NavPalette> _palettes = {
    NavEnvironment.neutral: _neutral,

    // Cool cream into a teal undertone.
    NavEnvironment.cold: NavPalette(
      background: Color(0xFFF5F9FA),
      surfaceWarm: Color(0xFFEAF1F3),
      overlay: Color(0xFF0B2B2E),
      accent: AppColors.teal,
    ),

    // Sand / amber.
    NavEnvironment.warm: NavPalette(
      background: Color(0xFFFFF6EC),
      surfaceWarm: Color(0xFFF9EADA),
      overlay: Color(0xFF3A1E0C),
      accent: AppColors.primary,
    ),

    // Brighter and airier than warm — heat lifts the paper, it doesn't tint it.
    NavEnvironment.hot: NavPalette(
      background: Color(0xFFFFFCF6),
      surfaceWarm: Color(0xFFFDF2E4),
      overlay: Color(0xFF43240E),
      accent: AppColors.yellow,
    ),

    // Cooler and muted.
    NavEnvironment.rain: NavPalette(
      background: Color(0xFFF4F6F7),
      surfaceWarm: Color(0xFFE8EDEF),
      overlay: Color(0xFF1B262B),
      accent: AppColors.teal,
    ),

    // Deeper supporting surfaces.
    NavEnvironment.night: NavPalette(
      background: Color(0xFF20262B),
      surfaceWarm: Color(0xFF2A3238),
      overlay: Color(0xFF000000),
      accent: AppColors.yellow,
    ),
  };

  static NavPalette of(NavEnvironment environment) =>
      _palettes[environment] ?? _neutral;

  /// Interpolate two atmospheres. Brand-anchored tokens are not interpolated
  /// away — only the supporting surfaces move.
  static NavPalette lerp(NavPalette a, NavPalette b, double t) {
    return NavPalette(
      background: Color.lerp(a.background, b.background, t)!,
      surfaceWarm: Color.lerp(a.surfaceWarm, b.surfaceWarm, t)!,
      overlay: Color.lerp(a.overlay, b.overlay, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NavPalette &&
      other.background == background &&
      other.surfaceWarm == surfaceWarm &&
      other.overlay == overlay &&
      other.accent == accent;

  @override
  int get hashCode => Object.hash(background, surfaceWarm, overlay, accent);
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Provides a smoothly-interpolated [NavPalette] to a subtree.
///
/// Changing `environment` never snaps: the previous palette is retained and
/// blended toward the new one over [NavMotion.atmospheric] (§13 — "do NOT
/// abruptly switch background").
/// ─────────────────────────────────────────────────────────────────────────────
class NavAtmosphere extends StatefulWidget {
  final NavEnvironment environment;

  /// Build with the currently-interpolated palette.
  final Widget Function(BuildContext context, NavPalette palette) builder;

  /// Safety surfaces pass false to keep maximum, stable contrast (§13, §40).
  final bool enabled;

  /// Fraction of the atmosphere to apply. Screens that want a whisper of the
  /// environment rather than the full treatment can dial this down.
  final double intensity;

  const NavAtmosphere({
    super.key,
    required this.environment,
    required this.builder,
    this.enabled = true,
    this.intensity = 1.0,
  });

  /// Read the palette currently in force. Returns the brand-neutral palette
  /// when no [NavAtmosphere] is above this context.
  static NavPalette of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_NavAtmosphereScope>()
            ?.palette ??
        NavPalette.of(NavEnvironment.neutral);
  }

  @override
  State<NavAtmosphere> createState() => _NavAtmosphereState();
}

class _NavAtmosphereState extends State<NavAtmosphere>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late NavPalette _from;
  late NavPalette _to;

  @override
  void initState() {
    super.initState();
    _from = _to = NavPalette.of(widget.environment);
    _controller = AnimationController(
      vsync: this,
      duration: NavMotion.atmospheric,
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(covariant NavAtmosphere oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.environment == widget.environment) return;
    // Start from wherever the blend currently sits, so an interrupted
    // transition continues from the visible colour instead of jumping back.
    _from = _current();
    _to = NavPalette.of(widget.environment);
    _controller
      ..duration = NavReduce.duration(context, NavMotion.atmospheric)
      ..forward(from: 0);
  }

  NavPalette _current() {
    final t = NavMotion.movement.transform(_controller.value);
    return NavPalette.lerp(_from, _to, t);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      final palette = NavPalette.of(NavEnvironment.neutral);
      return _NavAtmosphereScope(
        palette: palette,
        child: widget.builder(context, palette),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final blended = _current();
        final palette = widget.intensity >= 1.0
            ? blended
            : NavPalette.lerp(
                NavPalette.of(NavEnvironment.neutral),
                blended,
                widget.intensity.clamp(0.0, 1.0),
              );
        return _NavAtmosphereScope(
          palette: palette,
          child: widget.builder(context, palette),
        );
      },
    );
  }
}

class _NavAtmosphereScope extends InheritedWidget {
  final NavPalette palette;

  const _NavAtmosphereScope({required this.palette, required super.child});

  @override
  bool updateShouldNotify(_NavAtmosphereScope oldWidget) =>
      oldWidget.palette != palette;
}
