import 'dart:async';
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/component_stats.dart';
import '../../models/context/context_weather.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../theme.dart';
import '../../utils/component_actions.dart';
import '../../utils/table_column.dart';
import '../../widgets/chips/filter_sheet_chip.dart';
import '../../widgets/component_stats_card.dart';
import '../../widgets/display_installation_timeline.dart';
import '../../widgets/initial_changed_value_legend.dart';
import '../../widgets/notes_text.dart';
import '../../widgets/open_tasks_tile.dart';
import '../../widgets/sheets/column_filter.dart';
import '../../widgets/text/section_title.dart';

class ComponentDetailsPage extends StatefulWidget{
  final String componentId;

  const ComponentDetailsPage({super.key, required this.componentId});

  @override
  State<ComponentDetailsPage> createState() => _ComponentDetailsPageState();
}

class _ComponentDetailsPageState extends State<ComponentDetailsPage> {
  bool _sortAscending = true;
  TableColumn? _sortColumn;
  Offset? _touchedRadarOffset;
  String? _touchedRadarSetupId;
  TableColumn? _touchedRadarColumn;
  String? _selectedRadarSetupId;
  TableColumn? _selectedLineChartColumn;
  Set<String>? _selectedSetupIds;
  int? _touchedLineChartSpotX;

  static const bool _highlighting = true;

  static const List<List<int>?> _dashPatterns = [
    null,
    [6, 3],
    [2, 2],
    [10, 4, 2, 4],
  ];

  Map<String, double?> _ratingScores = {};
  Map<String, Map<String, double>> _metricScores = {};
  // ratingMetricId → display name, for the per-metric rating columns.
  Map<String, String> _ratingMetricNames = {};

  /// True for the synthetic rating columns whose value is a 0–10 score
  /// ([TableColumnSection.ratingScore] = the setup score, [ratingMetrics] = a
  /// single metric's pooled sub-score) rather than a raw adjustment value.
  static bool _isScoreColumn(TableColumn column) =>
      column.section == TableColumnSection.ratingScore ||
      column.section == TableColumnSection.ratingMetrics;

  dynamic _rawValue(Setup setup, TableColumn column) => switch (column.section) {
    TableColumnSection.componentAdjustments => setup.bikeAdjustmentValues[column.label],
    TableColumnSection.ratingMetrics => _metricScores[setup.id]?[column.label],
    TableColumnSection.ratingScore => _ratingScores[setup.id],
    TableColumnSection.personAttributes => setup.personAdjustmentValues[column.label],
    _ => null,
  };

  static Adjustment? _findAdjustment(
    TableColumn column,
    Iterable<Adjustment> componentAdjustments,
    Iterable<Adjustment> personAdjustments,
  ) => switch (column.section) {
    TableColumnSection.componentAdjustments => componentAdjustments.firstWhereOrNull((a) => a.id == column.label),
    TableColumnSection.personAttributes => personAdjustments.firstWhereOrNull((a) => a.id == column.label),
    _ => null,
  };

