import 'adjustment/adjustment.dart';
import 'bike.dart';
import 'component/component.dart';
import 'feedback/ride_feedback.dart';
import 'feedback/test_session.dart';
import 'person.dart';
import 'setup.dart';
import 'task/task_entry.dart';
import 'task/task_rule.dart';

class SelectedData {
  final Map<String, Person> persons;
  final Map<String, Bike> bikes;
  final Map<String, Component> components;
  final Map<String, Setup> setups;
  final Map<String, TaskRule> taskRules;
  final Map<String, TaskEntry> taskEntries;
  final Map<String, RideFeedback> feedbacks;
  final Map<String, TestSession> testSessions;

  SelectedData({
    Map<String, Person>? persons,
    Map<String, Bike>? bikes,
    Map<String, Component>? components,
    Map<String, Setup>? setups,
    Map<String, TaskRule>? taskRules,
    Map<String, TaskEntry>? taskEntries,
    Map<String, RideFeedback>? feedbacks,
    Map<String, TestSession>? testSessions,
  })  : persons = persons ?? {},
        bikes = bikes ?? {},
        components = components ?? {},
        setups = setups ?? {},
        taskRules = taskRules ?? {},
        taskEntries = taskEntries ?? {},
        feedbacks = feedbacks ?? {},
        testSessions = testSessions ?? {};

  factory SelectedData.fromJson(Map<String, dynamic> rawJson) {
    // Backup import (all legacy versions): normalize adjustment
    // unit spellings ("psi", "KPH", ...) to the canonical AdjustmentUnit
    // encoding before any model parsing happens, so old backups arrive
    // structured. `"unit"` is only ever used by Adjustment json.
    final json = _normalizeLegacyUnits(rawJson) as Map<String, dynamic>;

    final loadedPersons = (json['persons'] as List<dynamic>? ?? [])
        .map((a) => Person.fromJson(a as Map<String, dynamic>))
        .toList();
    final loadedBikes = (json['bikes'] as List<dynamic>? ?? [])
        .map((a) => Bike.fromJson(a as Map<String, dynamic>));
    final loadedComponents = (json['components'] as List<dynamic>? ?? [])
        .map((a) => Component.fromJson(json: a as Map<String, dynamic>))
        .toList();

    final adjustmentTypes = adjustmentTypesOf(components: loadedComponents, persons: loadedPersons);

    final loadedSetups = (json['setups'] as List<dynamic>? ?? [])
        .map((a) => Setup.fromJson(json: a as Map<String, dynamic>, adjustmentTypes: adjustmentTypes));
    final loadedTaskRules = (json['taskRules'] as List<dynamic>? ?? [])
        .map((a) => TaskRule.fromJson(a as Map<String, dynamic>));
    final loadedTaskEntries = (json['taskEntries'] as List<dynamic>? ?? [])
        .map((a) => TaskEntry.fromJson(a as Map<String, dynamic>));
    final loadedFeedbacks = (json['feedbacks'] as List<dynamic>? ?? [])
        .map((a) => RideFeedback.fromJson(a as Map<String, dynamic>));
    final loadedTestSessions = (json['testSessions'] as List<dynamic>? ?? []).map(
      (a) => TestSession.fromJson(json: a as Map<String, dynamic>, adjustmentTypes: adjustmentTypes),
    );

    return SelectedData(
      persons: {for (var item in loadedPersons) item.id: item},
      bikes: {for (var item in loadedBikes) item.id: item},
      components: {for (var item in loadedComponents) item.id: item},
      setups: {for (var item in loadedSetups) item.id: item},
      taskRules: {for (var item in loadedTaskRules) item.id: item},
      taskEntries: {for (var item in loadedTaskEntries) item.id: item},
      feedbacks: {for (var item in loadedFeedbacks) item.id: item},
      testSessions: {for (var item in loadedTestSessions) item.id: item},
    );
  }
}

Map<String, Adjustment> adjustmentsById({
  required Iterable<Component> components,
  required Iterable<Person> persons,
}) => {
  for (final component in components)
    for (final adjustment in component.adjustments) adjustment.id: adjustment,
  for (final person in persons)
    for (final adjustment in person.adjustments) adjustment.id: adjustment,
};

Map<String, AdjustmentType> adjustmentTypesOf({
  required Iterable<Component> components,
  required Iterable<Person> persons,
}) => _typesOf(adjustmentsById(components: components, persons: persons));

Map<String, AdjustmentType> _typesOf(Map<String, Adjustment> adjustments) =>
    adjustments.map((id, adjustment) => MapEntry(id, adjustment.type));

/// Recursively rewrites every `"unit"` string value in [node] via
/// [AdjustmentUnit.fromLegacy], leaving everything else untouched.
dynamic _normalizeLegacyUnits(dynamic node) {
  if (node is Map<String, dynamic>) {
    return node.map((key, value) {
      if (key == 'unit' && value is String) {
        return MapEntry(key, AdjustmentUnit.fromLegacy(value)?.encode());
      }
      return MapEntry(key, _normalizeLegacyUnits(value));
    });
  }
  if (node is List) {
    return node.map(_normalizeLegacyUnits).toList();
  }
  return node;
}
