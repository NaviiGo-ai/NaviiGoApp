import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../adaptive/adaptive_theme_extension.dart';
import '../theme/app_typography.dart';

/// Honest empty state for surfaces that need a journey to render.
///
/// Replaces the fabricated sample itineraries these pages used to inject so a
/// traveller with no trips was shown a real-looking (but invented) journey.
class NoJourneyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const NoJourneyState({
    super.key,
    this.title = 'No Active Journey',
    this.message =
        'Once you plan a trip it opens here with live chapters, waypoints and captured moments.',
    this.icon = Icons.explore_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AdaptiveThemeExtension.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: tokens.surfaceWarm.withAlpha(120),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: tokens.editorialBrown),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.editorialTitle(
                color: tokens.editorialBrown,
              ).copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.caption(color: tokens.textSecondary),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () => context.push('/trip-planner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.primaryAction,
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'PLAN A JOURNEY',
                style: AppTypography.button(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
