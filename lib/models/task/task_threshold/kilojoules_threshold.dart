part of 'task_threshold.dart';

class KilojoulesThreshold extends AccumulatingThreshold {
  final double kilojoules;
  const KilojoulesThreshold(this.kilojoules);

  @override
  double get target => kilojoules;

  @override
  double accumulated(TaskProgressContext context) => context.delta.kilojoules;

  @override
  IconData get iconData => Icons.bolt;

  @override
  String toDisplayValue({String distanceUnit = 'km', String altitudeUnit = 'm', String dateFormat = 'yyyy-MM-dd'}) =>
      '${NumberFormat.decimalPattern().format(kilojoules.round())} kJ';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'kilojoules',
        'kilojoules': kilojoules,
      };

  factory KilojoulesThreshold.fromJson(Map<String, dynamic> json) =>
      KilojoulesThreshold((json['kilojoules'] as num).toDouble());
}
