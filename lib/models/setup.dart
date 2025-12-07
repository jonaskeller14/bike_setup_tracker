import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import "adjustment.dart";
import 'weather.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;

class Setup {
  final String id;
  bool isDeleted;
  DateTime lastModified;
  final String name;
  final DateTime datetime;
  final String? notes;
  final String bike;
  final Map<Adjustment, dynamic> adjustmentValues;
  final LocationData? position;
  final geo.Placemark? place;
  final Weather? weather;
  Setup? previousSetup;
  bool isCurrent;

  Setup({
    String? id,
    bool? isDeleted, 
    DateTime? lastModified,
    required this.name,
    required this.datetime,
    this.notes,
    required this.bike,
    required this.adjustmentValues,
    this.place,
    this.position,
    this.weather,
    this.previousSetup,
    required this.isCurrent,
  }) : id = id ?? const Uuid().v4(),
       isDeleted = isDeleted ?? false,
       lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toIso8601String(),
    'name': name,
    'datetime': datetime.toIso8601String(),
    'notes': notes,
    'bike': bike,
    'adjustmentValues': {
      for (var entry in adjustmentValues.entries)
        entry.key.id: entry.value,
    },
    'position': position != null ? locationDataToJson(position!) : null,
    'place': place != null ? _placemarkToJson(place!) : null,
    'weather': weather?.toJson(),
    'previousSetup': previousSetup?.id,
    'isCurrent': isCurrent,
  };

  factory Setup.fromJson({required Map<String, dynamic> json, required List<Adjustment> allAdjustments}) {
    final adjustmentIDValues = json['adjustmentValues'] as Map<String, dynamic>? ?? {};

    final Map<Adjustment, dynamic> adjustmentValues = {};
    for (var entry in adjustmentIDValues.entries) {
      try {
        final adjustment = allAdjustments.firstWhere(
          (a) => a.id == entry.key,
        );
        adjustmentValues[adjustment] = entry.value;
      } on StateError {
        debugPrint('Adjustment with id ${entry.key} not found');
        continue;
      }
    }

    return Setup(
      id: json['id'],
      isDeleted: json["isDeleted"],
      lastModified: DateTime.tryParse(json["lastModified"] ?? ""),
      name: json['name'],
      datetime: DateTime.parse(json['datetime']),
      notes: json['notes'] != null ? json['notes'] as String : null,
      bike: json['bike'],
      adjustmentValues: adjustmentValues,
      position: json['position'] != null ? _locationDataFromJson(json['position']) : null,
      place: json['place'] != null ? _placemarkFromJson(json['place']) : null,
      weather: json['weather'] != null ? Weather.fromJson(json['weather']) : null,
      previousSetup: null, // linked later
      isCurrent: json['isCurrent'] ?? false,
    );
  }

  static Map<String, dynamic> locationDataToJson(LocationData data) => {
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

  static double convertAltitudeToMeters(double alt, String currentUnit) {
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

  static double convertAltitudeFromMeters(double altM, String targetUnit) {
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
