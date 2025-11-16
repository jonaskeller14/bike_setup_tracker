import 'package:uuid/uuid.dart';
import "adjustment.dart";
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;

class Setting {
  final String id;
  final String name;
  final DateTime datetime;
  final String? notes;
  Map<Adjustment, dynamic> adjustmentValues;
  final LocationData? position;
  final geo.Placemark? place;

  Setting({
    String? id,
    required this.name,
    required this.datetime,
    this.notes,
    required this.adjustmentValues,
    this.place,
    this.position,
  }): id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'datetime': datetime.toIso8601String(),
    'notes': notes,
    'adjustmentValues': {
      for (var entry in adjustmentValues.entries)
        entry.key.id: entry.value,
    },
    'position': position != null ? _locationDataToJson(position!) : null,
    'place': place != null ? _placemarkToJson(place!) : null,
  };

  factory Setting.fromJson(Map<String, dynamic> json, List<Adjustment> allAdjustments) {
    final adjustmentIDValues = json['adjustmentValues'] as Map<String, dynamic>? ?? {};

    final Map<Adjustment, dynamic> adjustmentValues = {};
    for (var entry in adjustmentIDValues.entries) {
      final adjustment = allAdjustments.firstWhere(
        (a) => a.id == entry.key,
        orElse: () => throw Exception('Adjustment with id ${entry.key} not found'),
      );
      adjustmentValues[adjustment] = entry.value;
    }

    return Setting(
      id: json['id'],
      name: json['name'],
      datetime: DateTime.parse(json['datetime']),
      notes: json['notes'] != null ? json['notes'] as String : null,
      adjustmentValues: adjustmentValues,
      position: json['position'] != null ? _locationDataFromJson(json['position']) : null,
      place: json['place'] != null ? _placemarkFromJson(json['place']) : null,
    );
  }

  static Map<String, dynamic> _locationDataToJson(LocationData data) => {
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

  static LocationData _locationDataFromJson(Map<String, dynamic> json) {
    return LocationData.fromMap({
      'latitude': json['latitude'],
      'longitude': json['longitude'],
      'altitude': json['altitude'],
      'accuracy': json['accuracy'],
      'heading': json['heading'],
      'speed': json['speed'],
      'speed_accuracy': json['speedAccuracy'], // Note: key expected by LocationData.fromMap
      'time': json['time'] != null ? DateTime.parse(json['time']).millisecondsSinceEpoch.toDouble() : null,
    });
  }

  static Map<String, dynamic> _placemarkToJson(geo.Placemark place) => {
    'name': place.name,
    'thoroughfare': place.thoroughfare,
    'subThoroughfare': place.subThoroughfare,
    'locality': place.locality,
    'subLocality': place.subLocality,
    'administrativeArea': place.administrativeArea,
    'subAdministrativeArea': place.subAdministrativeArea,
    'postalCode': place.postalCode,
    'country': place.country,
    'isoCountryCode': place.isoCountryCode,
  };

  static geo.Placemark _placemarkFromJson(Map<String, dynamic> json) {
    return geo.Placemark(
      name: json['name'],
      thoroughfare: json['thoroughfare'],
      subThoroughfare: json['subThoroughfare'],
      locality: json['locality'],
      subLocality: json['subLocality'],
      administrativeArea: json['administrativeArea'],
      subAdministrativeArea: json['subAdministrativeArea'],
      postalCode: json['postalCode'],
      country: json['country'],
      isoCountryCode: json['isoCountryCode'],
    );
  }
}
