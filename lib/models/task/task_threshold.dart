import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../component_stats.dart';

sealed class TaskThreshold {
  const TaskThreshold();

  Map<String, dynamic> toJson();

  bool isMet(
    ComponentStats current,
    ComponentStats baseline,
    DateTime currentDate,
    DateTime baselineDate, {
    TaskThreshold? delay,
  });

  double getProgress(
    ComponentStats current,
    ComponentStats baseline,
    DateTime currentDate,
    DateTime baselineDate, {
    TaskThreshold? delay,
  });

  IconData get iconData;
  String toDisplayValue({String distanceUnit = 'km', String altitudeUnit = 'm', String dateFormat = 'yyyy-MM-dd'});
  bool get isPositive;

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
      _ => throw ArgumentError('Unknown TaskThreshold type: $type'),
    };
  }
}

class ElevationThreshold extends TaskThreshold {
  final double meters;
  const ElevationThreshold(this.meters);

  double _getDelayMeters(TaskThreshold? delay) {
    if (delay is ElevationThreshold) return delay.meters;
    return 0;
  }

  @override
  bool isMet(ComponentStats current, ComponentStats baseline, DateTime currentDate, DateTime baselineDate, {TaskThreshold? delay}) {
    return (current.elevationGain - baseline.elevationGain) >= (meters + _getDelayMeters(delay));
  }

  @override
  double getProgress(ComponentStats current, ComponentStats baseline, DateTime currentDate, DateTime baselineDate, {TaskThreshold? delay}) {
    final total = meters + _getDelayMeters(delay);
    if (total <= 0) return 1.0;
    return (current.elevationGain - baseline.elevationGain) / total;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'elevation',
        'meters': meters,
      };

  @override
  IconData get iconData => Icons.terrain;

  @override
  String toDisplayValue({String distanceUnit = 'km', String altitudeUnit = 'm', String dateFormat = 'yyyy-MM-dd'}) {
    final value = altitudeUnit == 'ft' ? meters * 3.28084 : meters;
    return '${NumberFormat.decimalPattern().format(value.round())} $altitudeUnit';
  }

  @override
  bool get isPositive => meters > 0;

  factory ElevationThreshold.fromJson(Map<String, dynamic> json) =>
      ElevationThreshold((json['meters'] as num).toDouble());
}

class DistanceThreshold extends TaskThreshold {
  final double meters;
  const DistanceThreshold(this.meters);

  double _getDelayMeters(TaskThreshold? delay) {
    if (delay is DistanceThreshold) return delay.meters;
    return 0;
  }

  @override
  bool isMet(ComponentStats current, ComponentStats baseline, DateTime currentDate, DateTime baselineDate, {TaskThreshold? delay}) {
    return (current.distance - baseline.distance) >= (meters + _getDelayMeters(delay));
  }

  @override
  double getProgress(ComponentStats current, ComponentStats baseline, DateTime currentDate, DateTime baselineDate, {TaskThreshold? delay}) {
    final total = meters + _getDelayMeters(delay);
    if (total <= 0) return 1.0;
    return (current.distance - baseline.distance) / total;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'distance',
        'meters': meters,
      };

  @override
  IconData get iconData => Icons.route;

  @override
  String toDisplayValue({String distanceUnit = 'km', String altitudeUnit = 'm', String dateFormat = 'yyyy-MM-dd'}) {
    final value = distanceUnit == 'mi' ? meters / 1609.344 : meters / 1000;
    return '${NumberFormat('#,##0.#').format(value)} $distanceUnit';
  }

  @override
  bool get isPositive => meters > 0;

  factory DistanceThreshold.fromJson(Map<String, dynamic> json) =>
      DistanceThreshold((json['meters'] as num).toDouble());
}

class MovingTimeThreshold extends TaskThreshold {
  final Duration hours;
  const MovingTimeThreshold(this.hours);

  Duration _getDelayDuration(TaskThreshold? delay) {
    if (delay is MovingTimeThreshold) return delay.hours;
    return Duration.zero;
  }

  @override
  bool isMet(ComponentStats current, ComponentStats baseline, DateTime currentDate, DateTime baselineDate, {TaskThreshold? delay}) {
    return (current.movingTime - baseline.movingTime) >= (hours + _getDelayDuration(delay));
  }

  @override
  double getProgress(ComponentStats current, ComponentStats baseline, DateTime currentDate, DateTime baselineDate, {TaskThreshold? delay}) {
    final total = hours + _getDelayDuration(delay);
    if (total == Duration.zero) return 1.0;
    return (current.movingTime - baseline.movingTime).inMicroseconds / total.inMicroseconds;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'time',
        'microseconds': hours.inMicroseconds,
      };

  @override
  IconData get iconData => Icons.timer;

  @override
  String toDisplayValue({String distanceUnit = 'km', String altitudeUnit = 'm', String dateFormat = 'yyyy-MM-dd'}) => '${NumberFormat.decimalPattern().format(hours.inHours)} h';

  @override
  bool get isPositive => hours > Duration.zero;

  factory MovingTimeThreshold.fromJson(Map<String, dynamic> json) =>
      MovingTimeThreshold(Duration(microseconds: json['microseconds'] as int));
}

class ElapsedTimeThreshold extends TaskThreshold {
  final Duration hours;
  const ElapsedTimeThreshold(this.hours);

  Duration _getDelayDuration(TaskThreshold? delay) {
    if (delay is ElapsedTimeThreshold) return delay.hours;
    return Duration.zero;
  }

  @override
  bool isMet(ComponentStats current, ComponentStats baseline, DateTime currentDate, DateTime baselineDate, {TaskThreshold? delay}) {
    return (current.elapsedTime - baseline.elapsedTime) >= (hours + _getDelayDuration(delay));
  }

