import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/adjustment_value_text.dart';
import '../../l10n/entity_names.dart';
import '../../l10n/l10n.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/setup.dart';
import '../../theme.dart';
import '../../utils/automation_ids.dart';
import '../../utils/table_column.dart';
import '../empty_state_placeholder.dart';

const _minAxes = 3;
const _maxTooltipSetups = 3;
const _chartHeight = 350.0;

class SetupRadialChart extends StatefulWidget {
  final List<TableColumn> activeColumns;
  final List<Setup> setups;
  final List<Setup> selectedSetups;
  final AdjustmentValue? Function(Setup setup, TableColumn column) valueFor;
  final Adjustment? Function(TableColumn column) adjustmentFor;
  final String Function(TableColumn column) columnLabel;
  final ValueChanged<String> onSetupRemoved;

  const SetupRadialChart({
    super.key,
    required this.activeColumns,
    required this.setups,
    required this.selectedSetups,
    required this.valueFor,
    required this.adjustmentFor,
    required this.columnLabel,
    required this.onSetupRemoved,
  });

  @override
  State<SetupRadialChart> createState() => _SetupRadialChartState();
}

class _SetupRadialChartState extends State<SetupRadialChart> {
  _TouchedRadarValue? _touchedValue;
  String? _selectedSetupId;

  @override
  void didUpdateWidget(covariant SetupRadialChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.selectedSetups.any((setup) => setup.id == _touchedValue?.setupId)) {
      _touchedValue = null;
    }
    if (!widget.selectedSetups.any((setup) => setup.id == _selectedSetupId)) {
      _selectedSetupId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartColumns = widget.activeColumns.where((column) {
      final adjustment = widget.adjustmentFor(column);
      return adjustment is StepAdjustment || adjustment is NumericalAdjustment;
    }).toList();
    final axisColumns = chartColumns.where((column) {
      return widget.selectedSetups.any((setup) => widget.valueFor(setup, column)?.asNum != null);
    }).toList();

    final emptyState = _emptyStateText(context.l10n, chartColumns: chartColumns, axisColumns: axisColumns);
    if (emptyState != null) {
      return EmptyStatePlaceholder(
        icon: Icons.insights_rounded,
        title: emptyState.title,
        subtitle: emptyState.subtitle,
      );
    }

    final model = _RadarModel.build(
      axes: axisColumns.map(_axisFor).toList(),
      setups: widget.selectedSetups,
      valueFor: widget.valueFor,
      primary: Theme.of(context).colorScheme.primary,
    );
    final selectedLineIndex = model.lineIndexOf(_selectedSetupId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LayoutBuilder(
        // The legend shares the stack so the tooltip paints above it.
        builder: (context, constraints) => Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                Container(
                  height: _chartHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RadarChart(_chartData(context, model, selectedLineIndex), duration: Duration.zero),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _RadarLegend(
                    setups: widget.selectedSetups,
                    model: model,
                    selectedLineIndex: selectedLineIndex,
                    onTap: (setup) => _toggleSelection(setup, model, selectedLineIndex),
                    onLongPress: (setup) => _removeSetup(setup, model),
                  ),
                ),
              ],
            ),
            ?_tooltipFor(model, chartWidth: constraints.maxWidth),
          ],
        ),
      ),
    );
  }

  ({String title, String subtitle})? _emptyStateText(
    AppLocalizations l10n, {
    required List<TableColumn> chartColumns,
    required List<TableColumn> axisColumns,
  }) {
    if (chartColumns.isEmpty) {
      return (title: l10n.chartNoAdjustmentsTitle, subtitle: l10n.chartTrendNoColumnsSubtitle);
    }
    if (widget.setups.isEmpty) return (title: l10n.chartNoDataTitle, subtitle: l10n.chartNoDataSubtitle);
    if (widget.selectedSetups.isEmpty) {
      return (title: l10n.chartNoSetupsSelectedTitle, subtitle: l10n.chartNoSetupsSelectedSubtitle);
    }
    if (axisColumns.isEmpty) return (title: l10n.chartNoNumericalTitle, subtitle: l10n.chartNoNumericalSubtitle);
    if (axisColumns.length < _minAxes) {
      return (title: l10n.chartRadialNotEnoughTitle, subtitle: l10n.chartRadialNotEnoughSubtitle);
    }
    return null;
  }

  /// Scaled over all setups, not just the selected ones, so axes stay put while selecting.
  _RadarAxis _axisFor(TableColumn column) => _RadarAxis.fit(
    column: column,
    name: widget.columnLabel(column),
    unit: widget.adjustmentFor(column)?.unit?.label ?? '',
    values: widget.setups.map((setup) => widget.valueFor(setup, column)?.asNum).nonNulls,
  );

  RadarChartData _chartData(BuildContext context, _RadarModel model, int? selectedLineIndex) {
    final theme = Theme.of(context);
    return RadarChartData(
      radarShape: RadarShape.polygon,
      tickCount: 5,
      ticksTextStyle: const TextStyle(color: Colors.transparent),
      gridBorderData: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1),
      radarBorderData: const BorderSide(color: Colors.transparent),
      tickBorderData: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3), width: 1),
      titleTextStyle: theme.textTheme.bodySmall,
      getTitle: (index, angle) => RadarChartTitle(text: model.axes[index].shortName, angle: 0),
      radarTouchData: RadarTouchData(touchCallback: (event, response) => _handleTouch(model, event, response)),
      dataSets: model.lines.mapIndexed((index, line) {
        final isHighlighted = selectedLineIndex == null || selectedLineIndex == index;
        return RadarDataSet(
          dataEntries: line.values.map((value) => RadarEntry(value: value)).toList(),
          fillColor: line.color.withValues(alpha: isHighlighted ? 0.2 : 0.05),
          borderColor: isHighlighted ? line.color : line.color.withValues(alpha: 0.25),
          entryRadius: isHighlighted ? 3 : 2,
          borderWidth: isHighlighted ? 2 : 1.5,
        );
      }).toList(),
    );
  }

  void _handleTouch(_RadarModel model, FlTouchEvent event, RadarTouchResponse? response) {
    final spot = response?.touchedSpot;
    if (event.isInterestedForInteractions && spot != null) {
      final lineIndex = spot.touchedDataSetIndex;
      final axisIndex = spot.touchedRadarEntryIndex;
      if (lineIndex >= model.lines.length || axisIndex >= model.axes.length) return;
      final touched = _TouchedRadarValue(
        setupId: model.lines[lineIndex].setups.first.id,
        column: model.axes[axisIndex].column,
        offset: spot.offset,
      );
      if (touched.setupId != _touchedValue?.setupId || touched.column != _touchedValue?.column) {
        unawaited(HapticFeedback.selectionClick());
      }
      setState(() => _touchedValue = touched);
    } else if (event is FlPointerExitEvent || event is FlPanEndEvent || (event is FlTapUpEvent && spot == null)) {
      setState(() => _touchedValue = null);
    }
  }

  _RadarTooltip? _tooltipFor(_RadarModel model, {required double chartWidth}) {
    final touched = _touchedValue;
    if (touched == null) return null;
    final setup = widget.selectedSetups.firstWhereOrNull((s) => s.id == touched.setupId);
    final axis = model.axes.firstWhereOrNull((a) => a.column == touched.column);
    if (setup == null || axis == null) return null;

    final value = widget.valueFor(setup, axis.column);
    final sharingSetups = widget.selectedSetups
        .where((s) => widget.valueFor(s, axis.column)?.asNum == value?.asNum)
        .sorted((a, b) => b.datetime.compareTo(a.datetime));
    return _RadarTooltip(
      offset: touched.offset,
      chartWidth: chartWidth,
      setups: sharingSetups,
      colorOf: (setup) => model.lineOf(setup).color,
      axis: axis,
      value: value,
    );
  }

  void _toggleSelection(Setup setup, _RadarModel model, int? selectedLineIndex) {
    unawaited(HapticFeedback.selectionClick());
    final isSelected = selectedLineIndex == model.lineIndexOf(setup.id);
    setState(() => _selectedSetupId = isSelected ? null : setup.id);
  }

  void _removeSetup(Setup setup, _RadarModel model) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      if (_selectedSetupId == setup.id) {
        // Keep the rest of the merged line highlighted.
        _selectedSetupId = model.lineOf(setup).setups.firstWhereOrNull((s) => s.id != setup.id)?.id;
      }
      if (_touchedValue?.setupId == setup.id) _touchedValue = null;
    });
    widget.onSetupRemoved(setup.id);
  }
}

