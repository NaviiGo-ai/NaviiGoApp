import '../../../core/network/api_client.dart';
import '../domain/models/place_model.dart';

class AutocompleteSearchResult {
  final List<Map<String, String>> predictions;
  final bool unavailable;
  const AutocompleteSearchResult({
    required this.predictions,
    this.unavailable = false,
  });
}

class PlacesUnavailableException implements Exception {
  const PlacesUnavailableException();
}

class PlacesRepository {
  final ApiClient _apiClient;
  PlacesRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // Preserve the existing onboarding contract while discovery surfaces errors.
  Future<List<Map<String, String>>> searchAutocomplete(String query) async {
    try {
      return (await searchAutocompleteResult(query)).predictions;
    } catch (_) {
      return [];
    }
  }

  Future<AutocompleteSearchResult> searchAutocompleteResult(
    String query,
  ) async {
    if (query.trim().length < 2) {
      return const AutocompleteSearchResult(predictions: []);
    }
    final res = await _apiClient.get(
      '/api/places/autocomplete',
      queryParams: {'input': query.trim()},
      requiresAuth: false,
    );
    if (res is! Map || res['predictions'] is! List) {
      throw const FormatException('Invalid autocomplete response');
    }
    return AutocompleteSearchResult(
      predictions: (res['predictions'] as List)
          .whereType<Map>()
          .map(
            (item) => {
              'description': (item['description'] ?? '').toString(),
              'placeId': (item['place_id'] ?? '').toString(),
              'sub': (item['sub'] ?? '').toString(),
            },
          )
          .toList(),
    );
  }

  Future<List<PlaceModel>> getNearbyPlaces({
    double lat = 20.5937,
    double lng = 78.9629,
    String type = 'tourist_attraction',
    int radius = 5000,
  }) async {
    final res = await _apiClient.get(
      '/api/places/',
      queryParams: {
        'lat': '$lat',
        'lng': '$lng',
        'type': type,
        'radius': '$radius',
      },
      requiresAuth: false,
    );
    return _places(res, 'places', nearby: true);
  }

  Future<List<PlaceModel>> getPlaceDetails({
    double lat = 20.5937,
    double lng = 78.9629,
    String type = 'tourist_attraction',
    String query = '',
    int radius = 5000,
  }) async {
    final res = await _apiClient.get(
      '/api/places/details',
      queryParams: {
        'lat': '$lat',
        'lng': '$lng',
        'type': type,
        'query': query,
        'radius': '$radius',
      },
      requiresAuth: false,
    );
    if (res is Map && (res['_note'] != null || res['_status'] != null)) {
      throw const PlacesUnavailableException();
    }
    return _places(res, 'results');
  }

  List<PlaceModel> _places(
    dynamic response,
    String field, {
    bool nearby = false,
  }) {
    if (response is! Map ||
        response['success'] == false ||
        response[field] is! List) {
      throw const FormatException('Place results unavailable');
    }
    return (response[field] as List)
        .whereType<Map>()
        .map((raw) {
          final map = Map<String, dynamic>.from(raw);
          // Nominatim wrapper assigns priceLevel=1 unconditionally. It is not a
          // provider price and must not be surfaced as a travel fact.
          if (nearby) map.remove('priceLevel');
          return PlaceModel.fromBackendJson(map, baseUrl: _apiClient.baseUrl);
        })
        .where((place) => place.id.isNotEmpty && place.name.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>?> getWeather({
    double lat = 20.5937,
    double lng = 78.9629,
  }) async {
    try {
      final res = await _apiClient.get(
        '/api/weather',
        queryParams: {'lat': '$lat', 'lng': '$lng'},
        requiresAuth: false,
      );
      return res is Map<String, dynamic> ? res : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> getEvents(String destination) async {
    try {
      final res = await _apiClient.post(
        '/api/explore/events',
        body: {'destination': destination},
        requiresAuth: false,
      );
      return res is Map && res['events'] is List ? res['events'] as List : [];
    } catch (_) {
      return [];
    }
  }
}
