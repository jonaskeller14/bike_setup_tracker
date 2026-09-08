part of 'task_threshold.dart';

class DurationThreshold extends AccumulatingThreshold {
  final Duration days;
  const DurationThreshold(this.days);

  @override
  double get target => days.inMicroseconds.toDouble();

  @override
  double accumulated(TaskProgressContext context) => context.elapsed.inMicroseconds.toDouble();

  @override
  bool get requiresActivityData => false;

  @override
  IconData get iconData => Icons.calendar_today;

  @override
  String toDisplayValue({String distanceUnit = 'km', String altitudeUnit = 'm', String dateFormat = 'yyyy-MM-dd'}) =>
      '${NumberFormat.decimalPattern().format(days.inDays)} ${days.inDays == 1 ? 'day' : 'days'}';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'duration',
        'microseconds': days.inMicroseconds,
      };

  factory DurationThreshold.fromJson(Map<String, dynamic> json) =>
      DurationThreshold(Duration(microseconds: json['microseconds'] as int));
}
