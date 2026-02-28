import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_config.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/errors/exceptions.dart';
import '../models/dashboard_model.dart';
import '../sources/local/cache_store.dart';
import '../sources/remote/dio_provider.dart';

abstract class DashboardRepository {
  Future<DashboardSummary> getDashboardSummary({bool forceRefresh = false});
  Future<List<SectorRisk>> getSectorRisks({bool forceRefresh = false});
  Future<List<AlertSummary>> getAlerts({bool forceRefresh = false});
  Future<TrendMetrics> getTrendMetrics({bool forceRefresh = false});
  Stream<DashboardSummary> autoRefreshSummary();
}

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({required this.dio, required this.cacheStore});

  final Dio dio;
  final CacheStore cacheStore;

  static const _summaryCacheKey = 'dashboard_summary_cache';
  static const _alertsCacheKey = 'dashboard_alerts_cache';

  DashboardSummary? _summaryCache;
  DateTime? _summaryCachedAt;

  List<AlertSummary>? _alertsCache;
  DateTime? _alertsCachedAt;

  @override
  Future<DashboardSummary> getDashboardSummary({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final isSummaryFresh =
        _summaryCache != null &&
        _summaryCachedAt != null &&
        now.difference(_summaryCachedAt!) < AppConfig.current.dashboardCacheDuration;

    if (!forceRefresh && isSummaryFresh) {
      return _summaryCache!;
    }

    try {
      final response = await dio.get(ApiEndpoints.dashboardSummary);
      final data = response.data as Map<String, dynamic>;
      final normalized = _normalizeSummary(data);
      final summary = DashboardSummary.fromJson(normalized);
      _summaryCache = summary;
      _summaryCachedAt = now;
      await cacheStore.write(_summaryCacheKey, jsonEncode(summary.toJson()));
      return summary;
    } on DioException catch (error) {
      final appException = error.error;
      if (appException is AppException) {
        throw appException;
      }

      if (_summaryCache != null) {
        return _summaryCache!;
      }

      final cachedRaw = await cacheStore.read(_summaryCacheKey);
      if (cachedRaw != null) {
        final cachedJson = jsonDecode(cachedRaw) as Map<String, dynamic>;
        return DashboardSummary.fromJson(cachedJson);
      }

      throw ServerException(
        message: 'Unable to load dashboard summary.',
        statusCode: error.response?.statusCode,
      );
    }
  }

  @override
  Future<List<SectorRisk>> getSectorRisks({bool forceRefresh = false}) async {
    final summary = await getDashboardSummary(forceRefresh: forceRefresh);
    return summary.sectors;
  }

  @override
  Future<List<AlertSummary>> getAlerts({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final isAlertFresh =
        _alertsCache != null &&
        _alertsCachedAt != null &&
        now.difference(_alertsCachedAt!) < AppConfig.current.alertsCacheDuration;

    if (!forceRefresh && isAlertFresh) {
      return _alertsCache!;
    }

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

      _alertsCache = alerts;
      _alertsCachedAt = now;
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
      if (_alertsCache != null) {
        return _alertsCache!;
      }
      final cachedRaw = await cacheStore.read(_alertsCacheKey);
      if (cachedRaw != null) {
        final cachedJson = (jsonDecode(cachedRaw) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(AlertSummary.fromJson)
            .toList(growable: false);
        return cachedJson;
      }
      throw ServerException(
        message: 'Unable to load alerts.',
        statusCode: error.response?.statusCode,
      );
    }
  }

  @override
  Future<TrendMetrics> getTrendMetrics({bool forceRefresh = false}) async {
    final summary = await getDashboardSummary(forceRefresh: forceRefresh);
    return summary.trendMetrics;
  }

  @override
  Stream<DashboardSummary> autoRefreshSummary() async* {
    while (true) {
      yield await getDashboardSummary(forceRefresh: true);
      await Future<void>.delayed(const Duration(seconds: 30));
    }
  }

  Map<String, dynamic> _normalizeSummary(Map<String, dynamic> json) {
    final sectorsRaw = (json['sectors'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_normalizeSector)
        .toList(growable: false);
    final alertsRaw = (json['active_alerts'] as List<dynamic>? ??
            json['activeAlerts'] as List<dynamic>? ??
            <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_normalizeAlert)
        .toList(growable: false);

    final trend = (json['trend_metrics'] ?? json['trendMetrics'] ??
        <String, dynamic>{}) as Map<String, dynamic>;

    return {
      'nriScore': (json['nri_score'] ?? json['nriScore'] ?? 0).toDouble(),
      'nriDelta': (json['nri_delta'] ?? json['nriDelta'] ?? 0).toDouble(),
      'sectors': sectorsRaw,
      'activeAlerts': alertsRaw,
      'trendMetrics': {
        'avgSupplierRiskScore':
            (trend['avg_supplier_risk_score'] ?? trend['avgSupplierRiskScore'] ?? 0)
                .toDouble(),
        'activeDisruptionsCount':
            (trend['active_disruptions_count'] ?? trend['activeDisruptionsCount'] ?? 0)
                .toInt(),
        'predictionConfidence':
            (trend['prediction_confidence'] ?? trend['predictionConfidence'] ?? 0)
                .toDouble(),
        'riskScoreBars': (trend['risk_score_bars'] ?? trend['riskScoreBars'] ?? <dynamic>[])
            .map((e) => (e as num).toDouble())
            .toList(),
      },
      'lastUpdated': (json['last_updated'] ?? json['lastUpdated'] ?? DateTime.now().toIso8601String())
          .toString(),
    };
  }

  Map<String, dynamic> _normalizeSector(Map<String, dynamic> json) {
    return {
      'sector': (json['sector'] ?? '').toString(),
      'icon': (json['icon'] ?? '').toString(),
      'riskScore': (json['risk_score'] ?? json['riskScore'] ?? 0).toDouble(),
      'delta7d': (json['delta_7d'] ?? json['delta7d'] ?? 0).toDouble(),
      'sparklineData': (json['sparkline_data'] ?? json['sparklineData'] ?? <dynamic>[])
          .map((e) => (e as num).toDouble())
          .toList(),
    };
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

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final cacheStore = ref.watch(cacheStoreProvider);
  return DashboardRepositoryImpl(dio: dio, cacheStore: cacheStore);
});
