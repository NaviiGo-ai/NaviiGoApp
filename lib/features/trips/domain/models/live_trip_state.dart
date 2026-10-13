import '../../../../core/location/live_fix.dart';
import '../../../../core/location/location_adapter.dart';
import 'trip_itinerary_model.dart';
import '../services/trip_validation_service.dart';

/// A fix and its provenance are part of this model's public surface, so they
/// travel with it.
export '../../../../core/location/live_fix.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// MANUAL CHECK-IN
/// The traveller is the only source of truth about whether they actually
/// arrived. Nothing here infers "visited" from a GPS polyline.
/// ─────────────────────────────────────────────────────────────────────────────
enum TripCheckIn {
  /// Not yet reported.
  pending,

  /// "I'M HERE" — standing at the waypoint, not necessarily done with it.
  arrived,

  /// "COMPLETE" — visited and finished.
  completed,

  /// "SKIP" — deliberately passed over. Logged honestly as skipped, not done.
  skipped,
}

extension TripCheckInX on TripCheckIn {
  /// The waypoint is off the "up next" rail.
  bool get isLogged =>
      this == TripCheckIn.completed || this == TripCheckIn.skipped;

  bool get isConfirmedOnSite => this == TripCheckIn.arrived;

  String get wireName {
    switch (this) {
      case TripCheckIn.pending:
        return 'pending';
      case TripCheckIn.arrived:
        return 'arrived';
      case TripCheckIn.completed:
        return 'completed';
      case TripCheckIn.skipped:
        return 'skipped';
    }
  }

  String get label {
    switch (this) {
      case TripCheckIn.pending:
        return 'Not logged';
      case TripCheckIn.arrived:
        return 'You are here';
      case TripCheckIn.completed:
        return 'Completed';
      case TripCheckIn.skipped:
        return 'Skipped';
    }
  }

  static TripCheckIn fromString(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'arrived':
      case 'here':
        return TripCheckIn.arrived;
      case 'completed':
      case 'complete':
        return TripCheckIn.completed;
      case 'skipped':
      case 'skip':
        return TripCheckIn.skipped;
      default:
        return TripCheckIn.pending;
    }
  }
}

/// How sure we are that the traveller is standing at the current waypoint.
/// Deliberately coarse — it distinguishes what was *reported* from what was
/// merely *inferred*, and never dresses inference up as certainty.
enum ArrivalConfidence {
  /// No fix and no check-in: we do not know.
  unknown,

  /// A position fix puts the traveller inside the journey's region.
  inferred,

  /// The traveller said so.
  confirmed,
}

extension ArrivalConfidenceX on ArrivalConfidence {
  String get label {
    switch (this) {
      case ArrivalConfidence.unknown:
        return 'Position unknown';
      case ArrivalConfidence.inferred:
        return 'Inferred from location';
      case ArrivalConfidence.confirmed:
        return 'Confirmed by you';
    }
  }
}

/// Which face of the live screen the traveller should see.
enum LiveTripPhase {
  /// No journey to act on.
  none,

  /// Scheduled, but not yet inside the start window.
  preTrip,

  /// Inside the start window and at the start region — start is offered.
  atStart,

  /// Inside the start window but not at the start region.
  wrongCity,

  /// Under way.
  inMotion,

  /// Past its dates.
  finished,

  /// Abandoned.
  cancelled,
}

/// One waypoint on the live rail, paired with the traveller's check-in.
class LiveWaypoint {
  final String key;

  /// Zero-based index in the itinerary's ordered `dayPlans` list.
  ///
  /// This structural index is deliberately separate from [dayNumber], which is
  /// supplied by the itinerary and may be non-sequential.
  final int dayIndex;
  final int dayNumber;
  final TripActivityModel activity;
  final TripCheckIn checkIn;

  const LiveWaypoint({
    required this.key,
    required this.dayIndex,
    required this.dayNumber,
    required this.activity,
    required this.checkIn,
  });

  bool get isLogged => checkIn.isLogged;
}

/// Everything the live screen renders, derived in one place from real inputs:
/// the itinerary, the traveller's own check-ins, and the latest real fix.
/// There is no simulated speed, no fabricated progress, and no invented buddy.
class LiveTripState {
  final TripItineraryModel? trip;
  final Map<String, TripCheckIn> checkIns;
  final LiveFix? fix;
  final bool hasLocationPermission;
  final StartTripValidationResult? startCheck;

  /// Another journey of this traveller's already under way, when there is one.
  /// Its presence blocks starting [trip] until the traveller resolves it.
  final TripItineraryModel? conflictingTrip;

  /// Why the last location read produced no fix, when it didn't.
  final LocationFailure? locationFailure;

  final bool isOffline;
  final DateTime? lastUpdated;
  final bool isResolvingLocation;
  final bool isStartingTrip;
  final String? lastActionError;

