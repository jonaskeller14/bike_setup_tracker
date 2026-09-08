part of 'task_threshold.dart';

class MovingTimeThreshold extends AccumulatingThreshold {
  final Duration hours;
  const MovingTimeThreshold(this.hours);

  @override
  double get target => hours.inMicroseconds.toDouble();

  @override
  double accumulated(TaskProgressContext context) => context.delta.movingTime.inMicroseconds.toDouble();

  @override
  IconData get iconData => Icons.timer;

  @override
  String toDisplayValue({String distanceUnit = 'km', String altitudeUnit = 'm', String dateFormat = 'yyyy-MM-dd'}) =>
      '${NumberFormat.decimalPattern().format(hours.inHours)} h';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'time',
        'microseconds': hours.inMicroseconds,
      };

  factory MovingTimeThreshold.fromJson(Map<String, dynamic> json) =>
      MovingTimeThreshold(Duration(microseconds: json['microseconds'] as int));
}
