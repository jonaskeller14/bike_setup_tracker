import 'adjustment/adjustment_unit.dart';
import 'bike.dart';
import 'component.dart';
import 'person.dart';
import 'rating.dart';
import 'rating_entry.dart';
import 'setup.dart';
import 'task/task_entry.dart';
import 'task/task_rule.dart';

class SelectedData {
  final Map<String, Person> persons;
  final Map<String, Bike> bikes;
  final Map<String, Component> components;
  final Map<String, Setup> setups;
  final Map<String, Rating> ratings;
  final Map<String, RatingEntry> ratingEntries;
  final Map<String, TaskRule> taskRules;
  final Map<String, TaskEntry> taskEntries;

  SelectedData({
    Map<String, Person>? persons,
    Map<String, Bike>? bikes,
    Map<String, Component>? components,
    Map<String, Setup>? setups,
    Map<String, Rating>? ratings,
    Map<String, RatingEntry>? ratingEntries,
    Map<String, TaskRule>? taskRules,
    Map<String, TaskEntry>? taskEntries,
  })  : persons = persons ?? {},
        bikes = bikes ?? {},
        components = components ?? {},
        setups = setups ?? {},
        ratings = ratings ?? {},
        ratingEntries = ratingEntries ?? {},
        taskRules = taskRules ?? {},
        taskEntries = taskEntries ?? {};

  factory SelectedData.fromJson(Map<String, dynamic> rawJson) {
    // Backup import (all legacy versions): normalize adjustment/rating-metric
    // unit spellings ("psi", "KPH", ...) to the canonical AdjustmentUnit
    // encoding before any model parsing happens, so old backups arrive
    // structured. `"unit"` is only ever used by Adjustment/RatingMetric json.
    final json = _normalizeLegacyUnits(rawJson) as Map<String, dynamic>;

    final loadedPersons = (json['persons'] as List<dynamic>? ?? [])
        .map((a) => Person.fromJson(a as Map<String, dynamic>));
    final loadedBikes = (json['bikes'] as List<dynamic>? ?? [])
        .map((a) => Bike.fromJson(a as Map<String, dynamic>));
    final loadedComponents = (json['components'] as List<dynamic>? ?? [])
        .map((a) => Component.fromJson(json: a as Map<String, dynamic>));
    final loadedSetups = (json['setups'] as List<dynamic>? ?? [])
        .map((a) => Setup.fromJson(json: a as Map<String, dynamic>));
    final loadedRatings = (json['ratings'] as List<dynamic>? ?? [])
        .map((a) => Rating.fromJson(json: a as Map<String, dynamic>));
    final loadedRatingEntries = (json['ratingEntries'] as List<dynamic>? ?? [])
        .map((a) => RatingEntry.fromJson(json: a as Map<String, dynamic>));
    final loadedTaskRules = (json['taskRules'] as List<dynamic>? ?? [])
        .map((a) => TaskRule.fromJson(a as Map<String, dynamic>));
    final loadedTaskEntries = (json['taskEntries'] as List<dynamic>? ?? [])
        .map((a) => TaskEntry.fromJson(a as Map<String, dynamic>));

    return SelectedData(
      persons: {for (var item in loadedPersons) item.id: item},
      bikes: {for (var item in loadedBikes) item.id: item},
      components: {for (var item in loadedComponents) item.id: item},
      setups: {for (var item in loadedSetups) item.id: item},
      ratings: {for (var item in loadedRatings) item.id: item},
      ratingEntries: {for (var item in loadedRatingEntries) item.id: item},
      taskRules: {for (var item in loadedTaskRules) item.id: item},
      taskEntries: {for (var item in loadedTaskEntries) item.id: item},
    );
  }
}

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