  const LiveTripState({
    this.trip,
    this.checkIns = const {},
    this.fix,
    this.hasLocationPermission = false,
    this.startCheck,
    this.conflictingTrip,
    this.locationFailure,
    this.isOffline = false,
    this.lastUpdated,
    this.isResolvingLocation = false,
    this.isStartingTrip = false,
    this.lastActionError,
  });

  static const TripValidationService _service = TripValidationService();

  /// Stable key for a waypoint: `<dayIndex>:<activityIndex>`.
  static String waypointKey(int dayIndex, int activityIndex) =>
      '$dayIndex:$activityIndex';

  static String waypointKeyForActivity(
    int dayIndex,
    int activityIndex,
    TripActivityModel activity,
  ) {
    final stableId = activity.activityId?.trim();
    return stableId == null || stableId.isEmpty
        ? waypointKey(dayIndex, activityIndex)
        : stableId;
  }

  LiveTripState copyWith({
    TripItineraryModel? trip,
    Map<String, TripCheckIn>? checkIns,
    LiveFix? fix,
    bool? hasLocationPermission,
    StartTripValidationResult? startCheck,
    TripItineraryModel? conflictingTrip,
    LocationFailure? locationFailure,
    bool? isOffline,
    DateTime? lastUpdated,
    bool? isResolvingLocation,
    bool? isStartingTrip,
    String? lastActionError,
    bool clearActionError = false,
  }) {
    return LiveTripState(
      trip: trip ?? this.trip,
      checkIns: checkIns ?? this.checkIns,
      fix: fix ?? this.fix,
      hasLocationPermission:
          hasLocationPermission ?? this.hasLocationPermission,
      startCheck: startCheck ?? this.startCheck,
      conflictingTrip: conflictingTrip ?? this.conflictingTrip,
      locationFailure: locationFailure ?? this.locationFailure,
      isOffline: isOffline ?? this.isOffline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isResolvingLocation: isResolvingLocation ?? this.isResolvingLocation,
      isStartingTrip: isStartingTrip ?? this.isStartingTrip,
      lastActionError: clearActionError
          ? null
          : (lastActionError ?? this.lastActionError),
    );
  }

  TripStatus get status => trip?.tripStatus ?? TripStatus.planned;

  List<LiveWaypoint> get waypoints {
    final journey = trip;
    if (journey == null) return const [];
    final result = <LiveWaypoint>[];
    for (int d = 0; d < journey.dayPlans.length; d++) {
      final day = journey.dayPlans[d];
      for (int a = 0; a < day.activities.length; a++) {
        final activity = day.activities[a];
        final key = waypointKeyForActivity(d, a, activity);
        result.add(
          LiveWaypoint(
            key: key,
            dayIndex: d,
            dayNumber: day.dayNumber,
            activity: activity,
            // An explicit check-in wins; a server-side `isCompleted` is
            // honoured only when the traveller has not contradicted it.
            checkIn:
                checkIns[key] ??
                (activity.isCompleted
                    ? TripCheckIn.completed
                    : TripCheckIn.pending),
          ),
        );
      }
    }
    return result;
  }

  /// The waypoint the traveller is on right now, or null when the rail is done.
  LiveWaypoint? get nowWaypoint {
    for (final w in waypoints) {
      if (!w.isLogged) return w;
    }
    return null;
  }

  /// The waypoint after [nowWaypoint]. Null at the end of the rail.
  LiveWaypoint? get nextWaypoint {
    final all = waypoints;
    final index = all.indexWhere((w) => !w.isLogged);
    if (index < 0 || index + 1 >= all.length) return null;
    return all[index + 1];
  }

  /// The waypoints belonging to the ordered day-plan index [dayIndex].
  ///
  /// [dayIndex] is not inferred from the clock or from [LiveWaypoint.dayNumber].
  /// The latter remains the itinerary-provided display number and may not match
  /// this zero-based structural index.
  List<LiveWaypoint> waypointsForDay(int dayIndex) {
    return List<LiveWaypoint>.unmodifiable(
      waypoints.where((waypoint) => waypoint.dayIndex == dayIndex),
    );
  }

  /// The first unlogged waypoint for [dayIndex], or null when that day is done
  /// or has no activity details.
  LiveWaypoint? nowWaypointForDay(int dayIndex) {
    for (final waypoint in waypointsForDay(dayIndex)) {
      if (!waypoint.isLogged) return waypoint;
    }
    return null;
  }

  /// The waypoint after the current one within [dayIndex].
  ///
  /// This is scoped to the day: it never advances into a later day-plan.
  LiveWaypoint? nextWaypointForDay(int dayIndex) {
    final dayWaypoints = waypointsForDay(dayIndex);
    final currentIndex = dayWaypoints.indexWhere(
      (waypoint) => !waypoint.isLogged,
    );
    if (currentIndex < 0 || currentIndex + 1 >= dayWaypoints.length) {
      return null;
    }
    return dayWaypoints[currentIndex + 1];
  }

  int totalWaypointsForDay(int dayIndex) => waypointsForDay(dayIndex).length;

