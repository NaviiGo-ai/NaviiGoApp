import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/network/api_provider.dart';
import '../../data/trip_repository.dart';
import '../../domain/models/trip_itinerary_model.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TripRepository(apiClient: apiClient);
});

/// Stream of all user trips from Firestore
final userTripsStreamProvider = StreamProvider<List<TripItineraryModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value([]);
  }
  final repo = ref.watch(tripRepositoryProvider);
  return repo.getUserTripsStream(user.uid);
});

/// Journeys whose canonical lifecycle says they are under way.
///
/// Lifecycle is the only authority here. Dates may make a journey UPCOMING or
/// ELIGIBLE_TO_START, but merely arriving on the calendar must never make one
/// ACTIVE — that requires an explicit, validated transition.
final activeTripsProvider = Provider<List<TripItineraryModel>>((ref) {
  final trips = ref.watch(userTripsStreamProvider).value;
  if (trips == null) return const [];
  return trips.where((t) => t.tripStatus == TripStatus.active).toList();
});

/// Currently active ongoing trip (if any)
final activeTripProvider = Provider<TripItineraryModel?>((ref) {
  final active = ref.watch(activeTripsProvider);
  return active.isEmpty ? null : active.first;
});

/// Upcoming trips scheduled for future dates
final upcomingTripsProvider = Provider<List<TripItineraryModel>>((ref) {
  final tripsAsync = ref.watch(userTripsStreamProvider);
  return tripsAsync.when(
    data: (trips) => trips.where((t) => t.isUpcoming).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Past completed journeys
final pastTripsProvider = Provider<List<TripItineraryModel>>((ref) {
  final tripsAsync = ref.watch(userTripsStreamProvider);
  return tripsAsync.when(
    data: (trips) => trips.where((t) => t.isPast).toList(),
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
  return repo.getTripById(user.uid, tripId);
});
