import 'package:bike_setup_tracker/models/context/context_place.dart';
import 'package:bike_setup_tracker/models/context/context_position.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:location/location.dart';
import 'package:uuid/uuid.dart';
import 'context/context_weather.dart';
import 'setup.dart';

class RatingEntry {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String? name;
  final String bike;
  final String setupId;
  final DateTime dateTimeUTC;
  final DateTime dateTimeLocal;
  final String? notes;

  final Map<String, dynamic> metricValues;

  final LocationData? position;
  final geo.Placemark? place;
  final ContextWeather? weather;

  static const IconData iconData = Icons.star_rate;

  static const String namePlaceholder = 'Unnamed Rating';
  String get displayName => name ?? namePlaceholder;

  RatingEntry({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    this.name,
    required this.bike,
    required this.setupId,
    required DateTime dateTimeUTC,
    required this.dateTimeLocal,
    this.notes,
    Map<String, dynamic>? metricValues,
    this.position,
    this.place,
    this.weather,
  })  : id = id ?? const Uuid().v4(),
        isDeleted = isDeleted ?? false,
        dateTimeUTC = dateTimeUTC.toUtc(),
        lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc(),
        metricValues = metricValues ?? {};

  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'isDeleted': isDeleted,
    'lastModified': lastModified.toUtc().toIso8601String(),
    'name': name,
    'bike': bike,
    'setupId': setupId,
    'dateTimeUTC': dateTimeUTC.toUtc().toIso8601String(),
    'dateTimeLocal': dateTimeLocal.toIso8601String(),
    'notes': notes,
    'metricValues': Setup.adjustmentValuesToJson(metricValues),
    'position': position != null ? ContextPosition.toJson(position!) : null,
    'place': place != null ? ContextPlace.toJson(place!) : null,
    'weather': weather?.toJson(),
  };

  factory RatingEntry.fromJson({required Map<String, dynamic> json}) {
    final int? version = json['version'];
    switch (version) {
      case null || 1:
        return RatingEntry(
          id: json['id'],
          isDeleted: json['isDeleted'],
          lastModified: DateTime.tryParse(json['lastModified'] ?? ''),
          name: json['name'] as String?,
          bike: json['bike'],
          setupId: json['setupId'] as String,
          dateTimeUTC: DateTime.parse(json['dateTimeUTC']).toUtc(),
          dateTimeLocal: (DateTime.tryParse(json['dateTimeLocal'] ?? '') ??
                  DateTime.parse(json['dateTimeUTC']))
              .copyWith(isUtc: false),
          notes: json['notes'] as String?,
          metricValues: Setup.adjustmentValuesFromJson(
              (json['metricValues']) as Map<String, dynamic>? ?? {}),
          position: json['position'] != null ? ContextPosition.fromJson(json['position']) : null,
          place: json['place'] != null ? ContextPlace.fromJson(json['place']) : null,
          weather: json['weather'] != null ? ContextWeather.fromJson(json['weather']) : null,
        );
      default:
        throw Exception('Json Version $version of RatingEntry incompatible.');
    }
  }

  RatingEntry deepCopy() {
    final now = DateTime.now();
    return RatingEntry(
      name: name,
      bike: bike,
      setupId: setupId,
      dateTimeUTC: now.toUtc(),
      dateTimeLocal: now,
      notes: notes,
      metricValues: Map.from(metricValues),
      position: null,
      place: null,
      weather: null,
    );
  }

  RatingEntry copyWith({
    Object? id = const _Sentinel(),
    Object? isDeleted = const _Sentinel(),
    Object? lastModified = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? bike = const _Sentinel(),
    Object? setupId = const _Sentinel(),
    Object? dateTimeUTC = const _Sentinel(),
    Object? dateTimeLocal = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? metricValues = const _Sentinel(),
    Object? position = const _Sentinel(),
    Object? place = const _Sentinel(),
    Object? weather = const _Sentinel(),
  }) {
    return RatingEntry(
      id: id is _Sentinel ? this.id : (id as String?),
      isDeleted: isDeleted is _Sentinel ? this.isDeleted : (isDeleted as bool?),
      lastModified: lastModified is _Sentinel 
          ? this.lastModified 
          : (lastModified as DateTime?),
      name: name is _Sentinel ? this.name : (name as String?),
      bike: bike is _Sentinel ? this.bike : (bike as String),
      setupId: setupId is _Sentinel ? this.setupId : (setupId as String),
      dateTimeUTC: dateTimeUTC is _Sentinel ? this.dateTimeUTC : (dateTimeUTC as DateTime),
      dateTimeLocal: dateTimeLocal is _Sentinel 
          ? this.dateTimeLocal 
          : (dateTimeLocal as DateTime),
      notes: notes is _Sentinel ? this.notes : (notes as String?),
      metricValues: metricValues is _Sentinel
          ? this.metricValues
          : (metricValues as Map<String, dynamic>),
      position: position is _Sentinel ? this.position : (position as LocationData?),
      place: place is _Sentinel ? this.place : (place as geo.Placemark?),
      weather: weather is _Sentinel ? this.weather : (weather as ContextWeather?),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RatingEntry &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        isDeleted == other.isDeleted &&
        lastModified == other.lastModified &&
        name == other.name &&
        bike == other.bike &&
        setupId == other.setupId &&
        dateTimeUTC == other.dateTimeUTC &&
        dateTimeLocal == other.dateTimeLocal &&
        notes == other.notes &&
        mapEquals(metricValues, other.metricValues) &&
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
      bike,
      setupId,
      dateTimeUTC,
      dateTimeLocal,
      notes,
      Object.hashAll(metricValues.entries),
      position,
      place,
      weather,
    ]);
  }
}

class _Sentinel {
  const _Sentinel();
}
