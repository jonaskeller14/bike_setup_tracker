part of 'task_threshold.dart';

class ElapsedTimeThreshold extends AccumulatingThreshold {
  final Duration hours;
  const ElapsedTimeThreshold(this.hours);

  @override
  double get target => hours.inMicroseconds.toDouble();

  @override
  double accumulated(TaskProgressContext context) => context.delta.elapsedTime.inMicroseconds.toDouble();

  @override
  IconData get iconData => Icons.timelapse;

  @override
  String toDisplayValue({String distanceUnit = 'km', String altitudeUnit = 'm', String dateFormat = 'yyyy-MM-dd'}) =>
      '${NumberFormat.decimalPattern().format(hours.inHours)} h';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'elapsedTime',
        'microseconds': hours.inMicroseconds,
      };

  factory ElapsedTimeThreshold.fromJson(Map<String, dynamic> json) =>
      ElapsedTimeThreshold(Duration(microseconds: json['microseconds'] as int));
}
