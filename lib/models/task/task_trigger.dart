import 'package:flutter/widgets.dart';

import 'task_threshold/task_threshold.dart';

enum TaskTriggerMetric {
  distance,
  movingTime,
  elapsedTime,
  elevation,
  activityCount,
  kilojoules;

  static TaskTriggerMetric? of(TaskThreshold threshold) => switch (threshold) {
    DistanceThreshold() => distance,
    MovingTimeThreshold() => movingTime,
    ElapsedTimeThreshold() => elapsedTime,
    ElevationThreshold() => elevation,
    ActivityCountThreshold() => activityCount,
    KilojoulesThreshold() => kilojoules,
    DurationThreshold() || DateTimeThreshold() => null,
  };

  /// [amount] in the unit of [AccumulatingThreshold.target], in the backend's unit.
  double fromThresholdUnit(double amount) => switch (this) {
    movingTime || elapsedTime => amount / Duration.microsecondsPerSecond,
    _ => amount,
  };
}

/// What makes an open rule due, in terms the backend can check after each
/// Strava ride (`users/{uid}/task_triggers/{ruleId}`): the rides on [gearId]
/// that started from [countFrom] on add up to [needed]. It sends a push once
/// (#17 Phase 8).
///
/// A new ride after [countFrom] changes neither value, so the app writes a
/// trigger only when the rule, its last entry or the rides before [countFrom]
/// change, or once a month when [earliestCountFrom] moves.
@immutable
class TaskTrigger {
  // The rules allow 200; the notification shows far less.
  static const int maxTitleLength = 100;

  final String ruleId;
  final String gearId;
  final TaskTriggerMetric metric;

  /// UTC, whole seconds like Strava's start times, so the app and the backend
  /// (milliseconds) draw the same line.
  final DateTime countFrom;

  /// In the [metric]'s backend unit, whole, so float noise in the sums never
  /// rewrites it.
  final double needed;

  /// The rule's name, cut to [maxTitleLength] characters.
  final String title;

  TaskTrigger({
    required this.ruleId,
    required this.gearId,
    required this.metric,
    required DateTime countFrom,
    required double needed,
    required String title,
  }) : countFrom = _ceilToSecond(countFrom.toUtc()),
       needed = needed.roundToDouble(),
       title = title.characters.take(maxTitleLength).toString();

  /// The 1st of the month two months before [now], UTC. A trigger counts from
  /// here at the earliest, so the backend still counts a ride uploaded weeks
  /// late, and stored rides expire (TTL) long after. Every device picks the
  /// same day, so the triggers move once a month and not with each device.
  static DateTime earliestCountFrom(DateTime now) {
    final utc = now.toUtc();
    return DateTime.utc(utc.year, utc.month - 2);
  }

  /// The [countFrom] for a rule whose rides count from the latest of
  /// [windowStarts]: never before [earliestCountFrom], in whole seconds.
  static DateTime countFromFor({required DateTime now, required Iterable<DateTime?> windowStarts}) {
    var countFrom = earliestCountFrom(now);
    for (final start in windowStarts) {
      if (start != null && start.isAfter(countFrom)) countFrom = start.toUtc();
    }
    return _ceilToSecond(countFrom);
  }

  // Rounding up keeps a ride that started just before the original instant out.
  static DateTime _ceilToSecond(DateTime utc) {
    final fraction = utc.microsecondsSinceEpoch % Duration.microsecondsPerSecond;
    return fraction == 0 ? utc : utc.add(Duration(microseconds: Duration.microsecondsPerSecond - fraction));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskTrigger &&
          ruleId == other.ruleId &&
          gearId == other.gearId &&
          metric == other.metric &&
          countFrom == other.countFrom &&
          needed == other.needed &&
          title == other.title;

  @override
  int get hashCode => Object.hash(ruleId, gearId, metric, countFrom, needed, title);

  @override
  String toString() => 'TaskTrigger($ruleId, $gearId, ${metric.name} $needed from $countFrom, $title)';
}