/// One chart axis: an adjustment column and the value range it is scaled to.
class _RadarAxis {
  final TableColumn column;
  final String name;
  final String unit;
  final double min;
  final double max;

  const _RadarAxis({
    required this.column,
    required this.name,
    required this.unit,
    required this.min,
    required this.max,
  });

  factory _RadarAxis.fit({
    required TableColumn column,
    required String name,
    required String unit,
    required Iterable<num> values,
  }) {
    final doubles = values.map((value) => value.toDouble());
    final dataMin = doubles.minOrNull ?? 0.0;
    final dataMax = doubles.maxOrNull ?? 1.0;
    // Pad the range so points stay off the center and the outer edge.
    final padding = dataMin == dataMax ? 1.0 : (dataMax - dataMin) * 0.05;
    return _RadarAxis(column: column, name: name, unit: unit, min: dataMin - padding, max: dataMax + padding);
  }

  String get shortName => name.length > 15 ? '${name.substring(0, 12)}...' : name;

  /// Position on the axis from 0 (center) to 100 (edge); a missing value sits at the center.
  double normalize(num? value) {
    if (value == null) return 0.0;
    return ((value.toDouble() - min) / (max - min) * 100).clamp(0.0, 100.0);
  }

  String describe(AdjustmentValue? value, AppLocalizations l10n) {
    final text = value?.displayText(l10n) ?? '-';
    return unit.isEmpty ? '$name: $text' : '$name: $text $unit';
  }
}

