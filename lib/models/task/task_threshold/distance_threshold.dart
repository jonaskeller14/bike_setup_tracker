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
  String toDisplayValue({String distanceUnit = 'km', String altitudeUnit = 'm', String dateFormat = 'yyyy-MM-dd'}) {
    final value = distanceUnit == 'mi' ? meters / 1609.344 : meters / 1000;
    return '${NumberFormat('#,##0.#').format(value)} $distanceUnit';
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'distance',
        'meters': meters,
      };

  factory DistanceThreshold.fromJson(Map<String, dynamic> json) =>
      DistanceThreshold((json['meters'] as num).toDouble());
}
