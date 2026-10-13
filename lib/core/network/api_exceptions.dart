/// Domain-specific network and API exceptions for Naviigo
sealed class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([
    super.message =
        'Unable to connect to Naviigo servers. Please check your internet connection.',
  ]);
}

class AuthRequiredException extends AppException {
  const AuthRequiredException([String message = 'Please sign in to continue.'])
    : super(message, 401);
}

class ForbiddenException extends AppException {
  const ForbiddenException([
    String message = 'You do not have permission to access this resource.',
  ]) : super(message, 403);
}

class NotFoundException extends AppException {
  const NotFoundException([
    String message = 'Requested resource was not found.',
  ]) : super(message, 404);
}

class RateLimitException extends AppException {
  const RateLimitException([
    String message =
        'Too many requests. Please slow down and try again in a moment.',
  ]) : super(message, 429);
}

class ServerException extends AppException {
  const ServerException([
    String message =
        'Naviigo server encountered an issue. Please try again later.',
  ]) : super(message, 500);
}

class ValidationException extends AppException {
  final Map<String, dynamic>? details;
  const ValidationException(String message, [this.details])
    : super(message, 400);
}

/// A request could not be applied because the server's current state differs
/// from the state the client submitted.  Conflict responses are deliberately
/// kept distinct from validation and transport failures: callers can safely
/// refresh the owner document and ask the traveller to retry without treating
/// the operation as a generic server outage.
class ConflictException extends AppException {
  /// Stable server conflict code, for example `STALE_PROPOSAL` or
  /// `IDEMPOTENCY_CONFLICT`.
  final String? conflictCode;

  /// Structured details returned by the server.  This can include the current
  /// revision, the submitted revision, or the operation that conflicted.
  final Map<String, dynamic>? details;

  const ConflictException(String message, {this.conflictCode, this.details})
    : super(message, 409);

  /// Short alias useful to code which treats API error codes uniformly.
  String? get code => conflictCode;
}

/// A well-formed request failed the Phase 6 replan validation contract.
class UnprocessableEntityException extends AppException {
  final Map<String, dynamic>? details;

  const UnprocessableEntityException(String message, [this.details])
    : super(message, 422);
}
