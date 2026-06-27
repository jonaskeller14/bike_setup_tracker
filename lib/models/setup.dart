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
  final String? name;
  final DateTime datetime;  // UTC
  final DateTime datetimeLocal;
  final String? notes;
  final Set<String> tags;
  final String bike;
  final String? person;
  final Map<String, dynamic> bikeAdjustmentValues;
  final Map<String, dynamic> personAdjustmentValues;
  final LocationData? position;
  final geo.Placemark? place;
  final ContextWeather? weather;
  final List<String> images;

  // Transient values resolved at runtime
  bool isCurrent = false;
  Map<String, dynamic> previousBikeAdjustmentValues = {};
  Map<String, dynamic> previousPersonAdjustmentValues = {};

  static const IconData iconData = Icons.tune;

  static const String namePlaceholder = 'Unnamed Setup';
  String get displayName => name ?? namePlaceholder;

  Setup({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    this.name,
    required DateTime datetime,
    required this.datetimeLocal,
    this.notes,
    required this.tags,
    required this.bike,
    required this.person,
    required this.bikeAdjustmentValues,
    required this.personAdjustmentValues,
    this.place,
    this.position,
    this.weather,
    List<String>? images,
  }) : id = id ?? const Uuid().v4(),
       images = images ?? const [],
       isDeleted = isDeleted ?? false,
       datetime = datetime.toUtc(),
       lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
    'version': 6,
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
    'position': position != null ? ContextPosition.toJson(position!) : null,
    'place': place != null ? ContextPlace.toJson(place!) : null,
    'weather': weather?.toJson(),
    'images': images,
  };

  factory Setup.fromJson({required Map<String, dynamic> json}) {
    final int? version = json["version"];
    switch (version) {
      case null || 1 || 2 || 3 || 4 || 5 || 6:
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
          position: json['position'] != null ? ContextPosition.fromJson(json['position']) : null,
          place: json['place'] != null ? ContextPlace.fromJson(json['place']) : null,
          weather: json['weather'] != null ? ContextWeather.fromJson(json['weather']) : null,
          images: (json['images'] as List?)?.map((e) => e as String).toList() ?? <String>[],
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

  Setup deepCopy() {
    // Used for Setup restore --> Duplication with current Date, remove pos/place/weather.
    // Callers are responsible for copying image files via ImageStorageService.copyExisting
    // for each filename in the returned setup's images list before persisting.
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
      images: List.from(images),
    )..previousBikeAdjustmentValues = Map.from(previousBikeAdjustmentValues)
     ..previousPersonAdjustmentValues = Map.from(previousPersonAdjustmentValues);
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
    Object? position = const _Sentinel(),
    Object? place = const _Sentinel(),
    Object? weather = const _Sentinel(),
    Object? images = const _Sentinel(),
    Object? isCurrent = const _Sentinel(),
    Object? previousBikeAdjustmentValues = const _Sentinel(),
    Object? previousPersonAdjustmentValues = const _Sentinel(),
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
          : (name as String?),
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
      position: position is _Sentinel
          ? this.position
          : (position as LocationData?),
      place: place is _Sentinel
          ? this.place
          : (place as geo.Placemark?),
      weather: weather is _Sentinel
          ? this.weather
          : (weather as ContextWeather?),
      images: images is _Sentinel
          ? this.images
          : (images as List<String>),
    )..isCurrent = isCurrent is _Sentinel
          ? this.isCurrent
          : (isCurrent as bool)
     ..previousBikeAdjustmentValues = previousBikeAdjustmentValues is _Sentinel
          ? this.previousBikeAdjustmentValues
          : (previousBikeAdjustmentValues as Map<String, dynamic>)
     ..previousPersonAdjustmentValues = previousPersonAdjustmentValues is _Sentinel
          ? this.previousPersonAdjustmentValues
          : (previousPersonAdjustmentValues as Map<String, dynamic>);
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
        ContextPosition.equal(position, other.position) &&
        ContextPlace.equal(place, other.place) &&
        weather == other.weather &&
        listEquals(images, other.images);
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
      position,
      place,
      weather,
      Object.hashAll(images),
    ]);
  }
}

class _Sentinel {
  const _Sentinel();
}
