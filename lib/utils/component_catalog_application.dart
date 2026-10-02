import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/component/component_catalog.dart';
import '../models/component/preset_spec_keys.dart';
import 'component_preset_application.dart' show kForkSagNotes, kShockSagNotes;
import 'component_preset_resolver.dart';

/// A generation's label is its year span, which the `Year:` note line and the
/// year badge already carry.
const String _generationLevel = 'generation';

/// Turns a [resolved] catalog selection into [CatalogApplication] form-fill
/// data.
///
/// Pure logic, no UI. Combine order for the adjustment list is
/// **product specs → auto-injected SAG (fork/shock only) → option-value specs**,
/// mirroring the on-screen order documented in SCHEMA.md. Every adjustment is
/// instantiated fresh (new UUIDs) so the result is indistinguishable from a
/// hand-built component.
///
/// A required axis that is still open contributes no adjustments, and an
/// optional axis that was skipped leaves its spec (e.g. the SAG travel) unset.
CatalogApplication buildCatalogApplication(ResolvedPreset resolved) {
  return CatalogApplication(
    name: presetDisplayName(resolved),
    componentType: resolved.catalog.componentType,
    notes: _buildNotes(resolved),
    adjustments: _buildAdjustments(resolved),
    preset: toPresetMap(resolved),
  );
}

/// `FOX 36 Factory GRIP X2`: the brand, the path, and the chosen value of every
/// required axis that offered a choice.
String presetDisplayName(ResolvedPreset resolved) {
  return [
    resolved.catalog.brand,
    for (final node in resolved.path)
      if (node.level != _generationLevel) node.label,
    for (final axis in resolved.axes)
      if (axis.required && axis.values.length > 1) ?resolved.selections[axis.id]?.label,
  ].join(' ');
}

String _buildNotes(ResolvedPreset resolved) {
  final node = resolved.node;
  final axes = resolved.axes;
  final specs = resolved.effectiveSpecs;
  return [
    for (final axis in axes) '${axis.key.label}: ${_optionText(axis, resolved.selections[axis.id])}',
    for (final key in PresetSpecKeys.values)
      // A literal axis has its own line above.
      if (!axes.any((axis) => axis.key.spec == key)) ?_specLine(key, specs),
    if (_isNotBlank(node.years)) 'Year: ${node.years}',
    if (_isNotBlank(node.note)) node.note!,
    if (_isNotBlank(node.url)) node.url!,
  ].join('\n');
}

/// The chosen value, or everything the product can be had with.
String _optionText(OptionAxis axis, OptionValue? selected) {
  if (selected != null) {
    final description = selected.description;
    return _isNotBlank(description) ? '${selected.label} — $description' : selected.label;
  }
  final unit = axis.key.spec?.unit;
  if (unit == null) return axis.values.map((value) => value.label).join(' / ');
  // `150 / 160 mm` instead of the unit on every value. A literal value is its own id.
  final values = axis.values.map(
    (value) => switch (value.id) {
      final num number => formatSpecNumber(number),
      final id => id.toString(),
    },
  );
  return '${values.join(' / ')} $unit';
}

String? _specLine(SpecKey<Object> key, Specs specs) {
  final value = specs.get(key);
  return value == null ? null : '${key.label}: ${key.format(value)}';
}

List<Adjustment> _buildAdjustments(ResolvedPreset resolved) {
  return [
    ...?resolved.product?.adjustments.map((spec) => spec.build()),
    if (_takesSag(resolved.catalog.componentType)) _buildSag(resolved),
    for (final value in resolved.selections.values)
      for (final spec in value.adjustments) spec.build(),
  ];
}

bool _takesSag(ComponentType type) => type == ComponentType.fork || type == ComponentType.shock;

SagAdjustment _buildSag(ResolvedPreset resolved) {
  final isShock = resolved.catalog.componentType == ComponentType.shock;
  // Set by the chosen travel (fork) or size (shock); a one-time copy the user
  // edits on the SAG adjustment afterwards.
  final travel = resolved.effectiveSpecs.get(isShock ? PresetSpecKeys.strokeMm : PresetSpecKeys.travelMm);
  return SagAdjustment(
    name: 'SAG',
    notes: isShock ? kShockSagNotes : kForkSagNotes,
    referenceTravelMm: travel?.toDouble(),
  );
}

bool _isNotBlank(String? value) => value != null && value.isNotEmpty;
