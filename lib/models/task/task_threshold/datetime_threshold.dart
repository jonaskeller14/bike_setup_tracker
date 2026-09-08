part of 'task_threshold.dart';

/// A fixed calendar deadline. It has no baseline to count from, so progress
/// ramps up over a lead window before the deadline and creeps past `1.0`
/// within a grace window after it.
class DateTimeThreshold extends TaskThreshold {
  final DateTime deadline;
  const DateTimeThreshold(this.deadline);

  static const Duration _leadWindow = Duration(days: 7); // 0-100% (upcoming period)
  static const Duration _graceWindow = Duration(days: 3); // due-overdue period

  @override
  double progress(TaskProgressContext context, {TaskThreshold? delay}) {
    // A DateTimeThreshold delay would be a second deadline rather than an
    // offset, so only a DurationThreshold postpones this one.
    final effectiveDeadline = deadline.add(delay is DurationThreshold ? delay.days : Duration.zero);
    final remaining = effectiveDeadline.difference(context.now);

    if (remaining > Duration.zero) {
      return (1.0 - remaining.inMicroseconds / _leadWindow.inMicroseconds).clamp(0.0, 1.0);
    }

    final overdueBy = context.now.difference(effectiveDeadline);
    return 1.0 + (overdueBy.inMicroseconds / _graceWindow.inMicroseconds) * 0.1;
  }

  @override
  bool get requiresActivityData => false;

  @override
  bool get isPositive => true;

  @override
  IconData get iconData => Icons.event;

  @override
  String toDisplayValue({String distanceUnit = 'km', String altitudeUnit = 'm', String dateFormat = 'yyyy-MM-dd'}) =>
      DateFormat(dateFormat).format(deadline.toLocal());

  @override
  Map<String, dynamic> toJson() => {
        'type': 'dateTime',
        'deadline': deadline.toUtc().toIso8601String(),
      };

  factory DateTimeThreshold.fromJson(Map<String, dynamic> json) =>
      DateTimeThreshold(DateTime.parse(json['deadline'] as String).toUtc());

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DateTimeThreshold && deadline == other.deadline;

  @override
  int get hashCode => deadline.hashCode;
}
