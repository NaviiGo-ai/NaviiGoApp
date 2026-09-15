import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_provider.dart';
import '../../data/places_repository.dart';
import '../../domain/models/place_model.dart';

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PlacesRepository(apiClient: apiClient);
});

/// Autocomplete provider based on search query
final placeAutocompleteProvider =
    FutureProvider.family<List<Map<String, String>>, String>((
      ref,
      query,
    ) async {
      if (query.trim().length < 2) return [];
      final repo = ref.watch(placesRepositoryProvider);
      return await repo.searchAutocomplete(query);
    });

/// Nearby places provider
final nearbyPlacesProvider =
    FutureProvider.family<
      List<PlaceModel>,
      ({double lat, double lng, String type})
    >((ref, arg) async {
      final repo = ref.watch(placesRepositoryProvider);
      return await repo.getNearbyPlaces(
        lat: arg.lat,
        lng: arg.lng,
        type: arg.type,
      );
    });

/// Destination weather provider
final destinationWeatherProvider =
    FutureProvider.family<Map<String, dynamic>?, ({double lat, double lng})>((
      ref,
      arg,
    ) async {
      final repo = ref.watch(placesRepositoryProvider);
      return await repo.getWeather(lat: arg.lat, lng: arg.lng);
    });
