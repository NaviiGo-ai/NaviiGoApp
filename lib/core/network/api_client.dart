import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'api_exceptions.dart';

bool tokenBelongsToUid({
  required String? token,
  required Map<String, dynamic>? claims,
  required String expectedUid,
}) {
  if (token == null || token.isEmpty || claims == null) return false;

  final subject = claims['sub'];
  final firebaseUid = claims['user_id'];
  if (subject != null && subject != expectedUid) return false;
  if (firebaseUid != null && firebaseUid != expectedUid) return false;
  return subject == expectedUid || firebaseUid == expectedUid;
}

class ApiClient {
  final http.Client _httpClient;
  final String _baseUrl;
  final User? Function() _currentUser;

  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
    User? Function()? currentUser,
  }) : _httpClient = httpClient ?? http.Client(),
       _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
       _currentUser = currentUser ?? (() => FirebaseAuth.instance.currentUser);

  String get baseUrl => _baseUrl;

  /// Helper to get current Firebase ID token
  Future<String?> _getIdToken({
    bool forceRefresh = false,
    String? expectedAuthUid,
  }) async {
    try {
      final user = _currentUser();
      // Capture the matching Firebase User before asking for a token. If auth
      // changes after this point, this object can only produce the original
      // account's token.
      if (expectedAuthUid != null && user?.uid != expectedAuthUid) {
        return null;
      }
      if (user == null) return null;
      if (expectedAuthUid == null) {
        return await user.getIdToken(forceRefresh);
      }

      final result = await user.getIdTokenResult(forceRefresh);
      final token = result.token;
      if (!tokenBelongsToUid(
        token: token,
        claims: result.claims,
        expectedUid: expectedAuthUid,
      )) {
        return null;
      }
      // Native Firebase resolves the current native user when the method
      // channel call completes. Reject transitions during that await too.
      if (_currentUser()?.uid != expectedAuthUid) return null;
      return token;
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
      if (expectedAuthUid != null && _currentUser()?.uid != expectedAuthUid) {
        throw const AuthRequiredException();
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
    if (requiresAuth && kReleaseMode && uri.scheme != 'https') {
      throw const NetworkException(
        'Secure HTTPS is required for account requests.',
      );
    }
    final boundUid = requiresAuth
        ? expectedAuthUid ?? _currentUser()?.uid
        : null;
    if (requiresAuth && (boundUid == null || boundUid.isEmpty)) {
      throw const AuthRequiredException();
    }

    return _executeWithRetry(
      method: method,
      uri: uri,
      body: body,
      requiresAuth: requiresAuth,
      timeout: resolvedTimeout,
      extraHeaders: extraHeaders,
      expectedAuthUid: boundUid,
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
    int redirectsRemaining = 3,
  }) async {
    final headers = await _buildHeaders(
      requiresAuth: requiresAuth,
      extraHeaders: extraHeaders,
      forceTokenRefresh: isRetry,
      expectedAuthUid: expectedAuthUid,
    );

    if (requiresAuth && _currentUser()?.uid != expectedAuthUid) {
      throw const AuthRequiredException();
    }

    if (kDebugMode) {
      debugPrint(
        '[API] $method ${uri.path}${uri.query.isNotEmpty ? '?${uri.query}' : ''}',
      );
    }

    http.Response response;
    try {
      final encodedBody = body != null ? jsonEncode(body) : null;
      if (!const {
        'GET',
        'POST',
        'PATCH',
        'PUT',
        'DELETE',
      }.contains(method.toUpperCase())) {
        throw UnsupportedError('Unsupported HTTP method: $method');
      }
      final request = http.Request(method.toUpperCase(), uri)
        ..followRedirects = false
        ..headers.addAll(headers);
      if (encodedBody != null) request.body = encodedBody;
      // Never forward an account token through an unexpected redirect.
      response = await (() async => http.Response.fromStream(
        await _httpClient.send(request),
      ))().timeout(timeout);
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

    // Discard an old account's result before a provider or cache can consume it.
    if (requiresAuth && _currentUser()?.uid != expectedAuthUid) {
      throw const AuthRequiredException();
    }

    // FastAPI may canonicalize a missing trailing slash with 307/308. Follow
    // only method-preserving redirects to this exact origin, with a hard cap.
    if (response.statusCode == 307 || response.statusCode == 308) {
      final location = response.headers['location'];
      final target = location == null ? null : uri.resolve(location);
      if (redirectsRemaining == 0 ||
          target == null ||
          target.userInfo.isNotEmpty ||
          target.scheme != uri.scheme ||
          target.host != uri.host ||
          target.port != uri.port) {
        throw const ServerException('Unexpected API redirect.');
      }
      return _executeWithRetry(
        method: method,
        uri: target,
        body: body,
        requiresAuth: requiresAuth,
        timeout: timeout,
        extraHeaders: extraHeaders,
        expectedAuthUid: expectedAuthUid,
        isRetry: isRetry,
        redirectsRemaining: redirectsRemaining - 1,
      );
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
          redirectsRemaining: redirectsRemaining,
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

    final rawDetail = decoded is Map ? decoded['detail'] : null;
    final rawError = decoded is Map ? decoded['error'] : null;
    final detailMap = rawDetail is Map
        ? Map<String, dynamic>.from(rawDetail)
        : null;
    final errorMap = rawError is Map
        ? Map<String, dynamic>.from(rawError)
        : null;
    final errorEnvelope = detailMap ?? errorMap;
    final errorMessage =
        errorEnvelope?['message']?.toString() ??
        (rawDetail != null
            ? rawDetail.toString()
            : (decoded is Map && decoded['error'] != null)
            ? decoded['error'].toString()
            : 'Request failed with status $code');

    switch (code) {
      case 400:
        throw ValidationException(
          errorMessage,
          decoded is Map<String, dynamic> ? decoded : null,
        );
      case 409:
        final rawErrorCode =
            errorEnvelope?['code'] ??
            errorEnvelope?['errorCode'] ??
            errorEnvelope?['type'] ??
            (decoded is Map ? decoded['code'] : null) ??
            (decoded is Map ? decoded['errorCode'] : null) ??
            (rawDetail is String ? rawDetail : null);
        final details =
            errorEnvelope ??
            (decoded is Map<String, dynamic>
                ? Map<String, dynamic>.from(decoded)
                : null);
        throw ConflictException(
          errorMessage,
          conflictCode: rawErrorCode?.toString(),
          details: details,
        );
      case 401:
        throw AuthRequiredException(errorMessage);
      case 403:
        throw ForbiddenException(errorMessage);
      case 404:
        throw NotFoundException(errorMessage);
      case 422:
        throw UnprocessableEntityException(
          errorMessage,
          decoded is Map<String, dynamic> ? decoded : detailMap,
        );
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
