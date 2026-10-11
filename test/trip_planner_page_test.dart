import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naviigo_app/core/constants/master_destinations.dart';
import 'package:naviigo_app/core/auth/auth_provider.dart';
import 'package:naviigo_app/core/auth/auth_repository.dart';
import 'package:naviigo_app/core/network/api_exceptions.dart';
import 'package:naviigo_app/features/explore/presentation/pages/trip_planner_page.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';
import 'package:naviigo_app/features/trips/presentation/pages/generated_itinerary_page.dart';
import 'package:naviigo_app/features/trips/presentation/providers/trip_provider.dart';
import 'package:naviigo_app/features/trips/data/trip_repository.dart';

class _User extends Fake implements User {
  _User(this.uid);

  @override
  final String uid;
}

class _FakeFirestore extends Fake implements FirebaseFirestore {}

class _AuthRepository extends Fake implements AuthRepository {
  @override
  User? get currentUser => null;
}

class _BlockingTripRepository extends TripRepository {
  _BlockingTripRepository(this.gate)
    : super(firestore: _FakeFirestore(), currentUserUid: () => 'uid-a');

  final Completer<void> gate;
  var calls = 0;
  String? lastDestination;
  String? lastTravelerType;
  Map<String, dynamic>? lastPreferences;
  Object? failure;

  @override
  Future<TripItineraryModel> generateItineraryFromBackend({
    required String destName,
    String? destination,
    required int days,
    String purpose = 'cultural',
    String group = 'solo',
    int budget = 15000,
    String? startDate,
    String travelerType = 'comfort',
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? browsingSignals,
    String? arrivalTime,
    String? arrivalMode,
    String? departureTime,
    String? departureMode,
    String? hotelArea,
    String? originCity,
    List<Map<String, dynamic>>? mustDo,
    List<Map<String, dynamic>>? routeStops,
    required String expectedAuthUid,
  }) async {
    calls++;
    lastDestination = destination;
    lastTravelerType = travelerType;
    lastPreferences = preferences;
    await gate.future;
    if (failure != null) throw failure!;
    return TripItineraryModel.fromMap('generated', {
      'destId': destination ?? 'varanasi',
      'destName': destName,
      'userId': expectedAuthUid,
      'isEphemeral': true,
      'form': {'days': days},
      'dayPlans': [
        {
          'day': 1,
          'activities': [
            {'title': 'Activity'},
          ],
        },
      ],
    });
  }
}

