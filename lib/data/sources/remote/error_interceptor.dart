import 'package:dio/dio.dart';
import '../../../core/errors/exceptions.dart';

class ErrorInterceptor extends QueuedInterceptor {
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    late AppException appException;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        appException = TimeoutException(
          message: 'Request timeout. Please try again.',
        );
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode ?? 0;
        if (statusCode == 401 || statusCode == 403) {
          appException = AuthException(
            message: statusCode == 401
                ? 'Unauthorized. Please login again.'
                : 'Access denied.',
          );
        } else if (statusCode == 429) {
          appException = ServerException(
            message:
                err.response?.data['message'] ?? 'Too many requests. Please retry in a moment.',
            statusCode: statusCode,
          );
        } else if (statusCode == 404) {
          appException = ValidationException(message: 'Resource not found.');
        } else if (statusCode >= 500) {
          appException = ServerException(
            message: err.response?.data['message'] ?? 'Server error',
            statusCode: statusCode,
          );
        } else {
          appException = ServerException(
            message: err.response?.data['message'] ?? 'Error occurred',
            statusCode: statusCode,
          );
        }
        break;
      case DioExceptionType.connectionError:
        final rawMessage = err.message?.toLowerCase() ?? '';
        final host = err.requestOptions.uri.host;
        final hostNotFound =
            rawMessage.contains('no such host') ||
            rawMessage.contains('failed host lookup') ||
            rawMessage.contains('name or service not known');
        final connectionRefused =
            rawMessage.contains('connection refused') ||
            rawMessage.contains('actively refused');
        final isLocalHost =
            host == 'localhost' || host == '127.0.0.1' || host == '::1';
        appException = NetworkException(
          message: hostNotFound
              ? 'Unable to resolve API host ($host). Check API base URL.'
              : (connectionRefused && isLocalHost)
              ? 'Backend server is not running on localhost:8000. Start your API service and try again.'
              : 'Network connection error. Please check internet and try again.',
        );
        break;
      case DioExceptionType.unknown:
      default:
        appException = CacheException(message: 'An unexpected error occurred.');
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: appException,
        type: err.type,
        response: err.response,
      ),
    );
  }
}
