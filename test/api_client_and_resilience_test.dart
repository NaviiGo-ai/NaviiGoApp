import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:naviigo_app/core/network/api_client.dart';
import 'package:naviigo_app/core/network/api_exceptions.dart';
import 'package:naviigo_app/core/config/app_config.dart';

void main() {
  group('ApiClient & Network Resilience Unit Tests', () {
    test('AppConfig constants are defined for production and local environments', () {
      expect(AppConfig.apiBaseUrl, isNotEmpty);
      expect(AppConfig.apiBaseUrl, startsWith('http'));
      expect(AppConfig.placesApiBaseUrl, isNotEmpty);
      expect(AppConfig.placesApiBaseUrl, contains('/api/places'));
      expect(AppConfig.itineraryApiBaseUrl, contains('/api/itinerary'));
      expect(AppConfig.connectTimeout, equals(const Duration(seconds: 15)));
      expect(AppConfig.receiveTimeout, equals(const Duration(seconds: 30)));
    });

    test('ApiClient successfully returns decoded JSON on 200 OK', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"status": "ok", "data": [1, 2, 3]}', 200, headers: {
          'content-type': 'application/json',
        });
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'https://test.naviigo.com',
      );

      final result = await apiClient.get('/test', requiresAuth: false);
      expect(result, isA<Map<String, dynamic>>());
      expect(result['status'], 'ok');
      expect(result['data'], [1, 2, 3]);
    });

    test('ApiClient successfully sends PUT request and receives response', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        return http.Response('{"status": "updated", "id": "item_123"}', 200, headers: {
          'content-type': 'application/json',
        });
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'https://test.naviigo.com',
      );

      final result = await apiClient.put('/items/item_123', body: {'name': 'New Item'}, requiresAuth: false);
      expect(result['status'], 'updated');
      expect(result['id'], 'item_123');
    });

    test('ApiClient throws ValidationException on 400 Bad Request', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"detail": "Invalid coordinates", "field": "lat"}',
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'https://test.naviigo.com',
      );

      expect(
        () => apiClient.get('/invalid', requiresAuth: false),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', contains('Invalid coordinates')),
        ),
      );
    });

    test('ApiClient throws NotFoundException on 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"detail": "Place not found"}',
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'https://test.naviigo.com',
      );

      expect(
        () => apiClient.get('/places/unknown', requiresAuth: false),
        throwsA(
          isA<NotFoundException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', contains('Place not found')),
        ),
      );
    });

    test('ApiClient throws RateLimitException on 429', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"detail": "Rate limit exceeded. Slow down."}',
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'https://test.naviigo.com',
      );

      expect(
        () => apiClient.get('/heavy-endpoint', requiresAuth: false),
        throwsA(
          isA<RateLimitException>()
              .having((e) => e.statusCode, 'statusCode', 429)
              .having((e) => e.message, 'message', contains('Rate limit exceeded')),
        ),
      );
    });

    test('ApiClient throws ServerException on 500/503 (Render cold-start / server error)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"detail": "Server waking up from cold start"}',
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'https://test.naviigo.com',
      );

      expect(
        () => apiClient.get('/status', requiresAuth: false),
        throwsA(
          isA<ServerException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', contains('Server waking up')),
        ),
      );
    });
  });
}
