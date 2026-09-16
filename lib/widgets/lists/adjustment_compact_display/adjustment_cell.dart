import 'package:flutter/material.dart';

import '../../../models/adjustment/adjustment.dart';
import 'adjustment_display_item.dart';

/// One adjustment value as displayed in the compact adjustment view,
/// classified by how it relates to the previous setup.
sealed class AdjustmentCell {
  final Adjustment adjustment;
  final dynamic value;

  const AdjustmentCell(this.adjustment, this.value);

  factory AdjustmentCell.resolve({
    required Adjustment adjustment,
    required dynamic value,
    required dynamic previousValue,
    bool isError = false,
  }) {
    if (isError) return ErrorCell(adjustment, value);
    if (previousValue == null) return InitialCell(adjustment, value);
    if (adjustmentValuesEqual(value, previousValue)) return ConstantCell(adjustment, value);
    return ChangedCell(adjustment, value, previousValue);
  }

  /// Whether this value differs from the previous setup (kept when collapsed
  /// to changes only).
  bool get isChange => this is InitialCell || this is ChangedCell;

  CellDisplayText get displayText {
    String normalize(String s) => s.replaceAll(RegExp(r'\n|\r'), ' ');
    final valueText = normalize(Adjustment.formatValue(value));
    final cell = this;
    if (cell is! ChangedCell) return CellDisplayText(value: valueText);

    final previousValue = cell.previousValue;
    final bool isDelta = switch (adjustment) {
      NumericalAdjustment() || DurationAdjustment() || StepAdjustment() =>
        (value is num && previousValue is num) || (value is Duration && previousValue is Duration),
      BooleanAdjustment() || TextAdjustment() || CategoricalAdjustment() => false,
    };
    if (!isDelta) {
      return CellDisplayText(
        value: valueText,
        change: normalize(Adjustment.formatValue(previousValue)),
        changeDecoration: TextDecoration.lineThrough,
      );
    }

    final dynamic delta = value - previousValue;
    final bool isPositive = delta is num ? delta > 0 : !(delta as Duration).isNegative;
    final deltaText = Adjustment.formatValue(delta);
    return CellDisplayText(value: valueText, change: isPositive ? '+$deltaText' : deltaText);
  }
}

/// Same value as in the previous setup.
final class ConstantCell extends AdjustmentCell {
  const ConstantCell(super.adjustment, super.value);
}

/// First value ever set; there is no previous value.
final class InitialCell extends AdjustmentCell {
  const InitialCell(super.adjustment, super.value);
}

final class ChangedCell extends AdjustmentCell {
  final dynamic previousValue;

  const ChangedCell(super.adjustment, super.value, this.previousValue);
}

/// Value of an owner that is dangling for this setup (e.g. an uninstalled component).
final class ErrorCell extends AdjustmentCell {
  const ErrorCell(super.adjustment, super.value);
}

/// The text a cell's value line renders, shared by the cell widget and the
/// width-measurement pass so both always agree.
class CellDisplayText {
  final String value;
  final String? change;
  final TextDecoration changeDecoration;

  const CellDisplayText({required this.value, this.change, this.changeDecoration = TextDecoration.none});

  bool get hasChange => change != null;
}

/// An owner (component or person) with the cells to show for it.
class AdjustmentCellGroup {
  final AdjustmentDisplayItem owner;
  final List<AdjustmentCell> cells;

  const AdjustmentCellGroup({required this.owner, required this.cells});
}
