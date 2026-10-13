import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/cache/hive_service.dart';
import '../../../../core/location/geolocator_location_adapter.dart';
import '../../../../core/location/location_adapter.dart';
import '../../domain/models/live_trip_state.dart';
import '../../domain/models/trip_itinerary_model.dart';
import '../../domain/services/trip_validation_service.dart';
import 'trip_provider.dart';

// Keep the historical live-provider import surface available to callers while
// the owner identity seam lives with the trip streams. This is a re-export,
// not a second provider, so all owner gates continue to share one value.
export 'trip_provider.dart' show currentUserIdProvider;

/// ─────────────────────────────────────────────────────────────────────────────
/// CHECK-IN PERSISTENCE
/// Manual check-ins survive app restarts via the existing Hive box, and work
/// with no network — which is the point: they are the traveller's own record.
/// ─────────────────────────────────────────────────────────────────────────────
abstract class CheckInStore {
  Map<String, TripCheckIn> read(String tripId);
  Future<void> write(String tripId, Map<String, TripCheckIn> checkIns);
}

abstract class OwnerScopedCheckInStore {
  Map<String, TripCheckIn> readForOwner(String ownerUid, String tripId);
  Future<void> writeForOwner(
    String ownerUid,
    String tripId,
    Map<String, TripCheckIn> checkIns,
  );
}

class InMemoryCheckInStore implements CheckInStore, OwnerScopedCheckInStore {
  final Map<String, Map<String, TripCheckIn>> _data = {};
  final Map<String, Map<String, TripCheckIn>> _ownedData = {};

  static String _ownedKey(String ownerUid, String tripId) =>
      '$ownerUid\u0000$tripId';

  @override
  Map<String, TripCheckIn> read(String tripId) =>
      Map<String, TripCheckIn>.from(_data[tripId] ?? const {});

  @override
  Future<void> write(String tripId, Map<String, TripCheckIn> checkIns) async {
    _data[tripId] = Map<String, TripCheckIn>.from(checkIns);
  }

  @override
  Map<String, TripCheckIn> readForOwner(String ownerUid, String tripId) {
    return Map<String, TripCheckIn>.from(
      _ownedData[_ownedKey(ownerUid, tripId)] ?? const {},
    );
  }

  @override
  Future<void> writeForOwner(
    String ownerUid,
    String tripId,
    Map<String, TripCheckIn> checkIns,
  ) async {
    _ownedData[_ownedKey(ownerUid, tripId)] = Map<String, TripCheckIn>.from(
      checkIns,
    );
  }
}

class HiveCheckInStore implements CheckInStore, OwnerScopedCheckInStore {
  static String _boxKey(String ownerUid, String tripId) =>
      'trip_checkins:${ownerUid.length}:$ownerUid:$tripId';

  @override
  Map<String, TripCheckIn> read(String tripId) => const {};

  @override
  Future<void> write(String tripId, Map<String, TripCheckIn> checkIns) async {}

