import '../app/strings.dart';

/// 측정 시점의 인터넷 연결 종류 (PRD 1.3 용어 정의, FR-06)
enum ConnectionType {
  wifi(AppStrings.connectionWifi),
  lte(AppStrings.connectionLte),
  fiveG(AppStrings.connection5g),
  mobileOther(AppStrings.connectionMobileOther),
  none(AppStrings.connectionNone),
  unknown(AppStrings.connectionUnknown);

  const ConnectionType(this.label);
  final String label;
}

/// 측위 출처 추정 (PRD 6.2)
enum SourceEstimate {
  gps(AppStrings.sourceGps),
  wifi(AppStrings.sourceWifi),
  cell(AppStrings.sourceCell),
  unknown(AppStrings.sourceUnknown);

  const SourceEstimate(this.label);
  final String label;
}

/// 측정이 이루어진 플랫폼 (PRD 6.1)
enum AppPlatform { android, iosWeb }

/// 측정 결과 1건 (PRD 6.1 데이터 모델)
class Measurement {
  const Measurement({
    required this.id,
    required this.measuredAt,
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    required this.connectionType,
    required this.sourceEstimate,
    required this.platform,
    required this.timedOut,
    required this.appVersion,
    this.locationProvider,
    this.distanceFromPrevM,
    this.isMock,
    this.altitudeM,
  });

  final String id;

  /// 기기 로컬 시각. JSON에는 오프셋 포함 ISO 8601로 저장한다.
  final DateTime measuredAt;
  final double latitude;
  final double longitude;
  final double accuracyM;
  final ConnectionType connectionType;

  /// Android만: gps / network / fused. iOS PWA는 null.
  final String? locationProvider;
  final SourceEstimate sourceEstimate;
  final AppPlatform platform;

  /// 직전 결과와의 거리(m). 첫 측정은 null.
  final double? distanceFromPrevM;

  /// Android 12+ 모의 위치 여부. 그 외 null.
  final bool? isMock;

  /// 타임아웃 후 마지막 수신 위치를 사용했는지.
  final bool timedOut;
  final double? altitudeM;
  final String appVersion;

  Map<String, dynamic> toJson() => {
        'id': id,
        'measuredAt': _toIso8601WithOffset(measuredAt),
        'latitude': latitude,
        'longitude': longitude,
        'accuracyM': accuracyM,
        'connectionType': connectionType.name,
        'locationProvider': locationProvider,
        'sourceEstimate': sourceEstimate.name,
        'platform': platform.name,
        'distanceFromPrevM': distanceFromPrevM,
        'isMock': isMock,
        'timedOut': timedOut,
        'altitudeM': altitudeM,
        'appVersion': appVersion,
      };

  factory Measurement.fromJson(Map<String, dynamic> json) => Measurement(
        id: json['id'] as String,
        measuredAt: DateTime.parse(json['measuredAt'] as String).toLocal(),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracyM: (json['accuracyM'] as num).toDouble(),
        connectionType: ConnectionType.values.byName(
          json['connectionType'] as String,
        ),
        locationProvider: json['locationProvider'] as String?,
        sourceEstimate: SourceEstimate.values.byName(
          json['sourceEstimate'] as String,
        ),
        platform: AppPlatform.values.byName(json['platform'] as String),
        distanceFromPrevM: (json['distanceFromPrevM'] as num?)?.toDouble(),
        isMock: json['isMock'] as bool?,
        timedOut: json['timedOut'] as bool,
        altitudeM: (json['altitudeM'] as num?)?.toDouble(),
        appVersion: json['appVersion'] as String,
      );

  /// Dart의 toIso8601String()은 로컬 시각에 오프셋을 붙이지 않으므로 직접 붙인다.
  static String _toIso8601WithOffset(DateTime dt) {
    final local = dt.toLocal();
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hh = offset.inHours.abs().toString().padLeft(2, '0');
    final mm = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    // toIso8601String()은 마이크로초까지 붙일 수 있으므로 초 단위로 자른다.
    final base = local.toIso8601String().split('.').first;
    return '$base$sign$hh:$mm';
  }
}