/// One drawn line, shared by every setup with the same values on all axes.
class _RadarLine {
  final List<Setup> setups;
  final List<double> values;
  final Color color;

  const _RadarLine({required this.setups, required this.values, required this.color});
}

class _RadarModel {
  final List<_RadarAxis> axes;
  final List<_RadarLine> lines;
  final Map<String, int> _lineIndexBySetupId;

  const _RadarModel._(this.axes, this.lines, this._lineIndexBySetupId);

  factory _RadarModel.build({
    required List<_RadarAxis> axes,
    required List<Setup> setups,
    required AdjustmentValue? Function(Setup setup, TableColumn column) valueFor,
    required Color primary,
  }) {
    final lineSetups = <List<Setup>>[];
    final lineValues = <List<num?>>[];
    final lineIndexBySetupId = <String, int>{};
    for (final setup in setups) {
      final values = axes.map((axis) => valueFor(setup, axis.column)?.asNum).toList();
      var index = lineValues.indexWhere((other) => const ListEquality<num?>().equals(other, values));
      if (index == -1) {
        index = lineSetups.length;
        lineSetups.add([]);
        lineValues.add(values);
      }
      lineSetups[index].add(setup);
      lineIndexBySetupId[setup.id] = index;
    }

    final colors = chartColors(primary, lineSetups.length);
    final lines = lineSetups.mapIndexed((index, setups) {
      return _RadarLine(
        setups: setups,
        values: axes.mapIndexed((axisIndex, axis) => axis.normalize(lineValues[index][axisIndex])).toList(),
        color: colors[index],
      );
    }).toList();
    return _RadarModel._(axes, lines, lineIndexBySetupId);
  }

  int? lineIndexOf(String? setupId) => _lineIndexBySetupId[setupId];

  _RadarLine lineOf(Setup setup) => lines[_lineIndexBySetupId[setup.id]!];
}

class _TouchedRadarValue {
  final String setupId;
  final TableColumn column;
  final Offset offset;

  const _TouchedRadarValue({required this.setupId, required this.column, required this.offset});
}

/// Lists every setup that shares the touched value, newest first.
class _RadarTooltip extends StatelessWidget {
  final Offset offset;
  final double chartWidth;
  final List<Setup> setups;
  final Color Function(Setup setup) colorOf;
  final _RadarAxis axis;
  final AdjustmentValue? value;

  const _RadarTooltip({
    required this.offset,
    required this.chartWidth,
    required this.setups,
    required this.colorOf,
    required this.axis,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final dateFormat = DateFormat(context.read<AppSettings>().dateFormat, l10n.localeName);
    final hiddenCount = setups.length - _maxTooltipSetups;
    final opensLeft = offset.dx > chartWidth / 2;
    final opensUp = offset.dy > _chartHeight / 2;

    return Positioned(
      left: opensLeft ? null : offset.dx,
      right: opensLeft ? chartWidth - offset.dx : null,
      top: offset.dy,
      child: FractionalTranslation(
        translation: Offset(0, opensUp ? -1 : 0),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: opensLeft ? offset.dx : chartWidth - offset.dx),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final setup in setups.take(_maxTooltipSetups))
                    _RadarTooltipSetup(
                      label: setup.label(l10n),
                      date: dateFormat.format(setup.datetimeLocal),
                      color: colorOf(setup),
                    ),
                  if (hiddenCount > 0)
                    Text(
                      l10n.plusMore(hiddenCount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(axis.describe(value, l10n), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarTooltipSetup extends StatelessWidget {
  final String label;
  final String date;
  final Color color;

  const _RadarTooltipSetup({required this.label, required this.date, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            _ColorDot(color: color, size: 8),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            date,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 10),
          ),
        ),
      ],
    );
  }
}

class _RadarLegend extends StatelessWidget {
  final List<Setup> setups;
  final _RadarModel model;
  final int? selectedLineIndex;
  final ValueChanged<Setup> onTap;
  final ValueChanged<Setup> onLongPress;

  const _RadarLegend({
    required this.setups,
    required this.model,
    required this.selectedLineIndex,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: setups.mapIndexed((index, setup) {
        final isSelected = selectedLineIndex == model.lineIndexOf(setup.id);
        return _RadarLegendEntry(
          index: index,
          label: setup.label(context.l10n),
          color: model.lineOf(setup).color,
          isSelected: isSelected,
          isDimmed: selectedLineIndex != null && !isSelected,
          onTap: () => onTap(setup),
          onLongPress: () => onLongPress(setup),
        );
      }).toList(),
    );
  }
}

class _RadarLegendEntry extends StatelessWidget {
  final int index;
  final String label;
  final Color color;
  final bool isSelected;
  final bool isDimmed;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _RadarLegendEntry({
    required this.index,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.isDimmed,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      identifier: AutomationIds.radialChartLegend(index),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Opacity(
            opacity: isDimmed ? 0.3 : 1.0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                _ColorDot(color: color, size: 12),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? color : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final double size;

  const _ColorDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
