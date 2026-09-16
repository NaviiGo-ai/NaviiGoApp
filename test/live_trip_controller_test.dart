import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/features/trips/domain/models/live_trip_state.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';
import 'package:naviigo_app/features/trips/domain/services/trip_validation_service.dart';
import 'package:naviigo_app/features/trips/presentation/providers/live_trip_provider.dart';

/// Jaipur start date today, so the trip is inside its start window.
String _todayIso() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

TripItineraryModel _jaipurTrip({
  bool isActive = false,
  String? userId = 'pilot_1',
  String? status,
}) {
  return TripItineraryModel.fromMap('trip_live_1', {
    'destId': 'jaipur',
    'destName': 'Jaipur Royal Tour',
    if (userId != null) 'userId': userId,
    if (status != null) 'status': status,
    'isActive': isActive,
    'form': {'startDate': _todayIso(), 'days': 2},
    'dayPlans': [
      {
        'day': 1,
        'theme': 'Forts',
        'activities': [
          {'title': 'Amber Fort', 'time': '09:00 AM'},
          {'title': 'City Palace', 'time': '02:00 PM'},
        ],
      },
      {
        'day': 2,
        'theme': 'Bazaars',
        'activities': [
          {'title': 'Johari Bazaar'},
        ],
      },
    ],
  });
}

/// Fake adapter so location behaviour is exercised without a platform plugin.
class _FakeLocationAdapter implements LocationAdapter {
  _FakeLocationAdapter(this._result);
  LocationResult _result;
  int calls = 0;

  void respondWith(LocationResult result) => _result = result;

  @override
  Future<LocationResult> current() async {
    calls++;
    return _result;
  }
}