  @override
  Map<String, TripCheckIn> readForOwner(String ownerUid, String tripId) {
    if (ownerUid.isEmpty || tripId.isEmpty) return {};
    final raw = HiveService.itineraryBox.get(_boxKey(ownerUid, tripId));
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
  Future<void> writeForOwner(
    String ownerUid,
    String tripId,
    Map<String, TripCheckIn> checkIns,
  ) async {
    if (ownerUid.isEmpty || tripId.isEmpty) return;
    await HiveService.itineraryBox.put(_boxKey(ownerUid, tripId), {
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
final liveTripFixOwnerProvider = StateProvider<String?>((ref) => null);
final liveTripFixTripProvider = StateProvider<String?>((ref) => null);

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

/// Scope for transient live command state. A late result for another trip or
/// account must not remain visible when Riverpod retains the container.
final liveTripContextOwnerProvider = StateProvider<String?>((ref) => null);
final liveTripContextTripProvider = StateProvider<String?>((ref) => null);

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
  LiveTripController(this._ref, this.tripId, this._store, this.ownerUid)
    : super(_readOwnedCheckIns(_store, ownerUid, tripId));

  final Ref _ref;
  final String tripId;
  final CheckInStore _store;
  final String? ownerUid;
  int _operationGeneration = 0;
  Future<void> _checkInWriteQueue = Future<void>.value();
  Map<String, TripCheckIn> _confirmedCheckIns = const {};
  int _pendingCheckInWrites = 0;

  static Map<String, TripCheckIn> _readOwnedCheckIns(
    CheckInStore store,
    String? ownerUid,
    String tripId,
  ) {
    if (ownerUid == null || ownerUid.isEmpty) return {};
    if (store is OwnerScopedCheckInStore) {
      final scopedStore = store as OwnerScopedCheckInStore;
      return scopedStore.readForOwner(ownerUid, tripId);
    }
    return {};
  }

  void _activateContext() {
    if (ownerUid == null || ownerUid!.isEmpty) return;
    _ref.read(liveTripContextOwnerProvider.notifier).state = ownerUid;
    _ref.read(liveTripContextTripProvider.notifier).state = tripId;
  }

  int _beginOperation() {
    _activateContext();
    return ++_operationGeneration;
  }

  bool _isCurrentOperation(int generation) {
    return mounted &&
        generation == _operationGeneration &&
        ownerUid != null &&
        _ref.read(currentUserIdProvider) == ownerUid &&
        _ref.read(liveTripContextOwnerProvider) == ownerUid &&
        _ref.read(liveTripContextTripProvider) == tripId;
  }

  void invalidateSession() => _operationGeneration++;

  Future<void> _enqueueCheckInWrite(
    OwnerScopedCheckInStore store,
    String uid,
    Map<String, TripCheckIn> checkIns,
  ) {
    final write = _checkInWriteQueue.then<void>((_) async {
      await store.writeForOwner(uid, tripId, checkIns);
    });
    // A failed write must not poison later writes in the queue.
    _checkInWriteQueue = write.catchError((_) {});
    return write;
  }

  /// I'M HERE / COMPLETE / SKIP. The record is local and does not depend on the
  /// network, but a local persistence failure is surfaced and rolled back.
  Future<void> logCheckIn(String waypointKey, TripCheckIn checkIn) async {
    final uid = ownerUid;
    if (uid == null || _ref.read(currentUserIdProvider) != uid) return;
    final generation = _beginOperation();
    final next = Map<String, TripCheckIn>.from(state);
    if (checkIn == TripCheckIn.pending) {
      next.remove(waypointKey);
    } else {
      next[waypointKey] = checkIn;
    }
    if (_store is! OwnerScopedCheckInStore) return;
    if (_pendingCheckInWrites == 0) {
      _confirmedCheckIns = Map<String, TripCheckIn>.from(state);
    }
    _pendingCheckInWrites++;
    state = next;
    final scopedStore = _store as OwnerScopedCheckInStore;
    try {
      await _enqueueCheckInWrite(scopedStore, uid, next);
      _confirmedCheckIns = Map<String, TripCheckIn>.from(next);
      _pendingCheckInWrites--;
      if (_isCurrentOperation(generation)) {
        _ref.read(liveTripLastSyncProvider.notifier).state = DateTime.now();
      }
    } catch (_) {
      _pendingCheckInWrites--;
      if (!_isCurrentOperation(generation)) return;
      if (_pendingCheckInWrites == 0) {
        state = Map<String, TripCheckIn>.from(_confirmedCheckIns);
      }
      _ref.read(liveTripCommandProvider.notifier).state = _ref
          .read(liveTripCommandProvider.notifier)
          .state
          .copyWith(error: 'Could not save that check-in locally. Try again.');
    }
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
    final uid = ownerUid;
    if (uid == null || _ref.read(currentUserIdProvider) != uid) return;
    final generation = _beginOperation();
    final commands = _ref.read(liveTripCommandProvider.notifier);
    commands.state = commands.state.copyWith(
      isResolvingLocation: true,
      clearError: true,
    );
    try {
      final result = await _ref
          .read(locationAdapterProvider)
          .current(userInitiated: true);
      if (!_isCurrentOperation(generation)) return;
      _ref.read(liveTripPermissionProvider.notifier).state =
          result.permissionGranted;
      _ref.read(liveTripLocationFailureProvider.notifier).state =
          result.failure;
      final hasUsableFix = result.hasFix && result.failure == null;
      if (hasUsableFix) {
        _ref.read(liveTripFixProvider.notifier).state = result.fix;
        _ref.read(liveTripFixOwnerProvider.notifier).state = uid;
        _ref.read(liveTripFixTripProvider.notifier).state = tripId;
        _ref.read(liveTripLastSyncProvider.notifier).state = DateTime.now();
      } else {
        _ref.read(liveTripFixProvider.notifier).state = null;
        _ref.read(liveTripFixOwnerProvider.notifier).state = null;
        _ref.read(liveTripFixTripProvider.notifier).state = null;
      }
      commands.state = commands.state.copyWith(
        isResolvingLocation: false,
        error: hasUsableFix ? null : result.message,
        clearError: hasUsableFix,
      );
    } catch (_) {
      if (!_isCurrentOperation(generation)) return;
      _ref.read(liveTripLocationFailureProvider.notifier).state =
          LocationFailure.unavailable;
      _ref.read(liveTripFixProvider.notifier).state = null;
      _ref.read(liveTripFixOwnerProvider.notifier).state = null;
      _ref.read(liveTripFixTripProvider.notifier).state = null;
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
    if (uid == null ||
        uid != ownerUid ||
        trip.id != tripId ||
        trip.userId != uid ||
        trip.isEphemeral ||
        trip.tripStatus.isTerminal ||
        !trip.tripStatus.canStart) {
      return false;
    }

    final commands = _ref.read(liveTripCommandProvider.notifier);

    // One journey at a time. Beginning a second without ending the first is
    // never a silent side effect — the traveller resolves it explicitly.
    final conflict = otherActiveTrips(trip.id);
    final fixOwner = _ref.read(liveTripFixOwnerProvider);
    final fixTrip = _ref.read(liveTripFixTripProvider);
    final fix =
        (fixOwner == null && fixTrip == null) ||
            (fixOwner == uid && fixTrip == trip.id)
        ? _ref.read(liveTripFixProvider)
        : null;
    final contextOwner = _ref.read(liveTripContextOwnerProvider);
    final contextTrip = _ref.read(liveTripContextTripProvider);
    final contextMatches =
        (contextOwner == null && contextTrip == null) ||
        (contextOwner == uid && contextTrip == trip.id);
    final check = _ref
        .read(liveTripValidationServiceProvider)
        .validateStartTrip(
          trip: trip,
          currentUserId: uid,
          userLat: fix?.lat,
          userLng: fix?.lng,
          gpsAccuracyMeters: fix?.accuracyMeters,
          fixTimestamp: fix?.timestamp,
          hasLocationPermission: contextMatches
              ? _ref.read(liveTripPermissionProvider)
              : false,
          locationFailure: contextMatches
              ? _ref.read(liveTripLocationFailureProvider)
              : null,
          hasOtherActiveTrip: conflict != null,
        );
    if (!check.isValid) {
      commands.state = commands.state.copyWith(
        error:
            check.message ??
            'The journey cannot start until the start checks pass.',
      );
      return false;
    }
    if (conflict != null) {
      commands.state = commands.state.copyWith(
        isStartingTrip: false,
        error: 'You already have a journey under way.',
      );
      return false;
    }

    final generation = _beginOperation();
    commands.state = commands.state.copyWith(
      isStartingTrip: true,
      clearError: true,
    );
    try {
      await _ref.read(startTripWriterProvider)(uid, trip.id);
      if (!_isCurrentOperation(generation)) return false;
      _ref.read(liveTripLastSyncProvider.notifier).state = DateTime.now();
      _ref.read(liveTripOfflineProvider.notifier).state = false;
      commands.state = commands.state.copyWith(isStartingTrip: false);
      return true;
    } catch (_) {
      if (!_isCurrentOperation(generation)) return false;
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
    if (uid == null ||
        uid != ownerUid ||
        trip.userId != uid ||
        trip.isEphemeral ||
        trip.tripStatus.isTerminal ||
        trip.tripStatus != TripStatus.active) {
      return false;
    }

    final generation = _beginOperation();
    final commands = _ref.read(liveTripCommandProvider.notifier);
    commands.state = commands.state.copyWith(clearError: true);
    try {
      await _ref.read(endTripWriterProvider)(uid, trip.id);
      if (!_isCurrentOperation(generation)) return false;
      _ref.read(liveTripLastSyncProvider.notifier).state = DateTime.now();
      _ref.read(liveTripOfflineProvider.notifier).state = false;
      return true;
    } catch (_) {
      if (!_isCurrentOperation(generation)) return false;
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
      final ownerUid = ref.watch(currentUserIdProvider);
      final controller = LiveTripController(
        ref,
        tripId,
        ref.watch(checkInStoreProvider),
        ownerUid,
      );
      ref.onDispose(controller.invalidateSession);
      return controller;
    });

/// Everything the live screen renders, derived from real inputs only.
final liveTripStateProvider = Provider.family<LiveTripState, TripItineraryModel>((
  ref,
  trip,
) {
  final commands = ref.watch(liveTripCommandProvider);
  final fix = ref.watch(liveTripFixProvider);
  final fixOwner = ref.watch(liveTripFixOwnerProvider);
  final fixTrip = ref.watch(liveTripFixTripProvider);
  final permission = ref.watch(liveTripPermissionProvider);
  final locationFailure = ref.watch(liveTripLocationFailureProvider);
  final userId = ref.watch(currentUserIdProvider);
  final contextOwner = ref.watch(liveTripContextOwnerProvider);
  final contextTrip = ref.watch(liveTripContextTripProvider);
  final contextMatches =
      (contextOwner == null && contextTrip == null) ||
      (contextOwner == userId && contextTrip == trip.id);
  final fixMatches =
      (fixOwner == null && fixTrip == null) ||
      (fixOwner == userId && fixTrip == trip.id);
  final scopedFix = fixMatches ? fix : null;
  final scopedPermission = contextMatches ? permission : false;
  final scopedFailure = contextMatches ? locationFailure : null;

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
        userLat: scopedFix?.lat,
        userLng: scopedFix?.lng,
        gpsAccuracyMeters: scopedFix?.accuracyMeters,
        fixTimestamp: scopedFix?.timestamp,
        hasLocationPermission: scopedPermission,
        locationFailure: scopedFailure,
        hasOtherActiveTrip: conflict != null,
      );

  return LiveTripState(
    trip: trip,
    checkIns: ref.watch(liveTripControllerProvider(trip.id)),
    fix: scopedFix,
    hasLocationPermission: scopedPermission,
    startCheck: startCheck,
    conflictingTrip: conflict,
    locationFailure: scopedFailure,
    isOffline: contextMatches ? ref.watch(liveTripOfflineProvider) : false,
    lastUpdated: contextMatches ? ref.watch(liveTripLastSyncProvider) : null,
    isResolvingLocation: contextMatches ? commands.isResolvingLocation : false,
    isStartingTrip: contextMatches ? commands.isStartingTrip : false,
    lastActionError: contextMatches ? commands.error : null,
  );
});
