import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:naviigo_app/core/auth/auth_provider.dart';
import 'package:naviigo_app/core/auth/auth_repository.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';
import 'package:naviigo_app/features/trips/presentation/pages/generated_itinerary_page.dart';

class _User extends Fake implements User {
  _User(this.uid);

  @override
  final String uid;
}

class _AuthRepository extends Fake implements AuthRepository {
  @override
  User? get currentUser => null;
}

TripItineraryModel _trip({
  required String destination,
  String? userId,
  bool isEphemeral = true,
  bool isPublic = false,
}) {
  return TripItineraryModel.fromMap('generated-1', {
    'destId': destination.toLowerCase(),
    'destName': destination,
    if (userId != null) 'userId': userId,
    'isEphemeral': isEphemeral,
    'isPublic': isPublic,
    'form': {'days': 1},
    'dayPlans': [
      {
        'day': 1,
        'activities': [
          {'title': 'A real activity'},
        ],
      },
    ],
  });
}

TripItineraryModel _tripWithPlans(
  List<Map<String, dynamic>> dayPlans, {
  TripStatus? status,
  bool isEphemeral = false,
}) {
  return TripItineraryModel.fromMap('rich-trip', {
    'id': 'rich-trip',
    'uuid': 'rich-trip',
    'destId': 'jaipur',
    'destName': 'Jaipur',
    'userId': 'uid-a',
    'isEphemeral': isEphemeral,
    if (status != null) 'status': status.wireName,
    'form': {'days': dayPlans.length},
    'dayPlans': dayPlans,
  });
}

