import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import "set_adjustment.dart";

class SetTextAdjustmentWidget extends StatefulWidget {
  final TextAdjustment adjustment;
  final String? initialValue;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool highlighting;

  const SetTextAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    required this.onChanged,
    this.highlighting = true,
  });

  @override
  State<SetTextAdjustmentWidget> createState() => _SetTextAdjustmentWidgetState();
}

class _SetTextAdjustmentWidgetState extends State<SetTextAdjustmentWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(SetTextAdjustmentWidget oldWidget) {
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
    final String? parsedValue = _controller.text.trim().isEmpty ? null : _controller.text.trim();
    late bool isChanged;
    late bool isInitial;
    late Color? highlightColor;
    final highlights = Theme.of(context).extension<ValueHighlightColors>();
    if (widget.highlighting) {
      isChanged = widget.initialValue != parsedValue;
      isInitial = widget.initialValue == null;
      highlightColor = isChanged ? (isInitial ? highlights?.initial ?? Colors.green : highlights?.changed ?? Colors.orange) : null;
    } else {
      isChanged = false;
      isInitial = false;
      highlightColor = null;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isChanged ? (isInitial ? highlights?.initialFill ?? Colors.green.withValues(alpha: 0.08) : highlights?.changedFill ?? Colors.orange.withValues(alpha: 0.08)) : null,
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
                Icon(TextAdjustment.iconData, color: highlightColor),
                const SizedBox(width: 10),
                nameNotesSetAdjustmentWidget(context: context, adjustment: widget.adjustment, highlightColor: highlightColor),
              ],
            )
          ),
          Flexible(
            flex: 3,
            child: TextFormField(
              controller: _controller,
              textInputAction: TextInputAction.newline,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onChanged,
              maxLines: null,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: 'Enter Text',
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                suffixStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontWeight: FontWeight.normal,
                ),
                suffixText: widget.adjustment.unit != null ? widget.adjustment.unitSuffix() : null,
                suffixIcon: IconButton(
                  onPressed: () {
                    _controller.text = widget.initialValue ?? '';
                    widget.onChanged(_controller.text.trim());
                  }, 
                  icon: const Icon(Icons.replay),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              validator: (String? newValue) {
                if ((newValue == null || newValue.trim().isEmpty) && widget.initialValue != null) {
                  return 'Please enter a value';
                }
                if (DurationAdjustment.tryParseDurationString(newValue) != null) {
                  return "Pure Duration Format not allowed. Add characters or use Duration Adjustment type.";
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
