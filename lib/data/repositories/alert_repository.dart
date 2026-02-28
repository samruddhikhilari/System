import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/errors/exceptions.dart';
import '../models/dashboard_model.dart';
import '../sources/local/cache_store.dart';
import '../sources/remote/dio_provider.dart';
import 'auth_repository.dart';
import '../../services/websocket_service.dart';

abstract class AlertRepository {
  Future<List<AlertSummary>> getAlerts();
  Future<void> acknowledgeAlert(String alertId);
  Future<void> snoozeAlert(String alertId, Duration duration);
  Future<void> updatePreferences(Map<String, dynamic> preferences);
  Stream<AlertSummary> watchLiveAlerts();
  Future<void> initializeRealtime();
}

class AlertRepositoryImpl implements AlertRepository {
  AlertRepositoryImpl({
    required this.dio,
    required this.authRepository,
    required this.webSocketService,
    required this.cacheStore,
  });

  final Dio dio;
  final AuthRepository authRepository;
  final WebSocketService webSocketService;
  final CacheStore cacheStore;

  static const _alertsCacheKey = 'alerts_live_cache';

  @override
  Future<List<AlertSummary>> getAlerts() async {
    try {
      final response = await dio.get(ApiEndpoints.alerts);
      final list = response.data is List
          ? response.data as List<dynamic>
          : (response.data['alerts'] as List<dynamic>? ?? <dynamic>[]);

      final alerts = list
          .whereType<Map<String, dynamic>>()
          .map(_normalizeAlert)
          .map(AlertSummary.fromJson)
          .toList(growable: false);
      await cacheStore.write(
        _alertsCacheKey,
        jsonEncode(alerts.map((alert) => alert.toJson()).toList(growable: false)),
      );
      return alerts;
    } on DioException catch (error) {
      final appException = error.error;
      if (appException is AppException) {
        throw appException;
      }
      final cached = await cacheStore.read(_alertsCacheKey);
      if (cached != null) {
        return (jsonDecode(cached) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(AlertSummary.fromJson)
            .toList(growable: false);
      }
      throw ServerException(
        message: 'Unable to fetch alerts.',
        statusCode: error.response?.statusCode,
      );
    }
  }

  @override
  Future<void> acknowledgeAlert(String alertId) async {
    await dio.post(ApiEndpoints.alertAcknowledge(alertId));
  }

  @override
  Future<void> snoozeAlert(String alertId, Duration duration) async {
    await dio.post(
      ApiEndpoints.alertSnooze(alertId),
      data: {'duration_minutes': duration.inMinutes},
    );
  }

  @override
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    await dio.put(ApiEndpoints.alertPreferences, data: preferences);
  }

  @override
  Stream<AlertSummary> watchLiveAlerts() {
    return webSocketService.alertsStream
        .map(_normalizeAlert)
        .map(AlertSummary.fromJson);
  }

  @override
  Future<void> initializeRealtime() async {
    final token = await authRepository.getAccessToken();
    if (token == null || token.isEmpty) {
      return;
    }
    await webSocketService.connect(token);
  }

  Map<String, dynamic> _normalizeAlert(Map<String, dynamic> json) {
    return {
      'id': (json['id'] ?? '').toString(),
      'severity': (json['severity'] ?? 'medium').toString(),
      'title': (json['title'] ?? '').toString(),
      'body': (json['body'] ?? '').toString(),
      'supplierId': json['supplier_id']?.toString() ?? json['supplierId']?.toString(),
      'timestamp': (json['timestamp'] ?? DateTime.now().toIso8601String()).toString(),
      'status': (json['status'] ?? 'active').toString(),
    };
  }
}

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  final webSocketService = ref.watch(webSocketServiceProvider);
  final cacheStore = ref.watch(cacheStoreProvider);
  return AlertRepositoryImpl(
    dio: dio,
    authRepository: authRepository,
    webSocketService: webSocketService,
    cacheStore: cacheStore,
  );
});
