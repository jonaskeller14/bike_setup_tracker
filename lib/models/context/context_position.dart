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
          ? DateTime.parse(json['time']).millisecondsSinceEpoch.toDouble()
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
}