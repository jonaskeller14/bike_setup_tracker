import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import 'display_boolean_adjustment.dart';
import 'display_categorical_adjustment.dart';
import 'display_numerical_adjustment.dart';
import 'display_step_adjustment.dart';
import 'display_text_adjustment.dart';
import 'display_duration_adjustment.dart';

class AdjustmentDisplayList extends StatelessWidget {
  final List<Adjustment> adjustments;
  final Map<String, dynamic> initialAdjustmentValues;
  final Map<String, dynamic> adjustmentValues;

  const AdjustmentDisplayList({
    super.key,
    required this.adjustments,
    required this.initialAdjustmentValues,
    required this.adjustmentValues,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(adjustments.length, (index) {
        final adjustment = adjustments[index];
        dynamic initialValue = initialAdjustmentValues[adjustment.id];
        dynamic value = adjustmentValues[adjustment.id];
        switch (adjustment) {
          case BooleanAdjustment(): 
            return DisplayBooleanAdjustmentWidget(
              key: ValueKey(adjustment),
              adjustment: adjustment,
              initialValue: initialValue,
              value: value,
            );
          case NumericalAdjustment():
            return DisplayNumericalAdjustmentWidget(
              key: ValueKey(adjustment),
              adjustment: adjustment,
              initialValue: initialValue,
              value: value,
            );
          case StepAdjustment():
            return DisplayStepAdjustmentWidget(
              key: ValueKey(adjustment), 
              adjustment: adjustment,
              initialValue: initialValue,
              value: value, 
            );
          case CategoricalAdjustment():
            return DisplayCategoricalAdjustmentWidget(
              key: ValueKey(adjustment), 
              adjustment: adjustment, 
              initialValue: initialValue,
              value: value,
            );
          case TextAdjustment():
            return DisplayTextAdjustmentWidget(
              key: ValueKey(adjustment), 
              adjustment: adjustment, 
              initialValue: initialValue,
              value: value,
            );
          case DurationAdjustment():
            return DisplayDurationAdjustmentWidget(
              key: ValueKey(adjustment),
              adjustment: adjustment,
              initialValue: initialValue,
              value: value, 
            );
          default: throw Exception('Unknown adjustment type');
        }
      }),
    );
  }
}
