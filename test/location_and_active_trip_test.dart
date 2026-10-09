import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/core/location/location_adapter.dart';
import 'package:naviigo_app/features/trips/domain/models/live_trip_state.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';
import 'package:naviigo_app/features/trips/domain/services/trip_validation_service.dart';
import 'package:naviigo_app/features/trips/presentation/providers/live_trip_provider.dart';
import 'package:naviigo_app/features/trips/presentation/providers/trip_provider.dart';

String _todayIso() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

TripItineraryModel _makeTrip({
  required String id,
  required String destId,
  required String destName,
  String? status,
  bool isActive = false,
  String? userId = 'pilot_1',
  String? startDate,
  int days = 2,
}) {
  return TripItineraryModel.fromMap(id, {
    'id': id,
    'destId': destId,
    'destName': destName,
    if (userId != null) 'userId': userId,
    if (status != null) 'status': status,
    'isActive': isActive,
    'form': {'startDate': startDate ?? _todayIso(), 'days': days},
    'dayPlans': [
      {
        'day': 1,
        'theme': 'Day 1',
        'activities': [
          {'title': 'Activity 1'},
        ],
      },
    ],
  });
}

class _TargetedFakeLocationAdapter implements LocationAdapter {
  _TargetedFakeLocationAdapter(this._result);
  LocationResult _result;
  int openSettingsCalls = 0;
  int openLocationSettingsCalls = 0;

  void respondWith(LocationResult result) => _result = result;

  @override
  Future<LocationResult> current({bool userInitiated = false}) async => _result;

  @override
  Future<bool> openAppSettings() async {
    openSettingsCalls++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    openLocationSettingsCalls++;
    return true;
  }
}

Future<ProviderContainer> _makeContainer({
  required List<TripItineraryModel> trips,
  LocationAdapter? location,
  String? userId = 'pilot_1',
  StartTripWriter? writer,
  EndTripWriter? endWriter,
}) async {
  final container = ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      checkInStoreProvider.overrideWithValue(InMemoryCheckInStore()),
      userTripsStreamProvider.overrideWith((ref) => Stream.value(trips)),
      if (location != null) locationAdapterProvider.overrideWithValue(location),
      if (writer != null) startTripWriterProvider.overrideWithValue(writer),
      if (endWriter != null) endTripWriterProvider.overrideWithValue(endWriter),
    ],
  );
  addTearDown(container.dispose);
  // Ensure the stream emits its initial value so activeTripsProvider has data.
  await container.read(userTripsStreamProvider.future);
  return container;
}

