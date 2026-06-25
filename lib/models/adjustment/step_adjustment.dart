part of 'adjustment.dart';

enum StepAdjustmentVisualization {
  minusButtonValuePlusButton('Plus/Minus Buttons'),
  minusButtonValuePlusButtonClockwiseDial('Buttons with Clockwise Dial'),
  minusButtonValuePlusButtonCounterclockwiseDial('Buttons with Counterclockwise Dial'),
  slider('Slider'),
  sliderWithClockwiseDial('Slider with Clockwise Dial'),
  sliderWithCounterclockwiseDial('Slider with Counterclockwise Dial');
  
  final String value;
  const StepAdjustmentVisualization(this.value);
}

class StepAdjustment extends Adjustment {
  final int step;
  final int min;
  final int max;
  final StepAdjustmentVisualization visualization;

  static const IconData iconData = Icons.stairs_outlined;

  StepAdjustment({
    super.id,
    required super.name,
    required super.notes,
    required super.unit,
    required this.step,
    required this.min,
    required this.max,
    required this.visualization,
  });

  @override
  StepAdjustment deepCopy() {
    return StepAdjustment(
      name: name,
      notes: notes,
      unit: unit,
      step: step,
      min: min,
      max: max,
      visualization: visualization,
    );
  }

  @override
  bool isValidValue(dynamic value) {
    return value is int && value >= min && value <= max && ((value - min) % step == 0);
  }

  @override
  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'name': name,
    'notes': notes,
    'type': AdjustmentType.step.name,
    'unit': unit,
    'min': min,
    'max': max,
    'step': step,
    'visualization': visualization.toString(),
  };

  factory StepAdjustment.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null || 1:
        return StepAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: json['unit'] as String?,
          step: (json['step'] as num).toInt(),
          min: (json['min'] as num).toInt(),
          max: (json['max'] as num).toInt(),
          visualization: StepAdjustmentVisualization.values.firstWhere(
            (e) => e.toString() == json['visualization'],
            orElse: () => StepAdjustmentVisualization.slider,
          ),
        );
      default: throw Exception("Json Version $version of StepAdjustment incompatible.");
    }
  }

  @override
  IconData getIconData() => StepAdjustment.iconData;

  @override
  String getProperties() {
    return "Range ${Adjustment.formatValue(min)}..${Adjustment.formatValue(max)}, Step $step";
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StepAdjustment &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        name == other.name &&
        notes == other.notes &&
        unit == other.unit &&
        step == other.step &&
        min == other.min &&
        max == other.max &&
        visualization == other.visualization;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, notes, unit, step, min, max, visualization);
  }
}
