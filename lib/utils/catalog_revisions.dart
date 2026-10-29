import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/component/component_catalog.dart';
import 'component_preset_resolver.dart';

/// Brings components built from an older revision of their brand file up to
/// date: `fix` changes apply silently, `review` changes wait for the rider.

/// A level matches its node, an axis the chosen value, so a skipped option
/// matches nothing.
bool catalogChangeApplies(CatalogChange change, ResolvedPreset resolved) => change.when.entries.every((entry) {
  final Object? actual =
      resolved.path.firstWhereOrNull((node) => node.level == entry.key)?.id ?? resolved.selections[entry.key]?.id;
  return actual != null && entry.value.contains(actual);
});

/// The changes after [revision] that apply to [resolved], oldest first.
List<CatalogChange> catalogChangesSince(ResolvedPreset resolved, int revision) => [
  for (final change in resolved.catalog.changes)
    if (change.revision > revision && catalogChangeApplies(change, resolved)) change,
];

/// [adjustments] with each of the [changes]' fixes applied to the adjustments
/// built from its adjuster. [recordedValues] holds every recorded value by
/// adjustment id; a fix that would leave one of them invalid is skipped.
List<Adjustment> applyCatalogFixes(
  List<Adjustment> adjustments,
  ResolvedPreset resolved,
  Iterable<CatalogChange> changes,
  Map<String, List<AdjustmentValue>> recordedValues,
) {
  final specs = [
    ...?resolved.product?.adjustments,
    for (final value in resolved.selections.values) ...value.adjustments,
  ];
  var result = adjustments;
  for (final fix in changes.whereType<CatalogFix>()) {
    final spec = specs.firstWhereOrNull((spec) => spec.id == fix.adjuster);
    if (spec == null) continue;
    result = [
      for (final adjustment in result)
        if (adjustment.presetKey == spec.presetKey)
          _fixed(adjustment, spec, fix, recordedValues[adjustment.id] ?? const []) ?? adjustment
        else
          adjustment,
    ];
  }
  return result;
}

/// [own] corrected by [fix], or null where it does not apply or is unsafe.
Adjustment? _fixed(Adjustment own, PresetAdjustmentSpec spec, CatalogFix fix, List<AdjustmentValue> recorded) {
  final Adjustment? fixed;
  switch (fix) {
    case CatalogFieldFix(:final field, :final from, :final to):
      // A field the rider edited is theirs.
      final before = spec.buildWith(field, from);
      if (own.runtimeType != before.runtimeType || field.read(own) != field.read(before)) return null;
      fixed = field.write(own, field.read(spec.buildWith(field, to)));
    case CatalogStepFix(:final step, :final stepId):
      try {
        fixed = step(CatalogStepContext(adjustment: own, catalog: spec.build(), recorded: recorded));
      } catch (e, st) {
        // One faulty step must not hold back the other components.
        debugPrint('Catalog migration step "$stepId" failed: $e\n$st');
        return null;
      }
  }
  if (fixed == null || fixed == own) return null;
  return _isSafe(own, fixed, recorded) ? fixed : null;
}

/// A fix may change how an adjustment reads, never what its values mean: the
/// id, type and preset key stay, the range stays a range and every recorded
/// value stays valid.
bool _isSafe(Adjustment own, Adjustment fixed, List<AdjustmentValue> recorded) {
  final hasRange = switch (fixed) {
    StepAdjustment(:final min, :final max) => min < max,
    NumericalAdjustment(:final min, :final max) => min < max,
    _ => true,
  };
  return fixed.id == own.id &&
      fixed.runtimeType == own.runtimeType &&
      fixed.presetKey == own.presetKey &&
      hasRange &&
      recorded.every(fixed.isValidValue);
}

/// [component] with the fixes since its revision applied, and its revision
/// raised as far as no pending review holds it back; null when nothing changes.
Component? migrateCatalogFixes(
  Component component,
  ResolvedPreset resolved,
  Map<String, List<AdjustmentValue>> recordedValues,
) {
  final preset = component.preset;
  if (preset == null) return null;
  final changes = catalogChangesSince(resolved, preset.revision);
  final firstReview = changes.whereType<CatalogReview>().firstOrNull;
  final revision = max(preset.revision, firstReview == null ? resolved.catalog.revision : firstReview.revision - 1);
  final adjustments = applyCatalogFixes(component.adjustments, resolved, changes, recordedValues);
  if (revision == preset.revision && listEquals(adjustments, component.adjustments)) return null;
  return component.copyWith(adjustments: adjustments, preset: preset.withRevision(revision));
}

/// The reviews [resolved]'s component has not accepted or dismissed yet.
List<CatalogReview> pendingCatalogReviews(ResolvedPreset resolved, int revision) =>
    catalogChangesSince(resolved, revision).whereType<CatalogReview>().toList();
