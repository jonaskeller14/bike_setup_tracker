import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/component/component_catalog.dart';
import '../models/component/preset_spec_keys.dart';
import 'component_preset_resolver.dart';

const String kForkSagNotes =
    'Travel used with you and your gear on the bike in riding position. '
    'Targets: XC 15%, Trail 15-20%, Enduro 20%, DH 20-25%';
const String kShockSagNotes =
    'Travel used with you and your gear on the bike in riding position. '
    'Targets: XC 20-25%, Trail 25-30%, Enduro 30%, DH 30-35%';

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
    preset: toComponentPreset(resolved),
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

/// A short dash list of what the rider would otherwise look up: the chosen
/// configuration, the spring, the model years, the product note and any
/// adjuster to add by hand, then the setup guide link. Options the rider skipped
/// and the damper's internals are left out.
String _buildNotes(ResolvedPreset resolved) {
  final node = resolved.node;
  final chosen = [
    for (final axis in resolved.axes) ?resolved.selections[axis.id],
  ];
  final damper = resolved.selections[PresetOptionAxes.damper.id];
  final missing = [
    ...node.missingAdjustments,
    for (final value in chosen) ...value.missingAdjustments,
  ];
  final setupGuide = node.setupGuide;
  final bullets = [
    if (damper != null) 'Damper: ${damper.label}',
    _joined([
      for (final axis in resolved.axes)
        if (axis.id != PresetOptionAxes.damper.id) ?_chosenText(axis, resolved.selections[axis.id]),
    ]),
    _joined(_specTexts(resolved, chosen)),
    if (_isNotBlank(node.years)) 'Model years: ${node.years}',
    ..._noteLines(node.note),
    if (missing.isNotEmpty) 'Not in the catalog yet, add by hand: ${missing.join(', ')}',
  ].where(_isNotBlank).map((line) => line!.startsWith('- ') ? line : '- $line');
  return [
    bullets.join('\n'),
    if (_isNotBlank(setupGuide)) 'Setup guide: $setupGuide',
  ].where(_isNotBlank).join('\n\n');
}

String? _chosenText(OptionAxis axis, OptionValue? selected) =>
    selected == null ? null : '${axis.key.label}: ${selected.label}';

/// Spec facts the chosen values do not already name. A size's label carries
/// its lengths but not its mount, so the mount stays.
List<String> _specTexts(ResolvedPreset resolved, List<OptionValue> chosen) {
  final covered = {
    for (final value in chosen) ...value.specs.keys,
  }..remove(PresetSpecKeys.mount.id);
  final specs = resolved.effectiveSpecs;
  return [
    for (final key in PresetSpecKeys.values)
      if (!covered.contains(key.id)) ?_specText(key, specs),
  ];
}

String? _specText(SpecKey<Object> key, Specs specs) {
  final value = specs.get(key);
  return value == null ? null : '${key.label}: ${key.format(value)}';
}

/// A note authored as a dash list keeps its lines; prose becomes one bullet.
List<String> _noteLines(String? note) {
  if (!_isNotBlank(note)) return const [];
  final lines = note!.trim().split('\n').where((line) => line.trim().isNotEmpty).toList();
  return lines.every((line) => line.startsWith('- ')) ? lines : [lines.join(' ')];
}

String? _joined(List<String> parts) => parts.isEmpty ? null : parts.join(' · ');

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
