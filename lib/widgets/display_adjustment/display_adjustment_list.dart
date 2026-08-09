import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import 'display_boolean_adjustment.dart';
import 'display_categorical_adjustment.dart';
import 'display_duration_adjustment.dart';
import 'display_numerical_adjustment.dart';
import 'display_sag_adjustment.dart';
import 'display_step_adjustment.dart';
import 'display_text_adjustment.dart';

class AdjustmentDisplayList extends StatelessWidget {
  final List<Adjustment> adjustments;
  final Map<String, dynamic> initialAdjustmentValues;
  final Map<String, dynamic> adjustmentValues;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(adjustments.length, (index) {
        final adjustment = adjustments[index];
        final dynamic initialValue = initialAdjustmentValues[adjustment.id];
        final dynamic value = adjustmentValues[adjustment.id];
        final VoidCallback? onRemoveAdjustment = onRemove == null ? null : () => onRemove!(adjustment.id);
        switch (adjustment) {
          case BooleanAdjustment():
            return DisplayBooleanAdjustmentWidget(
              key: ValueKey(adjustment),
              adjustment: adjustment,
              initialValue: initialValue as bool?,
              value: value as bool?,
              isError: isError,
              onRemove: onRemoveAdjustment,
            );
          case SagAdjustment():
            return DisplaySagAdjustmentWidget(
              key: ValueKey(adjustment),
              adjustment: adjustment,
              initialValue: initialValue as num?,
              value: value as num?,
              isError: isError,
              onRemove: onRemoveAdjustment,
            );
          case NumericalAdjustment():
            return DisplayNumericalAdjustmentWidget(
              key: ValueKey(adjustment),
              adjustment: adjustment,
              initialValue: initialValue as num?,
              value: value as num?,
              isError: isError,
              onRemove: onRemoveAdjustment,
            );
          case StepAdjustment():
            return DisplayStepAdjustmentWidget(
              key: ValueKey(adjustment),
              adjustment: adjustment,
              initialValue: initialValue as num?,
              value: value as num?,
              isError: isError,
              onRemove: onRemoveAdjustment,
            );
          case CategoricalAdjustment():
            return DisplayCategoricalAdjustmentWidget(
              key: ValueKey(adjustment),
              adjustment: adjustment,
              initialValue: categoricalValueAsList(initialValue),
              value: categoricalValueAsList(value),
              isError: isError,
              onRemove: onRemoveAdjustment,
            );
          case TextAdjustment():
            return DisplayTextAdjustmentWidget(
              key: ValueKey(adjustment),
              adjustment: adjustment,
              initialValue: textValueAsString(initialValue),
              value: textValueAsString(value),
              isError: isError,
              onRemove: onRemoveAdjustment,
            );
          case DurationAdjustment():
            return DisplayDurationAdjustmentWidget(
              key: ValueKey(adjustment),
              adjustment: adjustment,
              initialValue: initialValue as Duration?,
              value: value as Duration?,
              isError: isError,
              onRemove: onRemoveAdjustment,
            );
        }
      }),
    );
  }
}
