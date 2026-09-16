import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion/nav_motion.dart';
import '../theme/app_colors.dart';

/// What the line is currently representing. The same geometry carries a
/// different meaning in each stage of a journey, so it must not look the same.
enum JourneyLineMode {
  /// Choosing. The line extends as decisions are made (§16, §20).
  plan,

  /// Reviewed. Stops and transfers of a generated itinerary (§21).
  itinerary,

  /// Travelling now. Teal, with a live pulse on the current node (§27).
  live,

  /// Already travelled. Every node settled — a memory trail, no future (§43).
  passport,
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Colour + behaviour for a mode. Kept in one place so the line's meaning is
/// never re-derived inside the painter.
/// ─────────────────────────────────────────────────────────────────────────────
class _JourneyPalette {
  final Color completed;
  final Color active;
  final Color future;
  final Color futureBorder;
  final Color halo;

  /// Live journeys breathe; everything else holds still (§52 — idle is calm).
  final bool pulse;

  /// A finished journey has no future nodes — it is entirely behind you.
  final bool historical;

  const _JourneyPalette({
    required this.completed,
    required this.active,
    required this.future,
    required this.futureBorder,
    required this.halo,
    this.pulse = false,
    this.historical = false,
  });

  static _JourneyPalette of(JourneyLineMode mode) => switch (mode) {
    JourneyLineMode.plan => const _JourneyPalette(
      completed: AppColors.primary,
      active: AppColors.primary,
      future: AppColors.surfaceWarm,
      futureBorder: AppColors.borderStrong,
      halo: AppColors.primary,
    ),
    JourneyLineMode.itinerary => const _JourneyPalette(
      completed: AppColors.primary,
      active: AppColors.primary,
      future: AppColors.surfaceWarm,
      futureBorder: AppColors.border,
      halo: AppColors.primary,
    ),
    JourneyLineMode.live => const _JourneyPalette(
      completed: AppColors.teal,
      active: AppColors.teal,
      future: AppColors.surfaceWarm,
      futureBorder: AppColors.border,
      halo: AppColors.teal,
      pulse: true,
    ),
    JourneyLineMode.passport => const _JourneyPalette(
      completed: AppColors.brown,
      active: AppColors.yellow,
      future: AppColors.surfaceMuted,
      futureBorder: AppColors.border,
      halo: AppColors.yellow,
      historical: true,
    ),
  };
}

/// ─────────────────────────────────────────────────────────────────────────
/// NAVIIGO SIGNATURE: THE JOURNEY LINE (§6)
///
/// The one device that appears in Plan, Itinerary, Live Trip, Map, Passport
/// and Story. It always means the same thing — *this is where you are on the
/// journey* — so it is drawn the same way everywhere and only its state and
/// palette change.
///
/// Advancing [currentStep] animates the line forward rather than jumping, and
/// [JourneyLineMode.live] adds a single restrained pulse on the active node.
/// Under reduced motion the line still advances (it carries meaning) but
/// travels without the pulse (§65).
/// ─────────────────────────────────────────────────────────────────────────
class JourneyLine extends StatefulWidget {
  /// Number of waypoints. Fewer than two has no line to draw.
  final int totalSteps;

  /// The waypoint the traveller is on now. Fractional values are allowed and
  /// render as a partially-completed segment.
  final double currentStep;

  final JourneyLineMode mode;
  final Axis axis;

  /// Thickness of the rail. Screens that give the line its own space (the
  /// itinerary day view) can widen it.
  final double thickness;

  const JourneyLine({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.mode = JourneyLineMode.plan,
    this.axis = Axis.horizontal,
    this.thickness = 3.0,
  });

  @override
  State<JourneyLine> createState() => _JourneyLineState();
}

class _JourneyLineState extends State<JourneyLine>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant JourneyLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) _syncPulse();
  }

  /// Only a live journey breathes, and never when motion is reduced.
  void _syncPulse() {
    final wanted = _JourneyPalette.of(widget.mode).pulse;
    if (wanted && _pulse == null) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat(reverse: true);
    } else if (!wanted && _pulse != null) {
      _pulse!.dispose();
      _pulse = null;
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalSteps <= 1) return const SizedBox.shrink();

    final bool reduced = NavReduce.of(context);
    final palette = _JourneyPalette.of(widget.mode);

    final Widget painter = TweenAnimationBuilder<double>(
      // On the first build begin == end, so nothing moves. When currentStep
      // changes, the line animates from wherever it currently is to the new
      // waypoint — progress, rather than a cut.
      tween: Tween<double>(begin: widget.currentStep, end: widget.currentStep),
      duration: NavReduce.geometry(context, NavMotion.editorial),
      curve: NavMotion.settle,
      builder: (context, animatedStep, _) {
        final Widget canvas = CustomPaint(
          painter: _JourneyLinePainter(
            totalSteps: widget.totalSteps,
            animatedStep: animatedStep,
            targetStep: widget.currentStep,
            palette: palette,
            axis: widget.axis,
            thickness: widget.thickness,
            pulse: (reduced || _pulse == null) ? 0.0 : _pulse!.value,
          ),
        );

        return widget.axis == Axis.horizontal
            ? SizedBox(height: 48, width: double.infinity, child: canvas)
            : LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  width: 48,
                  height: constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : 320,
                  child: canvas,
                ),
              );
      },
    );

    // The line repaints on every animation tick; keep it off the rest of the
    // screen's repaint path (§66).
    return RepaintBoundary(child: painter);
  }
}

