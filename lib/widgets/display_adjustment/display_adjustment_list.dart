import 'package:flutter/material.dart';

import '../../models/adjustment/adjustment.dart';
import 'display_boolean_adjustment.dart';
import 'display_categorical_adjustment.dart';
import 'display_dangling_adjustment.dart';
import 'display_duration_adjustment.dart';
import 'display_numerical_adjustment.dart';
import 'display_sag_adjustment.dart';
import 'display_step_adjustment.dart';
import 'display_text_adjustment.dart';

class AdjustmentDisplayList extends StatelessWidget {
  final List<Adjustment> adjustments;
  final Map<String, AdjustmentValue> initialAdjustmentValues;
  final Map<String, AdjustmentValue> adjustmentValues;
  final bool isError;
  final void Function(String adjustmentId)? onRemove;

  const AdjustmentDisplayList({
    super.key,
    required this.adjustments,
    required this.initialAdjustmentValues,
    required this.adjustmentValues,
    this.isError = false,
    this.onRemove,
  });

  Widget _row(Adjustment adjustment) {
    final value = adjustmentValues[adjustment.id];
    final VoidCallback? onRemoveAdjustment = onRemove == null ? null : () => onRemove!(adjustment.id);
    // `SagAdjustment` is a `NumericalAdjustment`, so its case must come first.
    return switch ((adjustment, value, initialAdjustmentValues[adjustment.id])) {
      (final BooleanAdjustment a, final BooleanValue? v, final BooleanValue? i) => DisplayBooleanAdjustmentWidget(
        key: ValueKey(a),
        adjustment: a,
        initialValue: i,
        value: v,
        isError: isError,
        onRemove: onRemoveAdjustment,
      ),
      (final SagAdjustment a, final NumericalValue? v, final NumericalValue? i) => DisplaySagAdjustmentWidget(
        key: ValueKey(a),
        adjustment: a,
        initialValue: i,
        value: v,
        isError: isError,
        onRemove: onRemoveAdjustment,
      ),
      (final NumericalAdjustment a, final NumericalValue? v, final NumericalValue? i) => DisplayNumericalAdjustmentWidget(
        key: ValueKey(a),
        adjustment: a,
        initialValue: i,
        value: v,
        isError: isError,
        onRemove: onRemoveAdjustment,
      ),
      (final StepAdjustment a, final StepValue? v, final StepValue? i) => DisplayStepAdjustmentWidget(
        key: ValueKey(a),
        adjustment: a,
        initialValue: i,
        value: v,
        isError: isError,
        onRemove: onRemoveAdjustment,
      ),
      (final CategoricalAdjustment a, final CategoricalValue? v, final CategoricalValue? i) => DisplayCategoricalAdjustmentWidget(
        key: ValueKey(a),
        adjustment: a,
        initialValue: i,
        value: v,
        isError: isError,
        onRemove: onRemoveAdjustment,
      ),
      (final TextAdjustment a, final TextValue? v, final TextValue? i) => DisplayTextAdjustmentWidget(
        key: ValueKey(a),
        adjustment: a,
        initialValue: i,
        value: v,
        isError: isError,
        onRemove: onRemoveAdjustment,
      ),
      (final DurationAdjustment a, final DurationValue? v, final DurationValue? i) => DisplayDurationAdjustmentWidget(
        key: ValueKey(a),
        adjustment: a,
        initialValue: i,
        value: v,
        isError: isError,
        onRemove: onRemoveAdjustment,
      ),
      _ => _mismatch(adjustment, value, onRemoveAdjustment),
    };
  }

  /// Values are paired with their adjustment type where they are decoded and
  /// written, so reaching this is a boundary bug. The value stays visible and
  /// removable rather than being hidden.
  Widget _mismatch(Adjustment adjustment, AdjustmentValue? value, VoidCallback? onRemove) {
    assert(false, 'Value $value does not match adjustment ${adjustment.id} (${adjustment.type.name})');
    return DisplayDanglingAdjustmentWidget(
      key: ValueKey(adjustment),
      name: adjustment.name,
      value: value,
      onRemove: onRemove,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [for (final adjustment in adjustments) _row(adjustment)],
    );
  }
}
