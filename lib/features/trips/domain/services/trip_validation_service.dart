import 'dart:math' as math;

import '../models/trip_itinerary_model.dart';

/// Why a trip could not begin. Every value maps to a distinct, actionable
/// screen state — the UI must never blur these into a generic "cannot start".
enum StartTripStatus {
  /// All gates passed; the traveller is at the start region on the start date.
  valid,

  /// No signed-in user.
  unauthenticated,

  /// Signed in, but this journey belongs to someone else.
  notOwner,

  /// Neither the itinerary nor the user's fix supplied usable coordinates.
  missingCoordinates,

  /// Foreground location permission is not granted.
  permissionDenied,

  /// The device fix is too coarse to prove proximity (see
  /// [TripValidationService.maxGpsAccuracyMeters]).
  inaccurateGps,

  /// Today is too far ahead of the scheduled departure to begin.
  dateMismatch,

  /// The traveller is far from the start region.
  wrongCity,
}

/// Outcome of a start-trip attempt. Carries enough context for the wrong-city
/// screen to render distance, destination, and recovery actions without
/// re-deriving anything.
class StartTripValidationResult {
  final StartTripStatus status;
  final double? distanceKm;
  final String? expectedDestinationName;
  final String? message;
  final DateTime? destinationLocalDate;

  const StartTripValidationResult({
    required this.status,
    this.distanceKm,
    this.expectedDestinationName,
    this.message,
    this.destinationLocalDate,
  });

  bool get isValid => status == StartTripStatus.valid;

  /// Distance is only meaningful once a fix was actually compared.
  bool get hasDistance => distanceKm != null;

  String get distanceLabel {
    final km = distanceKm;
    if (km == null) return '';
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// START TRIP VALIDATION
/// Pure Dart, no plugins. A trip may only begin when all six gates pass:
/// authenticated owner → coordinates present → location permission → GPS
/// accuracy → destination-local date → proximity to the start region.
///
/// Nothing here fabricates a position: if a gate cannot be evaluated, it fails
/// closed and names itself.
/// ─────────────────────────────────────────────────────────────────────────────
class TripValidationService {
  /// A fix looser than this cannot prove the traveller is in the start region.
  static const double maxGpsAccuracyMeters = 500;

  /// How close counts as "at the start". Covers a city plus its airport.
  static const double startRegionRadiusKm = 25;

  /// Every destination in the curated registry is in India, so the
  /// destination-local clock is IST. If the catalogue ever leaves India this
  /// becomes a per-destination field rather than a constant.
  static const Duration destinationUtcOffset = Duration(hours: 5, minutes: 30);

  const TripValidationService();

  /// Great-circle distance in kilometres (Haversine, mean Earth radius).
  double calculateDistanceKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const earthRadiusKm = 6371.0088;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// The destination's wall-clock date. `referenceDate` is taken as already
  /// being in the destination's zone (so tests stay deterministic); only the
  /// live `DateTime.now()` fallback is converted.
  DateTime destinationLocalDate(DateTime? referenceDate) {
    final source = referenceDate ?? DateTime.now().toUtc().add(destinationUtcOffset);
    return DateTime(source.year, source.month, source.day);
  }

  StartTripValidationResult validateStartTrip({
    required TripItineraryModel trip,
    required String? currentUserId,
    required double? userLat,
    required double? userLng,
    required double? gpsAccuracyMeters,
    required bool hasLocationPermission,
    DateTime? referenceDate,
  }) {
    final destinationName = trip.startRegionName;
    final localDate = destinationLocalDate(referenceDate);

    // Gate 1 — authenticated.
    final uid = currentUserId?.trim();
    if (uid == null || uid.isEmpty) {
      return StartTripValidationResult(
        status: StartTripStatus.unauthenticated,
        expectedDestinationName: destinationName,
        destinationLocalDate: localDate,
        message: 'Sign in to begin this journey.',
      );
    }

    // Gate 2 — owner.
    final owner = trip.userId?.trim();
    if (owner != null && owner.isNotEmpty && owner != uid) {
      return StartTripValidationResult(
        status: StartTripStatus.notOwner,
        expectedDestinationName: destinationName,
        destinationLocalDate: localDate,
        message: 'This journey belongs to another traveller.',
      );
    }

    // Gate 3 — location permission.
    if (!hasLocationPermission) {
      return StartTripValidationResult(
        status: StartTripStatus.permissionDenied,
        expectedDestinationName: destinationName,
        destinationLocalDate: localDate,
        message: 'Location permission is needed to confirm you are at the start.',
      );
    }

    // Gate 4 — a usable fix exists at both ends.
    if (userLat == null || userLng == null) {
      return StartTripValidationResult(
        status: StartTripStatus.missingCoordinates,
        expectedDestinationName: destinationName,
        destinationLocalDate: localDate,
        message: 'Waiting for a location fix.',
      );
    }
    if (trip.startLat == null || trip.startLng == null) {
      return StartTripValidationResult(
        status: StartTripStatus.missingCoordinates,
        expectedDestinationName: destinationName,
        destinationLocalDate: localDate,
        message: 'This journey has no start region on file.',
      );
    }

    // Gate 5 — GPS accuracy.
    if (gpsAccuracyMeters != null && gpsAccuracyMeters > maxGpsAccuracyMeters) {
      return StartTripValidationResult(
        status: StartTripStatus.inaccurateGps,
        expectedDestinationName: destinationName,
        destinationLocalDate: localDate,
        message:
            'Location is accurate to only ${gpsAccuracyMeters.round()} m. Step outside and try again.',
      );
    }

    final distanceKm = calculateDistanceKm(
      lat1: userLat,
      lng1: userLng,
      lat2: trip.startLat!,
      lng2: trip.startLng!,
    );

    // Gate 6 — proximity to the start region.
    if (distanceKm > startRegionRadiusKm) {
      return StartTripValidationResult(
        status: StartTripStatus.wrongCity,
        distanceKm: distanceKm,
        expectedDestinationName: destinationName,
        destinationLocalDate: localDate,
        message: 'You are not at the start yet.',
      );
    }

    // Gate 7 — destination-local date. Late starts are allowed; beginning more
    // than a day early is not.
    final start = trip.parsedStartDate;
    if (start != null) {
      final windowOpens = DateTime(
        start.year,
        start.month,
        start.day,
      ).subtract(const Duration(days: 1));
      if (localDate.isBefore(windowOpens)) {
        return StartTripValidationResult(
          status: StartTripStatus.dateMismatch,
          distanceKm: distanceKm,
          expectedDestinationName: destinationName,
          destinationLocalDate: localDate,
          message: 'This journey begins on ${trip.startDateFormatted}.',
        );
      }
    }

    return StartTripValidationResult(
      status: StartTripStatus.valid,
      distanceKm: distanceKm,
      expectedDestinationName: destinationName,
      destinationLocalDate: localDate,
      message: 'You are at the start. Have a good journey.',
    );
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
}
