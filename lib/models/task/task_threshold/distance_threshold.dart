part of 'task_threshold.dart';

class DistanceThreshold extends AccumulatingThreshold {
  final double meters;
  const DistanceThreshold(this.meters);

  @override
  double get target => meters;

  @override
  double accumulated(TaskProgressContext context) => context.delta.distance;

  @override
  IconData get iconData => Icons.route;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'distance',
        'meters': meters,
      };

  factory DistanceThreshold.fromJson(Map<String, dynamic> json) =>
      DistanceThreshold((json['meters'] as num).toDouble());
}
