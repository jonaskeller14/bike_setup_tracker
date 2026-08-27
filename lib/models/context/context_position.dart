import 'package:units_converter/units_converter.dart';

class ContextPosition {
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? accuracy;
  final double? heading;
  final double? speed;
  final double? speedAccuracy;
  final DateTime? timestamp;
  final bool? isMock;

  const ContextPosition({
    this.latitude,
    this.longitude,
    this.altitude,
    this.accuracy,
    this.heading,
    this.speed,
    this.speedAccuracy,
    this.timestamp,
    this.isMock,
  });

  ContextPosition copyWith({
    Object? latitude = const _Sentinel(),
    Object? longitude = const _Sentinel(),
    Object? altitude = const _Sentinel(),
    Object? accuracy = const _Sentinel(),
    Object? heading = const _Sentinel(),
    Object? speed = const _Sentinel(),
    Object? speedAccuracy = const _Sentinel(),
    Object? timestamp = const _Sentinel(),
    Object? isMock = const _Sentinel(),
  }) {
    return ContextPosition(
      latitude: _copyDouble(latitude, this.latitude),
      longitude: _copyDouble(longitude, this.longitude),
      altitude: _copyDouble(altitude, this.altitude),
      accuracy: _copyDouble(accuracy, this.accuracy),
      heading: _copyDouble(heading, this.heading),
      speed: _copyDouble(speed, this.speed),
      speedAccuracy: speedAccuracy is _Sentinel ? this.speedAccuracy : (speedAccuracy as num?)?.toDouble(),
      timestamp: timestamp is _Sentinel ? this.timestamp : timestamp as DateTime?,
      isMock: isMock is _Sentinel ? this.isMock : isMock as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'accuracy': accuracy,
    'heading': heading,
    'speed': speed,
    'speedAccuracy': speedAccuracy,
    'time': timestamp?.toIso8601String(),
    'isMock': isMock,
  };

  factory ContextPosition.fromJson(Map<String, dynamic> json) {
    return ContextPosition(
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      altitude: _toDouble(json['altitude']),
      accuracy: _toDouble(json['accuracy']),
      heading: _toDouble(json['heading']),
      speed: _toDouble(json['speed']),
      speedAccuracy: _toDouble(json['speedAccuracy']),
      timestamp: json['time'] == null ? null : DateTime.parse(json['time'] as String),
      isMock: json['isMock'] as bool?,
    );
  }

  static bool equal(ContextPosition? a, ContextPosition? b) {
    return identical(a, b) ||
        a != null && b != null && a.latitude == b.latitude && a.longitude == b.longitude && a.altitude == b.altitude;
  }

  static LENGTH _altitudeUnitEnum(String unit) => switch (unit) {
    'm' => LENGTH.meters,
    'ft' => LENGTH.feet,
    _ => LENGTH.meters,
  };

  static double? convertAltitudeToMeters(double? alt, String currentUnit) {
    if (alt == null) return null;
    return alt.convertFromTo(_altitudeUnitEnum(currentUnit), LENGTH.meters);
  }

  static double? convertAltitudeFromMeters(double? altM, String targetUnit) {
    if (altM == null) return null;
    return altM.convertFromTo(LENGTH.meters, _altitudeUnitEnum(targetUnit));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ContextPosition &&
            latitude == other.latitude &&
            longitude == other.longitude &&
            altitude == other.altitude &&
            accuracy == other.accuracy &&
            heading == other.heading &&
            speed == other.speed &&
            speedAccuracy == other.speedAccuracy &&
            timestamp == other.timestamp &&
            isMock == other.isMock;
  }

  @override
  int get hashCode => Object.hash(
    latitude,
    longitude,
    altitude,
    accuracy,
    heading,
    speed,
    speedAccuracy,
    timestamp,
    isMock,
  );

  static double? _toDouble(Object? value) => (value as num?)?.toDouble();

  static double? _copyDouble(Object? value, double? current) {
    return value is _Sentinel ? current : (value as num?)?.toDouble();
  }
}

class _Sentinel {
  const _Sentinel();
}
