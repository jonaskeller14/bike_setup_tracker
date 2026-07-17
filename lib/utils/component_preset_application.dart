import '../models/adjustment/adjustment.dart';
import '../models/component.dart';
import '../models/component_preset.dart';

const String kForkSagNotes =
    'Sag is how much your fork compresses under your body weight (including '
    'riding gear) in a static riding position. SAG is a good metric for initial '
    'setup. Recommended ranges by discipline: XC: 15%, Trail: 15-20%, '
    'Enduro: 20%, Downhill: 20-25%.';
const String kShockSagNotes =
    'Sag is how much your shock compresses under your body weight (including '
    'riding gear) in a static riding position. SAG is a good metric for initial '
    'setup. Recommended ranges by discipline: XC: 20-25%, Trail: 25-30%, '
    'Enduro: 30%, Downhill: 30-35%.';

/// Turns a selected [ComponentPresetVariant] (+ optionally the chosen [damper])
/// into [PresetApplication] form-fill data — the Phase 2 prefill engine (C6).
///
/// Pure logic, no UI. Combine order for the adjustment list is
/// **trim/model specs → auto-injected SAG (fork/shock only) → damper specs**,
/// mirroring the on-screen order documented in SCHEMA.md. Every adjustment is
/// instantiated fresh (new UUIDs) so the result is indistinguishable from a
/// hand-built component.
///
/// [damper] is what the picker's damper stage returns. When the variant carries
/// exactly one damper it is resolved automatically (the picker skips that stage),
/// so callers may omit it; when the variant carries several, the caller must
/// pass the chosen one for its adjustments to be included and for the name to be
/// disambiguated by damper.
PresetApplication buildApplication(
  ComponentPresetVariant variant, [
  DamperSpec? damper,
]) {
  final resolvedDamper = damper ??
      (variant.dampers.length == 1 ? variant.dampers.single : null);

  return PresetApplication(
    name: _buildName(variant, resolvedDamper),
    componentType: variant.componentType,
    notes: _buildNotes(variant, resolvedDamper),
    adjustments: _buildAdjustments(variant, resolvedDamper),
  );
}

String presetVariantDisplayName(ComponentPresetVariant variant, [DamperSpec? damper]) {
  final parts = <String>[variant.brand, variant.model, variant.trim];
  if (variant.dampers.length > 1 && damper != null) {
    parts.add(damper.name);
  }
  return parts.where((p) => p.isNotEmpty).join(' ');
}

String _buildName(ComponentPresetVariant variant, DamperSpec? damper) =>
    presetVariantDisplayName(variant, damper);

String _buildNotes(ComponentPresetVariant variant, DamperSpec? damper) {
  final lines = <String>[];

  if (damper != null) {
    final description = damper.description;
    lines.add(description == null || description.isEmpty
        ? 'Damper: ${damper.name}'
        : 'Damper: ${damper.name} — $description');
  }
  if (_isNotBlank(variant.springLabel)) {
    lines.add('Spring: ${variant.springLabel}');
  }
  if (variant.componentType == ComponentType.fork && variant.travelOptions.isNotEmpty) {
    lines.add('Travel: ${variant.travelOptions.join(' / ')} mm');
  }
  if (variant.componentType == ComponentType.shock && variant.strokeOptions.isNotEmpty) {
    lines.add('Stroke: ${variant.strokeOptions.join(' / ')}');
  }
  if (variant.wheelSizes.isNotEmpty) {
    lines.add('Wheel size: ${variant.wheelSizes.join(' / ')}');
  }
  if (_isNotBlank(variant.stanchion)) {
    lines.add('Stanchion: ${variant.stanchion}');
  }
  if (_isNotBlank(variant.yearRange)) {
    lines.add('Year: ${variant.yearRange}');
  }
  if (_isNotBlank(variant.note)) {
    lines.add(variant.note!);
  }
  if (_isNotBlank(variant.url)) {
    lines.add(variant.url!);
  }

  return lines.join('\n');
}

List<Adjustment> _buildAdjustments(
  ComponentPresetVariant variant,
  DamperSpec? damper,
) {
  return [
    for (final spec in variant.adjustmentSpecs) spec.build(),
    if (_takesSag(variant.componentType)) _buildSag(variant),
    if (damper != null)
      for (final spec in damper.adjustmentSpecs) spec.build(),
  ];
}

bool _takesSag(ComponentType type) =>
    type == ComponentType.fork || type == ComponentType.shock;

SagAdjustment _buildSag(ComponentPresetVariant variant) {
  return SagAdjustment(
    name: 'SAG',
    notes: variant.componentType == ComponentType.shock ? kShockSagNotes : kForkSagNotes,
    referenceTravelMm: _sagReferenceTravel(variant),
  );
}

double? _sagReferenceTravel(ComponentPresetVariant variant) {
  switch (variant.componentType) {
    case ComponentType.fork:
      return variant.travelOptions.length == 1
          ? variant.travelOptions.single.toDouble()
          : null;
    case ComponentType.shock:
      return variant.strokeOptions.length == 1
          ? double.tryParse(variant.strokeOptions.single)
          : null;
    default:
      return null;
  }
}

bool _isNotBlank(String? value) => value != null && value.isNotEmpty;
