import 'package:flutter/material.dart';

import '../../models/adjustment/adjustment.dart';
import '../../utils/unit_conversion.dart';
import 'set_numerical_adjustment.dart';

/// Sag entry: a percentage field whose suffix toggles to the derived mm reading
/// (and validates against the travel-converted bounds) once the adjustment
/// knows its reference travel.
class SetSagAdjustmentWidget extends StatelessWidget {
  final SagAdjustment adjustment;
  final double? initialValue;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool highlighting;
  final bool optional;

  const SetSagAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    required this.onChanged,
    this.highlighting = true,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return SetNumericalAdjustmentWidget(
      key: ValueKey(adjustment),
      adjustment: adjustment,
      initialValue: initialValue,
      value: value,
      onChanged: onChanged,
      highlighting: highlighting,
      optional: optional,
      cycle: sagUnitCycle(adjustment),
    );
  }
}
