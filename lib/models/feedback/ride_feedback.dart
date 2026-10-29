import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:uuid/uuid.dart';

import '../context/context_place.dart';
import '../context/context_position.dart';
import '../context/context_weather.dart';
import 'custom_issue.dart';
import 'feedback_comparison.dart';
import 'feedback_key.dart';
import 'feedback_observation.dart';

@immutable
class RideFeedback {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String bike;
  final String setupId; // Write-once provenance; display and ranking resolve the setup by time.
  final int? stravaActivityId; // Soft link: the activity may be gone.
  final DateTime dateTimeUTC;
  final DateTime dateTimeLocal;
  final String? notes;
  final ContextPosition? position;
  final geo.Placemark? place;
  final ContextWeather? weather;
  final Set<FeedbackObservation> observations;
  final Set<FeedbackComparison> comparisons;

  static const IconData iconData = Icons.rate_review;

  RideFeedback({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.bike,
    required this.setupId,
    this.stravaActivityId,
    required DateTime dateTimeUTC,
    required this.dateTimeLocal,
    this.notes,
    this.position,
    this.place,
    this.weather,
    Set<FeedbackObservation>? observations,
    Set<FeedbackComparison>? comparisons,
  }) : id = id ?? const Uuid().v4(),
       isDeleted = isDeleted ?? false,
       lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc(),
       dateTimeUTC = dateTimeUTC.toUtc(),
       observations = observations ?? const {},
       comparisons = comparisons ?? const {};

  /// Problems flagged in "Anything stand out?".
  Set<IssueKey> get issues => {
    for (final o in observations)
      if (o.key case final IssueKey key) key,
  };

  /// Flagged custom problems by label, one per slug. A flag without a label
  /// falls back to its slug.
  List<CustomIssue> get customIssues {
    final bySlug = <String, CustomIssue>{};
    for (final o in observations) {
      if (o.key case final CustomIssueKey key) {
        final label = o.textValue?.trim();
        bySlug.putIfAbsent(key.slug, () => CustomIssue(key.slug, label == null || label.isEmpty ? key.slug : label));
      }
    }
    return bySlug.values.sorted(compareCustomIssues);
  }

  bool get nothingStoodOut => observations.any((o) => o.key is NoIssueKey);

  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'isDeleted': isDeleted,
    'lastModified': lastModified.toUtc().toIso8601String(),
    'bike': bike,
    'setupId': setupId,
    'stravaActivityId': stravaActivityId,
    'dateTimeUTC': dateTimeUTC.toUtc().toIso8601String(),
    'dateTimeLocal': dateTimeLocal.toIso8601String(),
    'notes': notes,
    'position': position?.toJson(),
    'place': place != null ? ContextPlace.toJson(place!) : null,
    'weather': weather?.toJson(),
    'observations': observations.map((o) => o.toJson()).toList(),
    'comparisons': comparisons.map((c) => c.toJson()).toList(),
  };

  factory RideFeedback.fromJson(Map<String, dynamic> json) {
    final int? version = json['version'] as int?;
    switch (version) {
      case null || 1:
        return RideFeedback(
          id: json['id'] as String?,
          isDeleted: json['isDeleted'] as bool?,
          lastModified: DateTime.tryParse(json['lastModified'] as String? ?? ''),
          bike: json['bike'] as String,
          setupId: json['setupId'] as String,
          stravaActivityId: (json['stravaActivityId'] as num?)?.toInt(),
          dateTimeUTC: DateTime.parse(json['dateTimeUTC'] as String).toUtc(),
          dateTimeLocal: DateTime.parse(json['dateTimeLocal'] as String),
          notes: json['notes'] as String?,
          position: json['position'] != null
              ? ContextPosition.fromJson(json['position'] as Map<String, dynamic>)
              : null,
          place: json['place'] != null ? ContextPlace.fromJson(json['place'] as Map<String, dynamic>) : null,
          weather: json['weather'] != null ? ContextWeather.fromJson(json['weather'] as Map<String, dynamic>) : null,
          observations: (json['observations'] as List?)
              ?.map((e) => FeedbackObservation.fromJson(e as Map<String, dynamic>))
              .toSet(),
          comparisons: (json['comparisons'] as List?)
              ?.map((e) => FeedbackComparison.fromJson(e as Map<String, dynamic>))
              .toSet(),
        );
      default:
        throw Exception('Json Version $version of RideFeedback incompatible.');
    }
  }

  /// A new feedback dated now, without context or Strava link.
  RideFeedback deepCopy() {
    final now = DateTime.now();
    return RideFeedback(
      bike: bike,
      setupId: setupId,
      dateTimeUTC: now.toUtc(),
      dateTimeLocal: now,
      notes: notes,
      observations: observations.toSet(),
      comparisons: comparisons.toSet(),
    );
  }

  RideFeedback copyWith({
    Object? id = const _Sentinel(),
    Object? isDeleted = const _Sentinel(),
    Object? lastModified = const _Sentinel(),
    Object? bike = const _Sentinel(),
    Object? setupId = const _Sentinel(),
    Object? stravaActivityId = const _Sentinel(),
    Object? dateTimeUTC = const _Sentinel(),
    Object? dateTimeLocal = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? position = const _Sentinel(),
    Object? place = const _Sentinel(),
    Object? weather = const _Sentinel(),
    Object? observations = const _Sentinel(),
    Object? comparisons = const _Sentinel(),
  }) {
    return RideFeedback(
      id: id is _Sentinel ? this.id : (id as String?),
      isDeleted: isDeleted is _Sentinel ? this.isDeleted : (isDeleted as bool?),
      lastModified: lastModified is _Sentinel ? this.lastModified : (lastModified as DateTime?),
      bike: bike is _Sentinel ? this.bike : (bike as String),
      setupId: setupId is _Sentinel ? this.setupId : (setupId as String),
      stravaActivityId: stravaActivityId is _Sentinel ? this.stravaActivityId : (stravaActivityId as int?),
      dateTimeUTC: dateTimeUTC is _Sentinel ? this.dateTimeUTC : (dateTimeUTC as DateTime),
      dateTimeLocal: dateTimeLocal is _Sentinel ? this.dateTimeLocal : (dateTimeLocal as DateTime),
      notes: notes is _Sentinel ? this.notes : (notes as String?),
      position: position is _Sentinel ? this.position : (position as ContextPosition?),
      place: place is _Sentinel ? this.place : (place as geo.Placemark?),
      weather: weather is _Sentinel ? this.weather : (weather as ContextWeather?),
      observations: observations is _Sentinel ? this.observations : (observations as Set<FeedbackObservation>),
      comparisons: comparisons is _Sentinel ? this.comparisons : (comparisons as Set<FeedbackComparison>),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RideFeedback &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            isDeleted == other.isDeleted &&
            lastModified == other.lastModified &&
            bike == other.bike &&
            setupId == other.setupId &&
            stravaActivityId == other.stravaActivityId &&
            dateTimeUTC == other.dateTimeUTC &&
            dateTimeLocal == other.dateTimeLocal &&
            notes == other.notes &&
            ContextPosition.equal(position, other.position) &&
            ContextPlace.equal(place, other.place) &&
            weather == other.weather &&
            setEquals(observations, other.observations) &&
            setEquals(comparisons, other.comparisons);
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      isDeleted,
      lastModified,
      bike,
      setupId,
      stravaActivityId,
      dateTimeUTC,
      dateTimeLocal,
      notes,
      position,
      place,
      weather,
      Object.hashAllUnordered(observations),
      Object.hashAllUnordered(comparisons),
    ]);
  }
}

class _Sentinel {
  const _Sentinel();
}
