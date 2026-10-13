import 'dart:math' as math;

import '../../../../core/location/location_adapter.dart';
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

  /// Permission was declined for good; only Settings can restore it.
  permissionPermanentlyDenied,

  /// The OS restricts location for this app.
  locationRestricted,

  /// Permission is fine but device location is switched off. Fixed in a
  /// different settings screen to a permission problem, so it is its own state.
  servicesDisabled,

  /// No reading arrived inside the bounded wait.
  locationTimeout,

  /// A fix exists but is too old to say where the traveller is *now*.
  staleFix,

  /// The device fix is too coarse to prove proximity (see
  /// [TripValidationService.maxGpsAccuracyMeters]).
  inaccurateGps,

  /// Today is too far ahead of the scheduled departure to begin.
  dateMismatch,

  /// The traveller is far from the start region.
  wrongCity,

  /// Another journey of this traveller's is already under way. Never resolved
  /// silently — the traveller chooses which journey to keep.
  conflictWithActiveTrip,
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
/// START TRIP VALIDATION — the ONE authoritative path.
/// Pure Dart, no plugins. A trip may only begin when every gate passes:
///
///   authenticated owner → location permission → location services → a usable
///   fix exists → the fix is fresh → the fix is accurate → proximity to the
///   start region → destination-local date
///
/// Nothing here fabricates a position: if a gate cannot be evaluated, it fails
/// closed and names itself. The UI renders these results; it does not re-check
/// any of them.
/// ─────────────────────────────────────────────────────────────────────────────
class TripValidationService {
  /// A fix looser than this cannot prove the traveller is in the start region.
  /// Shared with the adapter's retry strategy via [LocationPolicy] so the two
  /// cannot drift.
  static const double maxGpsAccuracyMeters = LocationPolicy.maxAccuracyMeters;

  /// How close counts as "at the start". Covers a city plus its airport.
  static const double startRegionRadiusKm = LocationPolicy.startRegionRadiusKm;

  /// A fix older than this is not evidence of where someone is now. A cached
  /// coordinate from hours ago must never activate a journey.
  static const Duration maxFixAge = LocationPolicy.maxFixAge;

  /// Every destination in the curated registry is in India, so the
  /// destination-local clock is IST. If the catalogue ever leaves India this
  /// becomes a per-destination field rather than a constant.
  static const Duration destinationUtcOffset = Duration(hours: 5, minutes: 30);

  const TripValidationService();

  static bool hasValidCoordinates(double? lat, double? lng) {
    return lat != null &&
        lng != null &&
        lat.isFinite &&
        lng.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

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
    final source =
        referenceDate ?? DateTime.now().toUtc().add(destinationUtcOffset);
    return DateTime(source.year, source.month, source.day);
  }

