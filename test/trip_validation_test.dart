import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';
import 'package:naviigo_app/features/trips/domain/services/trip_validation_service.dart';

void main() {
  group('TripStatus Lifecycle & Model Tests', () {
    test('TripStatus fromString parses all variants with robust fallbacks', () {
      expect(TripStatus.fromString('DRAFT'), TripStatus.draft);
      expect(TripStatus.fromString('draft'), TripStatus.draft);
      expect(TripStatus.fromString('planned'), TripStatus.planned);
      expect(TripStatus.fromString('plan'), TripStatus.planned);
      expect(TripStatus.fromString('UPCOMING'), TripStatus.upcoming);
      expect(
        TripStatus.fromString('eligible_to_start'),
        TripStatus.eligibleToStart,
      );
      expect(TripStatus.fromString('ready'), TripStatus.eligibleToStart);
      expect(TripStatus.fromString('active'), TripStatus.active);
      expect(TripStatus.fromString('in_progress'), TripStatus.active);
      expect(TripStatus.fromString('completed'), TripStatus.completed);
      expect(TripStatus.fromString('past'), TripStatus.completed);
      expect(TripStatus.fromString('cancelled'), TripStatus.cancelled);
      expect(TripStatus.fromString('canceled'), TripStatus.cancelled);
      expect(TripStatus.fromString('unknown_nonsense'), TripStatus.planned);
      expect(TripStatus.fromString(null), TripStatus.planned);
    });

    test('TripItineraryModel copyWith and status resolution', () {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final trip = TripItineraryModel.fromMap('trip_101', {
        'destId': 'jaipur',
        'destName': 'Jaipur Royalty',
        'userId': 'user_abc',
        'form': {
          'startDate': futureDate.toIso8601String().split('T').first,
          'days': 3,
        },
      });

      expect(trip.userId, 'user_abc');
      expect(trip.startLat, isNotNull);
      expect(trip.startLng, isNotNull);
      expect(trip.tripStatus, TripStatus.upcoming);

      final activeTrip = trip.copyWith(
        status: TripStatus.active,
        isActive: true,
      );
      expect(activeTrip.tripStatus, TripStatus.active);
      expect(activeTrip.isActive, isTrue);

      final cancelledTrip = trip.copyWith(status: TripStatus.cancelled);
      expect(cancelledTrip.tripStatus, TripStatus.cancelled);
    });

    test('TripActivityModel and TripDayPlanModel copyWith functionality', () {
      const act = TripActivityModel(
        title: 'Amber Fort',
        location: 'Amer',
        isCompleted: false,
      );
      final completedAct = act.copyWith(isCompleted: true);
      expect(completedAct.title, 'Amber Fort');
      expect(completedAct.location, 'Amer');
      expect(completedAct.isCompleted, isTrue);

      const day = TripDayPlanModel(
        dayNumber: 1,
        theme: 'Forts',
        activities: [act],
      );
      final updatedDay = day.copyWith(
        theme: 'Palaces & Forts',
        activities: [completedAct],
      );
      expect(updatedDay.dayNumber, 1);
      expect(updatedDay.theme, 'Palaces & Forts');
      expect(updatedDay.activities.first.isCompleted, isTrue);
    });
  });

  group('TripValidationService Unit Tests (Pure Dart & Proximity)', () {
    const service = TripValidationService();

    final jaipurTrip = TripItineraryModel.fromMap('trip_jaipur', {
      'destId': 'jaipur',
      'destName': 'Jaipur Royal Tour',
      'userId': 'pilot_user_1',
      'form': {'startDate': '2026-10-15', 'days': 4},
    });

    test(
      'calculates accurate Haversine distance in km between coordinates',
      () {
        // Delhi (28.6139, 77.2090) to Jaipur (26.9124, 75.7873) is ~235-245 km
        final dist = service.calculateDistanceKm(
          lat1: 28.6139,
          lng1: 77.2090,
          lat2: 26.9124,
          lng2: 75.7873,
        );
        expect(dist, greaterThan(230));
        expect(dist, lessThan(250));

        // Same point distance is 0
        final zeroDist = service.calculateDistanceKm(
          lat1: 26.9124,
          lng1: 75.7873,
          lat2: 26.9124,
          lng2: 75.7873,
        );
        expect(zeroDist, closeTo(0, 0.001));
      },
    );

    test('fails validation when user is unauthenticated', () {
      final result = service.validateStartTrip(
        trip: jaipurTrip,
        currentUserId: null,
        userLat: 26.9124,
        userLng: 75.7873,
        gpsAccuracyMeters: 10,
        hasLocationPermission: true,
        referenceDate: DateTime(2026, 10, 15),
      );

      expect(result.status, StartTripStatus.unauthenticated);
      expect(result.isValid, isFalse);
    });

    test('fails validation when user is not the trip owner', () {
      final result = service.validateStartTrip(
        trip: jaipurTrip,
        currentUserId: 'intruder_user',
        userLat: 26.9124,
        userLng: 75.7873,
        gpsAccuracyMeters: 10,
        hasLocationPermission: true,
        referenceDate: DateTime(2026, 10, 15),
      );

      expect(result.status, StartTripStatus.notOwner);
      expect(result.isValid, isFalse);
    });

    test('fails closed when the trip carries no owner at all', () {
      // An absent owner is unverifiable, not implicitly the caller's. Otherwise
      // any journey without a userId — including one read from another
      // traveller's public document — would be startable by anyone.
      final unownedTrip = TripItineraryModel.fromMap('trip_unowned', {
        'destId': 'jaipur',
        'destName': 'Jaipur Royal Tour',
        'form': {'startDate': '2026-10-15', 'days': 4},
      });
      expect(unownedTrip.userId, isNull);

      final result = service.validateStartTrip(
        trip: unownedTrip,
        currentUserId: 'pilot_user_1',
        userLat: 26.9124,
        userLng: 75.7873,
        gpsAccuracyMeters: 10,
        hasLocationPermission: true,
        referenceDate: DateTime(2026, 10, 15),
      );

      expect(result.status, StartTripStatus.notOwner);
      expect(result.isValid, isFalse);
    });

    test('fails validation when location permission is denied', () {
      final result = service.validateStartTrip(
        trip: jaipurTrip,
        currentUserId: 'pilot_user_1',
        userLat: 26.9124,
        userLng: 75.7873,
        gpsAccuracyMeters: 10,
        hasLocationPermission: false,
        referenceDate: DateTime(2026, 10, 15),
      );

      expect(result.status, StartTripStatus.permissionDenied);
      expect(result.isValid, isFalse);
    });

    test('fails validation when GPS accuracy is too inaccurate (> 500m)', () {
      final result = service.validateStartTrip(
        trip: jaipurTrip,
        currentUserId: 'pilot_user_1',
        userLat: 26.9124,
        userLng: 75.7873,
        gpsAccuracyMeters: 750, // Bad GPS fix
        hasLocationPermission: true,
        referenceDate: DateTime(2026, 10, 15),
      );

      expect(result.status, StartTripStatus.inaccurateGps);
      expect(result.isValid, isFalse);
    });

    test('fails closed for malformed user coordinates', () {
      for (final coordinates in [
        (double.nan, 75.7873),
        (26.9124, double.infinity),
        (91.0, 75.7873),
        (26.9124, -181.0),
      ]) {
        final result = service.validateStartTrip(
          trip: jaipurTrip,
          currentUserId: 'pilot_user_1',
          userLat: coordinates.$1,
          userLng: coordinates.$2,
          gpsAccuracyMeters: 10,
          hasLocationPermission: true,
          referenceDate: DateTime(2026, 10, 15),
        );
        expect(result.status, StartTripStatus.missingCoordinates);
        expect(result.isValid, isFalse);
      }
    });

    test('fails closed for malformed itinerary start coordinates', () {
      final malformedTrip = jaipurTrip.copyWith(
        startLat: double.nan,
        startLng: 75.7873,
      );
      final result = service.validateStartTrip(
        trip: malformedTrip,
        currentUserId: 'pilot_user_1',
        userLat: 26.9124,
        userLng: 75.7873,
        gpsAccuracyMeters: 10,
        hasLocationPermission: true,
        referenceDate: DateTime(2026, 10, 15),
      );

      expect(result.status, StartTripStatus.missingCoordinates);
      expect(result.isValid, isFalse);
    });

    test(
      'fails validation with wrongCity when user is in Delhi but trip is in Jaipur',
      () {
        final result = service.validateStartTrip(
          trip: jaipurTrip,
          currentUserId: 'pilot_user_1',
          userLat: 28.6139, // Delhi
          userLng: 77.2090,
          gpsAccuracyMeters: 15,
          hasLocationPermission: true,
          referenceDate: DateTime(2026, 10, 15),
        );

        expect(result.status, StartTripStatus.wrongCity);
        expect(result.isValid, isFalse);
        expect(result.distanceKm, greaterThan(200));
        expect(result.expectedDestinationName, 'Jaipur');
      },
    );

    test('fails validation when trip start date is in the distant future', () {
      final result = service.validateStartTrip(
        trip: jaipurTrip,
        currentUserId: 'pilot_user_1',
        userLat: 26.9124, // In Jaipur
        userLng: 75.7873,
        gpsAccuracyMeters: 15,
        hasLocationPermission: true,
        referenceDate: DateTime(2026, 9, 1), // Months ahead
      );

      expect(result.status, StartTripStatus.dateMismatch);
      expect(result.isValid, isFalse);
    });

    test(
      'succeeds with valid status when all proximity, auth, date & GPS conditions pass',
      () {
        final result = service.validateStartTrip(
          trip: jaipurTrip,
          currentUserId: 'pilot_user_1',
          userLat: 26.9150, // In Jaipur, ~1km from destination center
          userLng: 75.7900,
          gpsAccuracyMeters: 12,
          hasLocationPermission: true,
          referenceDate: DateTime(2026, 10, 15),
        );

        expect(result.status, StartTripStatus.valid);
        expect(result.isValid, isTrue);
        expect(result.distanceKm, lessThan(5));
      },
    );
  });
}
