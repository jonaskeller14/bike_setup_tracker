import 'adjustment/adjustment.dart';
import 'component.dart';

/// In-memory model of the component-preset catalog (`data/component_presets/`).

/// Defers instantiation to selection time
class PresetAdjustmentSpec {
  final Map<String, dynamic> raw;

  const PresetAdjustmentSpec(this.raw);

  Adjustment build() => Adjustment.fromYaml(raw);
}

class DamperSpec {
  final String key;
  final String name;
  final String? description;
  final List<PresetAdjustmentSpec> adjustmentSpecs;
  final Map<String, dynamic> info;

  const DamperSpec({
    required this.key,
    required this.name,
    this.description,
    this.adjustmentSpecs = const [],
    this.info = const {},
  });
}

class ComponentPresetVariant {
  final String brand;
  final String model;
  final String trim;
  final ComponentType componentType;
  final String? category;
  final String? yearRange;

  /// Product page for this variant (trim-level `url` overrides the model-level).
  final String? url;

  /// Wheel sizes as authored (`29`, `27.5`, `700c`, …), stringified.
  final List<String> wheelSizes;

  /// Fork `travel_mm` options (numeric).
  final List<num> travelOptions;

  /// Shock `stroke_mm` options (may be descriptive strings), stringified.
  final List<String> strokeOptions;

  /// Informational spring label (`Air`, `Coil`, `DebonAir+`, …); no longer
  /// drives adjustment generation.
  final String? springLabel;

  /// Trim-level (spring) adjustment specs.
  final List<PresetAdjustmentSpec> adjustmentSpecs;

  /// Resolved dampers this trim can ship with (>1 = buyer-selectable).
  final List<DamperSpec> dampers;

  final String? stanchion;
  final String? note;

  const ComponentPresetVariant({
    required this.brand,
    required this.model,
    required this.trim,
    required this.componentType,
    this.category,
    this.yearRange,
    this.url,
    this.wheelSizes = const [],
    this.travelOptions = const [],
    this.strokeOptions = const [],
    this.springLabel,
    this.adjustmentSpecs = const [],
    this.dampers = const [],
    this.stanchion,
    this.note,
  });

  /// Stable, computed catalog identity — never persisted (see provenance
  /// decision). Used as an index key and for the CI duplicate check.
  String get presetKey => '${componentType.name}/$brand/$model/$trim';

  /// Compact travel/stroke label for subtitles: `160 mm`, `140–170 mm` for
  /// forks, the stroke options joined for shocks; `null` when unknown.
  String? get travelLabel {
    if (componentType == ComponentType.fork && travelOptions.isNotEmpty) {
      return travelOptions.length == 1
          ? '${travelOptions.single} mm'
          : '${travelOptions.first}–${travelOptions.last} mm';
    }
    if (componentType == ComponentType.shock && strokeOptions.isNotEmpty) {
      return strokeOptions.join(' / ');
    }
    return null;
  }
}

class PresetApplication {
  final String name;
  final ComponentType componentType;
  final String notes;
  final List<Adjustment> adjustments;

  const PresetApplication({
    required this.name,
    required this.componentType,
    required this.notes,
    required this.adjustments,
  });
}
