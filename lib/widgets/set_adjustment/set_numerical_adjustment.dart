import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/adjustment/adjustment.dart';
import "set_adjustment.dart";

class SetNumericalAdjustmentWidget extends StatefulWidget {
  final NumericalAdjustment adjustment;
  final double? initialValue;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool highlighting;

  const SetNumericalAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    required this.onChanged,
    this.highlighting = true,
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
    final newText = widget.value ?? '';
    // If the controller already holds the same text (e.g. parent echoed a local edit),
    // don't overwrite it — that would move the cursor to the end and disrupt editing.
    if (newText == _controller.text) return;
    _controller.value = _controller.value.copyWith(
      text: newText,
      // Place the cursor at the end for externally-driven updates (e.g. reset).
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
    late bool isChanged;
    late bool isInitial;
    late Color? highlightColor; 
    if (widget.highlighting) {
      isChanged = parsedValue == null ? false : widget.initialValue != parsedValue;
      isInitial = widget.initialValue == null;
      highlightColor = isChanged ? (isInitial ? Colors.green : Colors.orange) : null;
    } else {
      isChanged = false;
      isInitial = false;
      highlightColor = null;
    }
    
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
                Icon(NumericalAdjustment.iconData, color: highlightColor),
                SizedBox(width: 10),
                nameNotesSetAdjustmentWidget(context: context, adjustment: widget.adjustment, highlightColor: highlightColor),
              ],
            )
          ),
          Flexible(
            flex: 3,
            child: TextFormField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
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
                suffixStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontWeight: FontWeight.normal,
                ),
                suffixText: widget.adjustment.unit != null ? ' ${widget.adjustment.unit}' : null,
                suffixIcon: IconButton(
                  onPressed: () {
                    _controller.text = widget.initialValue?.toString() ?? '';
                    widget.onChanged(_controller.text.trim());
                  }, 
                  icon: const Icon(Icons.replay),
                  visualDensity: VisualDensity.compact,
                ),
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
