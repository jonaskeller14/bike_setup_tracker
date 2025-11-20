import 'dart:math';
import 'package:flutter/material.dart';
import '../models/adjustment.dart';
import 'set_adjustment/set_boolean_adjustment.dart';
import 'set_adjustment/set_categorical_adjustment.dart';
import 'set_adjustment/set_numerical_adjustment.dart';
import 'set_adjustment/set_step_adjustment.dart';

class AdjustmentSetList extends StatefulWidget {
  final List<Adjustment> adjustments;
  final Map<Adjustment, dynamic> initialAdjustmentValues;
  final void Function(Adjustment adjustment, dynamic newValue) onAdjustmentValueChanged;

  const AdjustmentSetList({
    super.key,
    required this.adjustments,
    required this.initialAdjustmentValues,
    required this.onAdjustmentValueChanged,
  });

  @override
  State<AdjustmentSetList> createState() => _AdjustmentSetListState();
}

class _AdjustmentSetListState extends State<AdjustmentSetList> {
  Map<Adjustment, dynamic> adjustmentValues = {};  // Types differ from real Adjustment value types because parsing happens later

  @override
  void initState() {
    super.initState();
    for (final adjustment in widget.adjustments) {
      final initialValue = widget.initialAdjustmentValues[adjustment];
      if (initialValue == null) {
        if (adjustment is BooleanAdjustment) {
          adjustmentValues[adjustment] = false;
        } else if (adjustment is NumericalAdjustment) {
          adjustmentValues[adjustment] = adjustment.min == double.negativeInfinity ? min(0.0, adjustment.max).toString() : (0.0).toString();
        } else if (adjustment is StepAdjustment) {
          adjustmentValues[adjustment] = adjustment.min;
        } else if (adjustment is CategoricalAdjustment) {
          adjustmentValues[adjustment] = adjustment.options[0];
        } else {
          throw Exception('Unknown adjustment type');
        }
      } else {
        adjustmentValues[adjustment] = initialValue;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.adjustments.length, (index) {
        final adjustment = widget.adjustments[index];
        if (adjustment is BooleanAdjustment) {
          return SetBooleanAdjustmentWidget(
            key: ValueKey(adjustment),
            adjustment: adjustment,
            initialValue: widget.initialAdjustmentValues[adjustment],
            value: adjustmentValues[adjustment],
            onChanged: (newValue) {
              setState(() => adjustmentValues[adjustment] = newValue);
              widget.onAdjustmentValueChanged(adjustment, newValue);
            },
          );
        } else if (adjustment is NumericalAdjustment) {
          return SetNumericalAdjustmentWidget(
            key: ValueKey(adjustment),
            adjustment: adjustment,
            initialValue: widget.initialAdjustmentValues[adjustment],
            value: adjustmentValues[adjustment].toString(),
            onChanged: (String newValue) {
              setState(() => adjustmentValues[adjustment] = newValue);
              final parsedValue = double.tryParse(newValue);
              if (parsedValue != null) {                
                widget.onAdjustmentValueChanged(adjustment, parsedValue);
              }
            },
          );
          
        } else if (adjustment is StepAdjustment) {
          return SetStepAdjustmentWidget(
            key: ValueKey(adjustment), 
            adjustment: adjustment,
            initialValue: widget.initialAdjustmentValues[adjustment]?.toDouble(),
            value: adjustmentValues[adjustment].toDouble(), 
            onChanged: (double newValue) {
              setState(() {
                adjustmentValues[adjustment] = newValue;
              });
            },
            onChangedEnd: (double newValue) {
              widget.onAdjustmentValueChanged(adjustment, newValue.toInt());
            },
          );
        } else if (adjustment is CategoricalAdjustment) {
          return SetCategoricalAdjustmentWidget(
            key: ValueKey(adjustment), 
            adjustment: adjustment, 
            initialValue: widget.initialAdjustmentValues[adjustment],
            value: adjustmentValues[adjustment], 
            onChanged: (String? newValue) {
              setState(() {
                adjustmentValues[adjustment] = newValue;
              });
              widget.onAdjustmentValueChanged(adjustment, newValue);
            },
          );
        }
        throw Exception('Unknown adjustment type');
      }),
    );
  }
}
