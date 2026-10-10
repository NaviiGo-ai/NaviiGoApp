import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'api_exceptions.dart';

class ApiClient {
  final http.Client _httpClient;
  final String _baseUrl;

  ApiClient({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  String get baseUrl => _baseUrl;

  /// Helper to get current Firebase ID token
  Future<String?> _getIdToken({
    bool forceRefresh = false,
    String? expectedAuthUid,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      // Capture the matching Firebase User before asking for a token. If auth
      // changes after this point, this object can only produce the original
      // account's token.
      if (expectedAuthUid != null && user?.uid != expectedAuthUid) {
        return null;
      }
      if (user == null) return null;
      return await user.getIdToken(forceRefresh);
    } catch (e) {
      debugPrint('[ApiClient] Error acquiring Firebase ID token: $e');
      return null;
    }
  }

  /// Construct headers with optional authentication
  Future<Map<String, String>> _buildHeaders({
    bool requiresAuth = true,
    Map<String, String>? extraHeaders,
    bool forceTokenRefresh = false,
    String? expectedAuthUid,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _getIdToken(
        forceRefresh: forceTokenRefresh,
        expectedAuthUid: expectedAuthUid,
      );
      if (expectedAuthUid != null && (token == null || token.isEmpty)) {
        throw const AuthRequiredException();
      }
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  /// Execute HTTP request with token refresh & retry logic
  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? queryParams,
    dynamic body,
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? extraHeaders,
    String? expectedAuthUid,
  }) async {
    final resolvedTimeout = timeout ?? AppConfig.standardTimeout;
    final uri = _buildUri(path, queryParams);

    return _executeWithRetry(
      method: method,
      uri: uri,
      body: body,
      requiresAuth: requiresAuth,
      timeout: resolvedTimeout,
      extraHeaders: extraHeaders,
      expectedAuthUid: expectedAuthUid,
      isRetry: false,
    );
  }

  Future<dynamic> _executeWithRetry({
    required String method,
    required Uri uri,
    required dynamic body,
    required bool requiresAuth,
    required Duration timeout,
    required Map<String, String>? extraHeaders,
    String? expectedAuthUid,
    required bool isRetry,
  }) async {
    final headers = await _buildHeaders(
      requiresAuth: requiresAuth,
      extraHeaders: extraHeaders,
      forceTokenRefresh: isRetry,
      expectedAuthUid: expectedAuthUid,
    );

    if (kDebugMode) {
      debugPrint(
        '[API] $method ${uri.path}${uri.query.isNotEmpty ? '?${uri.query}' : ''}',
      );
    }

    http.Response response;
    try {
      final encodedBody = body != null ? jsonEncode(body) : null;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _httpClient
              .get(uri, headers: headers)
              .timeout(timeout);
          break;
        case 'POST':
          response = await _httpClient
              .post(uri, headers: headers, body: encodedBody)
              .timeout(timeout);
          break;
        case 'PATCH':
          response = await _httpClient
              .patch(uri, headers: headers, body: encodedBody)
              .timeout(timeout);
          break;
        case 'PUT':
          response = await _httpClient
              .put(uri, headers: headers, body: encodedBody)
              .timeout(timeout);
          break;
        case 'DELETE':
          response = await _httpClient
              .delete(uri, headers: headers, body: encodedBody)
              .timeout(timeout);
          break;
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }
    } on TimeoutException {
      debugPrint('[API] Timeout calling ${uri.path}');
      throw const NetworkException(
        'Request timed out. The server may be waking up, please try again.',
      );
    } on SocketException catch (e) {
      debugPrint('[API] Network connection failure: $e');
      throw const NetworkException();
    } catch (e) {
      if (e is AppException) rethrow;
      debugPrint('[API] Network error: $e');
      throw NetworkException(e.toString());
    }

    if (kDebugMode) {
      debugPrint('[API] Response [${response.statusCode}] from ${uri.path}');
    }

    // Handle token expiration & retry once
    if (response.statusCode == 401 && requiresAuth && !isRetry) {
      debugPrint(
        '[API] 401 received. Attempting Firebase token force refresh and single retry...',
      );
      final refreshed = await _getIdToken(
        forceRefresh: true,
        expectedAuthUid: expectedAuthUid,
      );
      if (refreshed != null) {
        return _executeWithRetry(
          method: method,
          uri: uri,
          body: body,
          requiresAuth: requiresAuth,
          timeout: timeout,
          extraHeaders: extraHeaders,
          expectedAuthUid: expectedAuthUid,
          isRetry: true,
        );
      }
      throw const AuthRequiredException();
    }

    return _parseResponse(response);
  }

  Uri _buildUri(String path, Map<String, String>? queryParams) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$_baseUrl$cleanPath';
    final uri = Uri.parse(fullUrl);
    if (queryParams == null || queryParams.isEmpty) {
      return uri;
    }
    return uri.replace(
      queryParameters: {...uri.queryParameters, ...queryParams},
    );
  }

  dynamic _parseResponse(http.Response response) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (e) {
        decoded = response.body;
      }
    }

    final code = response.statusCode;
    if (code >= 200 && code < 300) {
      return decoded;
    }

    final errorMessage = (decoded is Map && decoded['detail'] != null)
        ? decoded['detail'].toString()
        : (decoded is Map && decoded['error'] != null)
        ? decoded['error'].toString()
        : 'Request failed with status $code';

    switch (code) {
      case 400:
        throw ValidationException(
          errorMessage,
          decoded is Map<String, dynamic> ? decoded : null,
        );
      case 401:
        throw AuthRequiredException(errorMessage);
      case 403:
        throw ForbiddenException(errorMessage);
      case 404:
        throw NotFoundException(errorMessage);
      case 429:
        throw RateLimitException(errorMessage);
      case 500:
      case 502:
      case 503:
      case 504:
      default:
        throw ServerException(errorMessage);
    }
  }

  // HTTP convenience methods
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    Duration? timeout,
  }) => _send(
    'GET',
    path,
    queryParams: queryParams,
    requiresAuth: requiresAuth,
    timeout: timeout,
  );

  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    Duration? timeout,
    String? expectedAuthUid,
  }) => _send(
    'POST',
    path,
    queryParams: queryParams,
    body: body,
    requiresAuth: requiresAuth,
    timeout: timeout,
    expectedAuthUid: expectedAuthUid,
  );

  Future<dynamic> put(
    String path, {
    dynamic body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    Duration? timeout,
  }) => _send(
    'PUT',
    path,
    queryParams: queryParams,
    body: body,
    requiresAuth: requiresAuth,
    timeout: timeout,
  );

  Future<dynamic> patch(
    String path, {
    dynamic body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    Duration? timeout,
  }) => _send(
    'PATCH',
    path,
    queryParams: queryParams,
    body: body,
    requiresAuth: requiresAuth,
    timeout: timeout,
  );

  Future<dynamic> delete(
    String path, {
    dynamic body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    Duration? timeout,
  }) => _send(
    'DELETE',
    path,
    queryParams: queryParams,
    body: body,
    requiresAuth: requiresAuth,
    timeout: timeout,
  );
}
