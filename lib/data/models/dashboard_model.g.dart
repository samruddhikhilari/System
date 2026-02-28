// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DashboardSummaryImpl _$$DashboardSummaryImplFromJson(
  Map<String, dynamic> json,
) => _$DashboardSummaryImpl(
  nriScore: (json['nriScore'] as num).toDouble(),
  nriDelta: (json['nriDelta'] as num).toDouble(),
  sectors: (json['sectors'] as List<dynamic>)
      .map((e) => SectorRisk.fromJson(e as Map<String, dynamic>))
      .toList(),
  activeAlerts: (json['activeAlerts'] as List<dynamic>)
      .map((e) => AlertSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
  trendMetrics: TrendMetrics.fromJson(
    json['trendMetrics'] as Map<String, dynamic>,
  ),
  lastUpdated: DateTime.parse(json['lastUpdated'] as String),
);

Map<String, dynamic> _$$DashboardSummaryImplToJson(
  _$DashboardSummaryImpl instance,
) => <String, dynamic>{
  'nriScore': instance.nriScore,
  'nriDelta': instance.nriDelta,
  'sectors': instance.sectors,
  'activeAlerts': instance.activeAlerts,
  'trendMetrics': instance.trendMetrics,
  'lastUpdated': instance.lastUpdated.toIso8601String(),
};

_$SectorRiskImpl _$$SectorRiskImplFromJson(Map<String, dynamic> json) =>
    _$SectorRiskImpl(
      sector: json['sector'] as String,
      icon: json['icon'] as String,
      riskScore: (json['riskScore'] as num).toDouble(),
      delta7d: (json['delta7d'] as num).toDouble(),
      sparklineData: (json['sparklineData'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );

Map<String, dynamic> _$$SectorRiskImplToJson(_$SectorRiskImpl instance) =>
    <String, dynamic>{
      'sector': instance.sector,
      'icon': instance.icon,
      'riskScore': instance.riskScore,
      'delta7d': instance.delta7d,
      'sparklineData': instance.sparklineData,
    };

_$AlertSummaryImpl _$$AlertSummaryImplFromJson(Map<String, dynamic> json) =>
    _$AlertSummaryImpl(
      id: json['id'] as String,
      severity: json['severity'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      supplierId: json['supplierId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
    );

Map<String, dynamic> _$$AlertSummaryImplToJson(_$AlertSummaryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'severity': instance.severity,
      'title': instance.title,
      'body': instance.body,
      'supplierId': instance.supplierId,
      'timestamp': instance.timestamp.toIso8601String(),
      'status': instance.status,
    };

_$TrendMetricsImpl _$$TrendMetricsImplFromJson(Map<String, dynamic> json) =>
    _$TrendMetricsImpl(
      avgSupplierRiskScore: (json['avgSupplierRiskScore'] as num).toDouble(),
      activeDisruptionsCount: (json['activeDisruptionsCount'] as num).toInt(),
      predictionConfidence: (json['predictionConfidence'] as num).toDouble(),
      riskScoreBars: (json['riskScoreBars'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );

Map<String, dynamic> _$$TrendMetricsImplToJson(_$TrendMetricsImpl instance) =>
    <String, dynamic>{
      'avgSupplierRiskScore': instance.avgSupplierRiskScore,
      'activeDisruptionsCount': instance.activeDisruptionsCount,
      'predictionConfidence': instance.predictionConfidence,
      'riskScoreBars': instance.riskScoreBars,
    };
