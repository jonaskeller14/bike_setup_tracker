import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../task_progress_context.dart';

part 'distance_threshold.dart';
part 'duration_threshold.dart';
part 'elapsed_time_threshold.dart';
part 'elevation_threshold.dart';
part 'moving_time_threshold.dart';
part 'activity_count_threshold.dart';
part 'datetime_threshold.dart';
part 'kilojoules_threshold.dart';

@immutable
sealed class TaskThreshold {
  const TaskThreshold();

  /// How far the task has come towards this threshold: `1.0` is exactly reached,
  /// anything above that is overdue. A [delay] of the same kind moves the target out.
  double progress(TaskProgressContext context, {TaskThreshold? delay});

  bool isMet(TaskProgressContext context, {TaskThreshold? delay}) =>
      progress(context, delay: delay) >= 1.0;

  /// Whether the threshold measures ride data and therefore needs a component
  /// or a bike to draw stats from.
  bool get requiresActivityData;

  /// Whether the threshold carries a usable (non-zero) target.
  bool get isPositive;

  IconData get iconData;

  String toDisplayValue({String distanceUnit = 'km', String altitudeUnit = 'm', String dateFormat = 'yyyy-MM-dd'});

  Map<String, dynamic> toJson();

  factory TaskThreshold.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'distance' => DistanceThreshold.fromJson(json),
      'time' => MovingTimeThreshold.fromJson(json),
      'elapsedTime' => ElapsedTimeThreshold.fromJson(json),
      'duration' => DurationThreshold.fromJson(json),
      'dateTime' => DateTimeThreshold.fromJson(json),
      'count' => ActivityCountThreshold.fromJson(json),
      'elevation' => ElevationThreshold.fromJson(json),
      'kilojoules' => KilojoulesThreshold.fromJson(json),
      _ => throw ArgumentError('Unknown TaskThreshold type: $type'),
    };
  }
}

sealed class AccumulatingThreshold extends TaskThreshold {
  const AccumulatingThreshold();

  /// Amount to reach, in the unit [accumulated] is measured in
  /// (meters, microseconds, rides).
  double get target;

  /// Amount gathered since the baseline.
  double accumulated(TaskProgressContext context);

  @override
  double progress(TaskProgressContext context, {TaskThreshold? delay}) {
    final total = totalTarget(delay);
    if (total <= 0) return 1.0;
    return accumulated(context) / total;
  }

  double totalTarget(TaskThreshold? delay) => target + _delayTarget(delay);

  /// Only a delay of the very same kind extends the target; anything else is ignored.
  double _delayTarget(TaskThreshold? delay) =>
      delay is AccumulatingThreshold && delay.runtimeType == runtimeType ? delay.target : 0;

  /// Whether this delay brings the target in rather than pushing it out.
  bool get isPullForward => target < 0;

  /// A delay of this kind that pulls the target in to what [context] has
  /// gathered so far, so the task is due right away.
  AccumulatingThreshold dueNowDelay(TaskProgressContext context) =>
      // The nudge keeps float rounding from landing the combined target a hair
      // above what was gathered, which would leave the task just short of due.
      _withTarget(accumulated(context) - target - 1e-6);

  AccumulatingThreshold _withTarget(double value) => switch (this) {
        DistanceThreshold() => DistanceThreshold(value),
        ElevationThreshold() => ElevationThreshold(value),
        MovingTimeThreshold() => MovingTimeThreshold(Duration(microseconds: value.round())),
        ElapsedTimeThreshold() => ElapsedTimeThreshold(Duration(microseconds: value.round())),
        DurationThreshold() => DurationThreshold(Duration(microseconds: value.round())),
        ActivityCountThreshold() => ActivityCountThreshold(value.round()),
        KilojoulesThreshold() => KilojoulesThreshold(value),
      };

  @override
  bool get requiresActivityData => true;

  @override
  bool get isPositive => target > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccumulatingThreshold &&
          runtimeType == other.runtimeType &&
          target == other.target;

  @override
  int get hashCode => Object.hash(runtimeType, target);
}