void main() {
  const jaipurLat = 26.9150;
  const jaipurLng = 75.7900;
  const delhiLat = 28.6139;
  const delhiLng = 77.2090;

  group('Active trip canonical source of truth (§9, §11, §12)', () {
    test(
      'activeTripProvider ignores a trip that merely matches today’s date',
      () async {
        final tripStartingToday = _makeTrip(
          id: 't_today',
          destId: 'jaipur',
          destName: 'Jaipur',
          isActive: false,
          // no explicit status: derives as eligibleToStart
        );
        final container = await _makeContainer(trips: [tripStartingToday]);

        expect(tripStartingToday.tripStatus, TripStatus.eligibleToStart);
        expect(container.read(activeTripProvider), isNull);
        expect(container.read(activeTripsProvider), isEmpty);
      },
    );

    test(
      'activeTripProvider returns the trip with explicit TripStatus.active',
      () async {
        final activeTrip = _makeTrip(
          id: 't_active',
          destId: 'jaipur',
          destName: 'Jaipur',
          status: 'active',
          isActive: true,
        );
        final eligibleTrip = _makeTrip(
          id: 't_eligible',
          destId: 'udaipur',
          destName: 'Udaipur',
          isActive: false,
        );
        final container = await _makeContainer(
          trips: [eligibleTrip, activeTrip],
        );

        expect(container.read(activeTripProvider), isNotNull);
        expect(container.read(activeTripProvider)!.id, 't_active');
        expect(container.read(activeTripsProvider).length, 1);
      },
    );

    test(
      'completed journey is no longer returned as active, regardless of date',
      () async {
        final completedTrip = _makeTrip(
          id: 't_done',
          destId: 'jaipur',
          destName: 'Jaipur',
          status: 'completed',
          isActive: false,
        );
        final container = await _makeContainer(trips: [completedTrip]);

        expect(completedTrip.tripStatus, TripStatus.completed);
        expect(container.read(activeTripProvider), isNull);
      },
    );

    test('cancelled journey is no longer returned as active', () async {
      final cancelledTrip = _makeTrip(
        id: 't_cancelled',
        destId: 'jaipur',
        destName: 'Jaipur',
        status: 'cancelled',
        isActive: false,
      );
      final container = await _makeContainer(trips: [cancelledTrip]);

      expect(cancelledTrip.tripStatus, TripStatus.cancelled);
      expect(container.read(activeTripProvider), isNull);
    });

    test(
      'multiple active-trip conflict blocks starting a second journey',
      () async {
        final runningTrip = _makeTrip(
          id: 't_running',
          destId: 'jaipur',
          destName: 'Jaipur Tour',
          status: 'active',
          isActive: true,
        );
        final secondTrip = _makeTrip(
          id: 't_second',
          destId: 'udaipur',
          destName: 'Udaipur Tour',
          isActive: false,
        );
        final started = <String>[];
        final adapter = _TargetedFakeLocationAdapter(
          LocationResult(
            fix: LiveFix(
              lat: 24.5854,
              lng: 73.7125, // Udaipur
              accuracyMeters: 10,
              timestamp: DateTime.now(),
            ),
            permissionGranted: true,
          ),
        );
        final container = await _makeContainer(
          trips: [runningTrip, secondTrip],
          location: adapter,
          writer: (uid, tripId) async => started.add('$uid/$tripId'),
        );

        final controller = container.read(
          liveTripControllerProvider(secondTrip.id).notifier,
        );
        await controller.refreshLocation();

        final state = container.read(liveTripStateProvider(secondTrip));
        expect(
          state.startCheck!.status,
          StartTripStatus.conflictWithActiveTrip,
        );
        expect(state.conflictingTrip!.id, 't_running');
        expect(state.canStartTrip, isFalse);

        final didStart = await controller.startTrip(secondTrip);
        expect(didStart, isFalse);
        expect(started, isEmpty);
      },
    );

    test(
      'endTrip transitions the conflicting journey via the repository writer',
      () async {
        final runningTrip = _makeTrip(
          id: 't_running',
          destId: 'jaipur',
          destName: 'Jaipur Tour',
          status: 'active',
          isActive: true,
        );
        final secondTrip = _makeTrip(
          id: 't_second',
          destId: 'udaipur',
          destName: 'Udaipur Tour',
          isActive: false,
        );
        final ended = <String>[];
        final container = await _makeContainer(
          trips: [runningTrip, secondTrip],
          endWriter: (uid, tripId) async => ended.add('$uid/$tripId'),
        );

        final controller = container.read(
          liveTripControllerProvider(secondTrip.id).notifier,
        );
        final didEnd = await controller.endTrip(runningTrip);

        expect(didEnd, isTrue);
        expect(ended, ['pilot_1/t_running']);
      },
    );
  });

  group('Location Adapter & Permission behavior (§1, §3, §4, §5, §6, §7)', () {
    test('permission denied is mapped and surfaces rationale', () async {
      final trip = _makeTrip(id: 't1', destId: 'jaipur', destName: 'Jaipur');
      final adapter = _TargetedFakeLocationAdapter(
        const LocationResult(
          failure: LocationFailure.permissionDenied,
          permissionGranted: false,
        ),
      );
      final container = await _makeContainer(trips: [trip], location: adapter);
      final controller = container.read(
        liveTripControllerProvider(trip.id).notifier,
      );

      await controller.refreshLocation();

      final state = container.read(liveTripStateProvider(trip));
      expect(state.startCheck!.status, StartTripStatus.permissionDenied);
      expect(state.locationFailure, LocationFailure.permissionDenied);
      expect(state.canStartTrip, isFalse);
    });

    test(
      'permanently denied permission maps to permissionPermanentlyDenied',
      () async {
        final trip = _makeTrip(id: 't1', destId: 'jaipur', destName: 'Jaipur');
        final adapter = _TargetedFakeLocationAdapter(
          const LocationResult(
            failure: LocationFailure.permissionPermanentlyDenied,
            permissionGranted: false,
          ),
        );
        final container = await _makeContainer(
          trips: [trip],
          location: adapter,
        );
        final controller = container.read(
          liveTripControllerProvider(trip.id).notifier,
        );

        await controller.refreshLocation();

        final state = container.read(liveTripStateProvider(trip));
        expect(
          state.startCheck!.status,
          StartTripStatus.permissionPermanentlyDenied,
        );
        expect(
          state.locationFailure,
          LocationFailure.permissionPermanentlyDenied,
        );
      },
    );

    test('restricted location maps to locationRestricted', () async {
      final trip = _makeTrip(id: 't1', destId: 'jaipur', destName: 'Jaipur');
      final adapter = _TargetedFakeLocationAdapter(
        const LocationResult(
          failure: LocationFailure.restricted,
          permissionGranted: false,
        ),
      );
      final container = await _makeContainer(trips: [trip], location: adapter);
      final controller = container.read(
        liveTripControllerProvider(trip.id).notifier,
      );

      await controller.refreshLocation();

      final state = container.read(liveTripStateProvider(trip));
      expect(state.startCheck!.status, StartTripStatus.locationRestricted);
      expect(state.locationFailure, LocationFailure.restricted);
    });

    test(
      'location services disabled maps to servicesDisabled independently of permission',
      () async {
        final trip = _makeTrip(id: 't1', destId: 'jaipur', destName: 'Jaipur');
        final adapter = _TargetedFakeLocationAdapter(
          const LocationResult(
            failure: LocationFailure.servicesDisabled,
            permissionGranted: true, // permission IS granted, GPS is OFF
          ),
        );
        final container = await _makeContainer(
          trips: [trip],
          location: adapter,
        );
        final controller = container.read(
          liveTripControllerProvider(trip.id).notifier,
        );

        await controller.refreshLocation();

        final state = container.read(liveTripStateProvider(trip));
        expect(state.startCheck!.status, StartTripStatus.servicesDisabled);
        expect(state.locationFailure, LocationFailure.servicesDisabled);
        expect(state.hasLocationPermission, isTrue);
        expect(state.canStartTrip, isFalse);
      },
    );

    test(
      'location timeout maps to locationTimeout without infinite wait',
      () async {
        final trip = _makeTrip(id: 't1', destId: 'jaipur', destName: 'Jaipur');
        final adapter = _TargetedFakeLocationAdapter(
          const LocationResult(
            failure: LocationFailure.timeout,
            permissionGranted: true,
          ),
        );
        final container = await _makeContainer(
          trips: [trip],
          location: adapter,
        );
        final controller = container.read(
          liveTripControllerProvider(trip.id).notifier,
        );

        await controller.refreshLocation();

        final state = container.read(liveTripStateProvider(trip));
        expect(state.startCheck!.status, StartTripStatus.locationTimeout);
        expect(state.locationFailure, LocationFailure.timeout);
        expect(state.isResolvingLocation, isFalse);
      },
    );

    test('poor accuracy (> 500m) fails closed on inaccurateGps', () async {
      final trip = _makeTrip(id: 't1', destId: 'jaipur', destName: 'Jaipur');
      final adapter = _TargetedFakeLocationAdapter(
        LocationResult(
          fix: LiveFix(
            lat: jaipurLat,
            lng: jaipurLng,
            accuracyMeters: 650, // exceeds LocationPolicy.maxAccuracyMeters
            timestamp: DateTime.now(),
          ),
          permissionGranted: true,
        ),
      );
      final container = await _makeContainer(trips: [trip], location: adapter);
      final controller = container.read(
        liveTripControllerProvider(trip.id).notifier,
      );

      await controller.refreshLocation();

      final state = container.read(liveTripStateProvider(trip));
      expect(state.startCheck!.status, StartTripStatus.inaccurateGps);
      expect(state.canStartTrip, isFalse);
    });

    test('fresh valid position at start region passes the gate', () async {
      final trip = _makeTrip(id: 't1', destId: 'jaipur', destName: 'Jaipur');
      final adapter = _TargetedFakeLocationAdapter(
        LocationResult(
          fix: LiveFix(
            lat: jaipurLat,
            lng: jaipurLng,
            accuracyMeters: 15,
            timestamp: DateTime.now(),
          ),
          permissionGranted: true,
        ),
      );
      final container = await _makeContainer(trips: [trip], location: adapter);
      final controller = container.read(
        liveTripControllerProvider(trip.id).notifier,
      );

      await controller.refreshLocation();

      final state = container.read(liveTripStateProvider(trip));
      expect(state.startCheck!.status, StartTripStatus.valid);
      expect(state.canStartTrip, isTrue);
      expect(state.phase, LiveTripPhase.atStart);
    });

    test('stale cached fix (> 5 min old) is rejected by the gate', () async {
      final trip = _makeTrip(id: 't1', destId: 'jaipur', destName: 'Jaipur');
      final adapter = _TargetedFakeLocationAdapter(
        LocationResult(
          fix: LiveFix(
            lat: jaipurLat,
            lng: jaipurLng,
            accuracyMeters: 10,
            // 20 minutes ago — a cached coordinate from earlier must not start a trip
            timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
          ),
          permissionGranted: true,
        ),
      );
      final container = await _makeContainer(trips: [trip], location: adapter);
      final controller = container.read(
        liveTripControllerProvider(trip.id).notifier,
      );

      await controller.refreshLocation();

      final state = container.read(liveTripStateProvider(trip));
      expect(state.startCheck!.status, StartTripStatus.staleFix);
      expect(state.canStartTrip, isFalse);
    });

    test('wrong city fix reports distance and sets wrongCity phase', () async {
      final trip = _makeTrip(id: 't1', destId: 'jaipur', destName: 'Jaipur');
      final adapter = _TargetedFakeLocationAdapter(
        LocationResult(
          fix: LiveFix(
            lat: delhiLat,
            lng: delhiLng,
            accuracyMeters: 12,
            timestamp: DateTime.now(),
          ),
          permissionGranted: true,
        ),
      );
      final container = await _makeContainer(trips: [trip], location: adapter);
      final controller = container.read(
        liveTripControllerProvider(trip.id).notifier,
      );

      await controller.refreshLocation();

      final state = container.read(liveTripStateProvider(trip));
      expect(state.startCheck!.status, StartTripStatus.wrongCity);
      expect(state.phase, LiveTripPhase.wrongCity);
      expect(state.startCheck!.distanceKm, greaterThan(200));
    });
  });
}
