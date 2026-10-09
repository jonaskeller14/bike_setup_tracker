import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/setup_comparison.dart' as comparison;
import '../../theme.dart';
import '../../utils/unit_conversion.dart';
import '../set_adjustment/set_step_adjustment_dial.dart';
import 'adjustment_icon_name_notes.dart';
import 'step_pips.dart';

enum DisplayAdjustmentDiffSide { both, a, b }

class DisplayAdjustmentDiff extends StatefulWidget {
  final String groupId;
  final comparison.SetupAdjustmentComparison row;
  final DisplayAdjustmentDiffSide side;

  const DisplayAdjustmentDiff({
    super.key,
    required this.groupId,
    required this.row,
    this.side = DisplayAdjustmentDiffSide.both,
  });

  @override
  State<DisplayAdjustmentDiff> createState() => _DisplayAdjustmentDiffState();
}

class _DisplayAdjustmentDiffState extends State<DisplayAdjustmentDiff> {
  int _unitIndex = 0;

  comparison.SetupAdjustmentComparison get row => widget.row;
  Adjustment get adjustment => row.adjustment;
  List<UnitCycleEntry> get _unitCycle => _cycleFor(adjustment);
  int get _activeUnitIndex => _unitIndex < _unitCycle.length ? _unitIndex : 0;
  String? get _activeUnitLabel => _unitCycle.isEmpty ? adjustment.unit?.label : _unitCycle[_activeUnitIndex].label;
  bool get _canToggleUnit => _unitCycle.length > 1;

  @override
  void didUpdateWidget(DisplayAdjustmentDiff oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldAdjustment = oldWidget.row.adjustmentA ?? oldWidget.row.adjustmentB;
    if (row.id != oldWidget.row.id || adjustment.unit != oldAdjustment?.unit) {
      _unitIndex = 0;
    }
  }

  void _toggleUnit() {
    if (!_canToggleUnit) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() => _unitIndex = (_activeUnitIndex + 1) % _unitCycle.length);
  }

  @override
  Widget build(BuildContext context) {
    final id = '${widget.groupId}-${row.id}';
    final changedColor = row.isDifferent ? Theme.of(context).extension<ValueHighlightColors>()!.changed : null;

    return Semantics(
      container: true,
      label: row.isDifferent ? 'Different ${row.label}' : row.label,
      child: Container(
        key: Key('compare-row-$id'),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdjustmentIconNameNotes(
              adjustment: adjustment,
              compact: true,
              color: changedColor,
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.side != DisplayAdjustmentDiffSide.b)
                  Expanded(
                    child: _DiffValue(
                      key: Key('compare-panel-a-$id'),
                      value: _display(row.valueA, row.adjustmentA ?? adjustment),
                      footer: _pips(row.valueA, row.adjustmentA ?? adjustment),
                      color: changedColor,
                      canToggleUnit: _canToggleUnit,
                      onToggleUnit: _toggleUnit,
                    ),
                  ),
                if (widget.side == DisplayAdjustmentDiffSide.both) const SizedBox(width: 8),
                if (widget.side != DisplayAdjustmentDiffSide.a)
                  Expanded(
                    child: _DiffValue(
                      key: Key('compare-panel-b-$id'),
                      value: _display(row.valueB, row.adjustmentB ?? adjustment),
                      footer: _pips(row.valueB, row.adjustmentB ?? adjustment),
                      color: changedColor,
                      canToggleUnit: _canToggleUnit,
                      onToggleUnit: _toggleUnit,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _DisplayedValue _display(
    comparison.SetupComparisonSideValue side,
    Adjustment definition,
  ) {
    if (side.provenance == comparison.SetupComparisonValueProvenance.unavailable) {
      return const _DisplayedValue(text: '-');
    }
    final value = side.value;
    if (value == null) return const _DisplayedValue(text: '-');

    if (_supportsUnitToggle(definition) && (value is StepValue || value is NumericalValue)) {
      final cycle = _cycleFor(definition);
      if (cycle.isNotEmpty) {
        final selected = cycle.firstWhere(
          (entry) => entry.label == _activeUnitLabel,
          orElse: () => cycle.first,
        );
        final converted = selected.label != cycle.first.label;
        return _DisplayedValue(
          text: converted ? formatConverted(selected.fromStorage(value.asNum!.toDouble())) : value.display,
          unit: selected.label,
          storageEquivalent: converted ? '= ${value.display} ${cycle.first.label}' : null,
          usesMonospace: true,
        );
      }
    }

    return _DisplayedValue(
      text: value.display,
      unit: definition.unit?.label,
      usesMonospace: _usesMonospaceValue(definition),
    );
  }

  /// A step value over its pips, which only fill up to the value: the coloured
  /// values already say that the sides differ.
  Widget? _pips(comparison.SetupComparisonSideValue side, Adjustment definition) {
    final value = side.value;
    if (side.provenance == comparison.SetupComparisonValueProvenance.unavailable) return null;
    if (definition is! StepAdjustment || value is! StepValue) return null;
    return StepPips(adjustment: definition, value: value, color: resolveStepAccentColor(context, definition));
  }

  bool _supportsUnitToggle(Adjustment value) => value is NumericalAdjustment || value is StepAdjustment;

  bool _usesMonospaceValue(Adjustment value) => value is NumericalAdjustment || value is StepAdjustment;

  List<UnitCycleEntry> _cycleFor(Adjustment value) {
    if (value is SagAdjustment) return sagUnitCycle(value);
    if (_supportsUnitToggle(value)) return knownUnitCycle(value.unit);
    return const [];
  }
}

class _DiffValue extends StatelessWidget {
  final _DisplayedValue value;
  final Widget? footer;
  final Color? color;
  final bool canToggleUnit;
  final VoidCallback onToggleUnit;

  const _DiffValue({
    super.key,
    required this.value,
    this.footer,
    required this.color,
    required this.canToggleUnit,
    required this.onToggleUnit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.bodyLarge?.copyWith(
      color: color,
      fontFamily: value.usesMonospace ? 'monospace' : null,
      fontWeight: FontWeight.bold,
      fontFeatures: value.usesMonospace ? [const FontFeature.tabularFigures()] : null,
    );
    final unitStyle = theme.textTheme.bodyLarge?.copyWith(
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        label: [value.text, value.unit].whereType<String>().join(' '),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: SelectableText(value.text, style: valueStyle)),
                if (value.unit != null)
                  canToggleUnit
                      ? InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: onToggleUnit,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(value.unit!, style: unitStyle),
                          ),
                        )
                      : Text(' ${value.unit}', style: unitStyle),
              ],
            ),
            if (value.storageEquivalent != null)
              Text(
                value.storageEquivalent!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            if (footer case final footer?) Padding(padding: const EdgeInsets.only(top: 6), child: footer),
          ],
        ),
      ),
    );
  }
}

class _DisplayedValue {
  final String text;
  final String? unit;
  final String? storageEquivalent;
  final bool usesMonospace;

  const _DisplayedValue({
    required this.text,
    this.unit,
    this.storageEquivalent,
    this.usesMonospace = false,
  });
}
