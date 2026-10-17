import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../models/adjustment/adjustment.dart';
import 'adjustment_role.dart';

enum PresetMergeAction { merged, newAdjustment, notAdded }

/// What linking a catalog product does with one of its adjusters on a
/// component that already has adjustments: merged into an [existing] one, added
/// as a new adjustment, or not added.
@immutable
class PresetMergeRow {
  final Adjustment catalog;
  final PresetMergeAction action;

  /// The component's adjustment the catalog adjuster is merged into; set only
  /// for [PresetMergeAction.merged].
  final Adjustment? existing;

  const PresetMergeRow.merged(this.catalog, Adjustment this.existing) : action = PresetMergeAction.merged;
  const PresetMergeRow.newAdjustment(this.catalog) : action = PresetMergeAction.newAdjustment, existing = null;
  const PresetMergeRow.notAdded(this.catalog) : action = PresetMergeAction.notAdded, existing = null;

  @override
  bool operator ==(Object other) =>
      other is PresetMergeRow && catalog == other.catalog && action == other.action && existing == other.existing;

  @override
  int get hashCode => Object.hash(catalog, action, existing);
}

/// Whether [existing] can take over [catalog]: types never cross, and SAG only
/// merges with SAG, since a merge never changes the type.
bool canMergeAdjustment(Adjustment existing, Adjustment catalog) =>
    existing.type == catalog.type && (existing is SagAdjustment) == (catalog is SagAdjustment);

/// The proposed row per [catalog] adjuster, in catalog order: each is merged
/// into an [existing] adjustment of the same type with the same role, else with
/// the same name, else added as new. An existing adjustment is merged at most once.
List<PresetMergeRow> proposePresetMerge(List<Adjustment> existing, List<Adjustment> catalog) {
  final matches = <Adjustment, Adjustment>{};

  void matchBy(String? Function(Adjustment) catalogKey, String? Function(Adjustment) existingKey) {
    for (final candidate in catalog) {
      if (matches.containsKey(candidate)) continue;
      final key = catalogKey(candidate);
      if (key == null) continue;
      final match = existing.firstWhereOrNull(
        (adjustment) =>
            !matches.containsValue(adjustment) &&
            canMergeAdjustment(adjustment, candidate) &&
            existingKey(adjustment) == key,
      );
      if (match != null) matches[candidate] = match;
    }
  }

  matchBy(adjustmentRole, adjustmentRole);
  matchBy((a) => adjustmentNameSlug(a.name), (a) => adjustmentNameSlug(a.name));

  return [
    for (final candidate in catalog)
      if (matches[candidate] case final match?)
        PresetMergeRow.merged(candidate, match)
      else
        PresetMergeRow.newAdjustment(candidate),
  ];
}

@immutable
class MergedAdjustment {
  final Adjustment adjustment;

  /// The catalog range differs but wasn't adopted because a recorded value
  /// would fall outside it.
  final bool keptOwnRange;

  const MergedAdjustment(this.adjustment, {this.keptOwnRange = false});
}

/// [existing] taking over [catalog]: its id, name, unit and type stay, so every
/// [recorded] value still resolves, and it gets the catalog's preset key.
///
/// It adopts the catalog range only while every recorded value stays valid; a
/// numerical range only in the same unit. A categorical adjustment gains the
/// catalog options it lacks, so option values of a guide can be applied.
MergedAdjustment mergeAdjustment(Adjustment existing, Adjustment catalog, Iterable<AdjustmentValue> recorded) {
  final stamped = existing.copyWith(presetKey: catalog.presetKey);
  final Adjustment? withRange = switch ((stamped, catalog)) {
    // A placeholder max is a guess; the rider's own range is better.
    (StepAdjustment(), StepAdjustment(:final notes)) when notes?.contains(StepAdjustment.unknownMaxWarning) ?? false =>
      null,
    (final StepAdjustment own, final StepAdjustment c) => own.copyWith(min: c.min, max: c.max, step: c.step),
    (SagAdjustment(), _) => null,
    (final NumericalAdjustment own, final NumericalAdjustment c) when own.unit == c.unit => own.copyWith(
      min: c.min,
      max: c.max,
    ),
    (final CategoricalAdjustment own, final CategoricalAdjustment c) => own.copyWith(
      options: {...own.options, ...c.options},
    ),
    _ => null,
  };
  if (withRange == null || withRange == stamped) return MergedAdjustment(stamped);
  if (recorded.every(withRange.isValidValue)) return MergedAdjustment(withRange);
  return MergedAdjustment(stamped, keptOwnRange: true);
}

@immutable
class PresetMergeResult {
  /// [existing] in its order with the merged ones replaced, then the new ones.
  final List<Adjustment> adjustments;
  final List<Adjustment> newAdjustments;

  /// The component's adjustments that are no longer in [adjustments].
  final List<Adjustment> removed;

  const PresetMergeResult(this.adjustments, this.newAdjustments, {this.removed = const []});
}

/// Applies the confirmed [rows] to [existing]. Adjustments no row merges stay
/// untouched; [recordedValues] holds every recorded value by adjustment id.
PresetMergeResult applyPresetMerge(
  List<Adjustment> existing,
  List<PresetMergeRow> rows,
  Map<String, List<AdjustmentValue>> recordedValues,
) {
  final merged = <String, Adjustment>{
    for (final row in rows)
      if (row.existing case final own?)
        own.id: mergeAdjustment(own, row.catalog, recordedValues[own.id] ?? const []).adjustment,
  };
  final newAdjustments = [
    for (final row in rows)
      if (row.action == PresetMergeAction.newAdjustment) row.catalog,
  ];
  return PresetMergeResult(
    [for (final adjustment in existing) merged[adjustment.id] ?? adjustment, ...newAdjustments],
    newAdjustments,
  );
}

/// Drops every [existing] adjustment for the [catalog] ones.
PresetMergeResult replaceWithPreset(List<Adjustment> existing, List<Adjustment> catalog) =>
    PresetMergeResult(List.of(catalog), List.of(catalog), removed: List.of(existing));

/// [recordedValues] as they will be stored once the [migrations] staged for
/// unsaved adjustment edits are applied, so a range is checked in the unit it
/// has. A value a migration clears is left out.
Map<String, List<AdjustmentValue>> migrateRecordedValues(
  Map<String, List<AdjustmentValue>> recordedValues,
  Map<String, ValueMigration> migrations,
) => {
  for (final MapEntry(:key, :value) in recordedValues.entries)
    key: switch (migrations[key]) {
      final migration? => [for (final recorded in value) ?migration.apply(recorded)],
      null => value,
    },
};
