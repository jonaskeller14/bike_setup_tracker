import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/adjustment/adjustment.dart';
import '../../utils/unit_conversion.dart';

class ToggleableUnitValue extends StatefulWidget {
  final AdjustmentValue? value;
  final AdjustmentValue? initialValue;
  final AdjustmentUnit? unit;
  final Color? highlightColor;
  final bool showPreviousValue;

  /// Overrides the unit-catalog cycle derived from [unit] — e.g. sag's % ↔ mm,
  /// where mm comes from the adjustment's reference travel rather than a
  /// catalog conversion. Entry 0 must be the storage unit.
  final List<UnitCycleEntry>? cycle;

  /// Extra widgets appended after the value block (e.g. a step's `[min..max]`
  /// range line).
  final List<Widget> trailing;

  const ToggleableUnitValue({
    super.key,
    required this.value,
    required this.initialValue,
    required this.unit,
    this.cycle,
    this.highlightColor,
    this.showPreviousValue = false,
    this.trailing = const [],
  });

  @override
  State<ToggleableUnitValue> createState() => _ToggleableUnitValueState();
}

class _ToggleableUnitValueState extends State<ToggleableUnitValue> {
  static const double _unitPadding = 6;

  int _index = 0;

  // Recomputed rather than cached: the cycle's conversions close over widget
  // state (e.g. a sag adjustment's travel), so a stale copy would convert with
  // outdated inputs.
  List<UnitCycleEntry> get _cycle => widget.cycle ?? knownUnitCycle(widget.unit);

  /// Guards against a cycle that shrank under a stale index (e.g. sag's travel
  /// was cleared while mm was active).
  int get _activeIndex => _index < _cycle.length ? _index : 0;

  bool get _toggleEnabled => _cycle.length > 1;
  bool get _isConverting => _activeIndex != 0;

  String? get _storageLabel => _cycle.isNotEmpty ? _cycle.first.label : widget.unit?.label;
  String? get _activeLabel => _cycle.isNotEmpty ? _cycle[_activeIndex].label : widget.unit?.label;

  @override
  void didUpdateWidget(ToggleableUnitValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the underlying unit changed identity, reset back to storage unit.
    if (widget.unit != oldWidget.unit) _index = 0;
  }

  String _formatInActive(AdjustmentValue? storageValue) {
    final number = storageValue?.asNum;
    if (!_isConverting || number == null) return storageValue?.display ?? '-';
    return formatConverted(_cycle[_activeIndex].fromStorage(number.toDouble()));
  }

  String get _activeSuffix {
    final label = _activeLabel;
    return label == null ? '' : ' $label';
  }

  void _cycleUnit() {
    if (!_toggleEnabled) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() => _index = (_activeIndex + 1) % _cycle.length);
  }

  Widget _unitLabel(BuildContext context) {
    final label = _activeLabel;
    if (label == null) return const SizedBox.shrink();
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: widget.highlightColor,
    );
    if (!_toggleEnabled) {
      return Text(' $label', style: style);
    }
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: _cycleUnit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _unitPadding),
        child: Text(label, style: style),
      ),
    );
  }

  /// Insets a line below the value by the tappable unit's padding so its text
  /// ends flush with the unit label's text rather than its tap target.
  Widget _alignedWithUnitText(Widget child) => Padding(
    padding: EdgeInsets.only(right: _toggleEnabled && _activeLabel != null ? _unitPadding : 0),
    child: child,
  );

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
      crossAxisAlignment: CrossAxisAlignment.end,
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
          _alignedWithUnitText(Text(
            '= ${widget.value!.display} $_storageLabel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          )),
        if (widget.showPreviousValue)
          _alignedWithUnitText(Opacity(
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
          )),
        ...widget.trailing,
      ],
    );
  }
}
