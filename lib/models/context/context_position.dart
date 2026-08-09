import 'package:location/location.dart';

class ContextPosition {
  const ContextPosition._();

  static Map<String, dynamic> toJson(LocationData data) => {
    'latitude': data.latitude,
    'longitude': data.longitude,
    'altitude': data.altitude,
    'accuracy': data.accuracy,
    'heading': data.heading,
    'speed': data.speed,
    'speedAccuracy': data.speedAccuracy,
    'time': data.time != null
        ? DateTime.fromMillisecondsSinceEpoch(data.time!.toInt()).toIso8601String()
        : null,
  };

  static LocationData fromJson(Map<String, dynamic> json) {
    return LocationData.fromMap({
      'latitude': json['latitude'],
      'longitude': json['longitude'],
      'altitude': json['altitude'],
      'accuracy': json['accuracy'],
      'heading': json['heading'],
      'speed': json['speed'],
      'speed_accuracy': json['speedAccuracy'], // key expected by LocationData.fromMap
      'time': json['time'] != null
          ? DateTime.parse(json['time'] as String).millisecondsSinceEpoch.toDouble()
          : null,
    });
  }

  static bool equal(LocationData? a, LocationData? b) {
    return identical(a, b) ||
        a != null &&
        b != null &&
        a.latitude == b.latitude &&
        a.longitude == b.longitude &&
        a.altitude == b.altitude;
  }

  static double? convertAltitudeToMeters(double? alt, String currentUnit) {
    if (alt == null) return null;
    const double ftToM = 1 / 3.28084; // ft / 3.28084 = m

    switch (currentUnit) {
      case 'm':
        return alt;
      case 'ft':
        return alt * ftToM;
      default:
        return alt;
    }
  }

  static double? convertAltitudeFromMeters(double? altM, String targetUnit) {
    if (altM == null) return null;
    const double mToFt = 3.28084;

    switch (targetUnit) {
      case 'm':
        return altM;
      case 'ft':
        return altM * mToFt;
      default:
        return altM;
    }
  }
}
