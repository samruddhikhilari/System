import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/auth_model.dart';
import '../models/user_model.dart';
import '../sources/remote/dio_provider.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String email, String password, String orgId);
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String organizationId,
  });
  Future<void> logout();
  Future<AuthResponse> refreshToken();
  Future<List<OrganizationModel>> getOrganizations();
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<String?> getAccessToken();
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.dio, required this.storage});

  final Dio dio;
  final FlutterSecureStorage storage;

  @override
  Future<AuthResponse> login(String email, String password, String orgId) async {
    try {
      final response = await dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
          'org_id': orgId,
          'device_id': 'mobile-${DateTime.now().millisecondsSinceEpoch}',
          'fcm_token': 'pending-token',
        },
      );

      final payload = _normalizeAuthPayload(response.data as Map<String, dynamic>);
      final result = AuthResponse.fromJson(payload);

      await saveTokens(result.accessToken, result.refreshToken);
      await storage.write(key: AppConstants.keyOrgId, value: orgId);
      await storage.write(key: AppConstants.keyUserId, value: result.userProfile.id);
      await storage.write(key: AppConstants.keyUserRole, value: result.userProfile.role);

      return result;
    } on DioException catch (error) {
      final appException = error.error;
      if (appException is AppException) {
        throw appException;
      }

      if (error.response?.statusCode == 401) {
        throw AuthException.invalidCredentials();
      }
      if (error.response?.statusCode == 423) {
        throw AuthException.accountLocked();
      }
      if (error.response?.statusCode == 403) {
        throw AuthException.orgAccessDenied();
      }

      throw ServerException(
        message: 'Unable to login right now. Please try again.',
        statusCode: error.response?.statusCode,
      );
    }
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String organizationId,
  }) async {
    try {
      await dio.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'org_id': organizationId,
        },
      );
    } on DioException catch (error) {
      final appException = error.error;
      if (appException is AppException) {
        throw appException;
      }

      if (error.response?.statusCode == 409) {
        throw const ValidationException(
          message: 'An account with this email already exists.',
          code: 'EMAIL_EXISTS',
        );
      }

      throw ServerException(
        message: 'Unable to register right now. Please try again.',
        statusCode: error.response?.statusCode,
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post(ApiEndpoints.logout);
    } catch (_) {}

    await storage.delete(key: AppConstants.keyAccessToken);
    await storage.delete(key: AppConstants.keyRefreshToken);
    await storage.delete(key: AppConstants.keyUserId);
    await storage.delete(key: AppConstants.keyUserRole);
    await storage.delete(key: AppConstants.keyOrgId);
  }

  @override
  Future<AuthResponse> refreshToken() async {
    final refresh = await storage.read(key: AppConstants.keyRefreshToken);
    if (refresh == null || refresh.isEmpty) {
      throw AuthException.tokenExpired();
    }

    try {
      final response = await dio.post(
        ApiEndpoints.refresh,
        data: {'refresh_token': refresh},
      );

      final payload = _normalizeAuthPayload(response.data as Map<String, dynamic>);
      final result = AuthResponse.fromJson(payload);
      await saveTokens(result.accessToken, result.refreshToken);
      await storage.write(key: AppConstants.keyUserRole, value: result.userProfile.role);
      return result;
    } on DioException catch (error) {
      final appException = error.error;
      if (appException is AppException) {
        throw appException;
      }
      throw AuthException.tokenExpired();
    }
  }

  @override
  Future<List<OrganizationModel>> getOrganizations() async {
    try {
      final response = await dio.get(ApiEndpoints.organizations);
      final rawList = response.data is List
          ? response.data as List<dynamic>
          : (response.data['data'] as List<dynamic>? ?? <dynamic>[]);

      return rawList
          .whereType<Map<String, dynamic>>()
          .map(_normalizeOrganizationPayload)
          .map(OrganizationModel.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      final appException = error.error;
      if (appException is AppException) {
        throw appException;
      }
      throw ServerException(
        message: 'Unable to load organizations.',
        statusCode: error.response?.statusCode,
      );
    }
  }

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await storage.write(key: AppConstants.keyAccessToken, value: accessToken);
    await storage.write(key: AppConstants.keyRefreshToken, value: refreshToken);
  }

  @override
  Future<String?> getAccessToken() async {
    return storage.read(key: AppConstants.keyAccessToken);
  }

  Map<String, dynamic> _normalizeAuthPayload(Map<String, dynamic> json) {
    final user = json['user_profile'] as Map<String, dynamic>? ??
        json['userProfile'] as Map<String, dynamic>? ??
        <String, dynamic>{};

    return {
      'accessToken': json['access_token'] ?? json['accessToken'] ?? '',
      'refreshToken': json['refresh_token'] ?? json['refreshToken'] ?? '',
      'expiresIn': json['expires_in'] ?? json['expiresIn'] ?? 0,
      'permissions': (json['permissions'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      'userProfile': _normalizeUserPayload(user),
    };
  }

  Map<String, dynamic> _normalizeUserPayload(Map<String, dynamic> json) {
    return {
      'id': (json['id'] ?? '').toString(),
      'email': (json['email'] ?? '').toString(),
      'name': (json['name'] ?? '').toString(),
      'phone': json['phone']?.toString(),
      'avatarUrl': json['avatar_url'] ?? json['avatarUrl'],
      'role': (json['role'] ?? 'user').toString(),
      'permissions': (json['permissions'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      'selectedOrgId': json['selected_org_id'] ?? json['selectedOrgId'],
      'createdAt': (json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String())
          .toString(),
      'lastLoginAt': (json['last_login_at'] ?? json['lastLoginAt'])?.toString(),
    };
  }

  Map<String, dynamic> _normalizeOrganizationPayload(Map<String, dynamic> json) {
    return {
      'id': (json['id'] ?? '').toString(),
      'name': (json['name'] ?? '').toString(),
      'logoUrl': json['logo_url'] ?? json['logoUrl'],
      'sector': (json['sector'] ?? '').toString(),
      'roleInOrg': (json['role_in_org'] ?? json['roleInOrg'] ?? 'member').toString(),
    };
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(dio: dio, storage: storage);
});
