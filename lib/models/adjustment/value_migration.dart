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

final class ClampToRangeStep extends ValueMigrationStep {
  final Adjustment target;

  const ClampToRangeStep(this.target);

  @override
  AdjustmentValue? apply(AdjustmentValue value) {
    final target = this.target;
    return switch ((target, value)) {
      (final NumericalAdjustment target, final NumericalValue value) => NumericalValue(
        value.value < target.min
            ? target.min
            : value.value > target.max
            ? target.max
            : value.value,
      ),
      (final DurationAdjustment target, final DurationValue value) => DurationValue(
        target.min != null && value.value < target.min!
            ? target.min!
            : target.max != null && value.value > target.max!
            ? target.max!
            : value.value,
      ),
      (final StepAdjustment target, final StepValue value) => StepValue(_snapToGrid(target, value.value)),
      _ => value,
    };
  }

  static int _snapToGrid(StepAdjustment target, int value) {
    if (value <= target.min) return target.min;
    if (target.step <= 0) return value < target.max ? value : target.max;
    final snapped = target.min + ((value - target.min) / target.step).round() * target.step;
    if (snapped <= target.max) return snapped;
    return target.min + (target.max - target.min) ~/ target.step * target.step;
  }

  @override
  bool operator ==(Object other) => other is ClampToRangeStep && other.target == target;

  @override
  int get hashCode => Object.hash(ClampToRangeStep, target);

  @override
  String toString() => 'ClampToRangeStep(${target.name})';
}

/// Clears values that [target] does not accept.
final class ClearInvalidStep extends ValueMigrationStep {
  final Adjustment target;

  const ClearInvalidStep(this.target);

  @override
  AdjustmentValue? apply(AdjustmentValue value) =>
      value.matches(target.type) && !target.isValidValue(value) ? null : value;

  @override
  bool operator ==(Object other) => other is ClearInvalidStep && other.target == target;

  @override
  int get hashCode => Object.hash(ClearInvalidStep, target);

  @override
  String toString() => 'ClearInvalidStep(${target.name})';
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

  ValueMigration(this.adjustmentId, List<ValueMigrationStep> steps)
    : steps = List.unmodifiable(_mergeUnitConversions(steps));

  /// Adjacent conversions merge into one, and one that returns to its starting
  /// unit disappears, so a round trip leaves the values untouched.
  static List<ValueMigrationStep> _mergeUnitConversions(List<ValueMigrationStep> steps) {
    final merged = <ValueMigrationStep>[];
    for (final step in steps) {
      if (step is ConvertUnitStep) {
        if (step.from == step.to) continue;
        if (merged.lastOrNull case final ConvertUnitStep previous when previous.to == step.from) {
          merged.removeLast();
          if (previous.from == step.to) continue;
          merged.add(ConvertUnitStep(previous.from, step.to));
          continue;
        }
      }
      merged.add(step);
    }
    return merged;
  }

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

  /// This migration followed by [next], which must belong to the same adjustment.
  ValueMigration then(ValueMigration next) {
    assert(next.adjustmentId == adjustmentId, 'Cannot chain migrations of different adjustments');
    return ValueMigration(adjustmentId, [...steps, ...next.steps]);
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