class _JourneyLinePainter extends CustomPainter {
  final int totalSteps;
  final double animatedStep;
  final double targetStep;
  final _JourneyPalette palette;
  final Axis axis;
  final double thickness;
  final double pulse;

  _JourneyLinePainter({
    required this.totalSteps,
    required this.animatedStep,
    required this.targetStep,
    required this.palette,
    required this.axis,
    required this.thickness,
    required this.pulse,
  });

  static const double _inset = 24.0;
  static const double _radius = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (totalSteps <= 1) return;

    final bool horizontal = axis == Axis.horizontal;
    final double span = horizontal ? size.width : size.height;
    final double cross = horizontal ? size.height : size.width;

    final double start = _inset;
    final double end = span - _inset;
    if (end <= start) return;

    final double spacing = (end - start) / (totalSteps - 1);
    final double crossCentre = cross / 2;

    Offset pointAt(double step) => horizontal
        ? Offset(start + (step * spacing), crossCentre)
        : Offset(crossCentre, start + (step * spacing));

    // 1 ─ The rail: the part of the journey not yet travelled. Dashed, so it
    //     reads as intent rather than a taut wire.
    _drawDashed(
      canvas,
      pointAt(0),
      pointAt((totalSteps - 1).toDouble()),
      Paint()
        ..color = palette.historical
            ? palette.future
            : palette.futureBorder.withAlpha(140)
        ..strokeWidth = thickness * 0.7
        ..style = PaintingStyle.stroke,
    );

    // 2 ─ Travelled: the animated portion running to where you are now.
    final double clamped = animatedStep.clamp(0.0, (totalSteps - 1).toDouble());
    if (clamped > 0) {
      canvas.drawLine(
        pointAt(0),
        pointAt(clamped),
        Paint()
          ..color = palette.completed
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    // 3 ─ Waypoints.
    for (int i = 0; i < totalSteps; i++) {
      final Offset centre = pointAt(i.toDouble());

      // A finished journey is entirely behind you: nothing is "upcoming".
      final bool settled = palette.historical || i < targetStep;
      final bool isActive = !palette.historical && (i - targetStep).abs() < 0.5;

      if (isActive) {
        // Halo — pulses only while actually travelling.
        final double haloRadius = _radius + 5 + (pulse * 5);
        canvas.drawCircle(
          centre,
          haloRadius,
          Paint()..color = palette.halo.withAlpha(40 + (pulse * 40).round()),
        );
        canvas.drawCircle(centre, _radius, Paint()..color = palette.active);
        canvas.drawCircle(centre, 3.0, Paint()..color = Colors.white);
      } else if (settled) {
        canvas.drawCircle(centre, _radius, Paint()..color = palette.completed);
        canvas.drawCircle(centre, 2.5, Paint()..color = Colors.white);
      } else {
        canvas.drawCircle(centre, _radius - 1, Paint()..color = palette.future);
        canvas.drawCircle(
          centre,
          _radius - 1,
          Paint()
            ..color = palette.futureBorder
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  /// Dash the rail by walking the segment in fixed strides. Cheap and stable —
  /// no PathMetrics allocation per frame.
  void _drawDashed(Canvas canvas, Offset from, Offset to, Paint paint) {
    const double dash = 6.0;
    const double gap = 5.0;
    final double total = (to - from).distance;
    if (total <= 0) return;

    final Offset step = (to - from) / total;
    double travelled = 0;
    while (travelled < total) {
      final double dashEnd = math.min(travelled + dash, total);
      canvas.drawLine(
        from + (step * travelled),
        from + (step * dashEnd),
        paint,
      );
      travelled = dashEnd + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _JourneyLinePainter old) {
    return old.animatedStep != animatedStep ||
        old.targetStep != targetStep ||
        old.totalSteps != totalSteps ||
        old.axis != axis ||
        old.thickness != thickness ||
        old.pulse != pulse ||
        old.palette != palette;
  }
}