  StartTripValidationResult validateStartTrip({
    required TripItineraryModel trip,
    required String? currentUserId,
    required double? userLat,
    required double? userLng,
    required double? gpsAccuracyMeters,
    required bool hasLocationPermission,
    DateTime? fixTimestamp,
    LocationFailure? locationFailure,
    bool hasOtherActiveTrip = false,
    DateTime? referenceDate,
  }) {
    final destinationName = trip.startRegionName;
    final localDate = destinationLocalDate(referenceDate);

    StartTripValidationResult fail(StartTripStatus status, String message) =>
        StartTripValidationResult(
          status: status,
          expectedDestinationName: destinationName,
          destinationLocalDate: localDate,
          message: message,
        );

    // Gate 1 — authenticated.
    final uid = currentUserId?.trim();
    if (uid == null || uid.isEmpty) {
      return fail(
        StartTripStatus.unauthenticated,
        'Sign in to begin this journey.',
      );
    }

    // Gate 2 — owner. A journey belonging to someone else is never startable,
    // whatever the client claims. An absent owner is unverifiable rather than
    // implicitly the caller's, so it fails closed too.
    final owner = trip.userId?.trim();
    if (owner == null || owner.isEmpty) {
      return fail(
        StartTripStatus.notOwner,
        'This journey has no owner on file, so it cannot be started here.',
      );
    }
    if (owner != uid) {
      return fail(
        StartTripStatus.notOwner,
        'This journey belongs to another traveller.',
      );
    }

    // Gate 3 — one journey at a time. Checked before location because the
    // traveller has to resolve it first, whatever the device reports.
    if (hasOtherActiveTrip) {
      return fail(
        StartTripStatus.conflictWithActiveTrip,
        'You already have a journey under way.',
      );
    }

    // Gate 4 — location permission.
    if (!hasLocationPermission) {
      // The platform told us *why* permission is unavailable; that reason gets
      // its own state because the recovery is different for each.
      switch (locationFailure) {
        case LocationFailure.permissionPermanentlyDenied:
          return fail(
            StartTripStatus.permissionPermanentlyDenied,
            'Location is blocked for Naviigo. You can turn it back on in Settings.',
          );
        case LocationFailure.restricted:
          return fail(
            StartTripStatus.locationRestricted,
            'Location is restricted on this device, so the start cannot be verified here.',
          );
        default:
          return fail(
            StartTripStatus.permissionDenied,
            'Location permission is needed to confirm you are at the start.',
          );
      }
    }

    // Gate 5 — device location switched on. Permission granted is not the same
    // thing, and the fix lives in another settings screen.
    if (locationFailure == LocationFailure.servicesDisabled) {
      return fail(
        StartTripStatus.servicesDisabled,
        'Location is turned off. Enable it to verify your trip start.',
      );
    }

    // Gate 6 — no reading arrived in time.
    if (locationFailure == LocationFailure.timeout) {
      return fail(
        StartTripStatus.locationTimeout,
        "Couldn't get a reliable location. Try again.",
      );
    }

    // Any other reported failure is still a failure. Do not let a stale fix or
    // an inconsistent adapter result authorize a journey.
    if (locationFailure != null) {
      return fail(
        StartTripStatus.missingCoordinates,
        'Location could not be read. Get a fresh reading to continue.',
      );
    }

    // Gate 7 — a usable fix exists at both ends.
    if (!hasValidCoordinates(userLat, userLng)) {
      return fail(
        StartTripStatus.missingCoordinates,
        'Waiting for a location fix.',
      );
    }
    if (!hasValidCoordinates(trip.startLat, trip.startLng)) {
      return fail(
        StartTripStatus.missingCoordinates,
        'This journey has no start region on file.',
      );
    }
    final currentLat = userLat;
    final currentLng = userLng;
    final startLat = trip.startLat;
    final startLng = trip.startLng;

    // Gate 8 — the fix is fresh. A coordinate from hours ago says where someone
    // *was*, which is not evidence they are at the start now.
    if (fixTimestamp != null &&
        DateTime.now().difference(fixTimestamp) > maxFixAge) {
      return fail(
        StartTripStatus.staleFix,
        'That location is out of date. Get a fresh reading to continue.',
      );
    }

    // Gate 9 — GPS accuracy.
    if (gpsAccuracyMeters != null && gpsAccuracyMeters > maxGpsAccuracyMeters) {
      return fail(
        StartTripStatus.inaccurateGps,
        'Location is accurate to only ${gpsAccuracyMeters.round()} m. Step outside and try again.',
      );
    }

    final distanceKm = calculateDistanceKm(
      lat1: currentLat!,
      lng1: currentLng!,
      lat2: startLat!,
      lng2: startLng!,
    );

    // Gate 10 — proximity to the start region.
    if (distanceKm > startRegionRadiusKm) {
      return StartTripValidationResult(
        status: StartTripStatus.wrongCity,
        distanceKm: distanceKm,
        expectedDestinationName: destinationName,
        destinationLocalDate: localDate,
        message: 'You are not at the start yet.',
      );
    }

    // Gate 11 — destination-local date. Late starts are allowed; beginning more
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
