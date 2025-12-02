import 'package:flutter/material.dart';
import '../../models/adjustment.dart';

class SetStepAdjustmentWidget extends StatelessWidget {
  final StepAdjustment adjustment;
  final double? initialValue;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangedEnd;
  final bool highlighting;

  const SetStepAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    required this.onChanged,
    required this.onChangedEnd,
    this.highlighting = true,
  });

  @override
  Widget build(BuildContext context) {
    late bool isChanged;
    late bool isInitial;
    late Color? highlightColor; 
    if (highlighting) {
      isChanged = initialValue != value;
      isInitial = initialValue == null;
      highlightColor = isChanged ? (isInitial ? Colors.green : Colors.orange) : null;
    } else {
      isChanged = false;
      isInitial = false;
      highlightColor = null;
    }
    final sliderDivisions = ((adjustment.max - adjustment.min) / adjustment.step).floor();
    final sliderMax = (adjustment.min + sliderDivisions * adjustment.step).toDouble();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isChanged ? highlightColor?.withValues(alpha: 0.08) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 20,
        children: [
          Flexible(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(Icons.format_list_numbered, color: highlightColor),
                SizedBox(width: 10),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      adjustment.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: highlightColor),
                    ),
                  ),
                ),
              ],
            )
          ),
          Flexible(
            flex: 3,
            child: Slider(
              padding: EdgeInsets.all(5),
              value: value,
              max: sliderMax,
              min: adjustment.min.toDouble(),
              divisions: sliderDivisions,
              label: value.toInt().toString(),
              onChanged: onChanged,
              onChangeEnd: onChangedEnd,
            ),
          ),
        ],
      ),
    );
  }
}