void main() {
  testWidgets('ownerless explicit result fails closed', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWithValue(null)],
        child: MaterialApp(
          home: GeneratedItineraryPage(trip: _trip(destination: 'Varanasi')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Itinerary Unavailable'), findsOneWidget);
    expect(find.text('Varanasi'), findsNothing);
  });

  testWidgets('reactively hides an explicit result after its owner changes', (
    tester,
  ) async {
    final authEvents = StreamController<User?>();
    addTearDown(authEvents.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((_) => authEvents.stream),
          authRepositoryProvider.overrideWithValue(_AuthRepository()),
        ],
        child: MaterialApp(
          home: GeneratedItineraryPage(
            trip: _trip(destination: 'Varanasi', userId: 'uid-a'),
          ),
        ),
      ),
    );

    authEvents.add(_User('uid-a'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Varanasi'), findsOneWidget);

    authEvents.add(_User('uid-b'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Itinerary Unavailable'), findsOneWidget);
    expect(find.text('Varanasi'), findsNothing);

    authEvents.add(null);
    await tester.pump();
    await tester.pump();
    expect(find.text('Itinerary Unavailable'), findsOneWidget);
  });

  testWidgets('missing explicit result does not fall back to stored trips', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWithValue(null)],
        child: MaterialApp(home: const GeneratedItineraryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Itinerary Yet'), findsOneWidget);
  });

  testWidgets(
    'owner mismatch shows an unavailable result instead of rendering it',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [currentUserProvider.overrideWithValue(null)],
          child: MaterialApp(
            home: GeneratedItineraryPage(
              trip: _trip(destination: 'Varanasi', userId: 'other-user'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Itinerary Unavailable'), findsOneWidget);
      expect(find.text('Varanasi'), findsNothing);
    },
  );

  testWidgets('overview remains renderable at narrow and large text scales', (
    tester,
  ) async {
    for (final scale in [0.8, 2.5]) {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: ProviderScope(
            overrides: [currentUserProvider.overrideWithValue(_User('uid-a'))],
            child: MaterialApp(
              home: GeneratedItineraryPage(
                trip: _trip(destination: 'Varanasi', userId: 'uid-a'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Varanasi'), findsOneWidget);
    }
  });

  testWidgets('private stored result has no share action', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWithValue(_User('uid-a'))],
        child: MaterialApp(
          home: GeneratedItineraryPage(
            trip: _trip(
              destination: 'Varanasi',
              userId: 'uid-a',
              isEphemeral: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.share_outlined), findsNothing);
  });

  testWidgets(
    'overview preserves backend day order and actual nonsequential numbers',
    (tester) async {
      final trip = _tripWithPlans([
        {
          'day': 4,
          'theme': 'Heritage morning',
          'areaFocus': 'Old City',
          'date': 'Oct 12, 2026',
          'activities': [
            {'title': 'Amber Fort', 'time': '09:00'},
          ],
        },
        {'day': 9, 'activities': []},
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [currentUserProvider.overrideWithValue(_User('uid-a'))],
          child: MaterialApp(home: GeneratedItineraryPage(trip: trip)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(find.textContaining('Day 4'), findsWidgets);
      expect(find.textContaining('Day 9'), findsWidgets);
      expect(find.text('Heritage morning'), findsOneWidget);
      expect(find.text('Area focus · Old City'), findsOneWidget);
      expect(find.text('No day details were provided.'), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 700));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DAY IN MOTION'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('DAY 4 TIMELINE'), findsOneWidget);

      await tester.tap(find.text('Day 9'));
      await tester.pumpAndSettle();
      expect(find.text('DAY 9 TIMELINE'), findsOneWidget);
      expect(
        find.text('No additional day context was provided.'),
        findsOneWidget,
      );
      expect(find.text('Heritage morning'), findsNothing);
      expect(find.text('Area focus · Old City'), findsNothing);
    },
  );

  testWidgets(
    'map state is unavailable without coordinates and truthful with them',
    (tester) async {
      Future<void> pumpTrip(TripItineraryModel trip) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [currentUserProvider.overrideWithValue(_User('uid-a'))],
            child: MaterialApp(home: GeneratedItineraryPage(trip: trip)),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpTrip(
        _tripWithPlans([
          {
            'day': 4,
            'activities': [
              {'title': 'Amber Fort'},
            ],
          },
        ]),
      );
      expect(find.text('ACTIVITY MAP UNAVAILABLE'), findsOneWidget);
      expect(
        find.text('This itinerary has no activity coordinates'),
        findsOneWidget,
      );
      expect(find.text('Coordinate-backed map handoff'), findsNothing);

      await pumpTrip(
        _tripWithPlans([
          {
            'day': 4,
            'activities': [
              {
                'title': 'Amber Fort',
                'location': 'Devisinghpura',
                'lat': 26.9855,
                'lng': 75.8513,
              },
            ],
          },
        ]),
      );
      expect(find.text('ACTIVITY LOCATIONS'), findsOneWidget);
      expect(find.text('Coordinate-backed map handoff'), findsOneWidget);

      await tester.tap(find.text('ACTIVITY LOCATIONS'));
      await tester.pumpAndSettle();
      expect(find.text('COORDINATES PROVIDED BY ITINERARY'), findsOneWidget);
      expect(find.text('26.9855, 75.8513'), findsOneWidget);
      expect(find.text('OPEN IN MAP'), findsOneWidget);
    },
  );

  testWidgets('terminal trips do not expose a start action', (tester) async {
    final trip = _tripWithPlans([
      {
        'day': 4,
        'activities': [
          {'title': 'Amber Fort'},
        ],
      },
    ], status: TripStatus.completed);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWithValue(_User('uid-a'))],
        child: MaterialApp(home: GeneratedItineraryPage(trip: trip)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('START LIVE JOURNEY'), findsNothing);
    expect(find.text('TRANSIT'), findsNothing);
  });

  testWidgets('view and day controls expose selected semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final trip = _tripWithPlans([
      {
        'day': 4,
        'activities': [
          {'title': 'Amber Fort'},
        ],
      },
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWithValue(_User('uid-a'))],
        child: MaterialApp(home: GeneratedItineraryPage(trip: trip)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('CHAPTERS OVERVIEW, selected'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('DAY IN MOTION'), findsAtLeastNWidgets(1));
    await tester.tap(find.bySemanticsLabel('DAY IN MOTION').first);
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('DAY IN MOTION, selected'),
      findsAtLeastNWidgets(1),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Day 4, selected'), findsAtLeastNWidgets(1));
    semantics.dispose();
  });

  testWidgets(
    'narrow high-scale reduced-motion itinerary has no layout exception',
    (tester) async {
      // Keep the logical viewport at 320 x 700 while exercising a 2.5x device.
      tester.view.physicalSize = const Size(800, 1750);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2.5),
            disableAnimations: true,
          ),
          child: ProviderScope(
            overrides: [currentUserProvider.overrideWithValue(_User('uid-a'))],
            child: MaterialApp(
              home: GeneratedItineraryPage(
                trip: _tripWithPlans([
                  {
                    'day': 4,
                    'theme': 'A long day theme that wraps safely',
                    'activities': [
                      {'title': 'Amber Fort', 'time': '09:00 AM'},
                    ],
                  },
                ]),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
