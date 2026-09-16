import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/cache/hive_service.dart';
import '../../domain/models/live_trip_state.dart';
import '../../domain/models/trip_itinerary_model.dart';
import '../../domain/services/trip_validation_service.dart';
import 'trip_provider.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// LOCATION
/// The app ships no GPS plugin, so position is always supplied to the live
/// layer by an adapter. Swapping in a platform implementation is the only
/// change required — nothing here invents a fix when the adapter cannot
/// provide one.
/// ─────────────────────────────────────────────────────────────────────────────
enum LocationFailure { permissionDenied, servicesDisabled, unavailable }

class LocationResult {
  final LiveFix? fix;
  final LocationFailure? failure;
  final bool permissionGranted;

  const LocationResult({
    this.fix,
    this.failure,
    this.permissionGranted = false,
  });

  bool get hasFix => fix != null;

  String get message {
    switch (failure) {
      case LocationFailure.permissionDenied:
        return 'Location permission was declined. Enable it in settings to confirm you are at the start.';
      case LocationFailure.servicesDisabled:
        return 'Turn on device location to confirm you are at the start.';
      case LocationFailure.unavailable:
        return 'Location is not available on this build yet.';
      case null:
        return 'Position updated.';
    }
  }
}

abstract class LocationAdapter {
  Future<LocationResult> current();
}

/// Default adapter. Reports the gap honestly instead of returning a made-up
/// coordinate; the start gate fails closed on it like any other missing input.
class UnavailableLocationAdapter implements LocationAdapter {
  const UnavailableLocationAdapter();

  @override
  Future<LocationResult> current() async => const LocationResult(
        failure: LocationFailure.unavailable,
        permissionGranted: false,
      );
}

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
          entry.key.toString(): TripCheckInX.fromString(entry.value?.toString()),
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
  (ref) => (uid, tripId) =>
      ref.read(tripRepositoryProvider).setActiveTrip(uid, tripId),
);

final locationAdapterProvider = Provider<LocationAdapter>(
  (ref) => const UnavailableLocationAdapter(),
);

final liveTripValidationServiceProvider = Provider<TripValidationService>(
  (ref) => const TripValidationService(),
);

final liveTripFixProvider = StateProvider<LiveFix?>((ref) => null);

final liveTripPermissionProvider = StateProvider<bool>((ref) => false);

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
  Future<void> refreshLocation() async {
    final commands = _ref.read(liveTripCommandProvider.notifier);
    commands.state = commands.state.copyWith(
      isResolvingLocation: true,
      clearError: true,
    );
    try {
      final result = await _ref.read(locationAdapterProvider).current();
      _ref.read(liveTripPermissionProvider.notifier).state =
          result.permissionGranted;
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

  /// Begin the journey. Persists `active` through the repository so the server
  /// and every other screen share one lifecycle, then marks it started locally.
  Future<bool> startTrip(TripItineraryModel trip) async {
    final uid = _ref.read(currentUserIdProvider);
    if (uid == null) return false;

    final commands = _ref.read(liveTripCommandProvider.notifier);
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

  void recordSyncFailure() {
    _ref.read(liveTripOfflineProvider.notifier).state = true;
  }

  void clearCommandError() {
    final commands = _ref.read(liveTripCommandProvider.notifier);
    commands.state = commands.state.copyWith(clearError: true);
  }
}

final liveTripControllerProvider =
    StateNotifierProvider.family<LiveTripController, Map<String, TripCheckIn>,
        String>((ref, tripId) {
  return LiveTripController(
    ref,
    tripId,
    ref.watch(checkInStoreProvider),
  );
});

/// Everything the live screen renders, derived from real inputs only.
final liveTripStateProvider =
    Provider.family<LiveTripState, TripItineraryModel>((ref, trip) {
  final commands = ref.watch(liveTripCommandProvider);
  final fix = ref.watch(liveTripFixProvider);
  final permission = ref.watch(liveTripPermissionProvider);
  final userId = ref.watch(currentUserIdProvider);

  final startCheck = ref.watch(liveTripValidationServiceProvider).validateStartTrip(
        trip: trip,
        currentUserId: userId,
        userLat: fix?.lat,
        userLng: fix?.lng,
        gpsAccuracyMeters: fix?.accuracyMeters,
        hasLocationPermission: permission,
      );

  return LiveTripState(
    trip: trip,
    checkIns: ref.watch(liveTripControllerProvider(trip.id)),
    fix: fix,
    hasLocationPermission: permission,
    startCheck: startCheck,
    isOffline: ref.watch(liveTripOfflineProvider),
    lastUpdated: ref.watch(liveTripLastSyncProvider),
    isResolvingLocation: commands.isResolvingLocation,
    isStartingTrip: commands.isStartingTrip,
    lastActionError: commands.error,
  );
});
