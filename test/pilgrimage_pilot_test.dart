import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naviigo_app/core/constants/master_destinations.dart';
import 'package:naviigo_app/core/auth/auth_provider.dart';
import 'package:naviigo_app/core/theme/app_theme.dart';
import 'package:naviigo_app/features/explore/presentation/pages/trip_planner_page.dart';
import 'package:naviigo_app/features/explore/presentation/pages/transportation_page.dart';
import 'package:naviigo_app/features/pilgrimage/domain/pilgrimage_pilot.dart';
import 'package:naviigo_app/features/pilgrimage/presentation/pilgrimage_page.dart';
import 'package:naviigo_app/features/explore/presentation/widgets/discovery_widgets.dart';

void main() {
  testWidgets(
    'planner requests the selected city photo and keeps credits accessible',
    (tester) async {
      String? photoQuery;
      final router = GoRouter(
        initialLocation: '/planner',
        initialExtra: pilgrimageDestinations.first.plannerArguments,
        routes: [
          GoRoute(path: '/planner', builder: (_, _) => const TripPlannerPage()),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(null),
            destinationPhotoProvider.overrideWith((ref, label) async {
              photoQuery = label;
              return <String, dynamic>{
                'image': 'https://example.com/ujjain.jpg',
                'credit': 'Test photographer',
                'source': 'Google Maps',
                'sourceUrl': 'https://maps.google.com/',
              };
            }),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(photoQuery, 'Ujjain, Madhya Pradesh');
      expect(find.text('Test photographer · Google Maps'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      expect(find.text('Photo credits'), findsOneWidget);
      expect(find.text('View source'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'a pilot city without an airport cannot open an unscoped flight search',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: TransportationPage())),
      );
      await tester.tap(find.text('Flights'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byType(DropdownButtonFormField<MasterDestination>).last,
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Ujjain'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Ujjain').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Check availability and book'),
        200,
      );
      final book = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Check availability and book'),
      );
      final search = tester.widget<FilledButton>(
        find.byWidgetPredicate((widget) => widget is FilledButton),
      );
      expect(book.onPressed, isNull);
      expect(search.onPressed, isNull);
      expect(find.textContaining('confirmed airports'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test('all five pilot handoffs resolve to their own canonical city', () {
    expect(pilgrimageDestinations.map((d) => d.id).toSet(), {
      'ujjain',
      'varanasi',
      'mathura',
      'dwarka',
      'puri',
    });
    for (final destination in pilgrimageDestinations) {
      final resolved = resolveTripPlannerDestination(
        destination.plannerArguments,
      );
      expect(resolved?.id, destination.id);
      expect(isPilgrimagePlannerHandoff(destination.plannerArguments), isTrue);
      expect(resolved?.lat, inInclusiveRange(-90, 90));
      expect(resolved?.lng, inInclusiveRange(-180, 180));
    }
    expect(
      kMasterDestinations.map((d) => d.id).toSet().length,
      kMasterDestinations.length,
    );
  });

  test('normal and unsupported handoffs do not change planner purpose', () {
    for (final extra in <Object?>[
      null,
      'ujjain',
      {'destination': 'ujjain'},
      {'destination': 'jaipur', 'purpose': 'spiritual'},
      {'destination': 'missing-city', 'purpose': 'spiritual'},
      {'destination': 'puri', 'purpose': 'arbitrary'},
    ]) {
      expect(isPilgrimagePlannerHandoff(extra), isFalse);
    }
    expect(findPilgrimageDestination('missing-city'), isNull);
  });

  testWidgets('hub opens each city and sends its spiritual planner handoff', (
    tester,
  ) async {
    Object? received;
    final router = GoRouter(
      initialLocation: '/pilgrimage-pilot',
      routes: [
        GoRoute(
          path: '/pilgrimage-pilot',
          builder: (_, _) => const PilgrimagePage(),
        ),
        GoRoute(
          path: '/pilgrimage-pilot/:id',
          builder: (_, state) => PilgrimageDestinationPage(
            destinationId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/trip-planner',
          builder: (_, state) {
            received = state.extra;
            return const Scaffold(body: Text('Planner opened'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.lightTheme(), routerConfig: router),
    );
    for (final destination in pilgrimageDestinations) {
      router.go('/pilgrimage-pilot');
      await tester.pumpAndSettle();
      final city = find.text(destination.title);
      await tester.scrollUntilVisible(
        city,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(city);
      await tester.pumpAndSettle();
      expect(find.text('Before departure'), findsOneWidget);
      await tester.tap(find.text('Plan ${destination.destination.name}'));
      await tester.pumpAndSettle();
      expect(received, destination.plannerArguments);
      expect(find.text('Planner opened'), findsOneWidget);
    }
  });

  testWidgets('city guidance remains usable at narrow width and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final destination in pilgrimageDestinations) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.7)),
            child: child!,
          ),
          home: PilgrimageDestinationPage(
            key: ValueKey(destination.id),
            destinationId: destination.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Open my saved trips'), 400);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'unknown pilot route offers recovery and founder trip stays upcoming',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const PilgrimageDestinationPage(destinationId: 'unknown'),
        ),
      );
      expect(find.text('Choose a pilot destination'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const FounderTravelsPage(),
        ),
      );
      expect(find.text('Kainchi Dham'), findsOneWidget);
      expect(find.text('UPCOMING FIELD TEST · DIWALI 2026'), findsOneWidget);
      expect(
        find.textContaining('first trip report will appear after the visit'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
