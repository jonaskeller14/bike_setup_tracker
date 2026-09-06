import 'package:flutter/material.dart';

import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import '../display_adjustment/adjustment_icon_name_notes.dart';

class SetTextAdjustmentWidget extends StatefulWidget {
  final TextAdjustment adjustment;
  final String? initialValue;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool highlighting;

  /// The field is not pre-filled with [initialValue], so it may be left empty
  /// and its reset button clears it instead of restoring [initialValue].
  final bool optional;

  const SetTextAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    required this.onChanged,
    this.highlighting = true,
    this.optional = false,
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

  bool get _resetWouldChange {
    final target = widget.optional ? '' : (widget.initialValue ?? '');
    final current = widget.value ?? '';
    return current.trim() != target.trim();
  }

  @override
  Widget build(BuildContext context) {
    final String? parsedValue = _controller.text.trim().isEmpty ? null : _controller.text.trim();
    late bool isChanged;
    late bool isInitial;
    late Color? highlightColor;
    final highlights = Theme.of(context).extension<ValueHighlightColors>();
    if (widget.highlighting) {
      isChanged = parsedValue == null ? false : widget.initialValue != parsedValue;
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
            child: AdjustmentIconNameNotes(adjustment: widget.adjustment, color: highlightColor),
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
                suffixIcon: _resetWouldChange
                    ? IconButton(
                        onPressed: () {
                          _controller.text = widget.optional ? '' : widget.initialValue ?? '';
                          widget.onChanged(_controller.text.trim());
                        },
                        icon: const Icon(Icons.replay),
                        visualDensity: VisualDensity.compact,
                      )
                    : const SizedBox.shrink(),
                suffixIconConstraints: const BoxConstraints(minHeight: 48, minWidth: 0),
              ),
              validator: (String? newValue) {
                if ((newValue == null || newValue.trim().isEmpty) && !widget.optional && widget.initialValue != null) {
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
