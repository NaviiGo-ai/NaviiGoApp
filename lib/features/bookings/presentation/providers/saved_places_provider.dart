import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../data/saved_places_repository.dart';
import '../../domain/models/saved_place_model.dart';

final savedPlacesRepositoryProvider = Provider<SavedPlacesRepository>((ref) {
  return SavedPlacesRepository();
});

final savedPlacesStreamProvider = StreamProvider<List<SavedPlaceModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final repo = ref.watch(savedPlacesRepositoryProvider);
  return repo.getSavedPlacesStream(user.uid);
});
