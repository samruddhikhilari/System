import 'package:dio/dio.dart';

class LoggingInterceptor extends QueuedInterceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    print('--- Request ---');
    print('URL: ${options.baseUrl}${options.path}');
    print('Method: ${options.method}');
    print('Headers: ${options.headers}');
    if (options.data != null) {
      print('Body: ${options.data}');
    }
    return handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    print('--- Response ---');
    print('Status: ${response.statusCode}');
    print('URL: ${response.requestOptions.path}');
    print('Data: ${response.data}');
    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    print('--- Error ---');
    print('Type: ${err.type}');
    print('Message: ${err.message}');
    print('URL: ${err.requestOptions.path}');
    if (err.response != null) {
      print('Status: ${err.response?.statusCode}');
      print('Data: ${err.response?.data}');
    }
    return handler.next(err);
  }
}
