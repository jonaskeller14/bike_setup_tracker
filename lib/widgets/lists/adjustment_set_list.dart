import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/adjustment/adjustment.dart';
import '../set_adjustment/set_boolean_adjustment.dart';
import '../set_adjustment/set_categorical_adjustment.dart';
import '../set_adjustment/set_duration_adjustment.dart';
import '../set_adjustment/set_numerical_adjustment.dart';
import '../set_adjustment/set_sag_adjustment.dart';
import '../set_adjustment/set_step_adjustment.dart';
import '../set_adjustment/set_text_adjustment.dart';

class AdjustmentSetList extends StatefulWidget {
  final List<Adjustment> adjustments;
  final Map<String, dynamic> initialAdjustmentValues;
  final Map<String, dynamic> adjustmentValues;
  final void Function({required Adjustment adjustment, required dynamic newValue}) onAdjustmentValueChanged;
  final void Function({required Adjustment adjustment}) removeFromAdjustmentValues;
  final bool prefillFromInitial;
  final Future<void> Function({required CategoricalAdjustment adjustment, required String option})? onAddCategoricalOption;

  const AdjustmentSetList({
    super.key,
    required this.adjustments,
    required this.initialAdjustmentValues,
    required this.adjustmentValues,
    required this.onAdjustmentValueChanged,
    required this.removeFromAdjustmentValues,
    this.prefillFromInitial = true,
    this.onAddCategoricalOption,
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

      // Step 2: Set from initialAdjustmentValues (skip when pre-fill is disabled)
      if (widget.prefillFromInitial) {
        final initialValue = widget.initialAdjustmentValues[adjustment.id];
        if (initialValue != null) {
          _adjustmentValues[adjustment.id] = initialValue;
          continue;
        }
      }

      // Step 3: Set defaults (null, min, false, ...)
      switch (adjustment) {
        case BooleanAdjustment(): _adjustmentValues[adjustment.id] = null;
        case NumericalAdjustment(): _adjustmentValues[adjustment.id] = null;
        case StepAdjustment(): _adjustmentValues[adjustment.id] = null;
        case CategoricalAdjustment(): _adjustmentValues[adjustment.id] = null;
        case TextAdjustment(): _adjustmentValues[adjustment.id] = null;
        case DurationAdjustment(): _adjustmentValues[adjustment.id] = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.adjustments.length, (index) {
        final adjustment = widget.adjustments[index];
        // Keyed by identity (adjustment.id), not content, so persisting a
        // definition change (e.g. adding a categorical option) updates the row in
        // place instead of tearing down its editing state — including a FormField
        // whose FormFieldState an open sheet still writes to.
        switch (adjustment) {
          case BooleanAdjustment(): 
            return SetBooleanAdjustmentWidget(
              key: ValueKey(adjustment.id),
              adjustment: adjustment,
              optional: !widget.prefillFromInitial,
              initialValue: widget.initialAdjustmentValues[adjustment.id] as bool?,
              value: _adjustmentValues[adjustment.id] as bool?,
              onChanged: (bool? newValue) {
                unawaited(HapticFeedback.lightImpact());
                setState(() => _adjustmentValues[adjustment.id] = newValue);
                if (newValue == null) {
                  widget.removeFromAdjustmentValues(adjustment: adjustment);
                } else {
                  widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: newValue);
                }
              },
            );
          case SagAdjustment():
            return SetSagAdjustmentWidget(
              key: ValueKey(adjustment.id),
              adjustment: adjustment,
              optional: !widget.prefillFromInitial,
              initialValue: widget.initialAdjustmentValues[adjustment.id] as double?,
              value: _adjustmentValues[adjustment.id]?.toString(),
              onChanged: (String newValue) {
                setState(() => _adjustmentValues[adjustment.id] = newValue);
                final parsedValue = double.tryParse(newValue);
                if (parsedValue == null) {
                  widget.removeFromAdjustmentValues(adjustment: adjustment);
                } else {
                  widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: parsedValue);
                }
              },
            );
          case NumericalAdjustment():
            return SetNumericalAdjustmentWidget(
              key: ValueKey(adjustment.id),
              adjustment: adjustment,
              optional: !widget.prefillFromInitial,
              initialValue: widget.initialAdjustmentValues[adjustment.id] as double?,
              value: _adjustmentValues[adjustment.id]?.toString(),
              onChanged: (String newValue) {
                setState(() => _adjustmentValues[adjustment.id] = newValue);
                final parsedValue = double.tryParse(newValue);
                if (parsedValue == null) {
                  widget.removeFromAdjustmentValues(adjustment: adjustment);
                } else {
                  widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: parsedValue);
                }
              },
            );
          case StepAdjustment():
            return SetStepAdjustmentWidget(
              key: ValueKey(adjustment.id), 
              adjustment: adjustment,
              optional: !widget.prefillFromInitial,
              initialValue: (widget.initialAdjustmentValues[adjustment.id] as num?)?.toDouble(),
              value: (_adjustmentValues[adjustment.id] as num?)?.toDouble(),
              onChanged: (double? newValue) {
                unawaited(HapticFeedback.lightImpact());
                setState(() {
                  _adjustmentValues[adjustment.id] = newValue;
                });
              },
              onChangedEnd: (double? newValue) {
                if (newValue == null) {
                  widget.removeFromAdjustmentValues(adjustment: adjustment);
                } else {
                  widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: newValue.toInt());
                }
              },
            );
          case CategoricalAdjustment():
            return SetCategoricalAdjustmentWidget(
              key: ValueKey(adjustment.id),
              adjustment: adjustment,
              optional: !widget.prefillFromInitial,
              initialValue: categoricalValueAsList(widget.initialAdjustmentValues[adjustment.id]),
              value: categoricalValueAsList(_adjustmentValues[adjustment.id]),
              onAddOption: widget.onAddCategoricalOption == null
                  ? null
                  : (String option) => widget.onAddCategoricalOption!(adjustment: adjustment, option: option),
              onChanged: (List<String>? newValue) {
                setState(() => _adjustmentValues[adjustment.id] = newValue);
                if (newValue == null) {
                  widget.removeFromAdjustmentValues(adjustment: adjustment);
                } else {
                  widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: newValue);
                }
              },
            );
          case TextAdjustment():
            return SetTextAdjustmentWidget(
              key: ValueKey(adjustment.id),
              adjustment: adjustment,
              optional: !widget.prefillFromInitial,
              initialValue: textValueAsString(widget.initialAdjustmentValues[adjustment.id]),
              value: textValueAsString(_adjustmentValues[adjustment.id]),
              onChanged: (String newValue) {
                setState(() => _adjustmentValues[adjustment.id] = newValue);
                if (newValue.isNotEmpty) {
                  widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: newValue);
                } else {
                  widget.removeFromAdjustmentValues(adjustment: adjustment);
                }
              },
            );
          case DurationAdjustment():
            return SetDurationAdjustmentWidget(
              key: ValueKey(adjustment.id),
              adjustment: adjustment,
              optional: !widget.prefillFromInitial,
              initialValue: widget.initialAdjustmentValues[adjustment.id] as Duration?,
              value: _adjustmentValues[adjustment.id] as Duration?,
              onChanged: (Duration? newValue) {
                if (!mounted) return;
                setState(() => _adjustmentValues[adjustment.id] = newValue);
                if (newValue != null) {        
                  widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: newValue);
                } else {
                  widget.removeFromAdjustmentValues(adjustment: adjustment);
                }
              },
            );
        }
      }),
    );
  }
}
