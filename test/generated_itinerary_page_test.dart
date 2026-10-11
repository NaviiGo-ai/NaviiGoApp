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
}
