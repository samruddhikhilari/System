// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DashboardSummary _$DashboardSummaryFromJson(Map<String, dynamic> json) {
  return _DashboardSummary.fromJson(json);
}

/// @nodoc
mixin _$DashboardSummary {
  double get nriScore => throw _privateConstructorUsedError;
  double get nriDelta => throw _privateConstructorUsedError;
  List<SectorRisk> get sectors => throw _privateConstructorUsedError;
  List<AlertSummary> get activeAlerts => throw _privateConstructorUsedError;
  TrendMetrics get trendMetrics => throw _privateConstructorUsedError;
  DateTime get lastUpdated => throw _privateConstructorUsedError;

  /// Serializes this DashboardSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DashboardSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DashboardSummaryCopyWith<DashboardSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardSummaryCopyWith<$Res> {
  factory $DashboardSummaryCopyWith(
    DashboardSummary value,
    $Res Function(DashboardSummary) then,
  ) = _$DashboardSummaryCopyWithImpl<$Res, DashboardSummary>;
  @useResult
  $Res call({
    double nriScore,
    double nriDelta,
    List<SectorRisk> sectors,
    List<AlertSummary> activeAlerts,
    TrendMetrics trendMetrics,
    DateTime lastUpdated,
  });

  $TrendMetricsCopyWith<$Res> get trendMetrics;
}

