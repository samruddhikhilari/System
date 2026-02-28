import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_constants.dart';

class AuthInterceptor extends QueuedInterceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: AppConstants.keyAccessToken);

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      final orgId = await storage.read(key: AppConstants.keyOrgId);
      if (orgId != null) {
        options.headers[AppConstants.headerOrgId] = orgId;
      }
    } catch (e) {
      print('AuthInterceptor Error: $e');
    }

    handler.next(options);
  }
}
