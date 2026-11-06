part of 'task_threshold.dart';

class ElevationThreshold extends AccumulatingThreshold {
  final double meters;
  const ElevationThreshold(this.meters);

  @override
  double get target => meters;

  @override
  double accumulated(TaskProgressContext context) => context.delta.elevationGain;

  @override
  IconData get iconData => Icons.terrain;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'elevation',
        'meters': meters,
      };

  factory ElevationThreshold.fromJson(Map<String, dynamic> json) =>
      ElevationThreshold((json['meters'] as num).toDouble());
}
