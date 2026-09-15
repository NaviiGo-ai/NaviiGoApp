import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum JourneyLineMode {
  plan, // Progress waypoint steps
  itinerary, // Day timeline stops & transfer connectors
  live, // Active progress tracking with illuminated node
  passport, // Memory trail
}

/// ─────────────────────────────────────────────────────────
/// NAVIIGO SIGNATURE: THE JOURNEY LINE
/// Primary brand motion device implemented via CustomPainter
/// ─────────────────────────────────────────────────────────
class JourneyLine extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final JourneyLineMode mode;
  final double progress; // 0.0 to 1.0 animation fraction

  const JourneyLine({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.mode = JourneyLineMode.plan,
    this.progress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: CustomPaint(
        painter: _JourneyLinePainter(
          totalSteps: totalSteps,
          currentStep: currentStep,
          mode: mode,
          progress: progress,
        ),
      ),
    );
  }
}

class _JourneyLinePainter extends CustomPainter {
  final int totalSteps;
  final int currentStep;
  final JourneyLineMode mode;
  final double progress;

  _JourneyLinePainter({
    required this.totalSteps,
    required this.currentStep,
    required this.mode,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalSteps <= 1) return;

    final startX = 24.0;
    final endX = size.width - 24.0;
    final stepSpacing = (endX - startX) / (totalSteps - 1);
    final centerY = size.height / 2;

    // 1. Inactive Track
    final inactivePaint = Paint()
      ..color = AppColors.cream.withAlpha(160)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(startX, centerY),
      Offset(endX, centerY),
      inactivePaint,
    );

    // 2. Active Animated Completed Track
    final activePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final currentTargetX = startX + (currentStep * stepSpacing);
    final prevTargetX =
        startX + ((currentStep - 1).clamp(0, totalSteps - 1) * stepSpacing);
    final animatedX = prevTargetX + ((currentTargetX - prevTargetX) * progress);

    canvas.drawLine(
      Offset(startX, centerY),
      Offset(animatedX, centerY),
      activePaint,
    );

    // 3. Waypoint Nodes
    for (int i = 0; i < totalSteps; i++) {
      final nodeX = startX + (i * stepSpacing);
      final isVisited = i < currentStep;
      final isCurrent = i == currentStep;

      if (isVisited) {
        // Visited solid terracotta node
        final visitedPaint = Paint()..color = AppColors.primary;
        canvas.drawCircle(Offset(nodeX, centerY), 7.0, visitedPaint);

        final innerWhite = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(nodeX, centerY), 2.5, innerWhite);
      } else if (isCurrent) {
        // Current illuminated active node
        final outerGlow = Paint()..color = AppColors.primary.withAlpha(50);
        canvas.drawCircle(Offset(nodeX, centerY), 12.0, outerGlow);

        final currentPaint = Paint()..color = AppColors.primary;
        canvas.drawCircle(Offset(nodeX, centerY), 7.5, currentPaint);

        final innerWhite = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(nodeX, centerY), 3.0, innerWhite);
      } else {
        // Unvisited future node
        final futurePaint = Paint()..color = AppColors.surfaceWarm;
        canvas.drawCircle(Offset(nodeX, centerY), 6.0, futurePaint);

        final futureBorder = Paint()
          ..color = AppColors.borderStrong
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(nodeX, centerY), 6.0, futureBorder);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _JourneyLinePainter oldDelegate) {
    return oldDelegate.currentStep != currentStep ||
        oldDelegate.progress != progress ||
        oldDelegate.mode != mode;
  }
}
