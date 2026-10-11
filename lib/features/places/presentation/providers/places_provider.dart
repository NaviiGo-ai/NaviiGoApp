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
final nearbyPlacesProvider = FutureProvider.autoDispose
    .family<List<PlaceModel>, ({double lat, double lng, String type})>((
      ref,
      arg,
    ) async {
      final repo = ref.watch(placesRepositoryProvider);
      return await repo.getNearbyPlaces(
        lat: arg.lat,
        lng: arg.lng,
        type: arg.type,
      );
    });

typedef PlaceSearch = ({
  String ownerUid,
  String query,
  String type,
  double? lat,
  double? lng,
});

/// Query and owner are part of the cache key; no retained response can cross
/// an account or query change. Defaults are API search bias, never user GPS.
final discoveryPlacesProvider = FutureProvider.autoDispose
    .family<List<PlaceModel>, PlaceSearch>((ref, request) {
      return ref
          .watch(placesRepositoryProvider)
          .getPlaceDetails(
            query: request.query,
            type: request.type,
            lat: request.lat ?? 20.5937,
            lng: request.lng ?? 78.9629,
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
