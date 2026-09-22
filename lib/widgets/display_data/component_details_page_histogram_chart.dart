import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/adjustment_activity_histogram.dart';
import '../../models/setup.dart';
import '../../theme.dart';
import '../../utils/adjustment_activity_histogram_grouping.dart';
import '../../utils/table_column.dart';
import '../empty_state_placeholder.dart';

class ComponentDetailsPageHistogramChart extends StatefulWidget {
  final List<TableColumn> activeColumns;
  final List<Setup> setups;
  final Map<String, int> setupActivityCounts;
  final bool hasAnyActivity;
  final bool activityCountsLoaded;
  final bool activityCountsFailed;
  final TableColumn? selectedHistogramColumn;
  final dynamic Function(Setup setup, TableColumn column) valueFor;
  final Adjustment? Function(TableColumn column) adjustmentFor;
  final String Function(TableColumn column) columnLabel;
  final ValueChanged<TableColumn> onSelectedColumnChanged;
  final ValueChanged<TableColumn> onColumnRemoved;

  const ComponentDetailsPageHistogramChart({
    super.key,
    required this.activeColumns,
    required this.setups,
    required this.setupActivityCounts,
    required this.hasAnyActivity,
    required this.activityCountsLoaded,
    required this.activityCountsFailed,
    required this.selectedHistogramColumn,
    required this.valueFor,
    required this.adjustmentFor,
    required this.columnLabel,
    required this.onSelectedColumnChanged,
    required this.onColumnRemoved,
  });

  @override
  State<ComponentDetailsPageHistogramChart> createState() => _ComponentDetailsPageHistogramChartState();
}

class _ComponentDetailsPageHistogramChartState extends State<ComponentDetailsPageHistogramChart> {
  int? _touchedBarIndex;

  AdjustmentActivityHistogram _histogramFor(TableColumn column, Adjustment adjustment) {
    return groupAdjustmentActivityHistogram(
      adjustment: adjustment,
      values: widget.setups.map(
        (setup) => AdjustmentActivityValue(
          setupId: setup.id,
          value: widget.valueFor(setup, column),
          activityCount: widget.setupActivityCounts[setup.id] ?? 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Free text has no meaningful distribution; rating columns are not linked to adjustment values.
    final chartColumns = widget.activeColumns.where((column) {
      final adjustment = widget.adjustmentFor(column);
      return adjustment != null && adjustment is! TextAdjustment;
    }).toList();

    if (chartColumns.isEmpty) {
      return const EmptyStatePlaceholder(
        icon: Icons.bar_chart_rounded,
        title: "No adjustments selected",
        subtitle: "Select adjustment columns to visualize the activity distribution",
      );
    }
    if (widget.setups.isEmpty) {
      return const EmptyStatePlaceholder(
        icon: Icons.bar_chart_rounded,
        title: "No data",
        subtitle: "No setup data available for this component",
      );
    }
    if (!widget.hasAnyActivity) {
      return const EmptyStatePlaceholder(
        icon: Icons.bar_chart_rounded,
        title: "No activities",
        subtitle: "Sync Strava activities to see which values you rode most",
      );
    }
    if (widget.activityCountsFailed) {
      return const EmptyStatePlaceholder.error(
        title: "Could not load activities",
        subtitle: "Something went wrong while linking activities to setups",
      );
    }
    if (!widget.activityCountsLoaded) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final selectedColumn = chartColumns.contains(widget.selectedHistogramColumn)
        ? widget.selectedHistogramColumn!
        : chartColumns.first;
    final colors = chartColors(Theme.of(context).colorScheme.primary, chartColumns.length);
    final color = colors[chartColumns.indexOf(selectedColumn)];
    final histogram = _histogramFor(selectedColumn, widget.adjustmentFor(selectedColumn)!);

    return Column(
      children: [
        const SizedBox(height: 16),
        if (histogram.isEmpty)
          EmptyStatePlaceholder(
            icon: Icons.bar_chart_rounded,
            title: "No activities linked",
            subtitle:
                "None of the setups with a '${widget.columnLabel(selectedColumn)}' value were used on an activity",
          )
        else
          _buildChart(context, histogram, color),
        const SizedBox(height: 16),
        _buildLegend(context, chartColumns, selectedColumn, colors),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildChart(BuildContext context, AdjustmentActivityHistogram histogram, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelStyle = theme.textTheme.bodySmall;
    final bars = histogram.bars;

    final maxCount = bars.map((bar) => bar.activityCount).max;
    final tickInterval = math.max(1, (maxCount / 4).ceil());
    final maxY = math.max(tickInterval, (maxCount / tickInterval).ceil() * tickInterval).toDouble();

    return Semantics(
      container: true,
      label: 'Activity distribution. ${bars.map((bar) => '${bar.label}: ${bar.activityCount} activities').join(', ')}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 300,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slotWidth = (constraints.maxWidth - 40) / bars.length;
              return BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: bars.mapIndexed((index, bar) {
                    final isTouched = _touchedBarIndex == index;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: bar.activityCount.toDouble(),
                          width: (slotWidth * 0.7).clamp(4.0, 32.0),
                          color: isTouched ? color : color.withValues(alpha: 0.75),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: tickInterval.toDouble(),
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(value.toInt().toString(), style: labelStyle, textAlign: TextAlign.right),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (value != index || index < 0 || index >= bars.length) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            angle: -math.pi / 4,
                            child: Text(
                              _abbreviate(bars[index].label),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: labelStyle,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: tickInterval.toDouble(),
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: colorScheme.outlineVariant.withValues(alpha: 0.5), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: colorScheme.outline),
                      bottom: BorderSide(color: colorScheme.outline),
                      top: BorderSide.none,
                      right: BorderSide.none,
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
                      final index = response?.spot?.touchedBarGroupIndex;
                      if (!event.isInterestedForInteractions || index == null) {
                        if (_touchedBarIndex != null) setState(() => _touchedBarIndex = null);
                        return;
                      }
                      if (_touchedBarIndex != index) {
                        unawaited(HapticFeedback.selectionClick());
                        setState(() => _touchedBarIndex = index);
                      }
                    },
                    touchTooltipData: BarTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipColor: (group) => colorScheme.surfaceContainerHighest,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final bar = bars[group.x];
                        final style = labelStyle!.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.bold);
                        return BarTooltipItem(
                          '${bar.label}\n',
                          style,
                          children: [
                            TextSpan(
                              text: Intl.plural(
                                bar.activityCount,
                                one: '1 activity',
                                other: '${bar.activityCount} activities',
                              ),
                              style: style.copyWith(color: color),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(
    BuildContext context,
    List<TableColumn> chartColumns,
    TableColumn selectedColumn,
    List<Color> colors,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: chartColumns.mapIndexed((index, column) {
          final isSelected = column == selectedColumn;
          final color = colors[index];

          return InkWell(
            onTap: () {
              if (isSelected) return;
              unawaited(HapticFeedback.selectionClick());
              setState(() => _touchedBarIndex = null);
              widget.onSelectedColumnChanged(column);
            },
            onLongPress: () {
              unawaited(HapticFeedback.selectionClick());
              widget.onColumnRemoved(column);
            },
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Opacity(
                opacity: isSelected ? 1.0 : 0.3,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                    ),
                    Flexible(
                      child: Text(
                        widget.columnLabel(column),
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
          );
        }).toList(),
      ),
    );
  }

  static String _abbreviate(String label) => label.length <= 12 ? label : '${label.substring(0, 9)}…';
}
