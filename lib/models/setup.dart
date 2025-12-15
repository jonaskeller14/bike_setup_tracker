import 'package:uuid/uuid.dart';
import 'weather.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'adjustment/adjustment.dart';

class Setup {
  final String id;
  bool isDeleted;
  DateTime lastModified;
  final String name;
  final DateTime datetime;
  final String? notes;
  final String bike;
  final String? person;
  final Map<String, dynamic> bikeAdjustmentValues;
  final Map<String, dynamic> personAdjustmentValues;
  final Map<String, dynamic> ratingAdjustmentValues;
  final LocationData? position;
  final geo.Placemark? place;
  final Weather? weather;

  Setup? previousBikeSetup;
  Setup? previousPersonSetup;
  bool isCurrent;

  Setup({
    String? id,
    bool? isDeleted, 
    DateTime? lastModified,
    required this.name,
    required this.datetime,
    this.notes,
    required this.bike,
    required this.person,
    required this.bikeAdjustmentValues,
    required this.personAdjustmentValues,
    required this.ratingAdjustmentValues,
    this.place,
    this.position,
    this.weather,
    this.previousBikeSetup,
    this.previousPersonSetup,
    required this.isCurrent,
  }) : id = id ?? const Uuid().v4(),
       isDeleted = isDeleted ?? false,
       lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'version': 2,
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toIso8601String(),
    'name': name,
    'datetime': datetime.toIso8601String(),
    'notes': notes,
    'bike': bike,
    'person': person,
    'bikeAdjustmentValues': adjustmentValuesToJson(bikeAdjustmentValues),
    'personAdjustmentValues': adjustmentValuesToJson(personAdjustmentValues),
    'ratingAdjustmentValues': adjustmentValuesToJson(ratingAdjustmentValues),
    'position': position != null ? locationDataToJson(position!) : null,
    'place': place != null ? _placemarkToJson(place!) : null,
    'weather': weather?.toJson(),
    'previousBikeSetup': previousBikeSetup?.id,
    'previousPersonSetup': previousPersonSetup?.id,
    'isCurrent': isCurrent,
  };

  factory Setup.fromJson({required Map<String, dynamic> json}) {
    final int? version = json["version"];
    switch (version) {
      case null:
        return Setup(
          id: json['id'],
          isDeleted: json["isDeleted"],
          lastModified: DateTime.tryParse(json["lastModified"] ?? ""),
          name: json['name'],
          datetime: DateTime.parse(json['datetime']),
          notes: json['notes'] != null ? json['notes'] as String : null,
          bike: json['bike'],
          person: json['person'],  // = null
          bikeAdjustmentValues: adjustmentValuesFromJson((json['bikeAdjustmentValues'] ?? json['adjustmentValues']) as Map<String, dynamic>? ?? {}),
          personAdjustmentValues: adjustmentValuesFromJson((json['personAdjustmentValues']) as Map<String, dynamic>? ?? {}),  // = {}
          ratingAdjustmentValues: adjustmentValuesFromJson((json['ratingAdjustmentValues']) as Map<String, dynamic>? ?? {}),  // = {}
          position: json['position'] != null ? _locationDataFromJson(json['position']) : null,
          place: json['place'] != null ? _placemarkFromJson(json['place']) : null,
          weather: json['weather'] != null ? Weather.fromJson(json['weather']) : null,
          previousBikeSetup: null, // linked later
          previousPersonSetup: null, // linked later
          isCurrent: json['isCurrent'] ?? false, //reset later
        );
      case 1:
        return Setup(
          id: json['id'],
          isDeleted: json["isDeleted"],
          lastModified: DateTime.tryParse(json["lastModified"] ?? ""),
          name: json['name'],
          datetime: DateTime.parse(json['datetime']),
          notes: json['notes'] != null ? json['notes'] as String : null,
          bike: json['bike'],
          person: json['person'],
          bikeAdjustmentValues: adjustmentValuesFromJson((json['bikeAdjustmentValues'] ?? json['adjustmentValues']) as Map<String, dynamic>? ?? {}),
          personAdjustmentValues: adjustmentValuesFromJson((json['personAdjustmentValues']) as Map<String, dynamic>? ?? {}),
          ratingAdjustmentValues: adjustmentValuesFromJson((json['ratingAdjustmentValues']) as Map<String, dynamic>? ?? {}),  // = {}
          position: json['position'] != null ? _locationDataFromJson(json['position']) : null,
          place: json['place'] != null ? _placemarkFromJson(json['place']) : null,
          weather: json['weather'] != null ? Weather.fromJson(json['weather']) : null,
          previousBikeSetup: null, // linked later
          previousPersonSetup: null, // linked later
          isCurrent: json['isCurrent'] ?? false, //reset later
        );
      case 2:
        return Setup(
          id: json['id'],
          isDeleted: json["isDeleted"],
          lastModified: DateTime.tryParse(json["lastModified"] ?? ""),
          name: json['name'],
          datetime: DateTime.parse(json['datetime']),
          notes: json['notes'] != null ? json['notes'] as String : null,
          bike: json['bike'],
          person: json['person'],
          bikeAdjustmentValues: adjustmentValuesFromJson((json['bikeAdjustmentValues'] ?? json['adjustmentValues']) as Map<String, dynamic>? ?? {}),
          personAdjustmentValues: adjustmentValuesFromJson((json['personAdjustmentValues']) as Map<String, dynamic>? ?? {}),
          ratingAdjustmentValues: adjustmentValuesFromJson((json['ratingAdjustmentValues']) as Map<String, dynamic>? ?? {}),
          position: json['position'] != null ? _locationDataFromJson(json['position']) : null,
          place: json['place'] != null ? _placemarkFromJson(json['place']) : null,
          weather: json['weather'] != null ? Weather.fromJson(json['weather']) : null,
          previousBikeSetup: null, // linked later
          previousPersonSetup: null, // linked later
          isCurrent: json['isCurrent'] ?? false, //reset later
        );
      default: throw Exception("Json Version $version of Setup incompatible.");
    }
  }

  static Map<String, dynamic> adjustmentValuesToJson(Map<String, dynamic> adjustmentValues) {
    return adjustmentValues.map((key, value) {
      if (value is Duration) {
        return MapEntry(key, DurationAdjustment.toIso8601String(value));
      }
      return MapEntry(key, value);
    });
  }

  static Map<String, dynamic> adjustmentValuesFromJson(Map<String, dynamic> adjustmentValues) {
    return adjustmentValues.map((key, value) {
      //FIXME: Critical Error if TextAdjustment value equals ISO-Format
      if (value is String) {
        final duration = DurationAdjustment.tryParseIso8601String(value); 
        if (duration != null) {
          return MapEntry(key, duration);
        }
      }
      return MapEntry(key, value);
    });
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
    final int? version = json["version"];
    switch (version) {
      case null:
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
      default: throw Exception("Json Version $version of Location incompatible."); 
    } 
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
    final int? version = json["version"];
    switch (version) {
      case null:
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
      default: throw Exception("Json Version $version of Place incompatible.");
    }
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
