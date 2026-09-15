import 'package:flutter/foundation.dart';

enum AppEnvironment { development, staging, production }

class AppConfig {
  AppConfig._();

  static const String _defaultProdUrl = 'https://naviigo-website.onrender.com';
  static String get _defaultDevUrl => kIsWeb
      ? 'http://localhost:8000'
      : (defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:8000'
            : 'http://localhost:8000');

  /// Active Environment configured at build or runtime
  static AppEnvironment get environment {
    const envStr = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'production',
    );
    switch (envStr.toLowerCase()) {
      case 'development':
      case 'dev':
        return AppEnvironment.development;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'production':
      case 'prod':
      default:
        return AppEnvironment.production;
    }
  }

  /// Canonical Base URL for Render FastAPI Backend
  static String get apiBaseUrl {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredUrl.isNotEmpty) {
      return configuredUrl;
    }
    return environment == AppEnvironment.development
        ? _defaultDevUrl
        : _defaultProdUrl;
  }

  /// Canonical API Endpoints
  static String get placesApiBaseUrl => '$apiBaseUrl/api/places';
  static String get itineraryApiBaseUrl => '$apiBaseUrl/api/itinerary';

  /// Named Firestore Database ID matching the Naviigo Platform
  static const String firestoreDatabaseId = 'naviigo-db';

  /// Firebase Project ID
  static const String firebaseProjectId = 'naviigo-firebase';

  /// Network Timeouts
  static const Duration standardTimeout = Duration(seconds: 15);
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration aiGenerationTimeout = Duration(seconds: 60);

  /// Default currency for the platform
  static const String defaultCurrency = 'INR';
}
