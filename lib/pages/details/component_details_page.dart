import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/bike.dart';
import '../../repositories/app_repository.dart';
import '../../models/rating.dart';
import '../../models/setup.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/weather.dart';
import '../../models/app_settings.dart';
import '../../models/component_stats.dart';
import '../../models/task_rule.dart';
import '../../utils/component_actions.dart';
import '../../utils/table_column.dart';
import '../../widgets/chips/bike_and_tags_filter.dart';
import '../../widgets/display_installation_timeline.dart';
import '../../widgets/sheets/column_filter.dart';
import '../../widgets/initial_changed_value_legend.dart';
import '../../widgets/open_tasks_card.dart';
import '../../widgets/component_stats_card.dart';

class ComponentDetailsPage extends StatefulWidget{
  final String componentId;

  const ComponentDetailsPage({super.key, required this.componentId});

  @override
  State<ComponentDetailsPage> createState() => _ComponentDetailsPageState();
}

class _ComponentDetailsPageState extends State<ComponentDetailsPage> {
  bool _sortAscending = true;
  TableColumn? _sortColumn;
  RadarTouchedSpot? _touchedRadarSpot;
  int? _selectedRadarDataSetIndex;
  int? _selectedLineChartColumnIndex;

  static const bool _highlighting = true;

  final Set<TableColumn> _columns = {
    TableColumn(section: TableColumnSection.generalContext, label: "Name", active: true),
    TableColumn(section: TableColumnSection.generalContext, label: "Notes", active: false),
    TableColumn(section: TableColumnSection.generalContext, label: "Tags", active: false),
    TableColumn(section: TableColumnSection.generalContext, label: "Date", active: true),
    TableColumn(section: TableColumnSection.generalContext, label: "Time", active: false),
    TableColumn(section: TableColumnSection.generalContext, label: "Place", active: false),
    TableColumn(section: TableColumnSection.generalContext, label: "Altitude", active: false),
    TableColumn(section: TableColumnSection.generalContext, label: "Bike", active: false),

    TableColumn(section: TableColumnSection.weatherContext, label: "Weather Code", active: false),
    TableColumn(section: TableColumnSection.weatherContext, label: "Temperature", active: false),
    TableColumn(section: TableColumnSection.weatherContext, label: "Precipitation", active: false),
    TableColumn(section: TableColumnSection.weatherContext, label: "Humidity", active: false),
    TableColumn(section: TableColumnSection.weatherContext, label: "Windspeed", active: false),
    TableColumn(section: TableColumnSection.weatherContext, label: "Soil Moisture", active: false),
    TableColumn(section: TableColumnSection.weatherContext, label: "Condition", active: false),
  };