  int loggedCountForDay(int dayIndex) =>
      waypointsForDay(dayIndex).where((waypoint) => waypoint.isLogged).length;

  int completedCountForDay(int dayIndex) => waypointsForDay(
    dayIndex,
  ).where((waypoint) => waypoint.checkIn == TripCheckIn.completed).length;

  int skippedCountForDay(int dayIndex) => waypointsForDay(
    dayIndex,
  ).where((waypoint) => waypoint.checkIn == TripCheckIn.skipped).length;

  /// Logged progress for [dayIndex], expressed as a fraction from 0 to 1.
  /// An empty day has no progress to report and returns 0.
  double dayProgressForDay(int dayIndex) {
    final total = totalWaypointsForDay(dayIndex);
    if (total == 0) return 0;
    return loggedCountForDay(dayIndex) / total;
  }

  /// True only when [dayIndex] has activities and all of them are logged.
  bool isDayComplete(int dayIndex) =>
      totalWaypointsForDay(dayIndex) > 0 && nowWaypointForDay(dayIndex) == null;

  int get totalWaypoints => waypoints.length;
  int get loggedCount => waypoints.where((w) => w.isLogged).length;
  int get completedCount =>
      waypoints.where((w) => w.checkIn == TripCheckIn.completed).length;
  int get skippedCount =>
      waypoints.where((w) => w.checkIn == TripCheckIn.skipped).length;

  /// True when every waypoint has been logged — the rail is finished, which is
  /// a fact about check-ins, not a guess about the clock.
  bool get isRailComplete => waypoints.isNotEmpty && nowWaypoint == null;

  ArrivalConfidence get arrivalConfidence {
    final now = nowWaypoint;
    if (now != null && now.checkIn.isConfirmedOnSite) {
      return ArrivalConfidence.confirmed;
    }
    if (fix != null && status == TripStatus.active) {
      return ArrivalConfidence.inferred;
    }
    return ArrivalConfidence.unknown;
  }

  ArrivalConfidence arrivalConfidenceForDay(
    int dayIndex, {
    bool inferFromLocation = false,
  }) {
    final now = nowWaypointForDay(dayIndex);
    if (now != null && now.checkIn.isConfirmedOnSite) {
      return ArrivalConfidence.confirmed;
    }
    if (inferFromLocation && fix != null && status == TripStatus.active) {
      return ArrivalConfidence.inferred;
    }
    return ArrivalConfidence.unknown;
  }

  /// Straight-line distance from the journey's start region, when both a fix
  /// and a region exist. Null means "not measurable", never "zero".
  double? get distanceFromStartRegionKm {
    final journey = trip;
    final position = fix;
    if (journey == null || position == null) return null;
    if (!TripValidationService.hasValidCoordinates(
      position.lat,
      position.lng,
    )) {
      return null;
    }
    if (!TripValidationService.hasValidCoordinates(
      journey.startLat,
      journey.startLng,
    )) {
      return null;
    }
    return _service.calculateDistanceKm(
      lat1: position.lat,
      lng1: position.lng,
      lat2: journey.startLat!,
      lng2: journey.startLng!,
    );
  }

  /// Genuine deviation: under way and measurably outside the journey's region.
  /// A stray position is reported as a fact ("you are N km from Jaipur"), and
  /// only while the journey is actually in motion.
  bool get isOffRoute {
    if (status != TripStatus.active) return false;
    final distance = distanceFromStartRegionKm;
    return distance != null &&
        distance > TripValidationService.startRegionRadiusKm;
  }

  LiveTripPhase get phase {
    final journey = trip;
    if (journey == null) return LiveTripPhase.none;
    switch (status) {
      case TripStatus.cancelled:
        return LiveTripPhase.cancelled;
      case TripStatus.completed:
        return LiveTripPhase.finished;
      case TripStatus.active:
        return LiveTripPhase.inMotion;
      default:
        break;
    }
    final check = startCheck;
    if (check == null) return LiveTripPhase.preTrip;
    if (check.status == StartTripStatus.valid) return LiveTripPhase.atStart;
    if (check.status == StartTripStatus.wrongCity) {
      return LiveTripPhase.wrongCity;
    }
    return LiveTripPhase.preTrip;
  }

  /// The start button is offered only when every gate passed and the lifecycle
  /// still permits a start.
  bool get canStartTrip =>
      status.canStart && startCheck?.status == StartTripStatus.valid;

  /// Real timestamp of the last successful read or write. Null when nothing has
  /// happened yet — the UI says so rather than showing a fabricated clock.
  String get lastUpdatedLabel => _relative(lastUpdated);

  static String _relative(DateTime? when) {
    if (when == null) return 'Not yet synced';
    final delta = DateTime.now().difference(when);
    if (delta.inSeconds < 30) return 'Just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
    if (delta.inHours < 24) return '${delta.inHours} hr ago';
    return '${delta.inDays} d ago';
  }
}
