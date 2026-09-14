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

  bool get hasDial =>
      this != StepAdjustmentVisualization.slider &&
      this != StepAdjustmentVisualization.minusButtonValuePlusButton;

  bool get isClockwiseDial =>
      this == StepAdjustmentVisualization.sliderWithClockwiseDial ||
      this == StepAdjustmentVisualization.minusButtonValuePlusButtonClockwiseDial;
}

enum StepAdjustmentDialColor {
  blue,
  red,
  green,
  brown,
  orange,
  purple,
  grey;
}

enum StepAdjustmentDialSize { normal, small }

class StepAdjustment extends Adjustment {
  final int step;
  final int min;
  final int max;
  final StepAdjustmentVisualization visualization;
  final StepAdjustmentDialColor dialColor;
  final StepAdjustmentDialSize dialSize;

  static const IconData iconData = Icons.stairs_outlined;

  StepAdjustment({
    super.id,
    required super.name,
    required super.notes,
    required super.unit,
    super.presetKey,
    required this.step,
    required this.min,
    required this.max,
    required this.visualization,
    this.dialColor = StepAdjustmentDialColor.blue,
    this.dialSize = StepAdjustmentDialSize.normal,
  });

  @override
  StepAdjustment deepCopy() {
    return StepAdjustment(
      name: name,
      notes: notes,
      unit: unit,
      presetKey: presetKey,
      step: step,
      min: min,
      max: max,
      visualization: visualization,
      dialColor: dialColor,
      dialSize: dialSize,
    );
  }

  StepAdjustment copyWith({
    Object? id = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? unit = const _Sentinel(),
    Object? presetKey = const _Sentinel(),
    Object? step = const _Sentinel(),
    Object? min = const _Sentinel(),
    Object? max = const _Sentinel(),
    Object? visualization = const _Sentinel(),
    Object? dialColor = const _Sentinel(),
    Object? dialSize = const _Sentinel(),
  }) {
    return StepAdjustment(
      id: id is _Sentinel ? this.id : (id as String),
      name: name is _Sentinel ? this.name : (name as String),
      notes: notes is _Sentinel ? this.notes : (notes as String?),
      unit: unit is _Sentinel ? this.unit : (unit as AdjustmentUnit?),
      presetKey: presetKey is _Sentinel ? this.presetKey : (presetKey as String?),
      step: step is _Sentinel ? this.step : (step as int),
      min: min is _Sentinel ? this.min : (min as int),
      max: max is _Sentinel ? this.max : (max as int),
      visualization: visualization is _Sentinel ? this.visualization : (visualization as StepAdjustmentVisualization),
      dialColor: dialColor is _Sentinel ? this.dialColor : (dialColor as StepAdjustmentDialColor),
      dialSize: dialSize is _Sentinel ? this.dialSize : (dialSize as StepAdjustmentDialSize),
    );
  }

  @override
  bool isValidValue(dynamic value) {
    return value is int && value >= min && value <= max && ((value - min) % step == 0);
  }

  @override
  Map<String, dynamic> toJson() => {
    'version': 2,
    'id': id,
    'name': name,
    'notes': notes,
    'type': AdjustmentType.step.name,
    'unit': unit?.encode(),
    'presetKey': presetKey,
    'min': min,
    'max': max,
    'step': step,
    'visualization': visualization.toString(),
    'dialColor': dialColor.name,
    'dialSize': dialSize.name,
  };

  factory StepAdjustment.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"] as int?;
    switch (version) {
      case null || 1 || 2:
        return StepAdjustment(
          id: json["id"] as String?,
          name: json['name'] as String,
          notes: json['notes'] as String?,
          unit: AdjustmentUnit.decode(json['unit'] as String?),
          presetKey: json['presetKey'] as String?,
          step: (json['step'] as num).toInt(),
          min: (json['min'] as num).toInt(),
          max: (json['max'] as num).toInt(),
          visualization: StepAdjustmentVisualization.values.firstWhere(
            (e) => e.toString() == json['visualization'] as String?,
            orElse: () => StepAdjustmentVisualization.slider,
          ),
          dialColor: StepAdjustmentDialColor.values.firstWhere(
            (e) => e.name == json['dialColor'] as String?,
            orElse: () => StepAdjustmentDialColor.blue,
          ),
          dialSize: StepAdjustmentDialSize.values.firstWhere(
            (e) => e.name == json['dialSize'] as String?,
            orElse: () => StepAdjustmentDialSize.normal,
          ),
        );
      default: throw Exception("Json Version $version of StepAdjustment incompatible.");
    }
  }

  static StepAdjustmentVisualization _visualizationFromYaml(String? name) {
    switch (name) {
      case null:
      case 'dial_ccw':
        return StepAdjustmentVisualization.sliderWithCounterclockwiseDial;
      case 'dial_cw':
        return StepAdjustmentVisualization.sliderWithClockwiseDial;
      case 'stepper':
        return StepAdjustmentVisualization.minusButtonValuePlusButton;
      case 'slider':
        return StepAdjustmentVisualization.slider;
      default:
        throw ArgumentError('Unknown step visualization "$name"');
    }
  }

  factory StepAdjustment.fromYaml(Map<String, dynamic> map) {
    _checkPresetKeys(map, const {
      'name', 'type', 'min', 'max', 'step', 'unit', 'visualization', 'notes',
    });
    final max = (map['max'] as num?)?.toInt();
    if (max == null) {
      throw ArgumentError('Step adjustment "${map['name']}" requires "max"');
    }
    return StepAdjustment(
      name: _requirePresetName(map),
      notes: map['notes'] as String?,
      unit: AdjustmentUnit.fromLegacy(map['unit'] as String?),
      min: (map['min'] as num?)?.toInt() ?? 0,
      max: max,
      step: (map['step'] as num?)?.toInt() ?? 1,
      visualization: _visualizationFromYaml(map['visualization'] as String?),
    );
  }

  @override
  IconData getIconData() => StepAdjustment.iconData;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StepAdjustment &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        name == other.name &&
        notes == other.notes &&
        unit == other.unit &&
        presetKey == other.presetKey &&
        step == other.step &&
        min == other.min &&
        max == other.max &&
        visualization == other.visualization &&
        dialColor == other.dialColor &&
        dialSize == other.dialSize;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, notes, unit, presetKey, step, min, max, visualization, dialColor, dialSize);
  }
}
