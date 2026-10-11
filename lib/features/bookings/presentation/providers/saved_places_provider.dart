import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../data/saved_places_repository.dart';
import '../../domain/models/saved_place_model.dart';
import '../../../analytics/data/analytics_repository.dart';

final savedPlacesRepositoryProvider = Provider<SavedPlacesRepository>((ref) {
  return SavedPlacesRepository();
});

final savedPlacesStreamProvider = StreamProvider<List<SavedPlaceModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final repo = ref.watch(savedPlacesRepositoryProvider);
  final uid = user.uid;
  return repo
      .getSavedPlacesStream(uid)
      .map(
        (places) =>
            places.map((place) => place.copyWith(sourceUserId: uid)).toList(),
      );
});

final safeSavedPlacesProvider = Provider<List<SavedPlaceModel>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const [];
  final places = ref.watch(savedPlacesStreamProvider).valueOrNull ?? const [];
  if (places.any((place) => place.sourceUserId != uid)) return const [];
  return places;
});

final savedPlaceActionProvider = StateNotifierProvider.autoDispose
    .family<SavedPlaceAction, AsyncValue<void>, ({String uid, String id})>((
      ref,
      key,
    ) {
      return SavedPlaceAction(ref, key.uid);
    });

class SavedPlaceAction extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  final String uid;
  SavedPlaceAction(this.ref, this.uid) : super(const AsyncData(null));

  Future<void> setSaved(
    SavedPlaceModel place,
    bool saved, {
    String? destinationId,
  }) async {
    if (state.isLoading || ref.read(currentUserProvider)?.uid != uid) return;
    final repository = ref.read(savedPlacesRepositoryProvider);
    state = const AsyncLoading();
    try {
      await repository.setSavedPlace(uid, place, saved);
      if (!mounted || ref.read(currentUserProvider)?.uid != uid) return;
      ref.invalidate(savedPlacesStreamProvider);
      ref
          .read(analyticsRepositoryProvider)
          .logEvent(
            eventType: saved ? 'PLACE_SAVED' : 'PLACE_UNSAVED',
            placeId: place.id,
            destinationId: destinationId,
          )
          .catchError((Object _) {});
      state = const AsyncData(null);
    } catch (error, stack) {
      if (mounted && ref.read(currentUserProvider)?.uid == uid) {
        state = AsyncError(error, stack);
      }
    }
  }
}