/// @nodoc
class _$DashboardSummaryCopyWithImpl<$Res, $Val extends DashboardSummary>
    implements $DashboardSummaryCopyWith<$Res> {
  _$DashboardSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DashboardSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nriScore = null,
    Object? nriDelta = null,
    Object? sectors = null,
    Object? activeAlerts = null,
    Object? trendMetrics = null,
    Object? lastUpdated = null,
  }) {
    return _then(
      _value.copyWith(
            nriScore: null == nriScore
                ? _value.nriScore
                : nriScore // ignore: cast_nullable_to_non_nullable
                      as double,
            nriDelta: null == nriDelta
                ? _value.nriDelta
                : nriDelta // ignore: cast_nullable_to_non_nullable
                      as double,
            sectors: null == sectors
                ? _value.sectors
                : sectors // ignore: cast_nullable_to_non_nullable
                      as List<SectorRisk>,
            activeAlerts: null == activeAlerts
                ? _value.activeAlerts
                : activeAlerts // ignore: cast_nullable_to_non_nullable
                      as List<AlertSummary>,
            trendMetrics: null == trendMetrics
                ? _value.trendMetrics
                : trendMetrics // ignore: cast_nullable_to_non_nullable
                      as TrendMetrics,
            lastUpdated: null == lastUpdated
                ? _value.lastUpdated
                : lastUpdated // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }

  /// Create a copy of DashboardSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TrendMetricsCopyWith<$Res> get trendMetrics {
    return $TrendMetricsCopyWith<$Res>(_value.trendMetrics, (value) {
      return _then(_value.copyWith(trendMetrics: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DashboardSummaryImplCopyWith<$Res>
    implements $DashboardSummaryCopyWith<$Res> {
  factory _$$DashboardSummaryImplCopyWith(
    _$DashboardSummaryImpl value,
    $Res Function(_$DashboardSummaryImpl) then,
  ) = __$$DashboardSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double nriScore,
    double nriDelta,
    List<SectorRisk> sectors,
    List<AlertSummary> activeAlerts,
    TrendMetrics trendMetrics,
    DateTime lastUpdated,
  });

  @override
  $TrendMetricsCopyWith<$Res> get trendMetrics;
}

/// @nodoc
class __$$DashboardSummaryImplCopyWithImpl<$Res>
    extends _$DashboardSummaryCopyWithImpl<$Res, _$DashboardSummaryImpl>
    implements _$$DashboardSummaryImplCopyWith<$Res> {
  __$$DashboardSummaryImplCopyWithImpl(
    _$DashboardSummaryImpl _value,
    $Res Function(_$DashboardSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DashboardSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nriScore = null,
    Object? nriDelta = null,
    Object? sectors = null,
    Object? activeAlerts = null,
    Object? trendMetrics = null,
    Object? lastUpdated = null,
  }) {
    return _then(
      _$DashboardSummaryImpl(
        nriScore: null == nriScore
            ? _value.nriScore
            : nriScore // ignore: cast_nullable_to_non_nullable
                  as double,
        nriDelta: null == nriDelta
            ? _value.nriDelta
            : nriDelta // ignore: cast_nullable_to_non_nullable
                  as double,
        sectors: null == sectors
            ? _value._sectors
            : sectors // ignore: cast_nullable_to_non_nullable
                  as List<SectorRisk>,
        activeAlerts: null == activeAlerts
            ? _value._activeAlerts
            : activeAlerts // ignore: cast_nullable_to_non_nullable
                  as List<AlertSummary>,
        trendMetrics: null == trendMetrics
            ? _value.trendMetrics
            : trendMetrics // ignore: cast_nullable_to_non_nullable
                  as TrendMetrics,
        lastUpdated: null == lastUpdated
            ? _value.lastUpdated
            : lastUpdated // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DashboardSummaryImpl implements _DashboardSummary {
  const _$DashboardSummaryImpl({
    required this.nriScore,
    required this.nriDelta,
    required final List<SectorRisk> sectors,
    required final List<AlertSummary> activeAlerts,
    required this.trendMetrics,
    required this.lastUpdated,
  }) : _sectors = sectors,
       _activeAlerts = activeAlerts;

  factory _$DashboardSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$DashboardSummaryImplFromJson(json);

  @override
  final double nriScore;
  @override
  final double nriDelta;
  final List<SectorRisk> _sectors;
  @override
  List<SectorRisk> get sectors {
    if (_sectors is EqualUnmodifiableListView) return _sectors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sectors);
  }

  final List<AlertSummary> _activeAlerts;
  @override
  List<AlertSummary> get activeAlerts {
    if (_activeAlerts is EqualUnmodifiableListView) return _activeAlerts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_activeAlerts);
  }

  @override
  final TrendMetrics trendMetrics;
  @override
  final DateTime lastUpdated;

  @override
  String toString() {
    return 'DashboardSummary(nriScore: $nriScore, nriDelta: $nriDelta, sectors: $sectors, activeAlerts: $activeAlerts, trendMetrics: $trendMetrics, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardSummaryImpl &&
            (identical(other.nriScore, nriScore) ||
                other.nriScore == nriScore) &&
            (identical(other.nriDelta, nriDelta) ||
                other.nriDelta == nriDelta) &&
            const DeepCollectionEquality().equals(other._sectors, _sectors) &&
            const DeepCollectionEquality().equals(
              other._activeAlerts,
              _activeAlerts,
            ) &&
            (identical(other.trendMetrics, trendMetrics) ||
                other.trendMetrics == trendMetrics) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    nriScore,
    nriDelta,
    const DeepCollectionEquality().hash(_sectors),
    const DeepCollectionEquality().hash(_activeAlerts),
    trendMetrics,
    lastUpdated,
  );

  /// Create a copy of DashboardSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardSummaryImplCopyWith<_$DashboardSummaryImpl> get copyWith =>
      __$$DashboardSummaryImplCopyWithImpl<_$DashboardSummaryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DashboardSummaryImplToJson(this);
  }
}

abstract class _DashboardSummary implements DashboardSummary {
  const factory _DashboardSummary({
    required final double nriScore,
    required final double nriDelta,
    required final List<SectorRisk> sectors,
    required final List<AlertSummary> activeAlerts,
    required final TrendMetrics trendMetrics,
    required final DateTime lastUpdated,
  }) = _$DashboardSummaryImpl;

  factory _DashboardSummary.fromJson(Map<String, dynamic> json) =
      _$DashboardSummaryImpl.fromJson;

  @override
  double get nriScore;
  @override
  double get nriDelta;
  @override
  List<SectorRisk> get sectors;
  @override
  List<AlertSummary> get activeAlerts;
  @override
  TrendMetrics get trendMetrics;
  @override
  DateTime get lastUpdated;

  /// Create a copy of DashboardSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DashboardSummaryImplCopyWith<_$DashboardSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SectorRisk _$SectorRiskFromJson(Map<String, dynamic> json) {
  return _SectorRisk.fromJson(json);
}

/// @nodoc
mixin _$SectorRisk {
  String get sector => throw _privateConstructorUsedError;
  String get icon => throw _privateConstructorUsedError;
  double get riskScore => throw _privateConstructorUsedError;
  double get delta7d => throw _privateConstructorUsedError;
  List<double> get sparklineData => throw _privateConstructorUsedError;

  /// Serializes this SectorRisk to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SectorRisk
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SectorRiskCopyWith<SectorRisk> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SectorRiskCopyWith<$Res> {
  factory $SectorRiskCopyWith(
    SectorRisk value,
    $Res Function(SectorRisk) then,
  ) = _$SectorRiskCopyWithImpl<$Res, SectorRisk>;
  @useResult
  $Res call({
    String sector,
    String icon,
    double riskScore,
    double delta7d,
    List<double> sparklineData,
  });
}

/// @nodoc
class _$SectorRiskCopyWithImpl<$Res, $Val extends SectorRisk>
    implements $SectorRiskCopyWith<$Res> {
  _$SectorRiskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SectorRisk
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sector = null,
    Object? icon = null,
    Object? riskScore = null,
    Object? delta7d = null,
    Object? sparklineData = null,
  }) {
    return _then(
      _value.copyWith(
            sector: null == sector
                ? _value.sector
                : sector // ignore: cast_nullable_to_non_nullable
                      as String,
            icon: null == icon
                ? _value.icon
                : icon // ignore: cast_nullable_to_non_nullable
                      as String,
            riskScore: null == riskScore
                ? _value.riskScore
                : riskScore // ignore: cast_nullable_to_non_nullable
                      as double,
            delta7d: null == delta7d
                ? _value.delta7d
                : delta7d // ignore: cast_nullable_to_non_nullable
                      as double,
            sparklineData: null == sparklineData
                ? _value.sparklineData
                : sparklineData // ignore: cast_nullable_to_non_nullable
                      as List<double>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SectorRiskImplCopyWith<$Res>
    implements $SectorRiskCopyWith<$Res> {
  factory _$$SectorRiskImplCopyWith(
    _$SectorRiskImpl value,
    $Res Function(_$SectorRiskImpl) then,
  ) = __$$SectorRiskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String sector,
    String icon,
    double riskScore,
    double delta7d,
    List<double> sparklineData,
  });
}

/// @nodoc
class __$$SectorRiskImplCopyWithImpl<$Res>
    extends _$SectorRiskCopyWithImpl<$Res, _$SectorRiskImpl>
    implements _$$SectorRiskImplCopyWith<$Res> {
  __$$SectorRiskImplCopyWithImpl(
    _$SectorRiskImpl _value,
    $Res Function(_$SectorRiskImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SectorRisk
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sector = null,
    Object? icon = null,
    Object? riskScore = null,
    Object? delta7d = null,
    Object? sparklineData = null,
  }) {
    return _then(
      _$SectorRiskImpl(
        sector: null == sector
            ? _value.sector
            : sector // ignore: cast_nullable_to_non_nullable
                  as String,
        icon: null == icon
            ? _value.icon
            : icon // ignore: cast_nullable_to_non_nullable
                  as String,
        riskScore: null == riskScore
            ? _value.riskScore
            : riskScore // ignore: cast_nullable_to_non_nullable
                  as double,
        delta7d: null == delta7d
            ? _value.delta7d
            : delta7d // ignore: cast_nullable_to_non_nullable
                  as double,
        sparklineData: null == sparklineData
            ? _value._sparklineData
            : sparklineData // ignore: cast_nullable_to_non_nullable
                  as List<double>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SectorRiskImpl implements _SectorRisk {
  const _$SectorRiskImpl({
    required this.sector,
    required this.icon,
    required this.riskScore,
    required this.delta7d,
    required final List<double> sparklineData,
  }) : _sparklineData = sparklineData;

  factory _$SectorRiskImpl.fromJson(Map<String, dynamic> json) =>
      _$$SectorRiskImplFromJson(json);

  @override
  final String sector;
  @override
  final String icon;
  @override
  final double riskScore;
  @override
  final double delta7d;
  final List<double> _sparklineData;
  @override
  List<double> get sparklineData {
    if (_sparklineData is EqualUnmodifiableListView) return _sparklineData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sparklineData);
  }

  @override
  String toString() {
    return 'SectorRisk(sector: $sector, icon: $icon, riskScore: $riskScore, delta7d: $delta7d, sparklineData: $sparklineData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SectorRiskImpl &&
            (identical(other.sector, sector) || other.sector == sector) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.riskScore, riskScore) ||
                other.riskScore == riskScore) &&
            (identical(other.delta7d, delta7d) || other.delta7d == delta7d) &&
            const DeepCollectionEquality().equals(
              other._sparklineData,
              _sparklineData,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    sector,
    icon,
    riskScore,
    delta7d,
    const DeepCollectionEquality().hash(_sparklineData),
  );

  /// Create a copy of SectorRisk
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SectorRiskImplCopyWith<_$SectorRiskImpl> get copyWith =>
      __$$SectorRiskImplCopyWithImpl<_$SectorRiskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SectorRiskImplToJson(this);
  }
}

abstract class _SectorRisk implements SectorRisk {
  const factory _SectorRisk({
    required final String sector,
    required final String icon,
    required final double riskScore,
    required final double delta7d,
    required final List<double> sparklineData,
  }) = _$SectorRiskImpl;

  factory _SectorRisk.fromJson(Map<String, dynamic> json) =
      _$SectorRiskImpl.fromJson;

  @override
  String get sector;
  @override
  String get icon;
  @override
  double get riskScore;
  @override
  double get delta7d;
  @override
  List<double> get sparklineData;

  /// Create a copy of SectorRisk
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SectorRiskImplCopyWith<_$SectorRiskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AlertSummary _$AlertSummaryFromJson(Map<String, dynamic> json) {
  return _AlertSummary.fromJson(json);
}

/// @nodoc
mixin _$AlertSummary {
  String get id => throw _privateConstructorUsedError;
  String get severity => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  String? get supplierId => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  /// Serializes this AlertSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AlertSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AlertSummaryCopyWith<AlertSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlertSummaryCopyWith<$Res> {
  factory $AlertSummaryCopyWith(
    AlertSummary value,
    $Res Function(AlertSummary) then,
  ) = _$AlertSummaryCopyWithImpl<$Res, AlertSummary>;
  @useResult
  $Res call({
    String id,
    String severity,
    String title,
    String body,
    String? supplierId,
    DateTime timestamp,
    String status,
  });
}

/// @nodoc
class _$AlertSummaryCopyWithImpl<$Res, $Val extends AlertSummary>
    implements $AlertSummaryCopyWith<$Res> {
  _$AlertSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AlertSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? severity = null,
    Object? title = null,
    Object? body = null,
    Object? supplierId = freezed,
    Object? timestamp = null,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            severity: null == severity
                ? _value.severity
                : severity // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            body: null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as String,
            supplierId: freezed == supplierId
                ? _value.supplierId
                : supplierId // ignore: cast_nullable_to_non_nullable
                      as String?,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AlertSummaryImplCopyWith<$Res>
    implements $AlertSummaryCopyWith<$Res> {
  factory _$$AlertSummaryImplCopyWith(
    _$AlertSummaryImpl value,
    $Res Function(_$AlertSummaryImpl) then,
  ) = __$$AlertSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String severity,
    String title,
    String body,
    String? supplierId,
    DateTime timestamp,
    String status,
  });
}

/// @nodoc
class __$$AlertSummaryImplCopyWithImpl<$Res>
    extends _$AlertSummaryCopyWithImpl<$Res, _$AlertSummaryImpl>
    implements _$$AlertSummaryImplCopyWith<$Res> {
  __$$AlertSummaryImplCopyWithImpl(
    _$AlertSummaryImpl _value,
    $Res Function(_$AlertSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AlertSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? severity = null,
    Object? title = null,
    Object? body = null,
    Object? supplierId = freezed,
    Object? timestamp = null,
    Object? status = null,
  }) {
    return _then(
      _$AlertSummaryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        severity: null == severity
            ? _value.severity
            : severity // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        body: null == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as String,
        supplierId: freezed == supplierId
            ? _value.supplierId
            : supplierId // ignore: cast_nullable_to_non_nullable
                  as String?,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AlertSummaryImpl implements _AlertSummary {
  const _$AlertSummaryImpl({
    required this.id,
    required this.severity,
    required this.title,
    required this.body,
    this.supplierId,
    required this.timestamp,
    required this.status,
  });

  factory _$AlertSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlertSummaryImplFromJson(json);

  @override
  final String id;
  @override
  final String severity;
  @override
  final String title;
  @override
  final String body;
  @override
  final String? supplierId;
  @override
  final DateTime timestamp;
  @override
  final String status;

  @override
  String toString() {
    return 'AlertSummary(id: $id, severity: $severity, title: $title, body: $body, supplierId: $supplierId, timestamp: $timestamp, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlertSummaryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.supplierId, supplierId) ||
                other.supplierId == supplierId) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    severity,
    title,
    body,
    supplierId,
    timestamp,
    status,
  );

  /// Create a copy of AlertSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlertSummaryImplCopyWith<_$AlertSummaryImpl> get copyWith =>
      __$$AlertSummaryImplCopyWithImpl<_$AlertSummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlertSummaryImplToJson(this);
  }
}

abstract class _AlertSummary implements AlertSummary {
  const factory _AlertSummary({
    required final String id,
    required final String severity,
    required final String title,
    required final String body,
    final String? supplierId,
    required final DateTime timestamp,
    required final String status,
  }) = _$AlertSummaryImpl;

  factory _AlertSummary.fromJson(Map<String, dynamic> json) =
      _$AlertSummaryImpl.fromJson;

  @override
  String get id;
  @override
  String get severity;
  @override
  String get title;
  @override
  String get body;
  @override
  String? get supplierId;
  @override
  DateTime get timestamp;
  @override
  String get status;

  /// Create a copy of AlertSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlertSummaryImplCopyWith<_$AlertSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TrendMetrics _$TrendMetricsFromJson(Map<String, dynamic> json) {
  return _TrendMetrics.fromJson(json);
}

/// @nodoc
mixin _$TrendMetrics {
  double get avgSupplierRiskScore => throw _privateConstructorUsedError;
  int get activeDisruptionsCount => throw _privateConstructorUsedError;
  double get predictionConfidence => throw _privateConstructorUsedError;
  List<double> get riskScoreBars => throw _privateConstructorUsedError;

  /// Serializes this TrendMetrics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TrendMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrendMetricsCopyWith<TrendMetrics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrendMetricsCopyWith<$Res> {
  factory $TrendMetricsCopyWith(
    TrendMetrics value,
    $Res Function(TrendMetrics) then,
  ) = _$TrendMetricsCopyWithImpl<$Res, TrendMetrics>;
  @useResult
  $Res call({
    double avgSupplierRiskScore,
    int activeDisruptionsCount,
    double predictionConfidence,
    List<double> riskScoreBars,
  });
}

/// @nodoc
class _$TrendMetricsCopyWithImpl<$Res, $Val extends TrendMetrics>
    implements $TrendMetricsCopyWith<$Res> {
  _$TrendMetricsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrendMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? avgSupplierRiskScore = null,
    Object? activeDisruptionsCount = null,
    Object? predictionConfidence = null,
    Object? riskScoreBars = null,
  }) {
    return _then(
      _value.copyWith(
            avgSupplierRiskScore: null == avgSupplierRiskScore
                ? _value.avgSupplierRiskScore
                : avgSupplierRiskScore // ignore: cast_nullable_to_non_nullable
                      as double,
            activeDisruptionsCount: null == activeDisruptionsCount
                ? _value.activeDisruptionsCount
                : activeDisruptionsCount // ignore: cast_nullable_to_non_nullable
                      as int,
            predictionConfidence: null == predictionConfidence
                ? _value.predictionConfidence
                : predictionConfidence // ignore: cast_nullable_to_non_nullable
                      as double,
            riskScoreBars: null == riskScoreBars
                ? _value.riskScoreBars
                : riskScoreBars // ignore: cast_nullable_to_non_nullable
                      as List<double>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TrendMetricsImplCopyWith<$Res>
    implements $TrendMetricsCopyWith<$Res> {
  factory _$$TrendMetricsImplCopyWith(
    _$TrendMetricsImpl value,
    $Res Function(_$TrendMetricsImpl) then,
  ) = __$$TrendMetricsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double avgSupplierRiskScore,
    int activeDisruptionsCount,
    double predictionConfidence,
    List<double> riskScoreBars,
  });
}

/// @nodoc
class __$$TrendMetricsImplCopyWithImpl<$Res>
    extends _$TrendMetricsCopyWithImpl<$Res, _$TrendMetricsImpl>
    implements _$$TrendMetricsImplCopyWith<$Res> {
  __$$TrendMetricsImplCopyWithImpl(
    _$TrendMetricsImpl _value,
    $Res Function(_$TrendMetricsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TrendMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? avgSupplierRiskScore = null,
    Object? activeDisruptionsCount = null,
    Object? predictionConfidence = null,
    Object? riskScoreBars = null,
  }) {
    return _then(
      _$TrendMetricsImpl(
        avgSupplierRiskScore: null == avgSupplierRiskScore
            ? _value.avgSupplierRiskScore
            : avgSupplierRiskScore // ignore: cast_nullable_to_non_nullable
                  as double,
        activeDisruptionsCount: null == activeDisruptionsCount
            ? _value.activeDisruptionsCount
            : activeDisruptionsCount // ignore: cast_nullable_to_non_nullable
                  as int,
        predictionConfidence: null == predictionConfidence
            ? _value.predictionConfidence
            : predictionConfidence // ignore: cast_nullable_to_non_nullable
                  as double,
        riskScoreBars: null == riskScoreBars
            ? _value._riskScoreBars
            : riskScoreBars // ignore: cast_nullable_to_non_nullable
                  as List<double>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TrendMetricsImpl implements _TrendMetrics {
  const _$TrendMetricsImpl({
    required this.avgSupplierRiskScore,
    required this.activeDisruptionsCount,
    required this.predictionConfidence,
    required final List<double> riskScoreBars,
  }) : _riskScoreBars = riskScoreBars;

  factory _$TrendMetricsImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrendMetricsImplFromJson(json);

  @override
  final double avgSupplierRiskScore;
  @override
  final int activeDisruptionsCount;
  @override
  final double predictionConfidence;
  final List<double> _riskScoreBars;
  @override
  List<double> get riskScoreBars {
    if (_riskScoreBars is EqualUnmodifiableListView) return _riskScoreBars;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_riskScoreBars);
  }

  @override
  String toString() {
    return 'TrendMetrics(avgSupplierRiskScore: $avgSupplierRiskScore, activeDisruptionsCount: $activeDisruptionsCount, predictionConfidence: $predictionConfidence, riskScoreBars: $riskScoreBars)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrendMetricsImpl &&
            (identical(other.avgSupplierRiskScore, avgSupplierRiskScore) ||
                other.avgSupplierRiskScore == avgSupplierRiskScore) &&
            (identical(other.activeDisruptionsCount, activeDisruptionsCount) ||
                other.activeDisruptionsCount == activeDisruptionsCount) &&
            (identical(other.predictionConfidence, predictionConfidence) ||
                other.predictionConfidence == predictionConfidence) &&
            const DeepCollectionEquality().equals(
              other._riskScoreBars,
              _riskScoreBars,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    avgSupplierRiskScore,
    activeDisruptionsCount,
    predictionConfidence,
    const DeepCollectionEquality().hash(_riskScoreBars),
  );

  /// Create a copy of TrendMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrendMetricsImplCopyWith<_$TrendMetricsImpl> get copyWith =>
      __$$TrendMetricsImplCopyWithImpl<_$TrendMetricsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TrendMetricsImplToJson(this);
  }
}

abstract class _TrendMetrics implements TrendMetrics {
  const factory _TrendMetrics({
    required final double avgSupplierRiskScore,
    required final int activeDisruptionsCount,
    required final double predictionConfidence,
    required final List<double> riskScoreBars,
  }) = _$TrendMetricsImpl;

  factory _TrendMetrics.fromJson(Map<String, dynamic> json) =
      _$TrendMetricsImpl.fromJson;

  @override
  double get avgSupplierRiskScore;
  @override
  int get activeDisruptionsCount;
  @override
  double get predictionConfidence;
  @override
  List<double> get riskScoreBars;

  /// Create a copy of TrendMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrendMetricsImplCopyWith<_$TrendMetricsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
