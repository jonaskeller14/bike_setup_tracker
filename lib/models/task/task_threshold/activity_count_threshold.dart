part of 'task_threshold.dart';

class ActivityCountThreshold extends AccumulatingThreshold {
  final int count;
  const ActivityCountThreshold(this.count);

  @override
  double get target => count.toDouble();

  @override
  double accumulated(TaskProgressContext context) => context.delta.activityCount.toDouble();

  @override
  IconData get iconData => Icons.repeat;

  @override
  String toDisplayValue({String distanceUnit = 'km', String altitudeUnit = 'm', String dateFormat = 'yyyy-MM-dd'}) =>
      '${NumberFormat.decimalPattern().format(count)} ${count == 1 ? 'ride' : 'rides'}';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'count',
        'count': count,
      };

  factory ActivityCountThreshold.fromJson(Map<String, dynamic> json) =>
      ActivityCountThreshold(json['count'] as int);
}
