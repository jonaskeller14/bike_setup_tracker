import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/adjustment/adjustment.dart';
import '../models/app_settings.dart';
import '../models/setup.dart';
import '../theme.dart';
import '../utils/table_column.dart';
import 'empty_state_placeholder.dart';

class ComponentDetailsPageLineChart extends StatefulWidget {
  final List<TableColumn> activeColumns;
  final List<Setup> setups;
  final List<Setup> selectedSetups;
  final TableColumn? selectedLineChartColumn;
  final dynamic Function(Setup setup, TableColumn column) valueFor;
  final Adjustment? Function(TableColumn column) adjustmentFor;
  final String Function(TableColumn column) columnLabel;
  final ValueChanged<TableColumn?> onSelectedColumnChanged;
  final ValueChanged<TableColumn> onColumnRemoved;

  const ComponentDetailsPageLineChart({
    super.key,
    required this.activeColumns,
    required this.setups,
    required this.selectedSetups,
    required this.selectedLineChartColumn,
    required this.valueFor,
    required this.adjustmentFor,
    required this.columnLabel,
    required this.onSelectedColumnChanged,
    required this.onColumnRemoved,
  });

  @override
  State<StatefulWidget> createState() => _ComponentDetailsPageLineChartState();
}

class _ComponentDetailsPageLineChartState extends State<ComponentDetailsPageLineChart> {
  int? _touchedLineChartSpotX;

  static const List<List<int>?> _dashPatterns = [
    null,
    [6, 3],
    [2, 2],
    [10, 4, 2, 4],
  ];

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();

    final activeChartColumns = widget.activeColumns.where((column) {
      if (column.section == TableColumnSection.ratingScore || column.section == TableColumnSection.ratingMetrics) {
        return true;
      }
      final adjustment = widget.adjustmentFor(column);
      return adjustment is StepAdjustment || adjustment is NumericalAdjustment;
    }).toList();

    if (activeChartColumns.isEmpty) {
      return const EmptyStatePlaceholder(
        icon: Icons.insights_rounded,
        title: "No adjustments selected",
        subtitle: "Select numerical or step adjustment columns to visualize trends",
      );
    }
    if (widget.setups.isEmpty) {
      return const EmptyStatePlaceholder(
        icon: Icons.insights_rounded,
        title: "No data",
        subtitle: "No setup data available for this component",
      );
    }
    if (widget.selectedSetups.isEmpty) {
      return const EmptyStatePlaceholder(
        icon: Icons.insights_rounded,
        title: "No setups selected",
        subtitle: "Select setups in the table above to visualize the chart",
      );
    }

    final validColumns = activeChartColumns.where((column) {
      return widget.selectedSetups.any((setup) => widget.valueFor(setup, column) is num);
    }).toList();

    if (validColumns.isEmpty) {
      return const EmptyStatePlaceholder(
        icon: Icons.insights_rounded,
        title: "No numerical data",
        subtitle: "The selected columns do not contain numerical data to plot",
      );
    }

    final chartSetups = widget.selectedSetups;

    if (chartSetups.length < 2) {
      return const EmptyStatePlaceholder(
        icon: Icons.insights_rounded,
        title: "Not enough setups",
        subtitle: "Select at least two setups in the table to visualize a trend",
      );
    }

