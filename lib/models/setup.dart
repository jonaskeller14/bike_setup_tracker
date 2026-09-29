import 'dart:convert';

import 'package:collection/collection.dart' show MapEquality;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:uuid/uuid.dart';

import 'adjustment/adjustment.dart';
import 'attachment.dart';
import 'context/context_place.dart';
import 'context/context_position.dart';
import 'context/context_weather.dart';

class Setup {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String? name;
  final bool isBookmarked;
  final DateTime datetime;  // UTC
  final DateTime datetimeLocal;
  final String? notes;
  final Set<String> tags;
  final String bike;
  final String? person;
  final Map<String, AdjustmentValue> bikeAdjustmentValues;
  final Map<String, AdjustmentValue> personAdjustmentValues;
  final ContextPosition? position;
  final geo.Placemark? place;
  final ContextWeather? weather;
  final List<Attachment> attachments;

  // Transient values resolved at runtime
  bool isCurrent = false;
  Map<String, AdjustmentValue> previousBikeAdjustmentValues = {};
  Map<String, AdjustmentValue> previousPersonAdjustmentValues = {};

  static const IconData iconData = Icons.tune;

  static const String namePlaceholder = 'Unnamed Setup';
  String get displayName => name ?? namePlaceholder;

  Setup({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    this.name,
    bool? isBookmarked,
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
    List<Attachment>? attachments,
  }) : id = id ?? const Uuid().v4(),
       attachments = attachments ?? const [],
       isDeleted = isDeleted ?? false,
       isBookmarked = isBookmarked ?? false,
       datetime = datetime.toUtc(),
       lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
    'version': 8,
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'isBookmarked': isBookmarked,
    'datetime': datetime.toUtc().toIso8601String(),
    'datetimeLocal': datetimeLocal.toIso8601String(),
    'notes': notes,
    'tags': tags.toList(),
    'bike': bike,
    'person': person,
    'bikeAdjustmentValues': adjustmentValuesToJson(bikeAdjustmentValues),
    'personAdjustmentValues': adjustmentValuesToJson(personAdjustmentValues),
    'position': position?.toJson(),
    'place': place != null ? ContextPlace.toJson(place!) : null,
    'weather': weather?.toJson(),
    'attachments': attachments.map((a) => a.toJson()).toList(),
  };

  factory Setup.fromJson({
    required Map<String, dynamic> json,
    required Map<String, AdjustmentType> adjustmentTypes,
  }) {
    final int? version = json["version"] as int?;
    switch (version) {
      case null || 1 || 2 || 3 || 4 || 5 || 6 || 7 || 8:
        return Setup(
          id: json['id'] as String?,
          isDeleted: json["isDeleted"] as bool?,
          lastModified: DateTime.tryParse(json["lastModified"] as String? ?? ""),
          name: json['name'] as String?,
          isBookmarked: json['isBookmarked'] as bool?,
          datetime: DateTime.parse(json['datetime'] as String).toUtc(),
          datetimeLocal: (DateTime.tryParse(json['datetimeLocal'] as String? ?? '') ?? DateTime.parse(json['datetime'] as String)).copyWith(isUtc: false),
          notes: json['notes'] != null ? json['notes'] as String : null,
          tags: (json['tags'] as List?)?.map((item) => item as String).toSet() ?? <String>{},
          bike: json['bike'] as String,
          person: json['person'] as String?,
          bikeAdjustmentValues: adjustmentValuesFromJson((json['bikeAdjustmentValues'] ?? json['adjustmentValues']) as Map<String, dynamic>? ?? {}, adjustmentTypes: adjustmentTypes),
          personAdjustmentValues: adjustmentValuesFromJson((json['personAdjustmentValues']) as Map<String, dynamic>? ?? {}, adjustmentTypes: adjustmentTypes),
          position: json['position'] != null ? ContextPosition.fromJson(json['position'] as Map<String, dynamic>) : null,
          place: json['place'] != null ? ContextPlace.fromJson(json['place'] as Map<String, dynamic>) : null,
          weather: json['weather'] != null ? ContextWeather.fromJson(json['weather'] as Map<String, dynamic>) : null,
          attachments: (json['attachments'] as List?)?.map((e) => Attachment.fromJson(e as Map<String, dynamic>)).toList() ?? <Attachment>[],
        );
      default: throw Exception("Json Version $version of Setup incompatible.");
    }
  }

  /// Durations are exported as `Duration.toString()`; unresolved values as
  /// their decoded raw JSON.
  static Map<String, dynamic> adjustmentValuesToJson(Map<String, AdjustmentValue> adjustmentValues) {
    return adjustmentValues.map((key, value) => MapEntry(key, switch (value) {
      BooleanValue(:final value) => value,
      StepValue(:final value) => value,
      NumericalValue(:final value) => value,
      TextValue(:final value) => value,
      CategoricalValue(:final options) => options,
      DurationValue(:final value) => value.toString(),
      UnresolvedValue(:final raw) => _decodeRawJson(raw),
    }));
  }

  static Object? _decodeRawJson(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return raw;
    }
  }

  /// [adjustmentTypes] maps adjustment ids from the same backup to their type.
  /// Values of unknown ids, and values whose JSON shape does not fit their
  /// type, are kept as [UnresolvedValue]s. Absent values are dropped.
  static Map<String, AdjustmentValue> adjustmentValuesFromJson(
    Map<String, dynamic> adjustmentValues, {
    Map<String, AdjustmentType> adjustmentTypes = const {},
  }) {
    return {
      for (final MapEntry(:key, :value) in adjustmentValues.entries)
        key: ?switch (adjustmentTypes[key]) {
          final type? => _adjustmentValueFromJson(value, type),
          null => value == '' ? null : UnresolvedValue.orNull(jsonEncode(value)),
        },
    };
  }

  /// Decodes the [UnresolvedValue]s of ids in [adjustmentTypes] as if they had
  /// been imported with their type; other values are returned unchanged.
  static Map<String, AdjustmentValue> resolveAdjustmentValues(
    Map<String, AdjustmentValue> adjustmentValues,
    Map<String, AdjustmentType> adjustmentTypes,
  ) {
    return {
      for (final MapEntry(:key, :value) in adjustmentValues.entries)
        key: ?switch ((value, adjustmentTypes[key])) {
          (UnresolvedValue(:final raw), final type?) => _adjustmentValueFromJson(_decodeRawJson(raw), type),
          _ => value,
        },
    };
  }

  static AdjustmentValue? _adjustmentValueFromJson(dynamic value, AdjustmentType type) {
    return switch ((type, value)) {
      (_, null) => null,
      (_, String() && '') => null,
      (AdjustmentType.boolean, final bool value) => BooleanValue(value),
      (AdjustmentType.step, final num value) => StepValue(value.toInt()),
      (AdjustmentType.numerical, final num value) => NumericalValue(value.toDouble()),
      (AdjustmentType.text, final String value) => TextValue.orNull(value),
      (AdjustmentType.categorical, final List<dynamic> value) => CategoricalValue(value.map((e) => e.toString()).toList()),
      // Legacy single-select categorical.
      (AdjustmentType.categorical, final String value) => CategoricalValue([value]),
      (AdjustmentType.duration, final String value) => switch (DurationAdjustment.tryParseDurationString(value)) {
        final duration? => DurationValue(duration),
        null => null,
      },
      // Guessing another type from the shape would store a value its own
      // type cannot decode.
      _ => UnresolvedValue(jsonEncode(value)),
    };
  }

  Setup deepCopy() {
    // Used for Setup restore --> Duplication with current Date, remove pos/place/weather.
    // Callers are responsible for copying attachment files via AttachmentStorageService.copyExisting
    // for each attachment in the returned setup's attachments list before persisting.
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
      attachments: List.from(attachments),
    )..previousBikeAdjustmentValues = Map.from(previousBikeAdjustmentValues)
     ..previousPersonAdjustmentValues = Map.from(previousPersonAdjustmentValues);
  }

  Setup copyWith({
    Object? id = const _Sentinel(),
    Object? isDeleted= const _Sentinel(),
    Object? lastModified = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? isBookmarked = const _Sentinel(),
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
    Object? attachments = const _Sentinel(),
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
      isBookmarked: isBookmarked is _Sentinel
          ? this.isBookmarked
          : (isBookmarked as bool?),
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
          : (bikeAdjustmentValues as Map<String, AdjustmentValue>),
      personAdjustmentValues: personAdjustmentValues is _Sentinel
          ? this.personAdjustmentValues
          : (personAdjustmentValues as Map<String, AdjustmentValue>),
      position: position is _Sentinel
          ? this.position
          : (position as ContextPosition?),
      place: place is _Sentinel
          ? this.place
          : (place as geo.Placemark?),
      weather: weather is _Sentinel
          ? this.weather
          : (weather as ContextWeather?),
      attachments: attachments is _Sentinel
          ? this.attachments
          : (attachments as List<Attachment>),
    )..isCurrent = isCurrent is _Sentinel
          ? this.isCurrent
          : (isCurrent as bool)
     ..previousBikeAdjustmentValues = previousBikeAdjustmentValues is _Sentinel
          ? this.previousBikeAdjustmentValues
          : (previousBikeAdjustmentValues as Map<String, AdjustmentValue>)
     ..previousPersonAdjustmentValues = previousPersonAdjustmentValues is _Sentinel
          ? this.previousPersonAdjustmentValues
          : (previousPersonAdjustmentValues as Map<String, AdjustmentValue>);
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
        isBookmarked == other.isBookmarked &&
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
        listEquals(attachments, other.attachments);
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      isDeleted,
      lastModified,
      name,
      isBookmarked,
      datetime,
      datetimeLocal,
      notes,
      Object.hashAll(tags),
      bike,
      person,
      const MapEquality<String, AdjustmentValue>().hash(bikeAdjustmentValues),
      const MapEquality<String, AdjustmentValue>().hash(personAdjustmentValues),
      position,
      place,
      weather,
      Object.hashAll(attachments),
    ]);
  }
}

class _Sentinel {
  const _Sentinel();
}