void main() {
  test(
    'planner resolves only registry destinations and never defaults to Jaipur',
    () {
      expect(
        resolveTripPlannerDestination({'destination': 'varanasi'})?.id,
        'varanasi',
      );
      expect(
        resolveTripPlannerDestination({'destination': 'Varanasi'})?.id,
        'varanasi',
      );
      expect(
        resolveTripPlannerDestination({'destination': 'hidden-gem'})?.id,
        isNull,
      );
      expect(resolveTripPlannerDestination(null), isNull);
    },
  );

  test('planner validation rejects unsupported and invalid values', () {
    final referenceDate = DateTime(2026, 10, 1);
    final destination = findDestinationById('varanasi');

    expect(
      validateTripPlannerInputs(
        destination: null,
        days: 3,
        budget: 25000,
        startDate: referenceDate,
        today: referenceDate,
      ),
      contains('supported destination'),
    );
    expect(
      validateTripPlannerInputs(
        destination: destination,
        days: 15,
        budget: 25000,
        startDate: referenceDate,
        today: referenceDate,
      ),
      contains('1 and 14'),
    );
    expect(
      validateTripPlannerInputs(
        destination: destination,
        days: 3,
        budget: double.nan,
        startDate: referenceDate,
        today: referenceDate,
      ),
      contains('positive'),
    );
    expect(
      validateTripPlannerInputs(
        destination: destination,
        days: 3,
        budget: 25000,
        startDate: DateTime(2026, 9, 30),
        today: referenceDate,
      ),
      contains('today or later'),
    );
    expect(
      validateTripPlannerInputs(
        destination: destination,
        days: 3,
        budget: 25000,
        startDate: DateTime(2026, 10, 2),
        today: referenceDate,
      ),
      isNull,
    );
  });

  test('unknown generation outcomes warn before retrying', () {
    final malformedMessage = friendlyTripGenerationError(
      const ItineraryGenerationResponseException(),
    );
    final serverMessage = friendlyTripGenerationError(
      const ServerException('backend unavailable'),
    );
    final networkMessage = friendlyTripGenerationError(
      const NetworkException('connection lost'),
    );

    for (final message in [malformedMessage, serverMessage, networkMessage]) {
      expect(message, contains('server may still finish or save'));
      expect(message, contains('retrying can create another trip'));
    }
    expect(serverMessage, isNot(contains('backend unavailable')));
    expect(networkMessage, isNot(contains('connection lost')));
    expect(
      friendlyTripGenerationError(const AuthRequiredException()),
      contains('Sign in again'),
    );
    expect(
      friendlyTripGenerationError(const ValidationException('invalid')),
      contains('request was rejected'),
    );
    expect(
      friendlyTripGenerationError(
        const NetworkException('Request timed out while generating'),
      ),
      contains('request timed out'),
    );
  });

  testWidgets(
    'planner ignores repeated generate taps while a request is pending',
    (tester) async {
      final gate = Completer<void>();
      final repository = _BlockingTripRepository(gate);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const TripPlannerPage()),
          GoRoute(
            path: '/itinerary',
            builder: (_, state) =>
                GeneratedItineraryPage(trip: state.extra as TripItineraryModel),
          ),
          GoRoute(path: '/login', builder: (_, __) => const SizedBox.shrink()),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(_User('uid-a')),
            tripRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      expect(
        tester
            .widget<PopScope<void>>(
              find.byWidgetPredicate((widget) => widget is PopScope<void>),
            )
            .canPop,
        isTrue,
      );

      await tester.tap(find.text('Varanasi'));
      await tester.pump();
      for (var step = 0; step < 8; step++) {
        if (tester.any(find.text('GENERATE YOUR JOURNEY →'))) break;
        await tester.tap(find.text('CONTINUE →'));
        await tester.pumpAndSettle();
      }

      final generateButton = find.text('GENERATE YOUR JOURNEY →');
      expect(generateButton, findsOneWidget);
      final submitButton = find.byType(ElevatedButton).last;
      await tester.tap(submitButton);
      await tester.pump();
      expect(repository.calls, 1);
      expect(
        tester
            .widget<PopScope<void>>(
              find.byWidgetPredicate((widget) => widget is PopScope<void>),
            )
            .canPop,
        isFalse,
      );
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Stop waiting?'), findsOneWidget);
      await tester.tap(find.text('Keep waiting'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(repository.lastDestination, 'varanasi');
      expect(repository.lastTravelerType, 'comfort');
      expect(repository.lastPreferences, isNull);

      // The button is disabled synchronously, before the backend future resolves.
      await tester.tap(submitButton);
      await tester.pump();
      expect(repository.calls, 1);

      gate.complete();
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.matches.last.matchedLocation,
        '/itinerary',
      );
    },
  );

  testWidgets('planner scenes remain usable at 320px with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final gate = Completer<void>();
    final repository = _BlockingTripRepository(gate);
    final router = GoRouter(
      initialLocation: '/planner',
      routes: [
        GoRoute(path: '/planner', builder: (_, __) => const TripPlannerPage()),
        GoRoute(
          path: '/itinerary',
          builder: (_, state) =>
              GeneratedItineraryPage(trip: state.extra as TripItineraryModel),
        ),
        GoRoute(path: '/login', builder: (_, __) => const SizedBox.shrink()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(_User('uid-a')),
          tripRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(2.5),
              disableAnimations: true,
            ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Varanasi'));
    await tester.pump();
    await tester.tap(find.text('Varanasi'));
    await tester.pump();

    for (var step = 0; step < 5; step++) {
      await tester.tap(find.text('CONTINUE →'));
      await tester.pumpAndSettle();
    }
    expect(find.text('GENERATE YOUR JOURNEY →'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pump();
    expect(find.bySemanticsLabel('Generating itinerary'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'unsupported entry destination shows an accessible selected error',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/unsupported',
        initialExtra: {'destination': 'hidden-gem'},
        routes: [
          GoRoute(
            path: '/unsupported',
            builder: (_, __) => const TripPlannerPage(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [currentUserProvider.overrideWithValue(null)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text(
          'That destination is not supported yet. Choose a destination from the registry.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'account switch invalidates a pending request without navigating',
    (tester) async {
      final authEvents = StreamController<User?>();
      addTearDown(authEvents.close);
      final gate = Completer<void>();
      final repository = _BlockingTripRepository(gate);
      final router = GoRouter(
        initialLocation: '/planner',
        routes: [
          GoRoute(
            path: '/planner',
            builder: (_, __) => const TripPlannerPage(),
          ),
          GoRoute(
            path: '/itinerary',
            builder: (_, state) =>
                GeneratedItineraryPage(trip: state.extra as TripItineraryModel),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((_) => authEvents.stream),
            authRepositoryProvider.overrideWithValue(_AuthRepository()),
            tripRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      authEvents.add(_User('uid-a'));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Varanasi'));
      await tester.pump();
      for (var step = 0; step < 5; step++) {
        await tester.tap(find.text('CONTINUE →'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pump();
      expect(repository.calls, 1);

      authEvents.add(_User('uid-b'));
      await tester.pump();
      await tester.pump();
      gate.complete();
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/planner');
      expect(
        find.text('Generated preview · save status unconfirmed'),
        findsNothing,
      );
    },
  );
}
