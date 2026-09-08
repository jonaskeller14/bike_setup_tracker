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
  String toDisplayValue({String distanceUnit = 'km', String altitudeUnit = 'm', String dateFormat = 'yyyy-MM-dd'}) {
    final value = altitudeUnit == 'ft' ? meters * 3.28084 : meters;
    return '${NumberFormat.decimalPattern().format(value.round())} $altitudeUnit';
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'elevation',
        'meters': meters,
      };

  factory ElevationThreshold.fromJson(Map<String, dynamic> json) =>
      ElevationThreshold((json['meters'] as num).toDouble());
}
