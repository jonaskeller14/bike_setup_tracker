import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import '../../utils/unit_conversion.dart';
import '../display_adjustment/adjustment_icon_name_notes.dart';

class SetNumericalAdjustmentWidget extends StatefulWidget {
  final NumericalAdjustment adjustment;
  final double? initialValue;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool highlighting;

  /// The field is not pre-filled with [initialValue], so it may be left empty
  /// and its reset button clears it instead of restoring [initialValue].
  final bool optional;

  final List<UnitCycleEntry>? cycle;

  const SetNumericalAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    required this.onChanged,
    this.highlighting = true,
    this.optional = false,
    this.cycle,
  });

  @override
  State<SetNumericalAdjustmentWidget> createState() => _SetNumericalAdjustmentWidgetState();
}

class _SetNumericalAdjustmentWidgetState extends State<SetNumericalAdjustmentWidget> {
  late final TextEditingController _controller;
  int _index = 0;
  String? _lastReported;

  // Recomputed, not cached: a cycle's conversions close over widget state (e.g.
  // a sag adjustment's travel), so a stale copy would convert with old inputs.
  List<UnitCycleEntry> get _cycle => widget.cycle ?? knownUnitCycle(widget.adjustment.unit);

  // Guards a cycle that shrank under a stale index (sag travel cleared while mm
  // was active).
  int get _activeIndex => _index < _cycle.length ? _index : 0;

  bool get _toggleEnabled => _cycle.length > 1;
  bool get _isConverting => _activeIndex != 0;

  String? get _storageLabel => _cycle.isNotEmpty ? _cycle.first.label : widget.adjustment.unit?.label;
  String? get _activeLabel => _cycle.isNotEmpty ? _cycle[_activeIndex].label : widget.adjustment.unit?.label;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
    _lastReported = widget.value;
  }

  @override
  void didUpdateWidget(SetNumericalAdjustmentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    // Ignore the parent echoing back the storage-unit value we just reported —
    // the controller may be displaying it in a different (active) unit.
    if (widget.value == _lastReported) return;
    // Externally-driven update (e.g. reset from elsewhere): show it in the
    // active unit, cursor at end.
    final newText = _displayTextForStorage(widget.value);
    if (newText == _controller.text) return;
    _setText(newText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _toDisplay(double storageValue) =>
      _isConverting ? _cycle[_activeIndex].fromStorage(storageValue) : storageValue;

  double _toStorage(double displayValue) =>
      _isConverting ? _cycle[_activeIndex].toStorage(displayValue) : displayValue;

  String _displayTextForStorage(String? storageValue) {
    if (!_isConverting) return storageValue ?? '';
    final parsed = double.tryParse(storageValue ?? '');
    return parsed == null ? storageValue ?? '' : formatConverted(_toDisplay(parsed));
  }

  String _storageTextForDisplay(String displayText) {
    if (!_isConverting) return displayText;
    final parsed = double.tryParse(displayText.trim());
    return parsed == null ? displayText : _toStorage(parsed).toString();
  }

  double _boundInActiveUnit(double bound) => bound.isFinite ? _toDisplay(bound) : bound;

  void _setText(String text) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _report(String storageText) {
    _lastReported = storageText;
    widget.onChanged(storageText);
  }

  void _handleChanged(String displayText) {
    _report(_storageTextForDisplay(displayText));
  }

  void _reset() {
    final storageInit = widget.optional ? null : widget.initialValue;
    _setText(storageInit == null ? '' : _displayTextForStorage(storageInit.toString()));
    // Report the exact stored initial value (not a round-tripped conversion) to
    // avoid float drift.
    _report(storageInit?.toString() ?? '');
  }

  // Compares by parsed value (not raw text) so "10" vs "10.0" doesn't falsely
  // show the reset button as having an effect.
  bool get _resetWouldChange {
    final storageInit = widget.optional ? null : widget.initialValue;
    final targetText = storageInit?.toString() ?? '';
    final currentText = widget.value ?? '';
    if (targetText.isEmpty || currentText.isEmpty) return targetText != currentText;
    final targetVal = double.tryParse(targetText);
    final currentVal = double.tryParse(currentText);
    if (targetVal != null && currentVal != null) return targetVal != currentVal;
    return targetText != currentText;
  }

  void _cycleUnit() {
    if (!_toggleEnabled) return;
    final active = _cycle[_activeIndex];
    final nextIndex = (_activeIndex + 1) % _cycle.length;
    final next = _cycle[nextIndex];
    unawaited(HapticFeedback.selectionClick());
    final parsed = double.tryParse(_controller.text.trim());
    setState(() {
      _index = nextIndex;
      if (parsed != null) _setText(formatConverted(next.fromStorage(active.toStorage(parsed))));
    });
  }

  Widget _buildSuffix(BuildContext context) {
    final label = _activeLabel;
    final suffixColor = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (label != null)
          _toggleEnabled
              ? InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: _cycleUnit,
                  child: Padding(
                    padding: EdgeInsets.only(left: 4, right: _resetWouldChange ? 4 : 12, top: 4, bottom: 4),
                    child: Text(label, style: TextStyle(color: suffixColor)),
                  ),
                )
              : Padding(
                  padding: EdgeInsets.only(left: 4, right: _resetWouldChange ? 4 : 12),
                  child: Text(label, style: TextStyle(color: suffixColor)),
                ),
        if (_resetWouldChange)
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.replay),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double? parsedValue = double.tryParse(widget.value ?? '');
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

    String? helperText;
    if (_isConverting) {
      final storageVal = double.tryParse(widget.value ?? '');
      if (storageVal != null) {
        helperText = '= ${formatConverted(storageVal)} $_storageLabel';
      }
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),],
              controller: _controller,
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: _handleChanged,
              onFieldSubmitted: _handleChanged,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: 'Please enter',
                helperText: helperText,
                helperMaxLines: 2,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                suffixIcon: _buildSuffix(context),
                suffixIconConstraints: const BoxConstraints(minHeight: 48, minWidth: 0),
              ),
              validator: (String? newValue) {
                if ((newValue == null || newValue.trim().isEmpty) && !widget.optional && widget.initialValue != null) {
                  return 'Please enter a value';
                }
                if (newValue != null && newValue.trim().isNotEmpty) {
                  final parsedValue = double.tryParse(newValue);
                  if (parsedValue == null) return "Please enter valid number";
                  final unitLabel = _activeLabel;
                  final unitSuffix = unitLabel == null ? "" : " $unitLabel";
                  final max = _boundInActiveUnit(widget.adjustment.max);
                  if (parsedValue > max) return "Max ${formatConverted(max)}$unitSuffix";
                  final min = _boundInActiveUnit(widget.adjustment.min);
                  if (parsedValue < min) return "Min ${formatConverted(min)}$unitSuffix";
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
