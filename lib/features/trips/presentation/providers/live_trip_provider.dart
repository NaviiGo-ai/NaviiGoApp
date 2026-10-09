import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/cache/hive_service.dart';
import '../../../../core/location/geolocator_location_adapter.dart';
import '../../../../core/location/location_adapter.dart';
import '../../domain/models/live_trip_state.dart';
import '../../domain/models/trip_itinerary_model.dart';
import '../../domain/services/trip_validation_service.dart';
import 'trip_provider.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// CHECK-IN PERSISTENCE
/// Manual check-ins survive app restarts via the existing Hive box, and work
/// with no network — which is the point: they are the traveller's own record.
/// ─────────────────────────────────────────────────────────────────────────────
abstract class CheckInStore {
  Map<String, TripCheckIn> read(String tripId);
  Future<void> write(String tripId, Map<String, TripCheckIn> checkIns);
}

class InMemoryCheckInStore implements CheckInStore {
  final Map<String, Map<String, TripCheckIn>> _data = {};

  @override
  Map<String, TripCheckIn> read(String tripId) =>
      Map<String, TripCheckIn>.from(_data[tripId] ?? const {});

  @override
  Future<void> write(String tripId, Map<String, TripCheckIn> checkIns) async {
    _data[tripId] = Map<String, TripCheckIn>.from(checkIns);
  }
}

class HiveCheckInStore implements CheckInStore {
  static String _boxKey(String tripId) => 'trip_checkins_$tripId';

  @override
  Map<String, TripCheckIn> read(String tripId) {
    final raw = HiveService.itineraryBox.get(_boxKey(tripId));
    if (raw is Map) {
      return {
        for (final entry in raw.entries)
          entry.key.toString(): TripCheckInX.fromString(
            entry.value?.toString(),
          ),
      };
    }
    return {};
  }

  @override
  Future<void> write(String tripId, Map<String, TripCheckIn> checkIns) async {
    await HiveService.itineraryBox.put(_boxKey(tripId), {
      for (final entry in checkIns.entries) entry.key: entry.value.wireName,
    });
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// PROVIDERS
/// Each mutable input lives in its own provider so a Firestore emission
/// rebuilds the derived [LiveTripState] without discarding the traveller's
/// check-ins, their latest fix, or the last-known sync time.
/// ─────────────────────────────────────────────────────────────────────────────
final checkInStoreProvider = Provider<CheckInStore>(
  (ref) => HiveCheckInStore(),
);

/// The signed-in traveller's id, or null. Split out from `currentUserProvider`
/// so start-trip validation can be exercised without constructing a Firebase
/// user.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider)?.uid,
);

/// Persists the start of a journey. Indirection so the start flow can be tested
/// without a live Firestore connection.
typedef StartTripWriter = Future<void> Function(String uid, String tripId);

final startTripWriterProvider = Provider<StartTripWriter>(
  (ref) =>
      (uid, tripId) =>
          ref.read(tripRepositoryProvider).setActiveTrip(uid, tripId),
);

/// Ends a journey the traveller explicitly walked away from. Separate from the
/// start writer because ending someone's journey is never a side effect of
/// beginning another — it is always its own confirmed action.
typedef EndTripWriter = Future<void> Function(String uid, String tripId);

final endTripWriterProvider = Provider<EndTripWriter>(
  (ref) =>
      (uid, tripId) => ref.read(tripRepositoryProvider).endTrip(uid, tripId),
);

/// The platform implementation. Widgets and providers never touch the plugin.
final locationAdapterProvider = Provider<LocationAdapter>(
  (ref) => const GeolocatorLocationAdapter(),
);

final liveTripValidationServiceProvider = Provider<TripValidationService>(
  (ref) => const TripValidationService(),
);

final liveTripFixProvider = StateProvider<LiveFix?>((ref) => null);

final liveTripPermissionProvider = StateProvider<bool>((ref) => false);

/// Why the last location read did not produce a fix. Kept separate from
/// permission because "location is switched off" and "you declined" are fixed
/// in different places.
final liveTripLocationFailureProvider = StateProvider<LocationFailure?>(
  (ref) => null,
);

/// True when the last read or write failed on connectivity — not a guess about
/// signal strength.
final liveTripOfflineProvider = StateProvider<bool>((ref) => false);

/// Real timestamp of the last successful read or write.
final liveTripLastSyncProvider = StateProvider<DateTime?>((ref) => null);

/// Transient command flags and the last real error from a command.
class LiveTripCommandState {
  final bool isResolvingLocation;
  final bool isStartingTrip;
  final String? error;

