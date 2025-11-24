import 'package:flutter/material.dart';
import '../models/adjustment.dart';
import 'set_adjustment/set_boolean_adjustment.dart';
import 'set_adjustment/set_categorical_adjustment.dart';
import 'set_adjustment/set_numerical_adjustment.dart';
import 'set_adjustment/set_step_adjustment.dart';

class AdjustmentSetList extends StatefulWidget {
  final List<Adjustment> adjustments;
  final Map<Adjustment, dynamic> initialAdjustmentValues;
  final void Function({required Adjustment adjustment, required dynamic newValue}) onAdjustmentValueChanged;
  final void Function({required Adjustment adjustment}) removeFromAdjustmentValues;

  const AdjustmentSetList({
    super.key,
    required this.adjustments,
    required this.initialAdjustmentValues,
    required this.onAdjustmentValueChanged,
    required this.removeFromAdjustmentValues,
  });

  @override
  State<AdjustmentSetList> createState() => _AdjustmentSetListState();
}

class _AdjustmentSetListState extends State<AdjustmentSetList> {
  final Map<Adjustment, dynamic> _adjustmentValues = {};  // Types differ from real Adjustment value types because parsing happens later

  @override
  void initState() {
    super.initState();
    
    for (final adjustment in widget.adjustments) {
      final initialValue = widget.initialAdjustmentValues[adjustment];
      if (initialValue == null) {
        if (adjustment is BooleanAdjustment) { 
          _adjustmentValues[adjustment] = false;
          widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: false); // FormField with null does not exist
        } else if (adjustment is NumericalAdjustment) {
          _adjustmentValues[adjustment] = null;
        } else if (adjustment is StepAdjustment) {
          _adjustmentValues[adjustment] = adjustment.min;
          widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: adjustment.min); // FormField with null does not exist
        } else if (adjustment is CategoricalAdjustment) {
          _adjustmentValues[adjustment] = null;
        } else {
          throw Exception('Unknown adjustment type');
        }
      } else {
        _adjustmentValues[adjustment] = initialValue;
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
            value: _adjustmentValues[adjustment],
            onChanged: (newValue) {
              setState(() => _adjustmentValues[adjustment] = newValue);
              widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: newValue);
            },
          );
        } else if (adjustment is NumericalAdjustment) {
          return SetNumericalAdjustmentWidget(
            key: ValueKey(adjustment),
            adjustment: adjustment,
            initialValue: widget.initialAdjustmentValues[adjustment],
            value: _adjustmentValues[adjustment]?.toString(),
            onChanged: (String newValue) {
              setState(() => _adjustmentValues[adjustment] = newValue);
              final parsedValue = double.tryParse(newValue);
              if (parsedValue != null) {                
                widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: parsedValue);
              } else {
                widget.removeFromAdjustmentValues(adjustment: adjustment);
              }
            },
          );
          
        } else if (adjustment is StepAdjustment) {
          return SetStepAdjustmentWidget(
            key: ValueKey(adjustment), 
            adjustment: adjustment,
            initialValue: widget.initialAdjustmentValues[adjustment]?.toDouble(),
            value: _adjustmentValues[adjustment].toDouble(), 
            onChanged: (double newValue) {
              setState(() {
                _adjustmentValues[adjustment] = newValue;
              });
            },
            onChangedEnd: (double newValue) {
              widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: newValue.toInt());
            },
          );
        } else if (adjustment is CategoricalAdjustment) {
          return SetCategoricalAdjustmentWidget(
            key: ValueKey(adjustment), 
            adjustment: adjustment, 
            initialValue: widget.initialAdjustmentValues[adjustment],
            value: _adjustmentValues[adjustment], 
            onChanged: (String? newValue) {
              setState(() {
                _adjustmentValues[adjustment] = newValue;
              });
              widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: newValue);
            },
          );
        }
        throw Exception('Unknown adjustment type');
      }),
    );
  }
}
