import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/adjustment/adjustment.dart';
import 'set_adjustment/set_boolean_adjustment.dart';
import 'set_adjustment/set_categorical_adjustment.dart';
import 'set_adjustment/set_numerical_adjustment.dart';
import 'set_adjustment/set_step_adjustment.dart';
import 'set_adjustment/set_text_adjustment.dart';

class AdjustmentSetList extends StatefulWidget {
  final List<Adjustment> adjustments;
  final Map<String, dynamic> initialAdjustmentValues;
  final Map<String, dynamic> adjustmentValues;
  final void Function({required Adjustment adjustment, required dynamic newValue}) onAdjustmentValueChanged;
  final void Function({required Adjustment adjustment}) removeFromAdjustmentValues;
  final void Function() changeListener;

  const AdjustmentSetList({
    super.key,
    required this.adjustments,
    required this.initialAdjustmentValues,
    required this.adjustmentValues,
    required this.onAdjustmentValueChanged,
    required this.removeFromAdjustmentValues,
    required this.changeListener,
  });

  @override
  State<AdjustmentSetList> createState() => _AdjustmentSetListState();
}

class _AdjustmentSetListState extends State<AdjustmentSetList> {
  final Map<String, dynamic> _adjustmentValues = {};  // Types differ from real Adjustment value types because parsing happens later

  @override
  void initState() {
    super.initState();
    
    for (final adjustment in widget.adjustments) {
      // Step 1: Set from AdjustmentValues
      if (widget.adjustmentValues.containsKey(adjustment.id)) {
        _adjustmentValues[adjustment.id] = widget.adjustmentValues[adjustment.id];
        continue;
      }
      // Step 2: Set from initialAdjustmentValues
      // Step 3: Set defaults (null, min, false, ...)
      final initialValue = widget.initialAdjustmentValues[adjustment.id];
      if (initialValue == null) {
        if (adjustment is BooleanAdjustment) { 
          _adjustmentValues[adjustment.id] = false;
          widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: false); // FormField with null does not exist
        } else if (adjustment is NumericalAdjustment) {
          _adjustmentValues[adjustment.id] = null;
        } else if (adjustment is StepAdjustment) {
          _adjustmentValues[adjustment.id] = adjustment.min;
          widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: adjustment.min); // FormField with null does not exist
        } else if (adjustment is CategoricalAdjustment) {
          _adjustmentValues[adjustment.id] = null;
        } else if (adjustment is TextAdjustment) {
          _adjustmentValues[adjustment.id] = null;
        } else {
          throw Exception('Unknown adjustment type');
        }
      } else {
        _adjustmentValues[adjustment.id] = initialValue;
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
            initialValue: widget.initialAdjustmentValues[adjustment.id],
            value: _adjustmentValues[adjustment.id],
            onChanged: (newValue) {
              HapticFeedback.lightImpact();
              setState(() => _adjustmentValues[adjustment.id] = newValue);
              widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: newValue);
              widget.changeListener();
            },
          );
        } else if (adjustment is NumericalAdjustment) {
          return SetNumericalAdjustmentWidget(
            key: ValueKey(adjustment),
            adjustment: adjustment,
            initialValue: widget.initialAdjustmentValues[adjustment.id],
            value: _adjustmentValues[adjustment.id]?.toString(),
            onChanged: (String newValue) {
              setState(() => _adjustmentValues[adjustment.id] = newValue);
              final parsedValue = double.tryParse(newValue);
              if (parsedValue != null) {                
                widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: parsedValue);
              } else {
                widget.removeFromAdjustmentValues(adjustment: adjustment);
              }
              widget.changeListener();
            },
          );
          
        } else if (adjustment is StepAdjustment) {
          return SetStepAdjustmentWidget(
            key: ValueKey(adjustment), 
            adjustment: adjustment,
            initialValue: widget.initialAdjustmentValues[adjustment.id]?.toDouble(),
            value: _adjustmentValues[adjustment.id].toDouble(), 
            onChanged: (double newValue) {
              HapticFeedback.lightImpact();
              setState(() {
                _adjustmentValues[adjustment.id] = newValue;
              });
            },
            onChangedEnd: (double newValue) {
              widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: newValue.toInt());
              widget.changeListener();
            },
          );
        } else if (adjustment is CategoricalAdjustment) {
          return SetCategoricalAdjustmentWidget(
            key: ValueKey(adjustment), 
            adjustment: adjustment, 
            initialValue: widget.initialAdjustmentValues[adjustment.id],
            value: _adjustmentValues[adjustment.id], 
            onChanged: (String? newValue) {
              setState(() {
                _adjustmentValues[adjustment.id] = newValue;
              });
              widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: newValue);
              widget.changeListener();
            },
          );
        } else if (adjustment is TextAdjustment) {
          return SetTextAdjustmentWidget(
            key: ValueKey(adjustment), 
            adjustment: adjustment, 
            initialValue: widget.initialAdjustmentValues[adjustment.id],
            value: _adjustmentValues[adjustment.id], 
            onChanged: (String? newValue) {
              setState(() {
                _adjustmentValues[adjustment.id] = newValue;
              });
              widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: newValue);
              widget.changeListener();
            },
          );
        }
        throw Exception('Unknown adjustment type');
      }),
    );
  }
}
