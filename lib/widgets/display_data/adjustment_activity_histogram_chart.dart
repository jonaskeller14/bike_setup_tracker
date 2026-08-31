import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/adjustment_activity_histogram.dart';

class AdjustmentActivityHistogramChart extends StatelessWidget {
  final AdjustmentActivityHistogram histogram;

  const AdjustmentActivityHistogramChart({super.key, required this.histogram});

  @override
  Widget build(BuildContext context) {
    final bars = histogram.bars;
    if (bars.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxCount = bars.fold<int>(0, (maximum, bar) => math.max(maximum, bar.activityCount));
    final tickInterval = math.max(1, (maxCount / 4).ceil());
    final chartMaximum = math.max(tickInterval, (maxCount / tickInterval).ceil() * tickInterval).toDouble();
    final summary = bars.map((bar) => '${bar.label}: ${bar.activityCount} activities').join(', ');

    return Semantics(
      container: true,
      label: 'Activity distribution. $summary',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
            return SizedBox(
              key: const ValueKey('adjustment-activity-histogram'),
              width: math.min(availableWidth, 320),
              height: 190,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: chartMaximum,
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: tickInterval.toDouble(),
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: colorScheme.onSecondary.withValues(alpha: 0.18),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      axisNameSize: 18,
                      axisNameWidget: SizedBox(
                        key: const ValueKey('histogram-activity-count-axis-label'),
                        child: Text(
                          'Activity count',
                          style: textTheme.labelSmall?.copyWith(color: colorScheme.onSecondary),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: tickInterval.toDouble(),
                        getTitlesWidget: (value, meta) => Text(
                          value.round().toString(),
                          style: textTheme.labelSmall?.copyWith(color: colorScheme.onSecondary),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 54,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= bars.length) return const SizedBox.shrink();
                          final label = _abbreviate(bars[index].label);
                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            angle: -math.pi / 4,
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(color: colorScheme.onSecondary),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => colorScheme.secondaryContainer,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final bar = bars[group.x];
                        return BarTooltipItem(
                          '${bar.label}\n${bar.activityCount} activities',
                          textTheme.labelSmall?.copyWith(color: colorScheme.onSecondaryContainer) ??
                              TextStyle(color: colorScheme.onSecondaryContainer),
                        );
                      },
                    ),
                  ),
                  barGroups: [
                    for (var index = 0; index < bars.length; index++)
                      BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: bars[index].activityCount.toDouble(),
                            width: math.max(6, math.min(18, 180 / bars.length)),
                            color: colorScheme.primaryContainer,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                        ],
                      ),
                  ],
                ),
                duration: Duration.zero,
              ),
            );
          },
        ),
      ),
    );
  }

  static String _abbreviate(String label) => label.length <= 12 ? label : '${label.substring(0, 9)}…';
}
