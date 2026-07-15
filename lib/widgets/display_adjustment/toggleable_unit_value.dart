import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/adjustment/adjustment.dart';
import '../../utils/unit_conversion.dart';

class ToggleableUnitValue extends StatefulWidget {
  final num? value;
  final num? initialValue;
  final AdjustmentUnit? unit;
  final Color? highlightColor;
  final bool showPreviousValue;

  final CrossAxisAlignment crossAxisAlignment;

  /// Extra widgets appended after the value block (e.g. a step's `[min..max]`
  /// range line).
  final List<Widget> trailing;

  const ToggleableUnitValue({
    super.key,
    required this.value,
    required this.initialValue,
    required this.unit,
    this.highlightColor,
    this.showPreviousValue = false,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.trailing = const [],
  });

  @override
  State<ToggleableUnitValue> createState() => _ToggleableUnitValueState();
}

class _ToggleableUnitValueState extends State<ToggleableUnitValue> {
  KnownUnit? _activeUnit;

  KnownUnit? get _storageUnit {
    final unit = widget.unit;
    return unit is KnownUnit ? unit : null;
  }

  bool get _toggleEnabled => _storageUnit != null;
  bool get _isConverting => _toggleEnabled && _activeUnit != _storageUnit;

  @override
  void initState() {
    super.initState();
    _activeUnit = _storageUnit;
  }

  @override
  void didUpdateWidget(ToggleableUnitValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the underlying unit changed identity, reset back to storage unit.
    if (widget.unit != oldWidget.unit) _activeUnit = _storageUnit;
  }

  double _toActive(num storageValue) => _isConverting
      ? convertUnit(storageValue.toDouble(), _storageUnit!, _activeUnit!)
      : storageValue.toDouble();

  String _formatInActive(num? storageValue) {
    if (storageValue == null) return Adjustment.formatValue(null);
    if (!_isConverting) return Adjustment.formatValue(storageValue);
    return formatConverted(_toActive(storageValue));
  }

  String get _activeSuffix {
    final active = _activeUnit;
    if (active != null) return ' ${active.label}';
    final unit = widget.unit;
    return unit == null ? '' : ' ${unit.label}';
  }

  void _cycleUnit() {
    final storage = _storageUnit;
    final active = _activeUnit;
    if (storage == null || active == null) return;
    final cycle = toggleCycle(storage.quantity);
    final next = cycle[(cycle.indexOf(active) + 1) % cycle.length];
    unawaited(HapticFeedback.selectionClick());
    setState(() => _activeUnit = next);
  }

  Widget _unitLabel(BuildContext context) {
    final unit = widget.unit;
    if (unit == null) return const SizedBox.shrink();
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: widget.highlightColor,
    );
    if (!_toggleEnabled) {
      return Text(' ${unit.label}', style: style);
    }
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: _cycleUnit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(_activeUnit!.label, style: style),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.bodyLarge?.copyWith(
      fontFamily: 'monospace',
      fontWeight: FontWeight.bold,
      color: widget.highlightColor,
      fontFeatures: [const FontFeature.tabularFigures()],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.crossAxisAlignment,
      spacing: 2,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: SelectableText(
                _formatInActive(widget.value),
                style: valueStyle,
              ),
            ),
            _unitLabel(context),
          ],
        ),
        if (_isConverting && widget.value != null)
          Text(
            '= ${Adjustment.formatValue(widget.value)} ${_storageUnit!.label}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        if (widget.showPreviousValue)
          Opacity(
            opacity: 0.7,
            child: Text(
              _formatInActive(widget.initialValue) + _activeSuffix,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.lineThrough,
                decorationThickness: 2,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ),
        ...widget.trailing,
      ],
    );
  }
}