  List<Setup> sortSetupsByColumn({
    required List<Setup> setups,
    required Iterable<Adjustment> componentAdjustments,
    required Iterable<Adjustment> personAdjustments,
    required Iterable<Adjustment> ratingAdjustments,
    required Map<String, Bike> bikes,
  }) {
    if (_sortColumn == null) return setups;

    switch (_sortColumn!.section) {
      case TableColumnSection.generalContext || TableColumnSection.weatherContext:
        switch (_sortColumn!.label) {
          case "Name": _sortAscending 
            ? setups.sort((a, b) => a.name.compareTo(b.name)) 
            : setups.sort((a, b) => b.name.compareTo(a.name));
          case "Notes": _sortAscending 
              ? setups.sort((a, b) => (a.notes ?? '').compareTo(b.notes ?? '')) 
              : setups.sort((a, b) => (b.notes ?? '').compareTo(a.notes ?? ''));
          case "Tags": _sortAscending 
              ? setups.sort((a, b) => (a.tags.join('; ')).compareTo(b.tags.join('; '))) 
              : setups.sort((a, b) => (b.tags.join('; ')).compareTo(a.tags.join('; ')));
          case "Date": _sortAscending 
              ? setups.sort((a, b) => a.datetime.compareTo(b.datetime)) 
              : setups.sort((a, b) => b.datetime.compareTo(a.datetime));
          case "Time": _sortAscending 
              ? setups.sort((a, b) => a.datetime.copyWith(year: 0, month: 0, day: 0).compareTo(b.datetime.copyWith(year: 0, month: 0, day: 0))) 
              : setups.sort((a, b) => b.datetime.copyWith(year: 0, month: 0, day: 0).compareTo(a.datetime.copyWith(year: 0, month: 0, day: 0)));
          case "Place": _sortAscending 
              ? setups.sort((a, b) => (a.place?.locality ?? '').compareTo(b.place?.locality ?? '')) 
              : setups.sort((a, b) => (b.place?.locality ?? '').compareTo(a.place?.locality ?? ''));
          case "Altitude": _sortAscending 
              ? setups.sort((a, b) => (a.position?.altitude ?? double.negativeInfinity).compareTo(b.position?.altitude ?? double.negativeInfinity)) 
              : setups.sort((a, b) => (b.position?.altitude ?? double.negativeInfinity).compareTo(a.position?.altitude ?? double.negativeInfinity));
          case "Bike": _sortAscending 
            ? setups.sort((a, b) => (bikes[a.bike]?.name ?? '').compareTo(bikes[b.bike]?.name ?? '')) 
            : setups.sort((a, b) => (bikes[b.bike]?.name ?? '').compareTo(bikes[a.bike]?.name ?? ''));
          case "Weather Code": _sortAscending 
              ? setups.sort((a, b) => (a.weather?.getWeatherCodeLabel() ?? '').compareTo(b.weather?.getWeatherCodeLabel() ?? '')) 
              : setups.sort((a, b) => (b.weather?.getWeatherCodeLabel() ?? '').compareTo(a.weather?.getWeatherCodeLabel() ?? ''));
          case "Temperature": _sortAscending 
              ? setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) 
              : setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));
          case "Precipitation": _sortAscending 
              ? setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) 
              : setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));
          case "Humidity": _sortAscending 
              ? setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) 
              : setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));
          case "Windspeed": _sortAscending 
              ? setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) 
              : setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));
          case "Soil Moisture": _sortAscending 
              ? setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) 
              : setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));
          case "Condition": _sortAscending 
              ? setups.sort((a, b) => (a.weather?.condition?.value ?? '').compareTo(b.weather?.condition?.value ?? '')) 
              : setups.sort((a, b) => (b.weather?.condition?.value ?? '').compareTo(a.weather?.condition?.value ?? ''));
        }
      case TableColumnSection.componentAdjustments || TableColumnSection.personAttributes || TableColumnSection.ratingMetrics:
        final column2value = switch (_sortColumn!.section) {
          TableColumnSection.componentAdjustments => (Setup s) => s.bikeAdjustmentValues[_sortColumn!.label],
          TableColumnSection.personAttributes => (Setup s) => s.personAdjustmentValues[_sortColumn!.label],
          TableColumnSection.ratingMetrics => (Setup s) => s.ratingAdjustmentValues[_sortColumn!.label],
          _ => null, 
        };
        if (column2value == null) return setups;

        final Adjustment? adjustment = switch (_sortColumn!.section) {
          TableColumnSection.componentAdjustments => componentAdjustments.firstWhereOrNull((a) => a.id == _sortColumn!.label),
          TableColumnSection.personAttributes => personAdjustments.firstWhereOrNull((a) => a.id == _sortColumn!.label),
          TableColumnSection.ratingMetrics => ratingAdjustments.firstWhereOrNull((a) => a.id == _sortColumn!.label),
          _ => null,
        };
        if (adjustment == null) return setups;

        switch (adjustment) {
          case BooleanAdjustment(): _sortAscending 
              ? setups.sort((a, b) => ((column2value(a) ?? false) ? 1 : 0).compareTo((column2value(b) ?? false) ? 1 : 0)) 
              : setups.sort((a, b) => ((column2value(b) ?? false) ? 1 : 0).compareTo((column2value(a) ?? false) ? 1 : 0));
          case StepAdjustment(): _sortAscending 
              ? setups.sort((a, b) => ((column2value(a) ?? 0) as int).compareTo((column2value(b) ?? 0) as int)) 
              : setups.sort((a, b) => ((column2value(b) ?? 0) as int).compareTo((column2value(a) ?? 0) as int));
          case NumericalAdjustment(): _sortAscending 
              ? setups.sort((a, b) => ((column2value(a) ?? double.negativeInfinity) as double).compareTo((column2value(b) ?? double.negativeInfinity) as double)) 
              : setups.sort((a, b) => ((column2value(b) ?? double.negativeInfinity) as double).compareTo((column2value(a) ?? double.negativeInfinity) as double));
          case CategoricalAdjustment(): _sortAscending 
              ? setups.sort((a, b) => ((column2value(a) ?? '') as String).compareTo((column2value(b) ?? '') as String)) 
              : setups.sort((a, b) => ((column2value(b) ?? '') as String).compareTo((column2value(a) ?? '') as String));
          case TextAdjustment(): _sortAscending 
              ? setups.sort((a, b) => ((column2value(a) ?? '') as String).compareTo((column2value(b) ?? '') as String)) 
              : setups.sort((a, b) => ((column2value(b) ?? '') as String).compareTo((column2value(a) ?? '') as String));
          case DurationAdjustment(): _sortAscending 
              ? setups.sort((a, b) => ((column2value(a) ?? Duration.zero) as Duration).compareTo((column2value(b) ?? Duration.zero) as Duration)) 
              : setups.sort((a, b) => ((column2value(b) ?? Duration.zero) as Duration).compareTo((column2value(a) ?? Duration.zero) as Duration));
        }
    }
    return setups;
  }

  Widget _emptyStatePlaceholder({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noColumnsPlaceholder() {
    return _emptyStatePlaceholder(
      icon: Icons.view_column_outlined,
      message: 'Select a column to display the table',
    );
  }

  Widget _noSetupsPlaceholder({required bool hasAdjustments}) {
    return _emptyStatePlaceholder(
      icon: Icons.history_rounded,
      message: hasAdjustments
          ? 'No setups yet'
          : 'No adjustments defined for this component',
    );
  }

  Widget _chartPlaceholder({required String message}) {
    return _emptyStatePlaceholder(
      icon: Icons.insights_rounded,
      message: message,
    );
  }

  List<Widget> _buildChartSection({
    required BuildContext context,
    required AppSettings appSettings,
    required List<TableColumn> activeColumns,
    required List<Setup> setups,
    required Iterable<Adjustment> componentAdjustments,
    required Iterable<Adjustment> personAdjustments,
    required Iterable<Adjustment> ratingAdjustments,
  }) {
    if (!appSettings.enableCharts) return [];

    final activeChartColumns = activeColumns.where((column) {
      Adjustment? adjustment = switch (column.section) {
        TableColumnSection.componentAdjustments => componentAdjustments.firstWhereOrNull((a) => a.id == column.label),
        TableColumnSection.ratingMetrics => ratingAdjustments.firstWhereOrNull((a) => a.id == column.label),
        TableColumnSection.personAttributes => personAdjustments.firstWhereOrNull((a) => a.id == column.label),
        _ => null,
      };
      return adjustment is StepAdjustment || adjustment is NumericalAdjustment;
    }).toList();

    return [
      const SizedBox(height: 32),
      Builder(
        builder: (context) {
          if (activeChartColumns.isEmpty) {
            return _chartPlaceholder(message: "Select numerical or step adjustment columns to visualize trends");
          }
          if (setups.isEmpty) {
            return _chartPlaceholder(message: "No setup data available for this component");
          }

          final validColumns = activeChartColumns.where((column) {
            return setups.any((setup) {
              final rawValue = switch (column.section) {
                TableColumnSection.componentAdjustments => setup.bikeAdjustmentValues[column.label],
                TableColumnSection.ratingMetrics => setup.ratingAdjustmentValues[column.label],
                TableColumnSection.personAttributes => setup.personAdjustmentValues[column.label],
                _ => null,
              };
              return rawValue is num;
            });
          }).toList();

          if (validColumns.isEmpty) {
            return _chartPlaceholder(message: "The selected columns do not contain numerical data to plot");
          }

          final chartSetups = setups.toList()..sort((a, b) => a.datetime.compareTo(b.datetime));

          if (chartSetups.length < 2) {
            return _chartPlaceholder(message: "At least two setups are required to visualize a trend chart");
          }

          final primaryHSL = HSLColor.fromColor(Theme.of(context).colorScheme.primary);

          return Column(
            children: [
              SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    lineBarsData: validColumns.mapIndexed((index, column) {
                      final isSelected = _selectedLineChartColumnIndex == null || _selectedLineChartColumnIndex == index;
                      final color = primaryHSL.withHue((primaryHSL.hue + (index * 45)) % 360).toColor();
                      final dashPatterns = [
                        null,           // Solid
                        [6, 3],         // Dashed
                        [2, 2],         // Dotted
                        [10, 4, 2, 4],  // Dash-Dot
                      ];
                      return LineChartBarData(
                        spots: chartSetups.asMap().entries.map((entry) {
                          final setup = entry.value;
                          final val = switch (column.section) {
                            TableColumnSection.componentAdjustments => setup.bikeAdjustmentValues[column.label],
                            TableColumnSection.ratingMetrics => setup.ratingAdjustmentValues[column.label],
                            TableColumnSection.personAttributes => setup.personAdjustmentValues[column.label],
                            _ => null,
                          };
                          return FlSpot(entry.key.toDouble(), (val as num?)?.toDouble() ?? 0.0);
                        }).toList(),
                        isCurved: false,
                        color: isSelected ? color : color.withValues(alpha: 0.15),
                        barWidth: isSelected ? 3 : 1.5,
                        dotData: FlDotData(show: isSelected),
                        dashArray: dashPatterns[index % dashPatterns.length],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                      getDrawingHorizontalLine: (value) => FlLine(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5), strokeWidth: 1),
                      getDrawingVerticalLine: (value) => FlLine(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5), strokeWidth: 1),
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
                            final adjustment = switch (column.section) {
                              TableColumnSection.componentAdjustments => componentAdjustments.firstWhereOrNull((a) => a.id == column.label),
                              TableColumnSection.ratingMetrics => ratingAdjustments.firstWhereOrNull((a) => a.id == column.label),
                              TableColumnSection.personAttributes => personAdjustments.firstWhereOrNull((a) => a.id == column.label),
                              _ => null,
                            };
                            final columnName = adjustment?.name ?? column.label;
                            final unit = adjustment?.unit ?? "";
                            final formattedY = Adjustment.formatValue(barSpot.y);
                            
                            final tooltipStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: barSpot.bar.color ?? Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            );

                            if (barSpot.barIndex == 0) {
                              final setup = chartSetups[barSpot.x.toInt()];
                              final dateStr = DateFormat(appSettings.dateFormat).format(setup.datetimeLocal);
                              return LineTooltipItem(
                                '${setup.name}\n',
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
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: validColumns.mapIndexed((index, column) {
                  final isSelected = _selectedLineChartColumnIndex == index;
                  final isDimmed = _selectedLineChartColumnIndex != null && !isSelected;
                  final color = primaryHSL.withHue((primaryHSL.hue + (index * 45)) % 360).toColor();
                  final dashPatterns = [
                    null,           // Solid
                    [6, 3],         // Dashed
                    [2, 2],         // Dotted
                    [10, 4, 2, 4],  // Dash-Dot
                  ];
                  final dashArray = dashPatterns[index % dashPatterns.length];

                  final adjustment = switch (column.section) {
                    TableColumnSection.componentAdjustments => componentAdjustments.firstWhereOrNull((a) => a.id == column.label),
                    TableColumnSection.ratingMetrics => ratingAdjustments.firstWhereOrNull((a) => a.id == column.label),
                    TableColumnSection.personAttributes => personAdjustments.firstWhereOrNull((a) => a.id == column.label),
                    _ => null,
                  };
                  final columnName = adjustment?.name ?? column.label;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedLineChartColumnIndex == index) {
                          _selectedLineChartColumnIndex = null;
                        } else {
                          _selectedLineChartColumnIndex = index;
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(
                            opacity: isDimmed ? 0.3 : 1.0,
                            child: CustomPaint(
                              size: const Size(24, 12),
                              painter: _DashLinePainter(color: color, dashArray: dashArray),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Opacity(
                            opacity: isDimmed ? 0.3 : 1.0,
                            child: Text(
                              columnName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? color : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              if (validColumns.length < 3)
                _chartPlaceholder(message: "At least 3 numerical columns are required to generate a radar chart")
              else
                Builder(
                  builder: (context) {
                    final radarSetups = chartSetups.reversed.take(5).toList();
                    final featureDefs = validColumns.map((column) {
                      final adjustment = switch (column.section) {
                        TableColumnSection.componentAdjustments => componentAdjustments.firstWhereOrNull((a) => a.id == column.label),
                        TableColumnSection.ratingMetrics => ratingAdjustments.firstWhereOrNull((a) => a.id == column.label),
                        TableColumnSection.personAttributes => personAdjustments.firstWhereOrNull((a) => a.id == column.label),
                        _ => null,
                      };

                      double dataMin = double.infinity;
                      double dataMax = double.negativeInfinity;
                      for (var setup in chartSetups) {
                        final rawValue = switch (column.section) {
                          TableColumnSection.componentAdjustments => setup.bikeAdjustmentValues[column.label],
                          TableColumnSection.ratingMetrics => setup.ratingAdjustmentValues[column.label],
                          TableColumnSection.personAttributes => setup.personAdjustmentValues[column.label],
                          _ => null,
                        };
                        if (rawValue is num) {
                          if (rawValue < dataMin) dataMin = rawValue.toDouble();
                          if (rawValue > dataMax) dataMax = rawValue.toDouble();
                        }
                      }

                      if (dataMin == double.infinity) dataMin = 0.0;
                      if (dataMax == double.negativeInfinity) dataMax = 1.0;
                      
                      // Add a small buffer to keep points off the extreme edges
                      if (dataMin == dataMax) {
                        dataMin -= 1;
                        dataMax += 1;
                      } else {
                        final range = dataMax - dataMin;
                        dataMin -= range * 0.05;
                        dataMax += range * 0.05;
                      }

                      return (
                        column: column,
                        name: adjustment?.name ?? column.label,
                        unit: adjustment?.unit ?? "",
                        min: dataMin,
                        max: dataMax,
                      );
                    }).toList();

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Tooltip(
                                  message: "Only the 5 latest setups of the currently selected setups are shown here. You can tap on legend entries to highlight specific graphs.",
                                  triggerMode: TooltipTriggerMode.tap,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.symmetric(horizontal: 24),
                                  showDuration: const Duration(seconds: 5),
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                            Stack(
                              children: [
                                SizedBox(
                                  height: 350,
                                  child: RadarChart(
                                    RadarChartData(
                                      radarShape: RadarShape.polygon,
                                      tickCount: 5,
                                      ticksTextStyle: const TextStyle(color: Colors.transparent),
                                      gridBorderData: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1),
                                      radarBorderData: const BorderSide(color: Colors.transparent),
                                      tickBorderData: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3), width: 1),
                                      titleTextStyle: Theme.of(context).textTheme.bodySmall,
                                      getTitle: (index, angle) {
                                        final name = featureDefs[index].name;
                                        final displayedName = name.length > 15 ? "${name.substring(0, 12)}..." : name;
                                        return RadarChartTitle(
                                          text: displayedName,
                                          angle: 0,
                                        );
                                      },
                                      radarTouchData: RadarTouchData(
                                        touchCallback: (event, response) {
                                          if (event.isInterestedForInteractions && response?.touchedSpot != null) {
                                            setState(() {
                                              _touchedRadarSpot = response?.touchedSpot;
                                            });
                                          } else if (event is FlPointerExitEvent || event is FlTapUpEvent || event is FlPanEndEvent) {
                                            setState(() {
                                              _touchedRadarSpot = null;
                                            });
                                          }
                                        },
                                      ),
                                      dataSets: radarSetups.mapIndexed((index, setup) {
                                        final isSelected = _selectedRadarDataSetIndex == null || _selectedRadarDataSetIndex == index;
                                        final color = primaryHSL.withHue((primaryHSL.hue + (index * 60)) % 360).toColor();

                                        final entries = featureDefs.map((def) {
                                          final rawValue = switch (def.column.section) {
                                            TableColumnSection.componentAdjustments => setup.bikeAdjustmentValues[def.column.label],
                                            TableColumnSection.ratingMetrics => setup.ratingAdjustmentValues[def.column.label],
                                            TableColumnSection.personAttributes => setup.personAdjustmentValues[def.column.label],
                                            _ => null,
                                          };

                                          double normalized = 0.0;
                                          if (rawValue is num) {
                                            final v = rawValue.toDouble();
                                            if (def.max > def.min) {
                                              normalized = ((v - def.min) / (def.max - def.min)) * 100;
                                            }
                                          }
                                          return RadarEntry(value: normalized.clamp(0.0, 100.0));
                                        }).toList();

                                        return RadarDataSet(
                                          dataEntries: entries,
                                          fillColor: isSelected ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.05),
                                          borderColor: isSelected ? color : color.withValues(alpha: 0.25),
                                          entryRadius: isSelected ? 3 : 2,
                                          borderWidth: isSelected ? 2 : 1.5,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                if (_touchedRadarSpot != null)
                                  Positioned(
                                    left: _touchedRadarSpot!.offset.dx > constraints.maxWidth / 2 ? null : _touchedRadarSpot!.offset.dx,
                                    right: _touchedRadarSpot!.offset.dx > constraints.maxWidth / 2 ? constraints.maxWidth - _touchedRadarSpot!.offset.dx : null,
                                    top: _touchedRadarSpot!.offset.dy,
                                    child: Material(
                                      elevation: 4,
                                      borderRadius: BorderRadius.circular(8),
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Builder(builder: (context) {
                                          final setup = radarSetups[_touchedRadarSpot!.touchedDataSetIndex];
                                          final def = featureDefs[_touchedRadarSpot!.touchedRadarEntryIndex];
                                          final rawValue = switch (def.column.section) {
                                            TableColumnSection.componentAdjustments => setup.bikeAdjustmentValues[def.column.label],
                                            TableColumnSection.ratingMetrics => setup.ratingAdjustmentValues[def.column.label],
                                            TableColumnSection.personAttributes => setup.personAdjustmentValues[def.column.label],
                                            _ => null,
                                          };
                                          final formattedVal = Adjustment.formatValue(rawValue);
                                          final dateStr = DateFormat(appSettings.dateFormat).format(setup.datetimeLocal);

                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                setup.name,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                dateStr,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  fontSize: 10,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "${def.name}: $formattedVal${def.unit.isNotEmpty ? " ${def.unit}" : ""}",
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          );
                                        }),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: radarSetups.mapIndexed((index, setup) {
                                final isSelected = _selectedRadarDataSetIndex == index;
                                final isDimmed = _selectedRadarDataSetIndex != null && !isSelected;
                                final color = primaryHSL.withHue((primaryHSL.hue + (index * 60)) % 360).toColor();
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (_selectedRadarDataSetIndex == index) {
                                        _selectedRadarDataSetIndex = null;
                                      } else {
                                        _selectedRadarDataSetIndex = index;
                                      }
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Opacity(
                                          opacity: isDimmed ? 0.3 : 1.0,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Opacity(
                                          opacity: isDimmed ? 0.3 : 1.0,
                                          child: Text(
                                            setup.name,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? color : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();

    final component = appRepository.components[widget.componentId];
    if (component == null) return const SizedBox.shrink();
    final componentAdjustments = component.adjustments;

    final ratings = appRepository.ratings;
    final bikes = appRepository.bikes;
    final bike = bikes[component.bike];
    
    final persons = appRepository.persons;
    final person = persons[bike?.person];
    final personAdjustments = person?.adjustments ?? [];

    final ratingAdjustments = ratings.values.expand((rating) => rating.adjustments);

    final List<Rating> validRatings = ratings.values.where((rating) {
      if (!appSettings.enableRating) return false;
      return switch (rating.filterType) {
        FilterType.global => true,
        FilterType.componentType => component.componentType.toString() == rating.filter,
        FilterType.component => component.id == rating.filter,
        FilterType.bike => component.bike == rating.filter,
        FilterType.person => bike?.person == rating.filter,
      };
    }).toList();

    // Remove only invalid columns (to keep prior modifications to 'active')
    for (final column in _columns.toSet()) {
      switch (column.section) {
        case TableColumnSection.generalContext:
          if (column.label == "Tags" && !appSettings.enableSetupTags) _columns.remove(column);
        case TableColumnSection.componentAdjustments:
          if (!componentAdjustments.any((a) => a.id == column.label)) _columns.remove(column);
        case TableColumnSection.personAttributes:
          if (!appSettings.enablePerson || person == null) {
            _columns.remove(column);
            continue;
          } else if (!personAdjustments.any((pa) => pa.id == column.label)) {
            _columns.remove(column);
            continue;
          }          
        case TableColumnSection.ratingMetrics:
          if (!validRatings.any((r) => r.adjustments.any((a) => a.id == column.label))) {
            _columns.remove(column);
          }
        case TableColumnSection.weatherContext: continue; 
      }
    }

    // Add missing columns
    if (appSettings.enableSetupTags) {
      _columns.add(TableColumn(section: TableColumnSection.generalContext, label: "Tags", active: false));
    }

    for (final adjustment in component.adjustments) {
      _columns.add(TableColumn(section: TableColumnSection.componentAdjustments, label: adjustment.id, active: true));
    }
    if (appSettings.enablePerson) {
      _columns.addAll(personAdjustments.map((a) => TableColumn(section: TableColumnSection.personAttributes, label: a.id, active: false)));
    }
    for (final rating in validRatings) {
      _columns.addAll(rating.adjustments.map((a) => TableColumn(section: TableColumnSection.ratingMetrics, label: a.id, active: false)));
    }

    final sortedColumns = _columns.sorted((a, b) => a.section.index.compareTo(b.section.index));  // sort by enum index
    final activeColumns = sortedColumns.where((c) => c.active).toList();
    if (!activeColumns.contains(_sortColumn)) _sortColumn = null;

    final setupsUnsorted = appRepository.filteredSetups.values.where(
        (s) => component.adjustments.any((adj) => s.bikeAdjustmentValues.containsKey(adj.id))
    ).toList().reversed.toList();

    final setups = sortSetupsByColumn(
      setups: setupsUnsorted,
      componentAdjustments: componentAdjustments,
      personAdjustments: personAdjustments,
      ratingAdjustments: ratingAdjustments,
      bikes: bikes,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          spacing: 8,
          children: [
            Icon(component.componentType.getIconData()),
            Expanded(
              child: Text(component.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ComponentActions.editComponent(context, component: component),
            icon: const Icon(Icons.edit),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (appSettings.enableStrava && appSettings.enableInstallationTimeline)
                ComponentStatsCard(componentStats: ComponentStats(
                  distance: component.totalDistance,
                  elevationGain: component.totalElevationGain,
                  movingTime: component.totalMovingTime,
                  elapsedTime: component.totalElapsedTime,
                  activityCount: component.totalActivityCount,
                )),
              if (component.notes != null)
                Card.outlined(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.notes),
                    titleAlignment: ListTileTitleAlignment.top,
                    title: SelectableText(component.notes!),
                    dense: true,
                  ),
                ),
              if (appSettings.enableInstallationTimeline)
                Card.outlined(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    title: const Text("Installation History"),
                    leading: const Icon(Icons.history),
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      DisplayInstallationTimeline(component: component),
                    ],
                  ),
                ),
              if (appSettings.enableTask) () {
                final openTasks = appRepository.taskRules.values.where((rule) {
                  if (rule.componentId != widget.componentId) return false;
                  final status = appRepository.getTaskRuleStatus(rule);
                  return status.type != TaskStatusType.completed;
                }).map((rule) => TaskRuleWithStatus(rule: rule, status: appRepository.getTaskRuleStatus(rule))).toList();

                openTasks.sort((a, b) {
                  if (a.status.type != b.status.type) {
                    return b.status.type.index.compareTo(a.status.type.index);
                  }
                  return b.status.progress.compareTo(a.status.progress);
                });

                return OpenTasksCard(openTasks: openTasks, repository: appRepository);
              }(),
              
              const SizedBox(height: 16),
              Text("Adjustment History".toUpperCase(), style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, 
                letterSpacing: 1.2, 
                color: Theme.of(context).colorScheme.primary
              )),
              const SizedBox(height: 8),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 6,
                  children: [
                    FilterChip(
                      avatar: const Icon(Icons.view_column_outlined),
                      showCheckmark: false,
                      label: const Text("Columns"),
                      selected: _columns.any((c) => c.active),
                      onSelected: (bool newValue) async {
                        await showColumnFilterSheet(
                          context: context, 
                          sortedColumns: sortedColumns, 
                          componentAdjustments: componentAdjustments,
                          ratingAdjustments: ratingAdjustments,
                          personAdjustments: personAdjustments,
                          onColumnStatusChanged: () => setState(() {}), // TableColumn.active is changed
                        );
                      },
                    ),
                    BikeAndTagsFilterChip(enableSetupTagFilter: appSettings.enableSetupTags),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (activeColumns.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    sortAscending: _sortAscending,
                    sortColumnIndex: activeColumns.contains(_sortColumn) 
                        ? activeColumns.indexOf(_sortColumn!)
                        : null,
                    columnSpacing: 20,
                    headingTextStyle: TextStyle(fontWeight: FontWeight.bold),
                    dataRowMaxHeight: double.infinity,
                    columns: activeColumns.map((column) {
                      switch (column.section) {
                        case TableColumnSection.generalContext || TableColumnSection.weatherContext:
                          return DataColumn(
                            label: Text(column.label, overflow: TextOverflow.ellipsis),
                            onSort: (int _, bool ascending) {
                              setState(() {
                                _sortAscending = ascending;
                                _sortColumn = column;
                              });
                            },
                          );
                        case TableColumnSection.componentAdjustments || TableColumnSection.personAttributes || TableColumnSection.ratingMetrics:
                          final Adjustment? adjustment = switch (column.section) {
                            TableColumnSection.componentAdjustments => componentAdjustments.firstWhereOrNull((a) => a.id == column.label),
                            TableColumnSection.ratingMetrics => ratingAdjustments.firstWhereOrNull((a) => a.id == column.label),
                            TableColumnSection.personAttributes => personAdjustments.firstWhereOrNull((a) => a.id == column.label),
                            _ => null,
                          };
                          return DataColumn(
                            label: Text(
                              (adjustment?.name ?? "-") + (adjustment?.unit != null ? " [${adjustment!.unit}]" : ""),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onSort: (int _, bool ascending) {
                              setState(() {
                                _sortAscending = ascending;
                                _sortColumn = column;
                              });
                            },
                          );
                      }
                    }).toList(),
                    rows: setups.map((setup) {
                      return DataRow(
                        cells: activeColumns.map((column) {
                          switch (column.section) {
                            case TableColumnSection.generalContext:
                              return switch (column.label) {
                                "Name" => DataCell(ConstrainedBox(constraints: BoxConstraints(maxWidth: 150), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(setup.name, overflow: TextOverflow.ellipsis)))),
                                "Notes" => DataCell(ConstrainedBox(constraints: BoxConstraints(maxWidth: 300), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(setup.notes ?? '-', overflow: TextOverflow.ellipsis)))),
                                "Tags" => DataCell(ConstrainedBox(constraints: BoxConstraints(maxWidth: 300), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(setup.tags.isEmpty ? '-' : setup.tags.join('; '), overflow: TextOverflow.ellipsis)))),
                                "Date" => DataCell(Text(DateFormat(appSettings.dateFormat).format(setup.datetimeLocal))),
                                "Time" => DataCell(Text(DateFormat(appSettings.timeFormat).format(setup.datetimeLocal))),
                                "Place" => DataCell(ConstrainedBox(constraints: BoxConstraints(maxWidth: 150), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(setup.place?.locality ?? '-', overflow: TextOverflow.ellipsis)))),
                                "Altitude" => DataCell(Center(child: Text(setup.position?.altitude == null ? '-' : "${setup.position!.altitude!.round()} ${appSettings.altitudeUnit}"))),
                                "Bike" => DataCell(ConstrainedBox(constraints: BoxConstraints(maxWidth: 150), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(bikes[setup.bike]?.name ?? '-', overflow: TextOverflow.ellipsis)))),
                                _ => const DataCell(Text("ERROR")),
                              };
                            case TableColumnSection.weatherContext:
                              return switch (column.label) {
                                "Weather Code" => DataCell(Center(child: Text(setup.weather?.getWeatherCodeLabel() ?? "-"))),
                                "Temperature" => DataCell(Center(child: Text(setup.weather?.currentTemperature == null ? '-' : "${Weather.convertTemperatureFromCelsius(setup.weather!.currentTemperature!, appSettings.temperatureUnit)?.round()} ${appSettings.temperatureUnit}"))),
                                "Precipitation" => DataCell(Center(child: Text(setup.weather?.dayAccumulatedPrecipitation == null ? '-' : "${Weather.convertPrecipitationFromMm(setup.weather!.dayAccumulatedPrecipitation!, appSettings.precipitationUnit)?.round()} ${appSettings.precipitationUnit}"))),
                                "Humidity" => DataCell(Center(child: Text(setup.weather?.currentHumidity == null ? '-' : "${setup.weather!.currentHumidity!.round()} %"))),
                                "Windspeed" => DataCell(Center(child: Text(setup.weather?.currentWindSpeed == null ? '-' : "${Weather.convertWindSpeedFromKmh(setup.weather!.currentWindSpeed!, appSettings.windSpeedUnit)?.round()} ${appSettings.windSpeedUnit}"))),
                                "Soil Moisture" => DataCell(Center(child: Text(setup.weather?.currentSoilMoisture0to7cm == null ? '-' : setup.weather!.currentSoilMoisture0to7cm!.toStringAsFixed(2)))),
                                "Condition" => DataCell(Center(child: Text(setup.weather?.condition == null ? '-' : setup.weather!.condition!.value))),
                                _ => const DataCell(Text("ERROR")),
                              };
                            case TableColumnSection.componentAdjustments || TableColumnSection.personAttributes || TableColumnSection.ratingMetrics:
                              final value = switch (column.section) {
                                TableColumnSection.componentAdjustments => setup.bikeAdjustmentValues[column.label],
                                TableColumnSection.ratingMetrics => setup.ratingAdjustmentValues[column.label],
                                TableColumnSection.personAttributes => setup.personAdjustmentValues[column.label],
                                _ => null,
                              };
                              final initialValue = switch (column.section) {
                                TableColumnSection.componentAdjustments => setup.previousBikeAdjustmentValues[column.label],
                                TableColumnSection.ratingMetrics => setup.previousRatingAdjustmentValues[column.label],
                                TableColumnSection.personAttributes => setup.previousPersonAdjustmentValues[column.label],
                                _ => null,
                              };
             
                              Color? highlightColor;
                              if (_highlighting) {
                                final bool isChanged = value != null && initialValue != value;
                                final bool isInitial = initialValue == null;
                                highlightColor = isChanged ? (isInitial ? Colors.green : Colors.orange) : null;
                              }
        
                              return DataCell(
                                Center(
                                  child: Text(
                                    Adjustment.formatValue(value), 
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: highlightColor, fontWeight: highlightColor != null ? FontWeight.bold : null),
                                  ),
                                ),
                              );
                          }
                        }).toList(),
                      );
                    }).toList(),
                  ),
                )
              else
                _noColumnsPlaceholder(),
              if (setups.isEmpty)
                _noSetupsPlaceholder(hasAdjustments: component.adjustments.isNotEmpty),
              if (activeColumns.isNotEmpty && setups.isNotEmpty)
                const InitialChangedValueLegend(),
              ..._buildChartSection(
                context: context,
                appSettings: appSettings,
                activeColumns: activeColumns,
                setups: setups,
                componentAdjustments: componentAdjustments,
                personAdjustments: personAdjustments,
                ratingAdjustments: ratingAdjustments,
              ),
            ],
          ),
        ),
      ),
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
        double dashLen = dashArray![i % dashArray!.length].toDouble();
        double spaceLen = dashArray![(i + 1) % dashArray!.length].toDouble();
        
        double endX = (currentX + dashLen).clamp(0, size.width);
        canvas.drawLine(Offset(currentX, size.height / 2), Offset(endX, size.height / 2), paint);
        
        currentX += dashLen + spaceLen;
        i += 2;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
