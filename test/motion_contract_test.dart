import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/core/constants/master_destinations.dart';
import 'package:naviigo_app/core/motion/nav_environment.dart';
import 'package:naviigo_app/core/motion/nav_motion.dart';
import 'package:naviigo_app/core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Guards the motion contract.
///
/// The motion spec fixes these numbers, and downstream widgets are written
/// against them. If someone edits a token to a value outside its band, or adds
/// a duplicate destination id (which makes two Hero flights claim the same tag
/// and throws mid-transition), it should fail here rather than on a device.
/// ─────────────────────────────────────────────────────────────────────────────

/// The band each token is required to sit in, per §1 of the motion spec.
const Map<String, (Duration, int, int)> _bands = {
  'instant': (NavMotion.instant, 100, 140),
  'fast': (NavMotion.fast, 140, 190),
  'standard': (NavMotion.standard, 220, 320),
  'editorial': (NavMotion.editorial, 350, 550),
  'immersive': (NavMotion.immersive, 550, 800),
  'atmospheric': (NavMotion.atmospheric, 800, 1500),
};

void main() {
  group('NavMotion tokens', () {
    test('every duration sits inside its specified band', () {
      _bands.forEach((name, band) {
        final (token, low, high) = band;
        final ms = token.inMilliseconds;
        expect(
          ms,
          inInclusiveRange(low, high),
          reason: '$name is ${ms}ms, outside its $low-${high}ms band',
        );
      });
    });

    test('tokens are strictly increasing', () {
      final ordered = [
        NavMotion.instant,
        NavMotion.fast,
        NavMotion.standard,
        NavMotion.editorial,
        NavMotion.immersive,
        NavMotion.atmospheric,
      ];
      for (var i = 1; i < ordered.length; i++) {
        expect(
          ordered[i] > ordered[i - 1],
          isTrue,
          reason: 'token $i (${ordered[i]}) must exceed its predecessor',
        );
      }
    });

    test('press and nav scale stay in the restrained range', () {
      // §57: "Do not create bouncy toy buttons" — subtle, not squashy.
      expect(NavMotion.pressScale, inInclusiveRange(0.97, 0.99));
      // §4: icon morph 4-8%, "no giant jumping icons".
      expect(NavMotion.navIconScale, inInclusiveRange(1.04, 1.08));
    });

    test('curveFor is monotonic across the token ladder', () {
      expect(NavMotion.curveFor(NavMotion.instant), NavMotion.response);
      expect(NavMotion.curveFor(NavMotion.fast), NavMotion.response);
      expect(NavMotion.curveFor(NavMotion.standard), NavMotion.movement);
      expect(NavMotion.curveFor(NavMotion.editorial), NavMotion.editorialCurve);
      expect(NavMotion.curveFor(NavMotion.immersive), NavMotion.settle);
      expect(NavMotion.curveFor(NavMotion.atmospheric), NavMotion.settle);
    });
  });

  group('NavReduce (§65)', () {
    testWidgets('reports reduced motion from the platform setting', (
      tester,
    ) async {
      final results = <bool>[];
      final durations = <int>[];

      Widget probe() => Builder(
        builder: (context) {
          results.add(NavReduce.of(context));
          durations.add(
            NavReduce.duration(context, NavMotion.immersive).inMilliseconds,
          );
          // Meaning-carrying motion keeps a legible geometry, not a 1ms cut.
          durations.add(
            NavReduce.geometry(context, NavMotion.immersive).inMilliseconds,
          );
          return const SizedBox.shrink();
        },
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: probe(),
          ),
        ),
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: probe(),
          ),
        ),
      );

      expect(results.first, isFalse, reason: 'motion on by default');
      expect(durations[0], NavMotion.immersive.inMilliseconds);

      expect(results.last, isTrue, reason: 'platform asked for reduced motion');
      expect(durations[2], 1, reason: 'decorative motion collapses');
      expect(
        durations[3],
        NavMotion.instant.inMilliseconds,
        reason: 'meaning-carrying motion stays legible',
      );
    });
  });

  group('NavPalette (§13)', () {
    test('neutral resolves to the brand base, not an invented mood', () {
      // §13: when there is no real weather/location context, render the brand
      // base rather than guessing an atmosphere.
      final neutral = NavPalette.of(NavEnvironment.neutral);
      expect(neutral.background, AppColors.background);
      expect(neutral.surfaceWarm, AppColors.surfaceWarm);
      expect(neutral.accent, AppColors.primary);
    });

    test('lerp endpoints are exact at t=0 and t=1', () {
      final a = NavPalette.of(NavEnvironment.cold);
      final b = NavPalette.of(NavEnvironment.night);

      expect(NavPalette.lerp(a, b, 0.0), a);
      expect(NavPalette.lerp(a, b, 1.0), b);
    });

    test('every environment has a palette', () {
      for (final env in NavEnvironment.values) {
        expect(NavPalette.of(env), isNotNull, reason: 'missing palette: $env');
      }
    });
  });

  group('destination ids', () {
    test('ids are unique and non-empty', () {
      // Hero tags are built from these (`destination-<id>`). Two entries
      // sharing an id means two in-flight Heroes claim one tag and Flutter
      // asserts mid-transition — a crash, not a glitch.
      final seen = <String>{};
      for (final d in kMasterDestinations) {
        expect(
          d.id.trim(),
          isNotEmpty,
          reason: '${d.name} has an empty id (Hero tag would be malformed)',
        );
        expect(
          seen.add(d.id),
          isTrue,
          reason: 'duplicate destination id "${d.id}" — Hero tag collision',
        );
      }
    });

    test('findDestinationById resolves by id and by name', () {
      final first = kMasterDestinations.first;

      expect(findDestinationById(first.id)?.id, first.id);
      expect(findDestinationById(first.name)?.id, first.id);
      expect(findDestinationById(first.id.toUpperCase())?.id, first.id);
      // The planner receives `dest.name` as its prefill; that path must work.
      expect(findDestinationById('  ${first.name}  ')?.id, first.id);
    });

    test('an unknown id resolves to null rather than a wrong destination', () {
      // Callers must decide what to do about a miss. They must not be handed
      // an unrelated destination to render as if it were the real one.
      expect(findDestinationById('no-such-destination-id'), isNull);
    });
  });
}
