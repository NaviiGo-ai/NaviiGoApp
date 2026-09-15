import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/place_model.dart';

class PlacesRepository {
  final ApiClient _apiClient;

  PlacesRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Autocomplete place search across India using /api/places/autocomplete
  Future<List<Map<String, String>>> searchAutocomplete(String query) async {
    if (query.trim().length < 2) return [];
    try {
      final res = await _apiClient.get(
        '/api/places/autocomplete',
        queryParams: {'input': query.trim()},
        requiresAuth: false,
      );

      if (res is Map && res['predictions'] is List) {
        final list = res['predictions'] as List;
        return list.map((item) {
          final map = item as Map<String, dynamic>;
          return {
            'description': (map['description'] ?? '').toString(),
            'placeId': (map['place_id'] ?? '').toString(),
            'sub': (map['sub'] ?? '').toString(),
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[PlacesRepository] Autocomplete error: $e');
      return [];
    }
  }

  /// Get nearby places from backend (/api/places)
  Future<List<PlaceModel>> getNearbyPlaces({
    double lat = 20.5937,
    double lng = 78.9629,
    String type = 'tourist_attraction',
    int radius = 5000,
  }) async {
    try {
      final res = await _apiClient.get(
        '/api/places',
        queryParams: {
          'lat': lat.toString(),
          'lng': lng.toString(),
          'type': type,
          'radius': radius.toString(),
        },
        requiresAuth: false,
      );

      if (res is Map && res['places'] is List) {
        final list = res['places'] as List;
        return list
            .map(
              (e) => PlaceModel.fromBackendJson(
                e as Map<String, dynamic>,
                baseUrl: _apiClient.baseUrl,
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[PlacesRepository] getNearbyPlaces error: $e');
      return [];
    }
  }

  /// Get detailed place search / details (/api/places/details)
  Future<List<PlaceModel>> getPlaceDetails({
    double lat = 20.5937,
    double lng = 78.9629,
    String type = 'tourist_attraction',
    String query = '',
    int radius = 5000,
  }) async {
    try {
      final res = await _apiClient.get(
        '/api/places/details',
        queryParams: {
          'lat': lat.toString(),
          'lng': lng.toString(),
          'type': type,
          'query': query,
          'radius': radius.toString(),
        },
        requiresAuth: false,
      );

      if (res is Map && res['results'] is List) {
        final list = res['results'] as List;
        return list
            .map(
              (e) => PlaceModel.fromBackendJson(
                e as Map<String, dynamic>,
                baseUrl: _apiClient.baseUrl,
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[PlacesRepository] getPlaceDetails error: $e');
      return [];
    }
  }

  /// Get destination real weather (/api/weather)
  Future<Map<String, dynamic>?> getWeather({
    double lat = 20.5937,
    double lng = 78.9629,
  }) async {
    try {
      final res = await _apiClient.get(
        '/api/weather',
        queryParams: {'lat': lat.toString(), 'lng': lng.toString()},
        requiresAuth: false,
      );
      if (res is Map<String, dynamic>) {
        return res;
      }
      return null;
    } catch (e) {
      debugPrint('[PlacesRepository] getWeather error: $e');
      return null;
    }
  }

  /// Get live events for a destination (/api/explore/events)
  Future<List<dynamic>> getEvents(String destination) async {
    try {
      final res = await _apiClient.post(
        '/api/explore/events',
        body: {'destination': destination},
        requiresAuth: false,
      );
      if (res is Map && res['events'] is List) {
        return res['events'] as List;
      }
      return [];
    } catch (e) {
      debugPrint('[PlacesRepository] getEvents error: $e');
      return [];
    }
  }
}
