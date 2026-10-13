import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/network/api_provider.dart';
import '../../data/trip_repository.dart';
import '../../domain/models/trip_itinerary_model.dart';

/// The signed-in traveller's id, or null. Keeping this primitive seam in the
/// trip provider lets owner-scoped derived streams be tested without creating a
/// Firebase User or touching the platform auth plugin.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider)?.uid,
);

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TripRepository(apiClient: apiClient);
});

/// Stream of all user trips from Firestore
final userTripsStreamProvider = StreamProvider<List<TripItineraryModel>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream.value([]);
  }
  final repo = ref.watch(tripRepositoryProvider);
  return repo.getUserTripsStream(uid);
});

/// Journeys whose canonical lifecycle says they are under way.
///
/// Lifecycle is the only authority here. Dates may make a journey UPCOMING or
/// ELIGIBLE_TO_START, but merely arriving on the calendar must never make one
/// ACTIVE — that requires an explicit, validated transition.
final activeTripsProvider = Provider<List<TripItineraryModel>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const [];
  final trips = ref.watch(userTripsStreamProvider).value;
  if (trips == null) return const [];
  return trips
      .where(
        (t) =>
            t.userId == uid &&
            !t.isEphemeral &&
            t.tripStatus == TripStatus.active,
      )
      .toList();
});

/// Currently active ongoing trip (if any)
final activeTripProvider = Provider<TripItineraryModel?>((ref) {
  final active = ref.watch(activeTripsProvider);
  return active.isEmpty ? null : active.first;
});

/// Upcoming trips scheduled for future dates
final upcomingTripsProvider = Provider<List<TripItineraryModel>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const [];
  final tripsAsync = ref.watch(userTripsStreamProvider);
  return tripsAsync.when(
    data: (trips) => trips
        .where(
          (t) =>
              t.userId == uid &&
              !t.isEphemeral &&
              const {
                TripStatus.planned,
                TripStatus.upcoming,
                TripStatus.eligibleToStart,
              }.contains(t.tripStatus),
        )
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Past completed journeys
final pastTripsProvider = Provider<List<TripItineraryModel>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const [];
  final tripsAsync = ref.watch(userTripsStreamProvider);
  return tripsAsync.when(
    // A cancelled journey is terminal, but it is not evidence that a visit
    // happened. History and Passport claims therefore only accept the
    // lifecycle's completed state; calendar dates are never a substitute for
    // that authority here.
    data: (trips) => trips
        .where(
          (t) =>
              t.userId == uid &&
              !t.isEphemeral &&
              t.tripStatus == TripStatus.completed,
        )
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Trip detail provider by tripId
final tripDetailProvider = FutureProvider.family<TripItineraryModel?, String>((
  ref,
  tripId,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final repo = ref.watch(tripRepositoryProvider);
  final trip = await repo.getTripById(user.uid, tripId);
  final currentUser = ref.read(currentUserProvider);
  if (currentUser?.uid != user.uid) return null;
  if (trip == null || trip.userId != user.uid) return null;
  return trip;
});
