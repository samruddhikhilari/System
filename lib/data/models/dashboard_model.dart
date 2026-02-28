import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_model.freezed.dart';
part 'dashboard_model.g.dart';

@freezed
class DashboardSummary with _$DashboardSummary {
  const factory DashboardSummary({
    required double nriScore,
    required double nriDelta,
    required List<SectorRisk> sectors,
    required List<AlertSummary> activeAlerts,
    required TrendMetrics trendMetrics,
    required DateTime lastUpdated,
  }) = _DashboardSummary;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryFromJson(json);
}

@freezed
class SectorRisk with _$SectorRisk {
  const factory SectorRisk({
    required String sector,
    required String icon,
    required double riskScore,
    required double delta7d,
    required List<double> sparklineData,
  }) = _SectorRisk;

  factory SectorRisk.fromJson(Map<String, dynamic> json) =>
      _$SectorRiskFromJson(json);
}

@freezed
class AlertSummary with _$AlertSummary {
  const factory AlertSummary({
    required String id,
    required String severity,
    required String title,
    required String body,
    String? supplierId,
    required DateTime timestamp,
    required String status,
  }) = _AlertSummary;

  factory AlertSummary.fromJson(Map<String, dynamic> json) =>
      _$AlertSummaryFromJson(json);
}

@freezed
class TrendMetrics with _$TrendMetrics {
  const factory TrendMetrics({
    required double avgSupplierRiskScore,
    required int activeDisruptionsCount,
    required double predictionConfidence,
    required List<double> riskScoreBars,
  }) = _TrendMetrics;

  factory TrendMetrics.fromJson(Map<String, dynamic> json) =>
      _$TrendMetricsFromJson(json);
}
