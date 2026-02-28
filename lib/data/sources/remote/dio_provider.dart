import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_config.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';
import 'logging_interceptor.dart';

final dioProvider = Provider((ref) {
  final dio = Dio();

  // Set base URL
  dio.options.baseUrl = AppConfig.current.fullBaseUrl;

  // Set timeouts
  dio.options.connectTimeout = AppConfig.current.connectTimeout;
  dio.options.receiveTimeout = AppConfig.current.receiveTimeout;

  // Set headers
  dio.options.headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Add interceptors
  dio.interceptors.add(AuthInterceptor());
  dio.interceptors.add(ErrorInterceptor());

  if (AppConfig.current.enableLogging) {
    dio.interceptors.add(LoggingInterceptor());
  }

  return dio;
});
