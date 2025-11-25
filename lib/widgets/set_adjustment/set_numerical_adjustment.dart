import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/adjustment.dart';

class SetNumericalAdjustmentWidget extends StatefulWidget {
  final NumericalAdjustment adjustment;
  final double? initialValue;
  final String? value;
  final ValueChanged<String> onChanged;

  const SetNumericalAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    required this.onChanged,
  });

  @override
  State<SetNumericalAdjustmentWidget> createState() => _SetNumericalAdjustmentWidgetState();
}

class _SetNumericalAdjustmentWidgetState extends State<SetNumericalAdjustmentWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(SetNumericalAdjustmentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    // Update text and keep the cursor at the end
    final newText = widget.value ?? '';
    _controller.value = _controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double? parsedValue = double.tryParse(widget.value ?? '');
    final isChanged = parsedValue == null ? false : widget.initialValue != parsedValue;
    final isInitial = widget.initialValue == null;
    final highlightColor = isChanged ? (isInitial ? Colors.green : Colors.orange) : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isChanged ? highlightColor?.withValues(alpha: 0.08) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.numbers, color: highlightColor),
          SizedBox(width: 10),
          Text(
            widget.adjustment.name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: highlightColor),
          ),
          SizedBox(width: 30),
          Expanded(
            child: TextFormField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),],
              controller: _controller,
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onChanged,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'Please enter',
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                suffixText: widget.adjustment.unit != null ? ' ${widget.adjustment.unit}' : null,
              ),
              validator: (value) {
                if ((value == null || value.trim().isEmpty) && widget.initialValue != null) {
                  return 'Please enter a value';
                }
                if (value != null && value.trim().isNotEmpty) {
                  final parsedValue = double.tryParse(value);
                  if (parsedValue == null) return "Please enter valid number";
                  final max = widget.adjustment.max;
                  if (parsedValue > max) return "Value exceeds maximum of $max";
                  final min = widget.adjustment.min;
                  if (parsedValue < min) return "Value is below minimum of $min";
                }
                return null;
              },   
            ),
          ),
        ],
      ),
    );
  }
}
