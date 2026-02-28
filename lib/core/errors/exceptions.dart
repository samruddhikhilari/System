/// Base exception class for the app
sealed class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory NetworkException.noConnection() {
    return const NetworkException(
      message: 'No internet connection. Please check your network settings.',
      code: 'NO_CONNECTION',
    );
  }

  factory NetworkException.timeout() {
    return const NetworkException(
      message: 'Request timeout. Please try again.',
      code: 'TIMEOUT',
    );
  }
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory AuthException.invalidCredentials() {
    return const AuthException(
      message: 'Invalid email or password.',
      code: 'INVALID_CREDENTIALS',
    );
  }

  factory AuthException.accountLocked() {
    return const AuthException(
      message:
          'Account locked due to multiple failed attempts. Try again in 15 minutes.',
      code: 'ACCOUNT_LOCKED',
    );
  }

  factory AuthException.orgAccessDenied() {
    return const AuthException(
      message: 'You do not have access to this organization.',
      code: 'ORG_ACCESS_DENIED',
    );
  }

  factory AuthException.tokenExpired() {
    return const AuthException(
      message: 'Session expired. Please login again.',
      code: 'TOKEN_EXPIRED',
    );
  }

  factory AuthException.unauthorized() {
    return const AuthException(
      message: 'Unauthorized access. Please login again.',
      code: 'UNAUTHORIZED',
    );
  }
}

/// Server exceptions
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    required super.message,
    super.code,
    this.statusCode,
    super.originalException,
    super.stackTrace,
  });

  factory ServerException.internal() {
    return const ServerException(
      message: 'Internal server error. Please try again later.',
      code: 'INTERNAL_ERROR',
      statusCode: 500,
    );
  }

  factory ServerException.notFound() {
    return const ServerException(
      message: 'Resource not found.',
      code: 'NOT_FOUND',
      statusCode: 404,
    );
  }

  factory ServerException.badRequest(String message) {
    return ServerException(
      message: message,
      code: 'BAD_REQUEST',
      statusCode: 400,
    );
  }
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, List<String>>? fieldErrors;

  const ValidationException({
    required super.message,
    this.fieldErrors,
    super.code,
  });

  factory ValidationException.emailInvalid() {
    return const ValidationException(
      message: 'Please enter a valid work email address.',
      code: 'EMAIL_INVALID',
    );
  }

  factory ValidationException.passwordWeak() {
    return const ValidationException(
      message: 'Password must be at least 8 characters.',
      code: 'PASSWORD_WEAK',
    );
  }
}

/// Cache exceptions
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory CacheException.notFound() {
    return const CacheException(
      message: 'Data not found in cache.',
      code: 'CACHE_NOT_FOUND',
    );
  }
}

/// Parse exceptions
class ParseException extends AppException {
  const ParseException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Timeout exceptions
class TimeoutException extends AppException {
  const TimeoutException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory TimeoutException.connectionTimeout() {
    return const TimeoutException(
      message: 'Connection timeout. Please try again.',
      code: 'CONNECTION_TIMEOUT',
    );
  }

  factory TimeoutException.sendTimeout() {
    return const TimeoutException(
      message: 'Send timeout. Please try again.',
      code: 'SEND_TIMEOUT',
    );
  }

  factory TimeoutException.receiveTimeout() {
    return const TimeoutException(
      message: 'Receive timeout. Please try again.',
      code: 'RECEIVE_TIMEOUT',
    );
  }
}
