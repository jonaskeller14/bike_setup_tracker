import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../../utils/unit_conversion.dart';
import 'adjustment.dart';

@immutable
sealed class ValueMigrationStep {
  const ValueMigrationStep();

  /// The rewritten [value], or `null` to remove the value row. Clearing a
  /// value always removes its row, also for a categorical, because an empty
  /// single-select selection is flagged as an error in the setup form.
  AdjustmentValue? apply(AdjustmentValue value);
}

final class ConvertUnitStep extends ValueMigrationStep {
  final KnownUnit from;
  final KnownUnit to;

  const ConvertUnitStep(this.from, this.to);

  @override
  AdjustmentValue? apply(AdjustmentValue value) =>
      value is NumericalValue ? NumericalValue(convertUnit(value.value, from, to)) : value;

  @override
  bool operator ==(Object other) => other is ConvertUnitStep && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(ConvertUnitStep, from, to);

  @override
  String toString() => 'ConvertUnitStep(${from.encode()} -> ${to.encode()})';
}

/// Renames or deletes options. All options are mapped at once from the
/// original selection, so swapping two options works. A `null` target drops
/// the option from the selection, and a selection left empty loses its row. It does not remove duplicates a mapping may
/// create; follow with [DedupeOptionsStep] when the adjustment is not counted.
final class MapOptionsStep extends ValueMigrationStep {
  final Map<String, String?> mapping;

  MapOptionsStep(Map<String, String?> mapping) : mapping = Map.unmodifiable(mapping);

  @override
  AdjustmentValue? apply(AdjustmentValue value) {
    if (value is! CategoricalValue) return value;
    final mapped = [
      for (final option in value.options)
        if (mapping.containsKey(option)) ?mapping[option] else option,
    ];
    return mapped.isEmpty && value.options.isNotEmpty ? null : CategoricalValue(mapped);
  }

  @override
  bool operator ==(Object other) =>
      other is MapOptionsStep && const MapEquality<String, String?>().equals(other.mapping, mapping);

  @override
  int get hashCode => Object.hash(MapOptionsStep, const MapEquality<String, String?>().hash(mapping));

  @override
  String toString() => 'MapOptionsStep($mapping)';
}

/// Removes repeated options, keeping the first occurrence of each.
final class DedupeOptionsStep extends ValueMigrationStep {
  const DedupeOptionsStep();

  @override
  AdjustmentValue? apply(AdjustmentValue value) =>
      value is CategoricalValue ? CategoricalValue(value.options.toSet().toList()) : value;

  @override
  bool operator ==(Object other) => other is DedupeOptionsStep;

  @override
  int get hashCode => (DedupeOptionsStep).hashCode;

  @override
  String toString() => 'DedupeOptionsStep()';
}

/// Turns a multi-option selection into one option, or clears it for a `null`
/// target. A selection matches a combination by its distinct options.
final class MapCombinationsStep extends ValueMigrationStep {
  final Map<Set<String>, String?> mapping;

  MapCombinationsStep(Map<Set<String>, String?> mapping)
    : mapping = Map.unmodifiable({
        for (final MapEntry(:key, :value) in mapping.entries) Set<String>.unmodifiable(key): value,
      });

  static const SetEquality<String> _setEquality = SetEquality<String>();

  @override
  AdjustmentValue? apply(AdjustmentValue value) {
    if (value is! CategoricalValue) return value;
    final selected = value.options.toSet();
    for (final MapEntry(key: combination, value: option) in mapping.entries) {
      if (_setEquality.equals(combination, selected)) return option == null ? null : CategoricalValue([option]);
    }
    return value;
  }

  @override
  bool operator ==(Object other) =>
      other is MapCombinationsStep &&
      other.mapping.length == mapping.length &&
      mapping.entries.every(
        (entry) => other.mapping.entries.any(
          (otherEntry) => _setEquality.equals(entry.key, otherEntry.key) && entry.value == otherEntry.value,
        ),
      );

  @override
  int get hashCode => Object.hash(
    MapCombinationsStep,
    Object.hashAllUnordered([
      for (final MapEntry(:key, :value) in mapping.entries) Object.hash(_setEquality.hash(key), value),
    ]),
  );

  @override
  String toString() => 'MapCombinationsStep($mapping)';
}

/// Moves values outside [range] to its nearest value (step values also snap
/// to the grid).
final class ClampToRangeStep extends ValueMigrationStep {
  final ValueRange range;

  const ClampToRangeStep(this.range);

  @override
  AdjustmentValue? apply(AdjustmentValue value) => range.clamp(value);

  @override
  bool operator ==(Object other) => other is ClampToRangeStep && other.range == range;

  @override
  int get hashCode => Object.hash(ClampToRangeStep, range);

  @override
  String toString() => 'ClampToRangeStep($range)';
}

/// Clears values outside [range].
final class ClearOutOfRangeStep extends ValueMigrationStep {
  final ValueRange range;

  const ClearOutOfRangeStep(this.range);

  @override
  AdjustmentValue? apply(AdjustmentValue value) => range.appliesTo(value) && !range.contains(value) ? null : value;

  @override
  bool operator ==(Object other) => other is ClearOutOfRangeStep && other.range == range;

  @override
  int get hashCode => Object.hash(ClearOutOfRangeStep, range);

  @override
  String toString() => 'ClearOutOfRangeStep($range)';
}

/// Clears every value.
final class ClearAllStep extends ValueMigrationStep {
  const ClearAllStep();

  @override
  AdjustmentValue? apply(AdjustmentValue value) => null;

  @override
  bool operator ==(Object other) => other is ClearAllStep;

  @override
  int get hashCode => (ClearAllStep).hashCode;

  @override
  String toString() => 'ClearAllStep()';
}

/// The ordered steps that rewrite every recorded value of one adjustment.
@immutable
class ValueMigration {
  final String adjustmentId;
  final List<ValueMigrationStep> steps;

  ValueMigration(this.adjustmentId, List<ValueMigrationStep> steps) : steps = List.unmodifiable(steps);

  bool get isNoOp => steps.isEmpty;

  /// The rewritten [value], or `null` when its row is to be removed.
  AdjustmentValue? apply(AdjustmentValue value) {
    AdjustmentValue? current = value;
    for (final step in steps) {
      if (current == null) return null;
      current = step.apply(current);
    }
    return current;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ValueMigration &&
          adjustmentId == other.adjustmentId &&
          const ListEquality<ValueMigrationStep>().equals(steps, other.steps));

  @override
  int get hashCode => Object.hash(adjustmentId, const ListEquality<ValueMigrationStep>().hash(steps));

  @override
  String toString() => 'ValueMigration($adjustmentId: $steps)';
}

class EditResult<T> {
  final T value;
  final List<ValueMigration> migrations;

  const EditResult(this.value, {this.migrations = const []});
}
