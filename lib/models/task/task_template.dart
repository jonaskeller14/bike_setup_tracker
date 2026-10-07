import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'task_association.dart';
import 'task_rule.dart';
import 'task_threshold/task_threshold.dart';

/// A ready-made task rule for a component type. Its [key] ends up in
/// [TaskRule.presetKey] of every rule created from it.
@immutable
class TaskTemplate {
  final String key;
  final String name;
  final String? notes;
  final TaskThreshold interval;

  /// Time-based interval used without the Strava entitlement when [interval]
  /// needs ride data. `null` hides the template without Strava.
  final TaskThreshold? fallbackInterval;
  final TaskPriority priority;
  final bool repeat;
  final bool preselected;

  const TaskTemplate({
    required this.key,
    required this.name,
    this.notes,
    required this.interval,
    this.fallbackInterval,
    this.priority = TaskPriority.medium,
    this.repeat = true,
    this.preselected = false,
  });
}

/// A catalog-sourced change to a generic [TaskTemplate], or a brand-only
/// template when no generic one has its key (then [name] is required).
@immutable
class TaskTemplateOverride {
  final TaskThreshold interval;

  /// Falls back to the generic template's fallback when `null`.
  final TaskThreshold? fallbackInterval;
  final String source;
  final String? name;
  final String? notes;
  final TaskPriority? priority;
  final bool? preselected;

  const TaskTemplateOverride({
    required this.interval,
    this.fallbackInterval,
    required this.source,
    this.name,
    this.notes,
    this.priority,
    this.preselected,
  });
}

/// A template resolved for one component: the interval it would be created
/// with, and where that interval comes from.
@immutable
class TaskSuggestion {
  final String key;
  final String name;
  final String? notes;
  final TaskPriority priority;
  final bool repeat;
  final bool preselected;

  /// The interval the created rule gets.
  final TaskThreshold interval;

  /// The ride-based interval that [interval] stands in for without Strava.
  final TaskThreshold? stravaInterval;

  /// Where the interval comes from; `null` for the generic value.
  final String? source;

  const TaskSuggestion({
    required this.key,
    required this.name,
    this.notes,
    required this.priority,
    required this.repeat,
    required this.preselected,
    required this.interval,
    this.stravaInterval,
    this.source,
  });

  bool get isFallback => stravaInterval != null;

  TaskRule toTaskRule(String componentId, {String distanceUnit = 'km', String altitudeUnit = 'm'}) {
    final line = _recommendationLine(distanceUnit: distanceUnit, altitudeUnit: altitudeUnit);
    return TaskRule(
      name: name,
      notes: notes == null ? line : '$notes\n\n$line',
      priority: priority,
      tags: const <String>{},
      association: ComponentTaskAssociation(componentId),
      interval: interval,
      repeat: repeat,
      presetKey: key,
    );
  }

  String _recommendationLine({required String distanceUnit, required String altitudeUnit}) {
    final effective = taskIntervalLabel(interval, distanceUnit: distanceUnit, altitudeUnit: altitudeUnit);
    final strava = stravaInterval;
    final origin = strava != null
        ? ' (time-based; ${taskIntervalLabel(strava, distanceUnit: distanceUnit, altitudeUnit: altitudeUnit)} with Strava)'
        : source == null
        ? ' (generic)'
        : '';
    final sourceSuffix = source == null ? '' : ' — $source';
    return 'Recommended interval: $effective$origin$sourceSuffix';
  }
}

/// "every 2,000 km", "every 6 months", "every year".
String taskIntervalLabel(TaskThreshold interval, {String distanceUnit = 'km', String altitudeUnit = 'm'}) {
  if (interval is DurationThreshold) {
    final days = interval.days.inDays;
    for (final (dayCount, singular, plural) in const [
      (365, 'year', 'years'),
      (30, 'month', 'months'),
      (7, 'week', 'weeks'),
      (1, 'day', 'days'),
    ]) {
      if (days < dayCount || days % dayCount != 0) continue;
      final count = days ~/ dayCount;
      return count == 1 ? 'every $singular' : 'every ${NumberFormat.decimalPattern().format(count)} $plural';
    }
  }
  return 'every ${interval.toDisplayValue(distanceUnit: distanceUnit, altitudeUnit: altitudeUnit)}';
}