    final lineChartColors = chartColors(Theme.of(context).colorScheme.primary, validColumns.length);

    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 300,
          child: LineChart(
            LineChartData(
              lineBarsData: validColumns.mapIndexed((index, column) {
                final effectiveSelectedColumn = validColumns.contains(widget.selectedLineChartColumn)
                    ? widget.selectedLineChartColumn
                    : null;
                final isSelected = effectiveSelectedColumn == null || effectiveSelectedColumn == column;
                final color = lineChartColors[index];
                return LineChartBarData(
                  spots: chartSetups.asMap().entries.map((entry) {
                    final val = widget.valueFor(entry.value, column);
                    return FlSpot(entry.key.toDouble(), (val as num?)?.toDouble() ?? 0.0);
                  }).toList(),
                  isCurved: false,
                  color: isSelected ? color : color.withValues(alpha: 0.15),
                  barWidth: isSelected ? 3 : 1.5,
                  dotData: FlDotData(show: isSelected),
                  dashArray: _dashPatterns[index % _dashPatterns.length],
                );
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (value != index || (index != 0 && index != chartSetups.length - 1)) {
                        return const SizedBox.shrink();
                      }

                      return SideTitleWidget(
                        meta: meta,
                        child: FractionalTranslation(
                          translation: Offset(index == 0 ? 0.5 : -0.5, 0),
                          child: Text(
                            DateFormat(appSettings.dateFormat).format(chartSetups[index].datetimeLocal),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          value.truncateToDouble() == value ? value.toInt().toString() : value.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5), strokeWidth: 1),
                getDrawingVerticalLine: (value) =>
                    FlLine(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5), strokeWidth: 1),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: Theme.of(context).colorScheme.outline),
                  bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
                  top: BorderSide.none,
                  right: BorderSide.none,
                ),
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                  final spots = response?.lineBarSpots;
                  if (event is FlTapDownEvent && spots != null && spots.isNotEmpty) {
                    unawaited(HapticFeedback.selectionClick());
                  } else if (event is FlPanUpdateEvent && spots != null && spots.isNotEmpty) {
                    final xIndex = spots.first.x.toInt();
                    if (_touchedLineChartSpotX != xIndex) {
                      _touchedLineChartSpotX = xIndex;
                      unawaited(HapticFeedback.selectionClick());
                    }
                  } else if (event is FlPanEndEvent || event is FlTapUpEvent) {
                    _touchedLineChartSpotX = null;
                  }
                },
                getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                  return spotIndexes.map((index) {
                    return TouchedSpotIndicatorData(
                      FlLine(color: barData.color?.withValues(alpha: 0.5), strokeWidth: 2),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 6,
                          color: barData.color ?? Theme.of(context).colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    );
                  }).toList();
                },
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.surfaceContainerHighest,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((barSpot) {
                      final column = validColumns[barSpot.barIndex];
                      final adjustment = widget.adjustmentFor(column);
                      final columnName = widget.columnLabel(column);
                      final unit = adjustment?.unit?.label ?? "";
                      final formattedY = Adjustment.formatValue(barSpot.y);

                      final tooltipStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: barSpot.bar.color ?? Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      );

                      if (barSpot.barIndex == 0) {
                        final setup = chartSetups[barSpot.x.toInt()];
                        final dateStr = DateFormat(appSettings.dateFormat).format(setup.datetimeLocal);
                        return LineTooltipItem(
                          '${setup.displayName}\n',
                          tooltipStyle.copyWith(color: Theme.of(context).colorScheme.onSurface),
                          children: [
                            TextSpan(
                              text: '$dateStr\n',
                              style: tooltipStyle.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.normal,
                                fontSize: 10,
                              ),
                            ),
                            TextSpan(
                              text: '$columnName: $formattedY${unit.isNotEmpty ? " $unit" : ""}',
                              style: tooltipStyle,
                            ),
                          ],
                        );
                      }

                      return LineTooltipItem(
                        '$columnName: $formattedY${unit.isNotEmpty ? " $unit" : ""}',
                        tooltipStyle,
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: validColumns.mapIndexed((index, column) {
              final effectiveSelectedColumn = validColumns.contains(widget.selectedLineChartColumn)
                  ? widget.selectedLineChartColumn
                  : null;
              final isSelected = effectiveSelectedColumn == column;
              final isDimmed = effectiveSelectedColumn != null && !isSelected;
              final color = lineChartColors[index];
              final dashArray = _dashPatterns[index % _dashPatterns.length];
              final columnName = widget.columnLabel(column);

              return InkWell(
                onTap: () {
                  unawaited(HapticFeedback.selectionClick());
                  widget.onSelectedColumnChanged(
                    widget.selectedLineChartColumn == column ? null : column,
                  );
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      Opacity(
                        opacity: isDimmed ? 0.3 : 1.0,
                        child: CustomPaint(
                          size: const Size(24, 12),
                          painter: _DashLinePainter(color: color, dashArray: dashArray),
                        ),
                      ),
                      Flexible(
                        child: Opacity(
                          opacity: isDimmed ? 0.3 : 1.0,
                          child: Text(
                            columnName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? color : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _DashLinePainter extends CustomPainter {
  final Color color;
  final List<int>? dashArray;

  _DashLinePainter({required this.color, this.dashArray});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    if (dashArray == null) {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    } else {
      double currentX = 0;
      int i = 0;
      while (currentX < size.width) {
        final double dashLen = dashArray![i % dashArray!.length].toDouble();
        final double spaceLen = dashArray![(i + 1) % dashArray!.length].toDouble();

        final double endX = (currentX + dashLen).clamp(0, size.width);
        canvas.drawLine(Offset(currentX, size.height / 2), Offset(endX, size.height / 2), paint);

        currentX += dashLen + spaceLen;
        i += 2;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