  const LiveTripCommandState({
    this.isResolvingLocation = false,
    this.isStartingTrip = false,
    this.error,
  });

  static const idle = LiveTripCommandState();

  LiveTripCommandState copyWith({
    bool? isResolvingLocation,
    bool? isStartingTrip,
    String? error,
    bool clearError = false,
  }) {
    return LiveTripCommandState(
      isResolvingLocation: isResolvingLocation ?? this.isResolvingLocation,
      isStartingTrip: isStartingTrip ?? this.isStartingTrip,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final liveTripCommandProvider = StateProvider<LiveTripCommandState>(
  (ref) => LiveTripCommandState.idle,
);

/// The controller owns the traveller's check-ins for one journey.
class LiveTripController extends StateNotifier<Map<String, TripCheckIn>> {
  LiveTripController(this._ref, this.tripId, this._store)
    : super(_store.read(tripId));

  final Ref _ref;
  final String tripId;
  final CheckInStore _store;

  /// I'M HERE / COMPLETE / SKIP. Logging a check-in always succeeds — it is the
  /// traveller's own record and must not depend on the network.
  Future<void> logCheckIn(String waypointKey, TripCheckIn checkIn) async {
    final next = Map<String, TripCheckIn>.from(state);
    if (checkIn == TripCheckIn.pending) {
      next.remove(waypointKey);
    } else {
      next[waypointKey] = checkIn;
    }
    state = next;
    await _store.write(tripId, next);
    _ref.read(liveTripLastSyncProvider.notifier).state = DateTime.now();
  }

  /// Undo a mistake — the traveller changes their mind.
  Future<void> clearCheckIn(String waypointKey) =>
      logCheckIn(waypointKey, TripCheckIn.pending);

  /// Ask the platform adapter for a position. Never fabricates one.
  ///
  /// Every caller is an explicit traveller action (VERIFY YOUR START / TRY
  /// LOCATION AGAIN), so this is the only place that may raise the OS
  /// permission prompt — permission is never requested at launch or on a
  /// rebuild.
  Future<void> refreshLocation() async {
    final commands = _ref.read(liveTripCommandProvider.notifier);
    commands.state = commands.state.copyWith(
      isResolvingLocation: true,
      clearError: true,
    );
    try {
      final result = await _ref
          .read(locationAdapterProvider)
          .current(userInitiated: true);
      _ref.read(liveTripPermissionProvider.notifier).state =
          result.permissionGranted;
      _ref.read(liveTripLocationFailureProvider.notifier).state =
          result.failure;
      if (result.hasFix) {
        _ref.read(liveTripFixProvider.notifier).state = result.fix;
        _ref.read(liveTripLastSyncProvider.notifier).state = DateTime.now();
      }
      commands.state = commands.state.copyWith(
        isResolvingLocation: false,
        error: result.hasFix ? null : result.message,
        clearError: result.hasFix,
      );
    } catch (_) {
      commands.state = commands.state.copyWith(
        isResolvingLocation: false,
        error: 'Could not read your location. Try again.',
      );
    }
  }

  /// Hand off to the OS permission screen. Only ever from an explicit OPEN
  /// SETTINGS action — the app never navigates there on its own.
  Future<bool> openAppSettings() =>
      _ref.read(locationAdapterProvider).openAppSettings();

  /// Hand off to the OS location-services switch.
  Future<bool> openLocationSettings() =>
      _ref.read(locationAdapterProvider).openLocationSettings();

  /// Begin the journey. Persists `active` through the repository so the server
  /// and every other screen share one lifecycle, then marks it started locally.
  Future<bool> startTrip(TripItineraryModel trip) async {
    final uid = _ref.read(currentUserIdProvider);
    if (uid == null) return false;

    final commands = _ref.read(liveTripCommandProvider.notifier);

    // One journey at a time. Beginning a second without ending the first is
    // never a silent side effect — the traveller resolves it explicitly.
    final conflict = otherActiveTrips(trip.id);
    if (conflict != null) {
      commands.state = commands.state.copyWith(
        isStartingTrip: false,
        error: 'You already have a journey under way.',
      );
      return false;
    }

    commands.state = commands.state.copyWith(
      isStartingTrip: true,
      clearError: true,
    );
    try {
      await _ref.read(startTripWriterProvider)(uid, trip.id);
      _ref.read(liveTripLastSyncProvider.notifier).state = DateTime.now();
      _ref.read(liveTripOfflineProvider.notifier).state = false;
      commands.state = commands.state.copyWith(isStartingTrip: false);
      return true;
    } catch (_) {
      // Starting genuinely failed — say so and stay in the pre-trip state
      // rather than showing a trip that did not begin.
      _ref.read(liveTripOfflineProvider.notifier).state = true;
      commands.state = commands.state.copyWith(
        isStartingTrip: false,
        error: 'Could not start the journey. Check your connection and retry.',
      );
      return false;
    }
  }

  /// End a journey the traveller chose to leave. Only ever called from the
  /// conflict resolution card, after the traveller picked it.
  Future<bool> endTrip(TripItineraryModel trip) async {
    final uid = _ref.read(currentUserIdProvider);
    if (uid == null) return false;

    final commands = _ref.read(liveTripCommandProvider.notifier);
    commands.state = commands.state.copyWith(clearError: true);
    try {
      await _ref.read(endTripWriterProvider)(uid, trip.id);
      _ref.read(liveTripLastSyncProvider.notifier).state = DateTime.now();
      _ref.read(liveTripOfflineProvider.notifier).state = false;
      return true;
    } catch (_) {
      _ref.read(liveTripOfflineProvider.notifier).state = true;
      commands.state = commands.state.copyWith(
        error: 'Could not end that journey. Check your connection and retry.',
      );
      return false;
    }
  }

  /// The journey already under way, if it is not [exceptTripId].
  TripItineraryModel? otherActiveTrips(String exceptTripId) {
    for (final t in _ref.read(activeTripsProvider)) {
      if (t.id != exceptTripId) return t;
    }
    return null;
  }

  void recordSyncFailure() {
    _ref.read(liveTripOfflineProvider.notifier).state = true;
  }

  void clearCommandError() {
    final commands = _ref.read(liveTripCommandProvider.notifier);
    commands.state = commands.state.copyWith(clearError: true);
  }
}

final liveTripControllerProvider =
    StateNotifierProvider.family<
      LiveTripController,
      Map<String, TripCheckIn>,
      String
    >((ref, tripId) {
      return LiveTripController(ref, tripId, ref.watch(checkInStoreProvider));
    });

/// Everything the live screen renders, derived from real inputs only.
final liveTripStateProvider = Provider.family<LiveTripState, TripItineraryModel>((
  ref,
  trip,
) {
  final commands = ref.watch(liveTripCommandProvider);
  final fix = ref.watch(liveTripFixProvider);
  final permission = ref.watch(liveTripPermissionProvider);
  final locationFailure = ref.watch(liveTripLocationFailureProvider);
  final userId = ref.watch(currentUserIdProvider);

  // Another journey already under way. Starting is blocked until the traveller
  // resolves it — the app never ends someone's journey on its own.
  TripItineraryModel? conflict;
  for (final other in ref.watch(activeTripsProvider)) {
    if (other.id != trip.id) {
      conflict = other;
      break;
    }
  }

  final startCheck = ref
      .watch(liveTripValidationServiceProvider)
      .validateStartTrip(
        trip: trip,
        currentUserId: userId,
        userLat: fix?.lat,
        userLng: fix?.lng,
        gpsAccuracyMeters: fix?.accuracyMeters,
        fixTimestamp: fix?.timestamp,
        hasLocationPermission: permission,
        locationFailure: locationFailure,
        hasOtherActiveTrip: conflict != null,
      );

  return LiveTripState(
    trip: trip,
    checkIns: ref.watch(liveTripControllerProvider(trip.id)),
    fix: fix,
    hasLocationPermission: permission,
    startCheck: startCheck,
    conflictingTrip: conflict,
    locationFailure: locationFailure,
    isOffline: ref.watch(liveTripOfflineProvider),
    lastUpdated: ref.watch(liveTripLastSyncProvider),
    isResolvingLocation: commands.isResolvingLocation,
    isStartingTrip: commands.isStartingTrip,
    lastActionError: commands.error,
  );
});
