import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/setup.dart';
import '../../theme.dart';
import '../../utils/table_column.dart';
import '../empty_state_placeholder.dart';

class ComponentDetailsPageRadialChart extends StatefulWidget {
  final List<TableColumn> activeColumns;
  final List<Setup> setups;
  final List<Setup> selectedSetups;
  final dynamic Function(Setup setup, TableColumn column) valueFor;
  final Adjustment? Function(TableColumn column) adjustmentFor;
  final String Function(TableColumn column) columnLabel;
  final ValueChanged<String> onSetupRemoved;

  const ComponentDetailsPageRadialChart({
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
  State<ComponentDetailsPageRadialChart> createState() => _ComponentDetailsPageRadialChartState();
}

class _ComponentDetailsPageRadialChartState extends State<ComponentDetailsPageRadialChart> {
  _TouchedRadarValue? _touchedRadarValue;
  String? _selectedRadarSetupId;

  @override
  void didUpdateWidget(covariant ComponentDetailsPageRadialChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.selectedSetups.any((setup) => setup.id == _touchedRadarValue?.setupId)) {
      _touchedRadarValue = null;
    }
    if (!widget.selectedSetups.any((setup) => setup.id == _selectedRadarSetupId)) {
      _selectedRadarSetupId = null;
    }
  }

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

    if (validColumns.length < 3) {
      return const EmptyStatePlaceholder(
        icon: Icons.insights_rounded,
        title: "Not enough columns",
        subtitle: "At least 3 numerical columns are required to generate a radar chart",
      );
    }

    // chartSetups covers all data for stable axis normalization
    final chartSetups = widget.setups.toList()..sort((a, b) => a.datetime.compareTo(b.datetime));

    final radarSetups = widget.selectedSetups;
    final radarColors = chartColors(Theme.of(context).colorScheme.primary, radarSetups.length);
    final effectiveSelectedSetupId = radarSetups.any((s) => s.id == _selectedRadarSetupId)
        ? _selectedRadarSetupId
        : null;
    final featureDefs = validColumns.map((column) {
      final adjustment = widget.adjustmentFor(column);

      double dataMin = double.infinity;
      double dataMax = double.negativeInfinity;
      for (var setup in chartSetups) {
        final rawValue = widget.valueFor(setup, column);
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
        name: widget.columnLabel(column),
        unit: adjustment?.unit?.label ?? "",
        min: dataMin,
        max: dataMax,
      );
    }).toList();
    
    return Padding(
      padding: const EdgeInsetsGeometry.symmetric(vertical: 16),
      child: LayoutBuilder(
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
                        gridBorderData: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          width: 1,
                        ),
                        radarBorderData: const BorderSide(color: Colors.transparent),
                        tickBorderData: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                          width: 1,
                        ),
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
                                if (newSetupId != _touchedRadarValue?.setupId ||
                                    newColumn != _touchedRadarValue?.tableColumn) {
                                  unawaited(HapticFeedback.selectionClick());
                                }
                                setState(() {
                                  _touchedRadarValue = _TouchedRadarValue(
                                    setupId: newSetupId,
                                    tableColumn: newColumn,
                                    offset: spot.offset,
                                  );
                                });
                              }
                            } else if (event is FlPointerExitEvent ||
                                event is FlPanEndEvent ||
                                (event is FlTapUpEvent && spot == null)) {
                              setState(() => _touchedRadarValue = null);
                            }
                          },
                        ),
                        dataSets: radarSetups.mapIndexed((index, setup) {
                          final isSelected =
                              effectiveSelectedSetupId == null || effectiveSelectedSetupId == setup.id;
                          final color = radarColors[index];

                          final entries = featureDefs.map((def) {
                            final rawValue = widget.valueFor(setup, def.column);
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
                            fillColor: isSelected
                                ? color.withValues(alpha: 0.2)
                                : color.withValues(alpha: 0.05),
                            borderColor: isSelected ? color : color.withValues(alpha: 0.25),
                            entryRadius: isSelected ? 3 : 2,
                            borderWidth: isSelected ? 2 : 1.5,
                          );
                        }).toList(),
                      ),
                      duration: Duration.zero,
                    ),
                  ),
                  if (_touchedRadarValue != null)
                    Builder(
                      builder: (context) {
                        final setup = radarSetups.firstWhereOrNull((s) => s.id == _touchedRadarValue!.setupId);
                        final def = featureDefs.firstWhereOrNull(
                          (d) => d.column == _touchedRadarValue!.tableColumn,
                        );
                        if (setup == null || def == null) return const SizedBox.shrink();
                        final rawValue = widget.valueFor(setup, def.column);
                        final formattedVal = Adjustment.formatValue(rawValue);
                        final dateStr = DateFormat(appSettings.dateFormat).format(setup.datetimeLocal);
                        return Positioned(
                          left: _touchedRadarValue!.offset.dx > constraints.maxWidth / 2
                              ? null
                              : _touchedRadarValue!.offset.dx,
                          right: _touchedRadarValue!.offset.dx > constraints.maxWidth / 2
                              ? constraints.maxWidth - _touchedRadarValue!.offset.dx
                              : null,
                          top: _touchedRadarValue!.offset.dy,
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
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
                      },
                    ),
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
                          if (_selectedRadarSetupId == setup.id) _selectedRadarSetupId = null;
                          if (_touchedRadarValue?.setupId == setup.id) {
                            _touchedRadarValue = null;
                          }
                        });
                        widget.onSetupRemoved(setup.id);
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
      ),
    );
  }
}

class _TouchedRadarValue {
  final String setupId;
  final TableColumn tableColumn;
  final Offset offset;

  const _TouchedRadarValue({required this.setupId, required this.tableColumn, required this.offset});
}
