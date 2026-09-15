import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/core/network/api_exceptions.dart';
import 'package:naviigo_app/core/config/app_config.dart';

void main() {
  group('Network Layer & AppException Tests', () {
    test('AppConfig provides valid backend and fallback URLs', () {
      expect(AppConfig.apiBaseUrl, isNotEmpty);
      expect(AppConfig.apiBaseUrl, startsWith('http'));
      expect(AppConfig.placesApiBaseUrl, contains('/api/places'));
      expect(AppConfig.itineraryApiBaseUrl, contains('/api/itinerary'));
    });

    test('AuthRequiredException handles 401 Unauthorized properly', () {
      const exc = AuthRequiredException();
      expect(exc.statusCode, 401);
      expect(exc.message, contains('sign in'));
      expect(exc.toString(), contains('sign in'));
    });

    test('ForbiddenException handles 403 Forbidden properly', () {
      const exc = ForbiddenException();
      expect(exc.statusCode, 403);
      expect(exc.message, contains('permission'));
    });

    test('NotFoundException handles 404 Not Found properly', () {
      const exc = NotFoundException('Place not found');
      expect(exc.statusCode, 404);
      expect(exc.message, 'Place not found');
    });

    test('RateLimitException handles 429 Too Many Requests properly', () {
      const exc = RateLimitException();
      expect(exc.statusCode, 429);
      expect(exc.message, contains('Too many requests'));
    });

    test('ServerException handles 500 / 503 Server Errors properly', () {
      const exc = ServerException('Naviigo server waking up');
      expect(exc.statusCode, 500);
      expect(exc.message, contains('Naviigo server waking up'));
    });

    test('NetworkException handles network connection failure', () {
      const exc = NetworkException();
      expect(exc.message, contains('internet connection'));
    });

    test('ValidationException handles 400 Bad Request with details', () {
      const exc = ValidationException('Invalid coordinates', {'lat': 'Must be between -90 and 90'});
      expect(exc.statusCode, 400);
      expect(exc.message, 'Invalid coordinates');
      expect(exc.details?['lat'], contains('between -90 and 90'));
    });
  });
}
