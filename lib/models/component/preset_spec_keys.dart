import 'package:collection/collection.dart';

import 'component.dart';

/// Registry of every key the component catalog (`data/component_presets/`) may
/// use under `specs:` and `options:`. The parser rejects anything unregistered,
/// so a typo fails the CI catalog test instead of being silently dropped.

/// A typed, registered `specs:` key.
class SpecKey<T extends Object> {
  final String id;
  final String label;
  final String? unit;
  final Set<ComponentType> componentTypes;
  final T? Function(Object raw) _convert;

  const SpecKey._(
    this.id,
    this.label,
    this._convert, {
    this.unit,
    required this.componentTypes,
  });

  /// Throws a [FormatException] when the authored [raw] value is not a [T].
  T parse(Object? raw) {
    final value = raw == null ? null : _convert(raw);
    if (value == null) {
      throw FormatException('Spec "$id" expects a $T value, got "$raw"');
    }
    return value;
  }

  String format(T value) {
    final text = value is num ? formatSpecNumber(value) : value.toString();
    return unit == null ? text : '$text $unit';
  }
}

/// A registered `options:` axis.
class OptionAxisKey {
  final String id;
  final String label;
  final Set<ComponentType> componentTypes;

  /// Set when the axis lists literal values of one spec (`travel_mm: [150, 160]`).
  /// Without it the values are defined elsewhere: under `option_values`, or by
  /// the size shorthand for [PresetOptionAxes.size].
  final SpecKey<Object>? spec;

  const OptionAxisKey._(
    this.id,
    this.label, {
    required this.componentTypes,
    this.spec,
  });
}

abstract final class PresetSpecKeys {
  static const travelMm = SpecKey<num>._(
    'travel_mm',
    'Travel',
    _asNum,
    unit: 'mm',
    componentTypes: {ComponentType.fork},
  );
  static const wheelSize = SpecKey<String>._(
    'wheel_size',
    'Wheel size',
    _asText,
    componentTypes: {ComponentType.fork},
  );
  static const stanchion = SpecKey<String>._(
    'stanchion',
    'Stanchion',
    _asText,
    componentTypes: _suspension,
  );
  static const spring = SpecKey<String>._(
    'spring',
    'Spring',
    _asText,
    componentTypes: _suspension,
  );
  static const eyeToEyeMm = SpecKey<num>._(
    'eye_to_eye_mm',
    'Eye-to-eye',
    _asNum,
    unit: 'mm',
    componentTypes: {ComponentType.shock},
  );
  static const strokeMm = SpecKey<num>._(
    'stroke_mm',
    'Stroke',
    _asNum,
    unit: 'mm',
    componentTypes: {ComponentType.shock},
  );
  static const mount = SpecKey<String>._(
    'mount',
    'Mount',
    _asText,
    componentTypes: {ComponentType.shock},
  );

  static const List<SpecKey<Object>> values = [
    travelMm,
    wheelSize,
    stanchion,
    spring,
    eyeToEyeMm,
    strokeMm,
    mount,
  ];

  static SpecKey<Object>? byId(String id) => values.firstWhereOrNull((key) => key.id == id);
}

abstract final class PresetOptionAxes {
  static const damper = OptionAxisKey._(
    'damper',
    'Damper',
    componentTypes: _suspension,
  );
  static const travelMm = OptionAxisKey._(
    'travel_mm',
    'Travel',
    componentTypes: {ComponentType.fork},
    spec: PresetSpecKeys.travelMm,
  );
  static const wheelSize = OptionAxisKey._(
    'wheel_size',
    'Wheel size',
    componentTypes: {ComponentType.fork},
    spec: PresetSpecKeys.wheelSize,
  );
  static const size = OptionAxisKey._(
    'size',
    'Size',
    componentTypes: {ComponentType.shock},
  );

  static const List<OptionAxisKey> values = [damper, travelMm, wheelSize, size];

  static OptionAxisKey? byId(String id) => values.firstWhereOrNull((axis) => axis.id == id);
}

/// Typed spec values of a catalog node or option value.
class Specs {
  final Map<String, Object> _values;

  const Specs(this._values);

  static const Specs empty = Specs({});

  T? get<T extends Object>(SpecKey<T> key) => _values[key.id] as T?;

  Iterable<String> get keys => _values.keys;

  /// [other] wins where both carry the same key.
  Specs mergedWith(Specs other) => Specs({..._values, ...other._values});
}

/// `52.5` stays `52.5`, `55.0` becomes `55` — sizes are authored either way.
String formatSpecNumber(num value) => value == value.roundToDouble() ? value.toInt().toString() : value.toString();

const Set<ComponentType> _suspension = {ComponentType.fork, ComponentType.shock};

num? _asNum(Object raw) => raw is num ? raw : null;

String? _asText(Object raw) => switch (raw) {
  String() => raw.isEmpty ? null : raw,
  num() => formatSpecNumber(raw),
  _ => null,
};