  String _columnLabel(TableColumn column, Iterable<Adjustment> componentAdjustments, Iterable<Adjustment> personAdjustments) {
    return switch (column.section) {
      TableColumnSection.generalContext || 
      TableColumnSection.weatherContext || 
      TableColumnSection.ratingScore => column.label,
      TableColumnSection.ratingMetrics => _ratingMetricNames[column.label] ?? column.label,
      TableColumnSection.componentAdjustments => componentAdjustments.firstWhereOrNull((a) => a.id == column.label)?.name ?? column.label,
      TableColumnSection.personAttributes => personAdjustments.firstWhereOrNull((a) => a.id == column.label)?.name ?? column.label,

    };
  }

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
    required Map<String, Bike> bikes,
  }) {
    if (_sortColumn == null) return setups;

    switch (_sortColumn!.section) {
      case TableColumnSection.generalContext || TableColumnSection.weatherContext:
        switch (_sortColumn!.label) {
          case "Name": _sortAscending
            ? setups.sort((a, b) => a.displayName.compareTo(b.displayName))
            : setups.sort((a, b) => b.displayName.compareTo(a.displayName));
          case "Notes": _sortAscending 
              ? setups.sort((a, b) => (a.notes ?? '').compareTo(b.notes ?? '')) 
              : setups.sort((a, b) => (b.notes ?? '').compareTo(a.notes ?? ''));
          case "Tags": _sortAscending 
              ? setups.sort((a, b) => a.tags.join('; ').compareTo(b.tags.join('; '))) 
              : setups.sort((a, b) => b.tags.join('; ').compareTo(a.tags.join('; ')));
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
      case TableColumnSection.ratingScore || TableColumnSection.ratingMetrics:
        double rs(Setup s) => (_rawValue(s, _sortColumn!) as double?) ?? double.negativeInfinity;
        _sortAscending
            ? setups.sort((a, b) => rs(a).compareTo(rs(b)))
            : setups.sort((a, b) => rs(b).compareTo(rs(a)));
      case TableColumnSection.componentAdjustments || TableColumnSection.personAttributes:
        final Adjustment? adjustment = _findAdjustment(_sortColumn!, componentAdjustments, personAdjustments);
        if (adjustment == null) return setups;

        dynamic v(Setup s) => _rawValue(s, _sortColumn!);

        switch (adjustment) {
          case BooleanAdjustment(): _sortAscending
              ? setups.sort((a, b) => ((v(a) ?? false) ? 1 : 0).compareTo((v(b) ?? false) ? 1 : 0))
              : setups.sort((a, b) => ((v(b) ?? false) ? 1 : 0).compareTo((v(a) ?? false) ? 1 : 0));
          case StepAdjustment(): _sortAscending
              ? setups.sort((a, b) => ((v(a) ?? 0) as int).compareTo((v(b) ?? 0) as int))
              : setups.sort((a, b) => ((v(b) ?? 0) as int).compareTo((v(a) ?? 0) as int));
          case NumericalAdjustment(): _sortAscending
              ? setups.sort((a, b) => ((v(a) ?? double.negativeInfinity) as double).compareTo((v(b) ?? double.negativeInfinity) as double))
              : setups.sort((a, b) => ((v(b) ?? double.negativeInfinity) as double).compareTo((v(a) ?? double.negativeInfinity) as double));
          case CategoricalAdjustment(): _sortAscending
              ? setups.sort((a, b) => Adjustment.formatValue(v(a) ?? '').compareTo(Adjustment.formatValue(v(b) ?? '')))
              : setups.sort((a, b) => Adjustment.formatValue(v(b) ?? '').compareTo(Adjustment.formatValue(v(a) ?? '')));
          case TextAdjustment(): _sortAscending
              ? setups.sort((a, b) => ((v(a) ?? '') as String).compareTo((v(b) ?? '') as String))
              : setups.sort((a, b) => ((v(b) ?? '') as String).compareTo((v(a) ?? '') as String));
          case DurationAdjustment(): _sortAscending
              ? setups.sort((a, b) => ((v(a) ?? Duration.zero) as Duration).compareTo((v(b) ?? Duration.zero) as Duration))
              : setups.sort((a, b) => ((v(b) ?? Duration.zero) as Duration).compareTo((v(a) ?? Duration.zero) as Duration));
        }
    }
    return setups;
  }

  DataColumn _dataColumn(TableColumn column, Iterable<Adjustment> componentAdjustments, Iterable<Adjustment> personAdjustments) {
    return DataColumn(
      label: GestureDetector(
        onLongPress: () {
          unawaited(HapticFeedback.selectionClick());
          setState(() {
            column.active = false;
            if (_selectedLineChartColumn == column) _selectedLineChartColumn = null;
          });
        },
        child: Text(_columnLabel(column, componentAdjustments, personAdjustments), overflow: TextOverflow.ellipsis),
      ),
      onSort: (int _, bool ascending) {
        setState(() {
          _sortAscending = ascending;
          _sortColumn = column;
        });
      },
    );
  }

  Widget _emptyStatePlaceholder({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                height: 1.5,
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

  Widget _buildLineChartSection({
    required BuildContext context,
    required AppSettings appSettings,
    required List<TableColumn> activeColumns,
    required List<Setup> setups,
    required List<Setup> selectedSetups,
    required Iterable<Adjustment> componentAdjustments,
    required Iterable<Adjustment> personAdjustments,
  }) {
    final activeChartColumns = activeColumns.where((column) {
      if (_isScoreColumn(column)) return true;
      final adjustment = _findAdjustment(column, componentAdjustments, personAdjustments);
      return adjustment is StepAdjustment || adjustment is NumericalAdjustment;
    }).toList();

    if (activeChartColumns.isEmpty) {
      return _chartPlaceholder(message: "Select numerical or step adjustment columns to visualize trends");
    }
    if (setups.isEmpty) {
      return _chartPlaceholder(message: "No setup data available for this component");
    }
    if (selectedSetups.isEmpty) {
      return _chartPlaceholder(message: "Select setups in the table above to visualize the chart");
    }

    final validColumns = activeChartColumns.where((column) {
      return selectedSetups.any((setup) => _rawValue(setup, column) is num);
    }).toList();

    if (validColumns.isEmpty) {
      return _chartPlaceholder(message: "The selected columns do not contain numerical data to plot");
    }

    final chartSetups = selectedSetups;

    if (chartSetups.length < 2) {
      return _chartPlaceholder(message: "Select at least two setups in the table to visualize a trend");
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
                final effectiveSelectedColumn = validColumns.contains(_selectedLineChartColumn) ? _selectedLineChartColumn : null;
                final isSelected = effectiveSelectedColumn == null || effectiveSelectedColumn == column;
                final color = lineChartColors[index];
                return LineChartBarData(
                  spots: chartSetups.asMap().entries.map((entry) {
                    final val = _rawValue(entry.value, column);
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
                          final adjustment = _findAdjustment(column, componentAdjustments, personAdjustments);
                          final columnName = _columnLabel(column, componentAdjustments, personAdjustments);
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
                  final effectiveSelectedColumn = validColumns.contains(_selectedLineChartColumn) ? _selectedLineChartColumn : null;
                  final isSelected = effectiveSelectedColumn == column;
                  final isDimmed = effectiveSelectedColumn != null && !isSelected;
                  final color = lineChartColors[index];
                  final dashArray = _dashPatterns[index % _dashPatterns.length];
                  final columnName = _columnLabel(column, componentAdjustments, personAdjustments);
              
                  return InkWell(
                    onTap: () {
                      unawaited(HapticFeedback.selectionClick());
                      setState(() {
                        if (_selectedLineChartColumn == column) {
                          _selectedLineChartColumn = null;
                        } else {
                          _selectedLineChartColumn = column;
                        }
                      });
                    },
                    onLongPress: () {
                      unawaited(HapticFeedback.selectionClick());
                      setState(() {
                        column.active = false;
                        if (_selectedLineChartColumn == column) _selectedLineChartColumn = null;
                      });
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

  Widget _buildRadialChartSection({
    required BuildContext context,
    required AppSettings appSettings,
    required List<TableColumn> activeColumns,
    required List<Setup> setups,
    required List<Setup> selectedSetups,
    required Iterable<Adjustment> componentAdjustments,
    required Iterable<Adjustment> personAdjustments,
  }) {
    final activeChartColumns = activeColumns.where((column) {
      if (_isScoreColumn(column)) return true;
      final adjustment = _findAdjustment(column, componentAdjustments, personAdjustments);
      return adjustment is StepAdjustment || adjustment is NumericalAdjustment;
    }).toList();

    if (activeChartColumns.isEmpty) {
      return _chartPlaceholder(message: "Select numerical or step adjustment columns to visualize trends");
    }
    if (setups.isEmpty) {
      return _chartPlaceholder(message: "No setup data available for this component");
    }
    if (selectedSetups.isEmpty) {
      return _chartPlaceholder(message: "Select setups in the table above to visualize the chart");
    }

    final validColumns = activeChartColumns.where((column) {
      return selectedSetups.any((setup) => _rawValue(setup, column) is num);
    }).toList();

    if (validColumns.isEmpty) {
      return _chartPlaceholder(message: "The selected columns do not contain numerical data to plot");
    }

    // chartSetups covers all data for stable axis normalization
    final chartSetups = setups.toList()..sort((a, b) => a.datetime.compareTo(b.datetime));

    return Column(
      children: [
        const SizedBox(height: 16),
        if (validColumns.length < 3)
          _chartPlaceholder(message: "At least 3 numerical columns are required to generate a radar chart")
        else
          Builder(
            builder: (context) {
              final radarSetups = selectedSetups;
              final radarColors = chartColors(Theme.of(context).colorScheme.primary, radarSetups.length);
              final effectiveSelectedSetupId = radarSetups.any((s) => s.id == _selectedRadarSetupId) ? _selectedRadarSetupId : null;
              final featureDefs = validColumns.map((column) {
                final adjustment = _findAdjustment(column, componentAdjustments, personAdjustments);

                double dataMin = double.infinity;
                double dataMax = double.negativeInfinity;
                for (var setup in chartSetups) {
                  final rawValue = _rawValue(setup, column);
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
                  name: _columnLabel(column, componentAdjustments, personAdjustments),
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
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 350,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                  return RadarChartTitle(text: displayedName, angle: 0);
                                },
                                radarTouchData: RadarTouchData(
                                  touchCallback: (event, response) {
                                    final spot = response?.touchedSpot;
                                    if (event.isInterestedForInteractions && spot != null) {
                                      final dataSetIndex = spot.touchedDataSetIndex;
                                      final entryIndex = spot.touchedRadarEntryIndex;
                                      if (dataSetIndex < radarSetups.length && entryIndex < featureDefs.length) {
                                        final newSetupId = radarSetups[dataSetIndex].id;
                                        final newColumn = featureDefs[entryIndex].column;
                                        if (newSetupId != _touchedRadarSetupId || newColumn != _touchedRadarColumn) {
                                          unawaited(HapticFeedback.selectionClick());
                                        }
                                        setState(() {
                                          _touchedRadarOffset = spot.offset;
                                          _touchedRadarSetupId = newSetupId;
                                          _touchedRadarColumn = newColumn;
                                        });
                                      }
                                    } else if (event is FlPointerExitEvent || event is FlPanEndEvent ||
                                               (event is FlTapUpEvent && spot == null)) {
                                      setState(() {
                                        _touchedRadarOffset = null;
                                        _touchedRadarSetupId = null;
                                        _touchedRadarColumn = null;
                                      });
                                    }
                                  },
                                ),
                                dataSets: radarSetups.mapIndexed((index, setup) {
                                  final isSelected = effectiveSelectedSetupId == null || effectiveSelectedSetupId == setup.id;
                                  final color = radarColors[index];

                                  final entries = featureDefs.map((def) {
                                    final rawValue = _rawValue(setup, def.column);
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
                              duration: Duration.zero,
                            ),
                          ),
                          if (_touchedRadarOffset != null && _touchedRadarSetupId != null && _touchedRadarColumn != null)
                            Builder(builder: (context) {
                              final setup = radarSetups.firstWhereOrNull((s) => s.id == _touchedRadarSetupId);
                              final def = featureDefs.firstWhereOrNull((d) => d.column == _touchedRadarColumn);
                              if (setup == null || def == null) return const SizedBox.shrink();
                              final rawValue = _rawValue(setup, def.column);
                              final formattedVal = Adjustment.formatValue(rawValue);
                              final dateStr = DateFormat(appSettings.dateFormat).format(setup.datetimeLocal);
                              return Positioned(
                                left: _touchedRadarOffset!.dx > constraints.maxWidth / 2 ? null : _touchedRadarOffset!.dx,
                                right: _touchedRadarOffset!.dx > constraints.maxWidth / 2 ? constraints.maxWidth - _touchedRadarOffset!.dx : null,
                                top: _touchedRadarOffset!.dy,
                                child: Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(8),
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          setup.displayName,
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
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: radarSetups.mapIndexed((index, setup) {
                            final isSelected = effectiveSelectedSetupId == setup.id;
                            final isDimmed = effectiveSelectedSetupId != null && !isSelected;
                            final color = radarColors[index];
                            return InkWell(
                              onTap: () {
                                unawaited(HapticFeedback.selectionClick());
                                setState(() {
                                  if (_selectedRadarSetupId == setup.id) {
                                    _selectedRadarSetupId = null;
                                  } else {
                                    _selectedRadarSetupId = setup.id;
                                  }
                                });
                              },
                              onLongPress: () {
                                unawaited(HapticFeedback.selectionClick());
                                setState(() {
                                  _selectedSetupIds!.remove(setup.id);
                                  if (_selectedRadarSetupId == setup.id) _selectedRadarSetupId = null;
                                  if (_touchedRadarSetupId == setup.id) {
                                    _touchedRadarOffset = null;
                                    _touchedRadarSetupId = null;
                                    _touchedRadarColumn = null;
                                  }
                                });
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
                                  spacing: 4,
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
                                    Flexible(
                                      child: Opacity(
                                        opacity: isDimmed ? 0.3 : 1.0,
                                        child: Text(
                                          setup.displayName,
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
                    ],
                  );
                },
              );
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();

    final component = appRepository.components[widget.componentId];
    if (component == null) return const SizedBox.shrink();
    final componentAdjustments = component.adjustments;

    final bikes = appRepository.bikes;
    final bike = bikes[component.bike];

    final persons = appRepository.persons;
    final person = persons[bike?.person];
    final personAdjustments = person?.adjustments ?? [];

    final setupsUnsorted = appRepository.filteredSetups.values.where(
        (s) => component.adjustments.any((adj) => s.bikeAdjustmentValues.containsKey(adj.id))
    ).toList().reversed.toList();

    // Rating scores derived from RatingEntries that resolve to each setup:
    // overall (0–10) and per-metric sub-scores (0–10).
    _ratingScores = {for (final s in setupsUnsorted) s.id: appRepository.scoreForSetup(s.id)};
    _metricScores = {for (final s in setupsUnsorted) s.id: appRepository.metricScoresForSetup(s.id)};

    // Rating-metric columns: one per metric that actually has data here, named
    // after the metric (values are the 0–10 sub-scores above).
    final allRatingMetrics = appRepository.allRatingMetricsById;
    final ratingMetricIds = <String>{for (final m in _metricScores.values) ...m.keys};
    _ratingMetricNames = {
      for (final id in ratingMetricIds) id: allRatingMetrics[id]?.adjustment.name ?? id,
    };

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
          if (!appSettings.enableRating || !ratingMetricIds.contains(column.label)) _columns.remove(column);
        case TableColumnSection.ratingScore:
          if (!appSettings.enableRating) _columns.remove(column);
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
    if (appSettings.enableRating) {
      _columns.add(TableColumn(section: TableColumnSection.ratingScore, label: "Rating Score", active: false));
      for (final id in ratingMetricIds) {
        _columns.add(TableColumn(section: TableColumnSection.ratingMetrics, label: id, active: false));
      }
    }

    final sortedColumns = _columns.sorted((a, b) => a.section.index.compareTo(b.section.index));  // sort by enum index
    final activeColumns = sortedColumns.where((c) => c.active).toList();
    if (!activeColumns.contains(_sortColumn)) _sortColumn = null;

    final setups = sortSetupsByColumn(
      setups: setupsUnsorted,
      componentAdjustments: componentAdjustments,
      personAdjustments: personAdjustments,
      bikes: bikes,
    );

    _selectedSetupIds ??= (setups.toList()..sort((a, b) => b.datetime.compareTo(a.datetime)))
        .take(5).map((s) => s.id).toSet();
    _selectedSetupIds!.removeWhere((id) => !setups.any((s) => s.id == id));
    final selectedSetups = setups.where((s) => _selectedSetupIds!.contains(s.id)).toList();

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [                            
              if (appSettings.enableStrava && subscriptionService.hasStravaEntitlement) ...[
                ComponentStatsCard(componentStats: ComponentStats(
                  distance: component.totalDistance,
                  elevationGain: component.totalElevationGain,
                  movingTime: component.totalMovingTime,
                  elapsedTime: component.totalElapsedTime,
                  activityCount: component.totalActivityCount,
                )),
                const Divider(height: 1),
              ],

              if (component.notes != null) ...[
                ListTile(
                  leading: const Icon(Icons.notes),
                  titleAlignment: ListTileTitleAlignment.titleHeight,
                  title: NotesText(component.notes!, maxLines: 10),
                  dense: true,
                ),
                const Divider(height: 1),
              ],

              if (appSettings.enableInstallationTimeline) ...[
                ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: Text(
                    "History",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  leading: const Icon(Icons.history),
                  childrenPadding: const EdgeInsets.only(left: 20, right: 16),
                  children: [
                    DisplayInstallationTimeline(component: component, showTaskEntries: true),
                  ],
                ),
                const Divider(height: 1),
              ],

              if (appSettings.enableTask) ...[
                OpenTasksTile.component(componentId: widget.componentId),
                const Divider(height: 1),
              ],

              const SectionTitle(title: "Adjustment History", infoText: "Add or remove columns via the Columns button, or long-press a column header to remove it. Use the filter button to narrow down by bike or tags. Select rows to compare specific setups in the charts below. Green values are new (no prior value), orange values have changed from the previous setup."),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          columnLabel: (TableColumn c) => _columnLabel(c, componentAdjustments, personAdjustments),
                          onColumnStatusChanged: () => setState(() {}), // TableColumn.active is changed
                        );
                      },
                    ),
                    FilterSheetChip(enableSetupTagFilter: appSettings.enableSetupTags),
                  ],
                ),
              ),
              if (activeColumns.isNotEmpty)
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    onSelectAll: (selectAll) {
                      unawaited(HapticFeedback.selectionClick());
                      setState(() {
                        if (selectAll == true) {
                          _selectedSetupIds!.addAll(setups.map((s) => s.id));
                        } else {
                          _selectedSetupIds!.clear();
                        }
                      });
                    },
                    sortAscending: _sortAscending,
                    sortColumnIndex: activeColumns.contains(_sortColumn) 
                        ? activeColumns.indexOf(_sortColumn!)
                        : null,
                    columnSpacing: 20,
                    headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                    dataRowMaxHeight: double.infinity,
                    columns: activeColumns.map((column) {
                      return _dataColumn(column, componentAdjustments, personAdjustments);
                    }).toList(),
                    rows: setups.map((setup) {
                      return DataRow(
                        selected: _selectedSetupIds!.contains(setup.id),
                        onSelectChanged: (bool? selected) {
                          unawaited(HapticFeedback.selectionClick());
                          setState(() {
                            if (selected == true) {
                              _selectedSetupIds!.add(setup.id);
                            } else {
                              _selectedSetupIds!.remove(setup.id);
                              if (_touchedRadarSetupId == setup.id) {
                                _touchedRadarOffset = null;
                                _touchedRadarSetupId = null;
                                _touchedRadarColumn = null;
                              }
                            }
                          });
                        },
                        cells: activeColumns.map((column) {
                          switch (column.section) {
                            case TableColumnSection.generalContext:
                              return switch (column.label) {
                                "Name" => DataCell(ConstrainedBox(constraints: const BoxConstraints(maxWidth: 150), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(setup.displayName, overflow: TextOverflow.ellipsis)))),
                                "Notes" => DataCell(ConstrainedBox(constraints: const BoxConstraints(maxWidth: 300), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(setup.notes ?? '-', overflow: TextOverflow.ellipsis)))),
                                "Tags" => DataCell(ConstrainedBox(constraints: const BoxConstraints(maxWidth: 300), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(setup.tags.isEmpty ? '-' : setup.tags.join('; '), overflow: TextOverflow.ellipsis)))),
                                "Date" => DataCell(Text(DateFormat(appSettings.dateFormat).format(setup.datetimeLocal))),
                                "Time" => DataCell(Text(DateFormat(appSettings.timeFormat).format(setup.datetimeLocal))),
                                "Place" => DataCell(ConstrainedBox(constraints: const BoxConstraints(maxWidth: 150), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(setup.place?.locality ?? '-', overflow: TextOverflow.ellipsis)))),
                                "Altitude" => DataCell(Center(child: Text(setup.position?.altitude == null ? '-' : "${setup.position!.altitude!.round()} ${appSettings.altitudeUnit}"))),
                                "Bike" => DataCell(ConstrainedBox(constraints: const BoxConstraints(maxWidth: 150), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(bikes[setup.bike]?.name ?? '-', overflow: TextOverflow.ellipsis)))),
                                _ => const DataCell(Text("ERROR")),
                              };
                            case TableColumnSection.weatherContext:
                              return switch (column.label) {
                                "Weather Code" => DataCell(Center(child: Text(setup.weather?.getWeatherCodeLabel() ?? "-"))),
                                "Temperature" => DataCell(Center(child: Text(setup.weather?.currentTemperature == null ? '-' : "${ContextWeather.convertTemperatureFromCelsius(setup.weather!.currentTemperature!, appSettings.temperatureUnit)?.round()} ${appSettings.temperatureUnit}"))),
                                "Precipitation" => DataCell(Center(child: Text(setup.weather?.dayAccumulatedPrecipitation == null ? '-' : "${ContextWeather.convertPrecipitationFromMm(setup.weather!.dayAccumulatedPrecipitation!, appSettings.precipitationUnit)?.round()} ${appSettings.precipitationUnit}"))),
                                "Humidity" => DataCell(Center(child: Text(setup.weather?.currentHumidity == null ? '-' : "${setup.weather!.currentHumidity!.round()} %"))),
                                "Windspeed" => DataCell(Center(child: Text(setup.weather?.currentWindSpeed == null ? '-' : "${ContextWeather.convertWindSpeedFromKmh(setup.weather!.currentWindSpeed!, appSettings.windSpeedUnit)?.round()} ${appSettings.windSpeedUnit}"))),
                                "Soil Moisture" => DataCell(Center(child: Text(setup.weather?.currentSoilMoisture0to7cm == null ? '-' : setup.weather!.currentSoilMoisture0to7cm!.toStringAsFixed(2)))),
                                "Condition" => DataCell(Center(child: Text(setup.weather?.condition == null ? '-' : setup.weather?.condition!.value ?? "-"))),
                                _ => const DataCell(Text("ERROR")),
                              };
                            case TableColumnSection.componentAdjustments || TableColumnSection.personAttributes:
                              final value = _rawValue(setup, column);
                              final initialValue = switch (column.section) {
                                TableColumnSection.componentAdjustments => setup.previousBikeAdjustmentValues[column.label],
                                TableColumnSection.personAttributes => setup.previousPersonAdjustmentValues[column.label],
                                _ => null,
                              };

                              Color? highlightColor;
                              if (_highlighting) {
                                final bool isChanged = value != null && initialValue != value;
                                final bool isInitial = initialValue == null;
                                final highlights = Theme.of(context).extension<ValueHighlightColors>();
                                highlightColor = isChanged ? (isInitial ? highlights?.initial ?? Colors.green : highlights?.changed ?? Colors.orange) : null;
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
                            case TableColumnSection.ratingScore || TableColumnSection.ratingMetrics:
                              final score = _rawValue(setup, column) as double?;
                              return DataCell(Center(child: Text(score == null ? '-' : "${score.toStringAsFixed(1)} / 10")));
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
              const SizedBox(height: 16),

              const Divider(height: 1),
              const SectionTitle(title: "Line Chart", infoText: "Shows the setups selected in the table above in their current sort order. The y-axis represents adjustment values. Select at least two setups to display a trend. Tap legend entries to highlight a specific line."),
              _buildLineChartSection(
                context: context,
                appSettings: appSettings,
                activeColumns: activeColumns,
                setups: setups,
                selectedSetups: selectedSetups,
                componentAdjustments: componentAdjustments,
                personAdjustments: personAdjustments,
              ),

              const Divider(height: 1),
              const SectionTitle(title: "Radial Chart", infoText: "Shows the setups selected in the table above. Axes are normalized across all data for stable comparison. Tap legend entries to highlight specific graphs."),
              _buildRadialChartSection(
                context: context,
                appSettings: appSettings,
                activeColumns: activeColumns,
                setups: setups,
                selectedSetups: selectedSetups,
                componentAdjustments: componentAdjustments,
                personAdjustments: personAdjustments,
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
