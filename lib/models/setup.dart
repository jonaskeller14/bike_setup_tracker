import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:location/location.dart';
import 'package:uuid/uuid.dart';
import 'adjustment/adjustment.dart';
import 'context/context_place.dart';
import 'context/context_position.dart';
import 'context/context_weather.dart';

class Setup {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String name;
  final DateTime datetime;  // UTC
  final DateTime datetimeLocal;
  final String? notes;
  final Set<String> tags;
  final String bike;
  final String? person;
  final Map<String, dynamic> bikeAdjustmentValues;
  final Map<String, dynamic> personAdjustmentValues;
  final Map<String, dynamic> ratingAdjustmentValues;
  final LocationData? position;
  final geo.Placemark? place;
  final ContextWeather? weather;

  // Transient values resolved at runtime
  bool isCurrent = false;
  Map<String, dynamic> previousBikeAdjustmentValues = {};
  Map<String, dynamic> previousPersonAdjustmentValues = {};
  Map<String, dynamic> previousRatingAdjustmentValues = {};

  static const IconData iconData = Icons.tune;

  Setup({
    String? id,
    bool? isDeleted, 
    DateTime? lastModified,
    required this.name,
    required DateTime datetime,
    required this.datetimeLocal,
    this.notes,
    required this.tags,
    required this.bike,
    required this.person,
    required this.bikeAdjustmentValues,
    required this.personAdjustmentValues,
    required this.ratingAdjustmentValues,
    this.place,
    this.position,
    this.weather,
  }) : id = id ?? const Uuid().v4(),
       isDeleted = isDeleted ?? false,
       datetime = datetime.toUtc(),
       lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
    'version': 4,
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'datetime': datetime.toUtc().toIso8601String(),
    'datetimeLocal': datetimeLocal.toIso8601String(),
    'notes': notes,
    'tags': tags.toList(),
    'bike': bike,
    'person': person,
    'bikeAdjustmentValues': adjustmentValuesToJson(bikeAdjustmentValues),
    'personAdjustmentValues': adjustmentValuesToJson(personAdjustmentValues),
    'ratingAdjustmentValues': adjustmentValuesToJson(ratingAdjustmentValues),
    'position': position != null ? ContextPosition.toJson(position!) : null,
    'place': place != null ? ContextPlace.toJson(place!) : null,
    'weather': weather?.toJson(),
  };

  factory Setup.fromJson({required Map<String, dynamic> json}) {
    final int? version = json["version"];
    switch (version) {
      case null || 1 || 2 || 3 || 4:
        return Setup(
          id: json['id'],
          isDeleted: json["isDeleted"],
          lastModified: DateTime.tryParse(json["lastModified"] ?? ""),
          name: json['name'],
          datetime: DateTime.parse(json['datetime']).toUtc(),
          datetimeLocal: (DateTime.tryParse(json['datetimeLocal'] ?? '') ?? DateTime.parse(json['datetime'])).copyWith(isUtc: false),
          notes: json['notes'] != null ? json['notes'] as String : null,
          tags: (json['tags'] as List?)?.map((item) => item as String).toSet() ?? <String>{},
          bike: json['bike'],
          person: json['person'],
          bikeAdjustmentValues: adjustmentValuesFromJson((json['bikeAdjustmentValues'] ?? json['adjustmentValues']) as Map<String, dynamic>? ?? {}),
          personAdjustmentValues: adjustmentValuesFromJson((json['personAdjustmentValues']) as Map<String, dynamic>? ?? {}),
          ratingAdjustmentValues: adjustmentValuesFromJson((json['ratingAdjustmentValues']) as Map<String, dynamic>? ?? {}),
          position: json['position'] != null ? ContextPosition.fromJson(json['position']) : null,
          place: json['place'] != null ? ContextPlace.fromJson(json['place']) : null,
          weather: json['weather'] != null ? ContextWeather.fromJson(json['weather']) : null,
        );
      default: throw Exception("Json Version $version of Setup incompatible.");
    }
  }

  static Map<String, dynamic> adjustmentValuesToJson(Map<String, dynamic> adjustmentValues) {
    return adjustmentValues.map((key, value) {
      switch (value) {
        case Duration(): return MapEntry(key, value.toString());
        default: return MapEntry(key, value);
      }
    });
  }

  static Map<String, dynamic> adjustmentValuesFromJson(Map<String, dynamic> adjustmentValues) {
    return adjustmentValues.map((key, value) {
      switch (value) {
        case String():
          final Duration? duration = DurationAdjustment.tryParseDurationString(value);
          if (duration != null) {
            return MapEntry(key, duration);
          } else if (value.isEmpty) {
            return MapEntry(key, null);
          } else {
            return MapEntry(key, value);
          } // TextAdjustment --> String?, DurationAdjustment --> Duration
        default: return MapEntry(key, value);
      }
    });
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

  Setup deepCopy() {
    // Used for Setup restore --> Duplication with current Date, remove pos/place/weather
    final now = DateTime.now();

    return Setup(
      name: name,
      notes: notes,
      datetime: now.toUtc(),
      datetimeLocal: now,
      position: null,
      place: null,
      weather: null,
      tags: tags.toSet(),
      bike: bike,
      person: person,
      bikeAdjustmentValues: Map.from(bikeAdjustmentValues),
      personAdjustmentValues: Map.from(personAdjustmentValues),
      ratingAdjustmentValues: {},
    )..previousBikeAdjustmentValues = Map.from(previousBikeAdjustmentValues)
     ..previousPersonAdjustmentValues = Map.from(previousPersonAdjustmentValues)
     ..previousRatingAdjustmentValues = Map.from(previousRatingAdjustmentValues);
  }

  Setup copyWith({
    Object? id = const _Sentinel(),
    Object? isDeleted= const _Sentinel(),
    Object? lastModified = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? datetime = const _Sentinel(),
    Object? datetimeLocal = const _Sentinel(),
    Object? tags = const _Sentinel(),
    Object? bike = const _Sentinel(),
    Object? person = const _Sentinel(),
    Object? bikeAdjustmentValues = const _Sentinel(),
    Object? personAdjustmentValues = const _Sentinel(),
    Object? ratingAdjustmentValues = const _Sentinel(),
    Object? position = const _Sentinel(),
    Object? place = const _Sentinel(),
    Object? weather = const _Sentinel(),
    Object? isCurrent = const _Sentinel(),
    Object? previousBikeAdjustmentValues = const _Sentinel(),
    Object? previousPersonAdjustmentValues = const _Sentinel(),
    Object? previousRatingAdjustmentValues = const _Sentinel(),
  }) {
    return Setup(
      id: id is _Sentinel
          ? this.id
          : (id as String?),
      isDeleted: isDeleted is _Sentinel
          ? this.isDeleted
          : (isDeleted as bool?),
      lastModified: lastModified is _Sentinel
          ? this.lastModified
          : (lastModified as DateTime?),
      name: name is _Sentinel
          ? this.name
          : (name as String), 
      notes: notes is _Sentinel
          ? this.notes
          : (notes as String?),
      datetime: datetime is _Sentinel
          ? this.datetime
          : (datetime as DateTime), 
      datetimeLocal: datetimeLocal is _Sentinel
          ? this.datetimeLocal
          : (datetimeLocal as DateTime), 
      tags: tags is _Sentinel
          ? this.tags
          : (tags as Set<String>), 
      bike: bike is _Sentinel
          ? this.bike
          : (bike as String), 
      person: person is _Sentinel
          ? this.person
          : (person as String?),
      bikeAdjustmentValues: bikeAdjustmentValues is _Sentinel
          ? this.bikeAdjustmentValues
          : (bikeAdjustmentValues as Map<String, dynamic>), 
      personAdjustmentValues: personAdjustmentValues is _Sentinel
          ? this.personAdjustmentValues
          : (personAdjustmentValues as Map<String, dynamic>), 
      ratingAdjustmentValues: ratingAdjustmentValues is _Sentinel
          ? this.ratingAdjustmentValues
          : (ratingAdjustmentValues as Map<String, dynamic>),
      position: position is _Sentinel
          ? this.position
          : (position as LocationData?),
      place: place is _Sentinel
          ? this.place
          : (place as geo.Placemark?),
      weather: weather is _Sentinel
          ? this.weather
          : (weather as ContextWeather?),
    )..isCurrent = isCurrent is _Sentinel
          ? this.isCurrent
          : (isCurrent as bool)
     ..previousBikeAdjustmentValues = previousBikeAdjustmentValues is _Sentinel
          ? this.previousBikeAdjustmentValues
          : (previousBikeAdjustmentValues as Map<String, dynamic>)
     ..previousPersonAdjustmentValues = previousPersonAdjustmentValues is _Sentinel
          ? this.previousPersonAdjustmentValues
          : (previousPersonAdjustmentValues as Map<String, dynamic>)
     ..previousRatingAdjustmentValues = previousRatingAdjustmentValues is _Sentinel
          ? this.previousRatingAdjustmentValues
          : (previousRatingAdjustmentValues as Map<String, dynamic>);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Setup &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        isDeleted == other.isDeleted &&
        lastModified == other.lastModified &&
        name == other.name &&
        datetime == other.datetime &&
        datetimeLocal == other.datetimeLocal &&
        notes == other.notes &&
        setEquals(tags, other.tags) &&
        bike == other.bike &&
        person == other.person &&
        mapEquals(bikeAdjustmentValues, other.bikeAdjustmentValues) &&
        mapEquals(personAdjustmentValues, other.personAdjustmentValues) &&
        mapEquals(ratingAdjustmentValues, other.ratingAdjustmentValues) &&
        ContextPosition.equal(position, other.position) &&
        ContextPlace.equal(place, other.place) &&
        weather == other.weather;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      isDeleted,
      lastModified,
      name,
      datetime,
      datetimeLocal,
      notes,
      Object.hashAll(tags),
      bike,
      person,
      Object.hashAll(bikeAdjustmentValues.entries),
      Object.hashAll(personAdjustmentValues.entries),
      Object.hashAll(ratingAdjustmentValues.entries),
      position,
      place,
      weather,
    ]);
  }
}

class _Sentinel {
  const _Sentinel();
}
