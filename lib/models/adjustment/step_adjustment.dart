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

class StepAdjustment extends Adjustment<int> {
  int step;
  int min;
  int max;
  StepAdjustmentVisualization visualization;

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
    return StepAdjustment(name: name, notes: notes, unit: unit, step: step, min: min, max: max, visualization: visualization);
  }

  @override
  bool isValidValue(dynamic value) {
    return value is int && value >= min && value <= max && ((value - min) % step == 0);
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'notes': notes,
    'type': 'step',
    'valueType': valueType.toString(),
    'unit': unit,
    'step': step,
    'min': min,
    'max': max,
    'visualization': visualization.toString(),
  };

  @override
  Icon getIcon({double? size, Color? color}) {
    return getIconStatic(size: size, color: color);
  }

  static Icon getIconStatic({double? size, Color? color}) {
    return Icon(Icons.stairs_outlined, size: size, color: color,);
  }

  @override
  String getProperties() {
    return "Range $min..$max, Step $step";
  }
}
