import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import '../../utils/unit_conversion.dart';
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
  KnownUnit? _activeUnit;
  String? _lastReported;

  KnownUnit? get _storageUnit {
    final unit = widget.adjustment.unit;
    return unit is KnownUnit ? unit : null;
  }

  bool get _toggleEnabled => _storageUnit != null;
  bool get _isConverting => _toggleEnabled && _activeUnit != _storageUnit;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
    _activeUnit = _storageUnit;
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
      _isConverting ? convertUnit(storageValue, _storageUnit!, _activeUnit!) : storageValue;

  double _toStorage(double displayValue) =>
      _isConverting ? convertUnit(displayValue, _activeUnit!, _storageUnit!) : displayValue;

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
    final storageInit = widget.initialValue;
    _setText(storageInit == null ? '' : _displayTextForStorage(storageInit.toString()));
    // Report the exact stored initial value (not a round-tripped conversion) to
    // avoid float drift.
    _report(storageInit?.toString() ?? '');
  }

  void _cycleUnit() {
    final storage = _storageUnit;
    final active = _activeUnit;
    if (storage == null || active == null) return;
    final cycle = toggleCycle(storage.quantity);
    final next = cycle[(cycle.indexOf(active) + 1) % cycle.length];
    unawaited(HapticFeedback.selectionClick());
    final parsed = double.tryParse(_controller.text.trim());
    setState(() {
      _activeUnit = next;
      if (parsed != null) _setText(formatConverted(convertUnit(parsed, active, next)));
    });
  }

  Widget _buildSuffix(BuildContext context) {
    final unit = widget.adjustment.unit;
    final suffixColor = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (unit != null)
          _toggleEnabled
              ? InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: _cycleUnit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(_activeUnit!.label, style: TextStyle(color: suffixColor)),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(unit.label, style: TextStyle(color: suffixColor)),
                ),
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
        helperText = '= ${formatConverted(storageVal)} ${_storageUnit!.label}';
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
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(NumericalAdjustment.iconData, color: highlightColor),
                const SizedBox(width: 10),
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
              onChanged: _handleChanged,
              onFieldSubmitted: _handleChanged,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: 'Please enter',
                helperText: helperText,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                suffixIcon: _buildSuffix(context),
                suffixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
              ),
              validator: (String? newValue) {
                if ((newValue == null || newValue.trim().isEmpty) && widget.initialValue != null) {
                  return 'Please enter a value';
                }
                if (newValue != null && newValue.trim().isNotEmpty) {
                  final parsedValue = double.tryParse(newValue);
                  if (parsedValue == null) return "Please enter valid number";
                  final unitLabel = _activeUnit?.label ?? widget.adjustment.unit?.label;
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
