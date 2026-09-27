import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/adjustment/adjustment.dart';
import '../display_adjustment/display_dangling_adjustment.dart';
import '../set_adjustment/set_boolean_adjustment.dart';
import '../set_adjustment/set_categorical_adjustment.dart';
import '../set_adjustment/set_duration_adjustment.dart';
import '../set_adjustment/set_numerical_adjustment.dart';
import '../set_adjustment/set_sag_adjustment.dart';
import '../set_adjustment/set_step_adjustment.dart';
import '../set_adjustment/set_text_adjustment.dart';

class AdjustmentSetList extends StatefulWidget {
  final List<Adjustment> adjustments;
  final Map<String, AdjustmentValue> initialAdjustmentValues;
  final Map<String, AdjustmentValue> adjustmentValues;
  final void Function({required Adjustment adjustment, required AdjustmentValue newValue}) onAdjustmentValueChanged;
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
  final Map<String, AdjustmentValue?> _adjustmentValues = {};

  @override
  void initState() {
    super.initState();
    for (final adjustment in widget.adjustments) {
      _adjustmentValues[adjustment.id] = widget.adjustmentValues[adjustment.id] ??
          (widget.prefillFromInitial ? widget.initialAdjustmentValues[adjustment.id] : null);
    }
  }

  void _setValue(Adjustment adjustment, AdjustmentValue? newValue) {
    setState(() => _adjustmentValues[adjustment.id] = newValue);
    _report(adjustment, newValue);
  }

  void _report(Adjustment adjustment, AdjustmentValue? newValue) {
    if (newValue == null) {
      widget.removeFromAdjustmentValues(adjustment: adjustment);
    } else {
      widget.onAdjustmentValueChanged(adjustment: adjustment, newValue: newValue);
    }
  }

  Widget _row(Adjustment adjustment) {
    final value = _adjustmentValues[adjustment.id];
    final optional = !widget.prefillFromInitial;
    // Keyed by identity (adjustment.id), not content, so persisting a
    // definition change (e.g. adding a categorical option) updates the row in
    // place instead of tearing down its editing state — including a FormField
    // whose FormFieldState an open sheet still writes to.
    final key = ValueKey(adjustment.id);
    // `SagAdjustment` is a `NumericalAdjustment`, so its case must come first.
    return switch ((adjustment, value, widget.initialAdjustmentValues[adjustment.id])) {
      (final BooleanAdjustment a, final BooleanValue? v, final BooleanValue? i) => SetBooleanAdjustmentWidget(
        key: key,
        adjustment: a,
        optional: optional,
        initialValue: i,
        value: v,
        onChanged: (newValue) {
          unawaited(HapticFeedback.lightImpact());
          _setValue(a, newValue);
        },
      ),
      (final SagAdjustment a, final NumericalValue? v, final NumericalValue? i) => SetSagAdjustmentWidget(
        key: key,
        adjustment: a,
        optional: optional,
        initialValue: i,
        value: v,
        onChanged: (newValue) => _setValue(a, newValue),
      ),
      (final NumericalAdjustment a, final NumericalValue? v, final NumericalValue? i) => SetNumericalAdjustmentWidget(
        key: key,
        adjustment: a,
        optional: optional,
        initialValue: i,
        value: v,
        onChanged: (newValue) => _setValue(a, newValue),
      ),
      (final StepAdjustment a, final StepValue? v, final StepValue? i) => SetStepAdjustmentWidget(
        key: key,
        adjustment: a,
        optional: optional,
        initialValue: i,
        value: v,
        onChanged: (newValue) {
          unawaited(HapticFeedback.lightImpact());
          setState(() => _adjustmentValues[a.id] = newValue);
        },
        onChangedEnd: (newValue) => _report(a, newValue),
      ),
      (final CategoricalAdjustment a, final CategoricalValue? v, final CategoricalValue? i) => SetCategoricalAdjustmentWidget(
        key: key,
        adjustment: a,
        optional: optional,
        initialValue: i,
        value: v,
        onAddOption: widget.onAddCategoricalOption == null
            ? null
            : (String option) => widget.onAddCategoricalOption!(adjustment: a, option: option),
        onChanged: (newValue) => _setValue(a, newValue),
      ),
      (final TextAdjustment a, final TextValue? v, final TextValue? i) => SetTextAdjustmentWidget(
        key: key,
        adjustment: a,
        optional: optional,
        initialValue: i,
        value: v,
        onChanged: (newValue) => _setValue(a, newValue),
      ),
      (final DurationAdjustment a, final DurationValue? v, final DurationValue? i) => SetDurationAdjustmentWidget(
        key: key,
        adjustment: a,
        optional: optional,
        initialValue: i,
        value: v,
        onChanged: (newValue) {
          if (!mounted) return;
          _setValue(a, newValue);
        },
      ),
      _ => _mismatch(adjustment, value),
    };
  }

  /// Values are paired with their adjustment type where they are decoded and
  /// written, so reaching this is a boundary bug. The value stays visible and
  /// removable instead of being emptied and silently dropped on save.
  Widget _mismatch(Adjustment adjustment, AdjustmentValue? value) {
    assert(false, 'Value $value does not match adjustment ${adjustment.id} (${adjustment.type.name})');
    return DisplayDanglingAdjustmentWidget(
      key: ValueKey(adjustment.id),
      name: adjustment.name,
      value: value,
      onRemove: value == null ? null : () => _setValue(adjustment, null),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [for (final adjustment in widget.adjustments) _row(adjustment)],
    );
  }
}
