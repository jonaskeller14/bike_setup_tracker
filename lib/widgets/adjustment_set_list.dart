import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/adjustment.dart';

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
  Map<Adjustment, dynamic> adjustmentValues = {};

  @override
  void initState() {
    super.initState();
    for (final adjustment in widget.adjustments) {
      final initialValue = widget.initialAdjustmentValues[adjustment];
      if (initialValue == null) {
        if (adjustment is BooleanAdjustment) {
          adjustmentValues[adjustment] = false;
        } else if (adjustment is NumericalAdjustment) {
          adjustmentValues[adjustment] = adjustment.min == double.negativeInfinity ? min(0.0, adjustment.max) : adjustment;
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
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.toggle_on),
                SizedBox(width: 10.0),
                Text(
                  adjustment.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(width: 30.0),
                Expanded(
                  child: Align(
                  alignment: Alignment.centerRight,
                  child: Switch(
                    value: adjustmentValues[adjustment],
                    onChanged: (newValue) {
                      setState(() {
                        adjustmentValues[adjustment] = newValue;
                      });
                      widget.onAdjustmentValueChanged(adjustment, newValue);
                      },
                  ),
                ),  
                ),
              ],
            ),
          );
        } else if (adjustment is NumericalAdjustment) {
          final controller = TextEditingController(text: adjustmentValues[adjustment].toString());
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.numbers),
                SizedBox(width: 10.0),
                Text(
                  adjustment.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(width: 30.0),
                Expanded(
                  child: TextField(
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    controller: controller,
                    onTap: () {controller.clear();},
                    onChanged: (newValue) {
                      final parsedValue = double.tryParse(newValue);
                      if (parsedValue != null) {
                        adjustmentValues[adjustment] = parsedValue;
                        widget.onAdjustmentValueChanged(adjustment, parsedValue);
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      suffixText: adjustment.unit != null ? ' ${adjustment.unit}' : null,
                    ),
                  )
                ),
              ],
            )
          );
        } else if (adjustment is StepAdjustment) {
          final sliderDivisions = ((adjustment.max - adjustment.min) / adjustment.step).floor();
          final sliderMax = (adjustment.min + sliderDivisions * adjustment.step).toDouble();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.format_list_numbered),
                SizedBox(width: 10.0),
                Text(
                  adjustment.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(width: 30.0),
                Expanded(child: Slider(
                  value: adjustmentValues[adjustment].toDouble(),
                  max: sliderMax,
                  min: adjustment.min.toDouble(),
                  divisions: sliderDivisions,
                  label: adjustmentValues[adjustment].toString(),
                  onChanged: (double newValue) {
                    setState(() {
                      adjustmentValues[adjustment] = newValue.toInt();
                    });
                    widget.onAdjustmentValueChanged(adjustment, newValue.toInt());
                  },
                  ),
                ),
              ],
            ),
          );
        } else if (adjustment is CategoricalAdjustment) {
          final options = adjustment.options;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.category),
                SizedBox(width: 10.0),
                Text(
                  adjustment.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(width: 30.0),
                Expanded(child: DropdownButton<String>(
                  isExpanded: true,
                  value: adjustmentValues[adjustment],
                  items: options.map<DropdownMenuItem<String>>((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option, overflow: TextOverflow.ellipsis,),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      adjustmentValues[adjustment] = newValue;
                    });
                    widget.onAdjustmentValueChanged(adjustment, newValue);
                  },
                ),)
              ],
            ),
          );
        }
        throw Exception('Unknown adjustment type');
      }),
    );
  }
}
