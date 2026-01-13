import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';

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
    late bool isChanged;
    late bool isInitial;
    late Color? highlightColor; 
    if (widget.highlighting) {
      isChanged = widget.initialValue != _controller.text.trim();
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
                Icon(TextAdjustment.iconData, color: highlightColor),
                SizedBox(width: 10),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: widget.adjustment.notes == null 
                        ? Text(widget.adjustment.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: highlightColor))
                        : Tooltip(
                            triggerMode: TooltipTriggerMode.tap,
                            preferBelow: false,
                            showDuration: Duration(seconds: 5),
                            message: widget.adjustment.notes!,
                            child: Text.rich(
                              TextSpan(
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: highlightColor),
                                children: [
                                  TextSpan(text: widget.adjustment.name),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 2),
                                      child: Opacity(
                                        opacity: 0.5,
                                        child: Icon(
                                          Icons.info_outline,
                                          color: highlightColor,
                                          size: Theme.of(context).textTheme.bodyMedium?.fontSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            )
          ),
          Flexible(
            flex: 3,
            child: TextFormField(
              controller: _controller,
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onChanged,
              maxLines: null,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'Enter Text',
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                suffixStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontWeight: FontWeight.normal,
                ),
                suffixText: widget.adjustment.unit != null ? ' ${widget.adjustment.unit}' : null,
                suffixIcon: IconButton(
                  onPressed: () {
                    _controller.text = widget.initialValue ?? '';
                    widget.onChanged(_controller.text.trim());
                  }, 
                  icon: const Icon(Icons.replay)
                ),
              ),
              validator: (String? newValue) => null // Allow empty field
            ), 
          ),
        ],
      ),
    );
  }
}