  @override
  double getProgress(ComponentStats current, ComponentStats baseline, DateTime currentDate, DateTime baselineDate, {TaskThreshold? delay}) {
    final total = hours + _getDelayDuration(delay);
    if (total == Duration.zero) return 1.0;
    return (current.elapsedTime - baseline.elapsedTime).inMicroseconds / total.inMicroseconds;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'elapsedTime',
        'microseconds': hours.inMicroseconds,
      };

  @override
  IconData get iconData => Icons.timelapse;

  @override
  String toDisplayValue({String distanceUnit = 'km', String altitudeUnit = 'm', String dateFormat = 'yyyy-MM-dd'}) => '${NumberFormat.decimalPattern().format(hours.inHours)} h';

  @override
  bool get isPositive => hours > Duration.zero;

  factory ElapsedTimeThreshold.fromJson(Map<String, dynamic> json) =>
      ElapsedTimeThreshold(Duration(microseconds: json['microseconds'] as int));
}

class DurationThreshold extends TaskThreshold {
  final Duration days;
  const DurationThreshold(this.days);

  Duration _getDelayDuration(TaskThreshold? delay) {
    if (delay is DurationThreshold) return delay.days;
    return Duration.zero;
  }

  @override
  bool isMet(ComponentStats current, ComponentStats baseline, DateTime currentDate, DateTime baselineDate, {TaskThreshold? delay}) {
    return currentDate.difference(baselineDate) >= (days + _getDelayDuration(delay));
  }

  @override
  double getProgress(ComponentStats current, ComponentStats baseline, DateTime currentDate, DateTime baselineDate, {TaskThreshold? delay}) {
    final total = days + _getDelayDuration(delay);
    if (total == Duration.zero) return 1.0;
    return currentDate.difference(baselineDate).inMicroseconds / total.inMicroseconds;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'duration',
        'microseconds': days.inMicroseconds,
      };

  @override
  IconData get iconData => Icons.calendar_today;

  @override
  String toDisplayValue({String distanceUnit = 'km', String altitudeUnit = 'm', String dateFormat = 'yyyy-MM-dd'}) => '${NumberFormat.decimalPattern().format(days.inDays)} ${days.inDays == 1 ? 'day' : 'days'}';

  @override
  bool get isPositive => days > Duration.zero;

  factory DurationThreshold.fromJson(Map<String, dynamic> json) =>
      DurationThreshold(Duration(microseconds: json['microseconds'] as int));
}

class DateTimeThreshold extends TaskThreshold {
  final DateTime deadline;
  const DateTimeThreshold(this.deadline);

  static const Duration _leadWindow = Duration(days: 7); // 0-100% (upcoming period)
  static const Duration _graceWindow = Duration(days: 3); // due-overdue period

  Duration _getDelayDuration(TaskThreshold? delay) {
    if (delay is DurationThreshold) return delay.days;
    // Note: if delay is another DateTimeThreshold, it doesn't make much sense to add them.
    return Duration.zero;
  }

  @override
  bool isMet(ComponentStats current, ComponentStats baseline, DateTime currentDate, DateTime baselineDate, {TaskThreshold? delay}) {
    return currentDate.isAfter(deadline.add(_getDelayDuration(delay)));
  }

  @override
  double getProgress(ComponentStats current, ComponentStats baseline, DateTime currentDate, DateTime baselineDate, {TaskThreshold? delay}) {
    final effectiveDeadline = deadline.add(_getDelayDuration(delay));
    final remaining = effectiveDeadline.difference(currentDate);

    if (remaining > Duration.zero) {
      return (1.0 - remaining.inMicroseconds / _leadWindow.inMicroseconds).clamp(0.0, 1.0);
    }

    final overdueBy = currentDate.difference(effectiveDeadline);
    return 1.0 + (overdueBy.inMicroseconds / _graceWindow.inMicroseconds) * 0.1;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'dateTime',
        'deadline': deadline.toUtc().toIso8601String(),
      };

  @override
  IconData get iconData => Icons.event;

  @override
  String toDisplayValue({String distanceUnit = 'km', String altitudeUnit = 'm', String dateFormat = 'yyyy-MM-dd'}) => DateFormat(dateFormat).format(deadline.toLocal());

  @override
  bool get isPositive => true;

  factory DateTimeThreshold.fromJson(Map<String, dynamic> json) =>
      DateTimeThreshold(DateTime.parse(json['deadline'] as String).toUtc());
}

class ActivityCountThreshold extends TaskThreshold {
  final int count;
  const ActivityCountThreshold(this.count);

  int _getDelayCount(TaskThreshold? delay) {
    if (delay is ActivityCountThreshold) return delay.count;
    return 0;
  }

  @override
  bool isMet(ComponentStats current, ComponentStats baseline, DateTime currentDate, DateTime baselineDate, {TaskThreshold? delay}) {
    return (current.activityCount - baseline.activityCount) >= (count + _getDelayCount(delay));
  }

  @override
  double getProgress(ComponentStats current, ComponentStats baseline, DateTime currentDate, DateTime baselineDate, {TaskThreshold? delay}) {
    final total = count + _getDelayCount(delay);
    if (total <= 0) return 1.0;
    return (current.activityCount - baseline.activityCount) / total;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'count',
        'count': count,
      };

  @override
  IconData get iconData => Icons.repeat;

  @override
  String toDisplayValue({String distanceUnit = 'km', String altitudeUnit = 'm', String dateFormat = 'yyyy-MM-dd'}) => '${NumberFormat.decimalPattern().format(count)} ${count == 1 ? 'ride' : 'rides'}';

  @override
  bool get isPositive => count > 0;

  factory ActivityCountThreshold.fromJson(Map<String, dynamic> json) =>
      ActivityCountThreshold(json['count'] as int);
}