ProviderContainer _container({
  CheckInStore? store,
  LocationAdapter? location,
  String? userId = 'pilot_1',
  StartTripWriter? writer,
}) {
  final container = ProviderContainer(
    overrides: [
      checkInStoreProvider.overrideWithValue(store ?? InMemoryCheckInStore()),
      currentUserIdProvider.overrideWithValue(userId),
      if (location != null) locationAdapterProvider.overrideWithValue(location),
      if (writer != null) startTripWriterProvider.overrideWithValue(writer),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('LiveTripState derivation', () {
    test('walks the waypoint rail through manual check-ins', () async {
      final trip = _jaipurTrip(isActive: true, status: 'active');
      final container = _container();
      final controller = container.read(liveTripControllerProvider(trip.id).notifier);

      var state = container.read(liveTripStateProvider(trip));
      expect(state.totalWaypoints, 3);
      expect(state.nowWaypoint!.activity.title, 'Amber Fort');
      expect(state.nextWaypoint!.activity.title, 'City Palace');
      expect(state.loggedCount, 0);
      expect(state.isRailComplete, isFalse);

      // I'M HERE on the first stop: they are standing at it, not done with it.
      // NOW stays put and NEXT advances.
      await controller.logCheckIn(
        LiveTripState.waypointKey(0, 0),
        TripCheckIn.arrived,
      );
      state = container.read(liveTripStateProvider(trip));
      expect(state.nowWaypoint!.activity.title, 'Amber Fort');
      expect(state.nextWaypoint!.activity.title, 'City Palace');
      expect(state.arrivalConfidence, ArrivalConfidence.confirmed);
      expect(state.nowWaypoint!.checkIn.label, 'You are here');
      expect(state.loggedCount, 0, reason: 'arrived is not yet logged as done');

      await controller.logCheckIn(
        LiveTripState.waypointKey(0, 0),
        TripCheckIn.completed,
      );
      state = container.read(liveTripStateProvider(trip));
      expect(state.loggedCount, 1);
      expect(state.completedCount, 1);
      expect(state.nowWaypoint!.activity.title, 'City Palace');

      await controller.logCheckIn(
        LiveTripState.waypointKey(0, 1),
        TripCheckIn.completed,
      );
      state = container.read(liveTripStateProvider(trip));
      expect(state.nowWaypoint!.activity.title, 'Johari Bazaar');
      expect(state.isRailComplete, isFalse);

      // SKIP is logged as skipped, never as completed — the traveller passed it
      // over, and the record says so.
      await controller.logCheckIn(
        LiveTripState.waypointKey(1, 0),
        TripCheckIn.skipped,
      );
      state = container.read(liveTripStateProvider(trip));
      expect(state.skippedCount, 1);
      expect(state.completedCount, 2);
      expect(state.isRailComplete, isTrue);
      expect(state.nowWaypoint, isNull);
      expect(state.nextWaypoint, isNull);
    });

    test('check-ins survive a new controller via the store', () async {
      final trip = _jaipurTrip(isActive: true, status: 'active');
      final store = InMemoryCheckInStore();

      final first = _container(store: store);
      await first
          .read(liveTripControllerProvider(trip.id).notifier)
          .logCheckIn(LiveTripState.waypointKey(0, 0), TripCheckIn.completed);

      // A fresh container is what an app restart looks like.
      final second = _container(store: store);
      final state = second.read(liveTripStateProvider(trip));
      expect(state.completedCount, 1);
      expect(state.nowWaypoint!.activity.title, 'City Palace');
    });

    test('clearing a check-in puts the waypoint back on the rail', () async {
      final trip = _jaipurTrip(isActive: true, status: 'active');
      final container = _container();
      final controller =
          container.read(liveTripControllerProvider(trip.id).notifier);

      await controller.logCheckIn(
        LiveTripState.waypointKey(0, 0),
        TripCheckIn.completed,
      );
      await controller.clearCheckIn(LiveTripState.waypointKey(0, 0));

      final state = container.read(liveTripStateProvider(trip));
      expect(state.completedCount, 0);
      expect(state.nowWaypoint!.activity.title, 'Amber Fort');
    });

    test('arrival confidence never claims more than it knows', () {
      final trip = _jaipurTrip(isActive: true, status: 'active');
      final container = _container();

      // No fix, no check-in.
      expect(
        container.read(liveTripStateProvider(trip)).arrivalConfidence,
        ArrivalConfidence.unknown,
      );

      // A real fix while under way is inference, not confirmation.
      container.read(liveTripFixProvider.notifier).state = LiveFix(
        lat: 26.9150,
        lng: 75.7900,
        accuracyMeters: 12,
        timestamp: DateTime.now(),
      );
      expect(
        container.read(liveTripStateProvider(trip)).arrivalConfidence,
        ArrivalConfidence.inferred,
      );
    });

    test('phase follows the lifecycle, not the clock alone', () {
      // A scheduled trip with no fix is pre-trip, not silently active.
      final planned = _jaipurTrip();
      final container = _container();
      expect(
        container.read(liveTripStateProvider(planned)).phase,
        LiveTripPhase.preTrip,
      );
      expect(container.read(liveTripStateProvider(planned)).status,
          TripStatus.eligibleToStart);

      for (final entry in {
        'active': LiveTripPhase.inMotion,
        'completed': LiveTripPhase.finished,
        'cancelled': LiveTripPhase.cancelled,
      }.entries) {
        final trip = _jaipurTrip(isActive: entry.key == 'active', status: entry.key);
        expect(
          _container().read(liveTripStateProvider(trip)).phase,
          entry.value,
          reason: 'status ${entry.key}',
        );
      }
    });
  });

  group('Start trip gating', () {
    test('offers the start only when at the region on the start date', () {
      final trip = _jaipurTrip();
      final container = _container(
        location: _FakeLocationAdapter(
          LocationResult(
            fix: LiveFix(
              lat: 26.9150,
              lng: 75.7900,
              accuracyMeters: 12,
              timestamp: DateTime.now(),
            ),
            permissionGranted: true,
          ),
        ),
      );

      // No fix yet — the start gate stays shut.
      expect(container.read(liveTripStateProvider(trip)).canStartTrip, isFalse);
      expect(
        container.read(liveTripStateProvider(trip)).phase,
        LiveTripPhase.preTrip,
      );
    });

    test('reports wrong city with distance and destination for recovery', () async {
      final trip = _jaipurTrip();
      final container = _container(
        location: _FakeLocationAdapter(
          LocationResult(
            fix: LiveFix(
              lat: 28.6139, // Delhi
              lng: 77.2090,
              accuracyMeters: 15,
              timestamp: DateTime.now(),
            ),
            permissionGranted: true,
          ),
        ),
      );

      await container.read(liveTripControllerProvider(trip.id).notifier).refreshLocation();

      final state = container.read(liveTripStateProvider(trip));
      expect(state.phase, LiveTripPhase.wrongCity);
      expect(state.canStartTrip, isFalse);
      expect(state.startCheck!.expectedDestinationName, 'Jaipur');
      expect(state.startCheck!.distanceKm, greaterThan(200));
      expect(state.startCheck!.distanceLabel, endsWith('km'));
    });

    test('at the start region the gate opens and the start succeeds', () async {
      final trip = _jaipurTrip();
      final started = <String>[];
      final container = _container(
        location: _FakeLocationAdapter(
          LocationResult(
            fix: LiveFix(
              lat: 26.9150,
              lng: 75.7900,
              accuracyMeters: 12,
              timestamp: DateTime.now(),
            ),
            permissionGranted: true,
          ),
        ),
        writer: (uid, tripId) async => started.add('$uid/$tripId'),
      );

      final controller =
          container.read(liveTripControllerProvider(trip.id).notifier);
      await controller.refreshLocation();

      final state = container.read(liveTripStateProvider(trip));
      expect(state.phase, LiveTripPhase.atStart);
      expect(state.canStartTrip, isTrue);
      expect(state.lastUpdated, isNotNull);

      expect(await controller.startTrip(trip), isTrue);
      expect(started, ['pilot_1/trip_live_1']);
      expect(container.read(liveTripLastSyncProvider), isNotNull);
      expect(container.read(liveTripOfflineProvider), isFalse);
    });

    test('a denied permission is surfaced, never worked around', () async {
      final trip = _jaipurTrip();
      final container = _container(
        location: _FakeLocationAdapter(
          const LocationResult(
            failure: LocationFailure.permissionDenied,
            permissionGranted: false,
          ),
        ),
      );

      await container.read(liveTripControllerProvider(trip.id).notifier).refreshLocation();

      final state = container.read(liveTripStateProvider(trip));
      expect(state.startCheck!.status, StartTripStatus.permissionDenied);
      expect(state.fix, isNull);
      expect(state.lastActionError, contains('permission'));
      expect(state.isResolvingLocation, isFalse);
    });

    test('a failed start does not pretend the journey began', () async {
      final trip = _jaipurTrip();
      final container = _container(
        location: _FakeLocationAdapter(
          LocationResult(
            fix: LiveFix(
              lat: 26.9150,
              lng: 75.7900,
              accuracyMeters: 12,
              timestamp: DateTime.now(),
            ),
            permissionGranted: true,
          ),
        ),
        writer: (uid, tripId) async => throw Exception('offline'),
      );

      final controller =
          container.read(liveTripControllerProvider(trip.id).notifier);
      await controller.refreshLocation();

      expect(await controller.startTrip(trip), isFalse);
      final state = container.read(liveTripStateProvider(trip));
      expect(state.isStartingTrip, isFalse);
      expect(state.lastActionError, contains('Could not start'));
      expect(container.read(liveTripOfflineProvider), isTrue);
      // Still startable — the gate did not open on a failure.
      expect(state.phase, LiveTripPhase.atStart);
    });

    test('an unauthenticated traveller cannot start', () async {
      final trip = _jaipurTrip(userId: 'someone_else');
      final container = _container(
        userId: null,
        location: _FakeLocationAdapter(
          LocationResult(
            fix: LiveFix(
              lat: 26.9150,
              lng: 75.7900,
              accuracyMeters: 12,
              timestamp: DateTime.now(),
            ),
            permissionGranted: true,
          ),
        ),
      );

      final controller =
          container.read(liveTripControllerProvider(trip.id).notifier);
      await controller.refreshLocation();

      expect(
        container.read(liveTripStateProvider(trip)).startCheck!.status,
        StartTripStatus.unauthenticated,
      );
      expect(await controller.startTrip(trip), isFalse);
    });
  });

  group('Route deviation and sync honesty', () {
    test('reports genuine deviation only while under way', () {
      final trip = _jaipurTrip(isActive: true, status: 'active');
      final container = _container();

      container.read(liveTripFixProvider.notifier).state = LiveFix(
        lat: 26.9124,
        lng: 75.7873,
        accuracyMeters: 10,
        timestamp: DateTime.now(),
      );
      expect(container.read(liveTripStateProvider(trip)).isOffRoute, isFalse);
      expect(
        container.read(liveTripStateProvider(trip)).distanceFromStartRegionKm,
        lessThan(1),
      );

      container.read(liveTripFixProvider.notifier).state = LiveFix(
        lat: 28.6139,
        lng: 77.2090,
        accuracyMeters: 10,
        timestamp: DateTime.now(),
      );
      final deviated = container.read(liveTripStateProvider(trip));
      expect(deviated.isOffRoute, isTrue);
      expect(
        deviated.distanceFromStartRegionKm,
        greaterThan(TripValidationService.startRegionRadiusKm),
      );
    });

    test('deviation is not reported for a journey that has not begun', () {
      final trip = _jaipurTrip(status: 'eligible_to_start');
      final container = _container();
      container.read(liveTripFixProvider.notifier).state = LiveFix(
        lat: 28.6139,
        lng: 77.2090,
        timestamp: DateTime.now(),
      );
      expect(container.read(liveTripStateProvider(trip)).isOffRoute, isFalse);
    });

    test('last-updated is a real timestamp or an honest absence', () {
      final trip = _jaipurTrip(isActive: true, status: 'active');
      final container = _container();

      // Nothing has happened yet.
      expect(
        container.read(liveTripStateProvider(trip)).lastUpdatedLabel,
        'Not yet synced',
      );

      container.read(liveTripLastSyncProvider.notifier).state = DateTime.now();
      expect(
        container.read(liveTripStateProvider(trip)).lastUpdatedLabel,
        'Just now',
      );

      container.read(liveTripLastSyncProvider.notifier).state =
          DateTime.now().subtract(const Duration(minutes: 12));
      expect(
        container.read(liveTripStateProvider(trip)).lastUpdatedLabel,
        '12 min ago',
      );
    });
  });
}
