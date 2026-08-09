import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:location/location.dart';

export 'package:location/location.dart';

class LocationDataConverter extends TypeConverter<LocationData, String> {
  const LocationDataConverter();

  @override
  LocationData fromSql(String fromDb) {
    final Map<String, dynamic> jsonMap = json.decode(fromDb) as Map<String, dynamic>;
    // Mimics the parsing logic from Setup.dart for backward compatibility
    final int? version = jsonMap["version"] as int?;
    switch (version) {
      case null || 1:
        return LocationData.fromMap({
          'latitude': jsonMap['latitude'],
          'longitude': jsonMap['longitude'],
          'accuracy': jsonMap['accuracy'],
          'altitude': jsonMap['altitude'],
          'speed': jsonMap['speed'],
          'speed_accuracy': jsonMap['speedAccuracy'], 
          'heading': jsonMap['heading'],
          'time': jsonMap['time'],
        });
      default:
        throw Exception("Json Version $version of LocationData incompatible.");
    }
  }

  @override
  String toSql(LocationData value) {
    return json.encode({
      'version': 1,
      'latitude': value.latitude,
      'longitude': value.longitude,
      'accuracy': value.accuracy,
      'altitude': value.altitude,
      'speed': value.speed,
      'speedAccuracy': value.speedAccuracy,
      'heading': value.heading,
      'time': value.time,
      'isMock': value.isMock,
    });
  }
}
