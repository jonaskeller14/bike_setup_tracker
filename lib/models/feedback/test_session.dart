import 'package:collection/collection.dart' show ListEquality, MapEquality;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:uuid/uuid.dart';

import '../adjustment/adjustment.dart';
import '../context/context_place.dart';
import '../setup.dart';
import 'feedback_key.dart';
import 'test_session_method.dart';

@immutable
class TestSession {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String bike;
  final String? name;
  final TestSessionMethod? method; // null=free session without proposals
  final List<String> adjustmentIds;
  final List<FeedbackAspect> goal; // Aspects to improve
  final Map<String, AdjustmentValue> locks; // Aspects to improve
  final DateTime startedAtUTC;
  final DateTime startedAtLocal;
  final DateTime? endedAtUTC;
  final DateTime? endedAtLocal;
  final geo.Placemark? place;
  final String? notes;

  /// Setup id → adjustment id → value the engine proposed for that run.
  final Map<String, Map<String, AdjustmentValue>> proposals;

  static const IconData iconData = Icons.science;
  static const int maxGoalAspects = 3;
  static const String namePlaceholder = 'Test session';
  String get displayName => name ?? namePlaceholder;
  bool get isRunning => endedAtUTC == null;

  TestSession({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.bike,
    this.name,
    this.method,
    required this.adjustmentIds,
    List<FeedbackAspect>? goal,
    Map<String, AdjustmentValue>? locks,
    required DateTime startedAtUTC,
    required this.startedAtLocal,
    DateTime? endedAtUTC,
    this.endedAtLocal,
    this.place,
    this.notes,
    Map<String, Map<String, AdjustmentValue>>? proposals,
  }) : assert((endedAtUTC == null) == (endedAtLocal == null), 'endedAtUTC and endedAtLocal are set together'),
       id = id ?? const Uuid().v4(),
       isDeleted = isDeleted ?? false,
       lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc(),
       goal = goal ?? const [],
       locks = locks ?? const {},
       startedAtUTC = startedAtUTC.toUtc(),
       endedAtUTC = endedAtUTC?.toUtc(),
       proposals = proposals ?? const {};

  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'isDeleted': isDeleted,
    'lastModified': lastModified.toUtc().toIso8601String(),
    'bike': bike,
    'name': name,
    'method': method?.toJson(),
    'adjustmentIds': adjustmentIds,
    'goal': goal.map((a) => a.raw).toList(),
    'locks': Setup.adjustmentValuesToJson(locks),
    'startedAtUTC': startedAtUTC.toUtc().toIso8601String(),
    'startedAtLocal': startedAtLocal.toIso8601String(),
    'endedAtUTC': endedAtUTC?.toUtc().toIso8601String(),
    'endedAtLocal': endedAtLocal?.toIso8601String(),
    'place': place != null ? ContextPlace.toJson(place!) : null,
    'notes': notes,
    'proposals': proposals.map((setupId, values) => MapEntry(setupId, Setup.adjustmentValuesToJson(values))),
  };

  factory TestSession.fromJson({
    required Map<String, dynamic> json,
    required Map<String, AdjustmentType> adjustmentTypes,
  }) {
    final int? version = json['version'] as int?;
    switch (version) {
      case null || 1:
        final method = json['method'] as Map<String, dynamic>?;
        final endedAtUTC = json['endedAtUTC'] as String?;
        final endedAtLocal = json['endedAtLocal'] as String?;
        return TestSession(
          id: json['id'] as String?,
          isDeleted: json['isDeleted'] as bool?,
          lastModified: DateTime.tryParse(json['lastModified'] as String? ?? ''),
          bike: json['bike'] as String,
          name: json['name'] as String?,
          method: method != null ? TestSessionMethod.fromJson(method) : null,
          adjustmentIds: (json['adjustmentIds'] as List).map((e) => e as String).toList(),
          goal: (json['goal'] as List?)?.map((e) => FeedbackAspect.parse(e as String)).toList(),
          locks: Setup.adjustmentValuesFromJson(
            json['locks'] as Map<String, dynamic>? ?? {},
            adjustmentTypes: adjustmentTypes,
          ),
          startedAtUTC: DateTime.parse(json['startedAtUTC'] as String).toUtc(),
          startedAtLocal: DateTime.parse(json['startedAtLocal'] as String),
          endedAtUTC: endedAtUTC != null ? DateTime.parse(endedAtUTC).toUtc() : null,
          endedAtLocal: endedAtLocal != null ? DateTime.parse(endedAtLocal) : null,
          place: json['place'] != null ? ContextPlace.fromJson(json['place'] as Map<String, dynamic>) : null,
          notes: json['notes'] as String?,
          proposals: (json['proposals'] as Map<String, dynamic>? ?? {}).map(
            (setupId, values) => MapEntry(
              setupId,
              Setup.adjustmentValuesFromJson(values as Map<String, dynamic>, adjustmentTypes: adjustmentTypes),
            ),
          ),
        );
      default:
        throw Exception('Json Version $version of TestSession incompatible.');
    }
  }

  TestSession copyWith({
    Object? id = const _Sentinel(),
    Object? isDeleted = const _Sentinel(),
    Object? lastModified = const _Sentinel(),
    Object? bike = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? method = const _Sentinel(),
    Object? adjustmentIds = const _Sentinel(),
    Object? goal = const _Sentinel(),
    Object? locks = const _Sentinel(),
    Object? startedAtUTC = const _Sentinel(),
    Object? startedAtLocal = const _Sentinel(),
    Object? endedAtUTC = const _Sentinel(),
    Object? endedAtLocal = const _Sentinel(),
    Object? place = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? proposals = const _Sentinel(),
  }) {
    return TestSession(
      id: id is _Sentinel ? this.id : (id as String?),
      isDeleted: isDeleted is _Sentinel ? this.isDeleted : (isDeleted as bool?),
      lastModified: lastModified is _Sentinel ? this.lastModified : (lastModified as DateTime?),
      bike: bike is _Sentinel ? this.bike : (bike as String),
      name: name is _Sentinel ? this.name : (name as String?),
      method: method is _Sentinel ? this.method : (method as TestSessionMethod?),
      adjustmentIds: adjustmentIds is _Sentinel ? this.adjustmentIds : (adjustmentIds as List<String>),
      goal: goal is _Sentinel ? this.goal : (goal as List<FeedbackAspect>),
      locks: locks is _Sentinel ? this.locks : (locks as Map<String, AdjustmentValue>),
      startedAtUTC: startedAtUTC is _Sentinel ? this.startedAtUTC : (startedAtUTC as DateTime),
      startedAtLocal: startedAtLocal is _Sentinel ? this.startedAtLocal : (startedAtLocal as DateTime),
      endedAtUTC: endedAtUTC is _Sentinel ? this.endedAtUTC : (endedAtUTC as DateTime?),
      endedAtLocal: endedAtLocal is _Sentinel ? this.endedAtLocal : (endedAtLocal as DateTime?),
      place: place is _Sentinel ? this.place : (place as geo.Placemark?),
      notes: notes is _Sentinel ? this.notes : (notes as String?),
      proposals: proposals is _Sentinel ? this.proposals : (proposals as Map<String, Map<String, AdjustmentValue>>),
    );
  }

  static const _proposalsEquality = MapEquality<String, Map<String, AdjustmentValue>>(
    values: MapEquality<String, AdjustmentValue>(),
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TestSession &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            isDeleted == other.isDeleted &&
            lastModified == other.lastModified &&
            bike == other.bike &&
            name == other.name &&
            method == other.method &&
            listEquals(adjustmentIds, other.adjustmentIds) &&
            listEquals(goal, other.goal) &&
            mapEquals(locks, other.locks) &&
            startedAtUTC == other.startedAtUTC &&
            startedAtLocal == other.startedAtLocal &&
            endedAtUTC == other.endedAtUTC &&
            endedAtLocal == other.endedAtLocal &&
            ContextPlace.equal(place, other.place) &&
            notes == other.notes &&
            _proposalsEquality.equals(proposals, other.proposals);
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      isDeleted,
      lastModified,
      bike,
      name,
      method,
      const ListEquality<String>().hash(adjustmentIds),
      const ListEquality<FeedbackAspect>().hash(goal),
      const MapEquality<String, AdjustmentValue>().hash(locks),
      startedAtUTC,
      startedAtLocal,
      endedAtUTC,
      endedAtLocal,
      place,
      notes,
      _proposalsEquality.hash(proposals),
    ]);
  }
}

class _Sentinel {
  const _Sentinel();
}
