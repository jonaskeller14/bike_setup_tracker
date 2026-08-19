import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/component_stats.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../utils/component_actions.dart';
import '../../utils/table_column.dart';
import '../../widgets/chips/filter_sheet_chip.dart';
import '../../widgets/display_data/component_details_page_line_chart.dart';
import '../../widgets/display_data/component_details_page_radial_chart.dart';
import '../../widgets/display_data/component_details_page_table.dart';
import '../../widgets/display_data/component_stats_card.dart';
import '../../widgets/display_installation_timeline.dart';
import '../../widgets/empty_state_placeholder.dart';
import '../../widgets/initial_changed_value_legend.dart';
import '../../widgets/notes_text.dart';
import '../../widgets/open_tasks_tile.dart';
import '../../widgets/sheets/column_filter.dart';
import '../../widgets/text/section_title.dart';

class ComponentDetailsPage extends StatefulWidget {
  final String componentId;

  const ComponentDetailsPage({super.key, required this.componentId});

  @override
  State<ComponentDetailsPage> createState() => _ComponentDetailsPageState();
}

class _ComponentDetailsPageState extends State<ComponentDetailsPage> {
  static const int _defaultSelectedSetupCount = 3;

  bool _sortAscending = true;
  TableColumn? _sortColumn;
  TableColumn? _selectedLineChartColumn;
  Set<String>? _selectedSetupIds;

  Map<String, double?> _ratingScores = {};
  Map<String, Map<String, double>> _metricScores = {};
  // ratingMetricId → display name, for the per-metric rating columns.
  Map<String, String> _ratingMetricNames = {};

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

  String _columnLabel(
    TableColumn column,
    Iterable<Adjustment> componentAdjustments,
    Iterable<Adjustment> personAdjustments,
  ) {
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
          case "Name":
            _sortAscending
                ? setups.sort((a, b) => a.displayName.compareTo(b.displayName))
                : setups.sort((a, b) => b.displayName.compareTo(a.displayName));
          case "Notes":
            _sortAscending
                ? setups.sort((a, b) => (a.notes ?? '').compareTo(b.notes ?? ''))
                : setups.sort((a, b) => (b.notes ?? '').compareTo(a.notes ?? ''));
          case "Tags":
            _sortAscending
                ? setups.sort((a, b) => a.tags.join('; ').compareTo(b.tags.join('; ')))
                : setups.sort((a, b) => b.tags.join('; ').compareTo(a.tags.join('; ')));
          case "Date":
            _sortAscending
                ? setups.sort((a, b) => a.datetime.compareTo(b.datetime))
                : setups.sort((a, b) => b.datetime.compareTo(a.datetime));
          case "Time":
            _sortAscending
                ? setups.sort(
                    (a, b) => a.datetime
                        .copyWith(year: 0, month: 0, day: 0)
                        .compareTo(b.datetime.copyWith(year: 0, month: 0, day: 0)),
                  )
                : setups.sort(
                    (a, b) => b.datetime
                        .copyWith(year: 0, month: 0, day: 0)
                        .compareTo(a.datetime.copyWith(year: 0, month: 0, day: 0)),
                  );
          case "Place":
            _sortAscending
                ? setups.sort((a, b) => (a.place?.locality ?? '').compareTo(b.place?.locality ?? ''))
                : setups.sort((a, b) => (b.place?.locality ?? '').compareTo(a.place?.locality ?? ''));
          case "Altitude":
            _sortAscending
                ? setups.sort(
                    (a, b) => (a.position?.altitude ?? double.negativeInfinity).compareTo(
                      b.position?.altitude ?? double.negativeInfinity,
                    ),
                  )
                : setups.sort(
                    (a, b) => (b.position?.altitude ?? double.negativeInfinity).compareTo(
                      a.position?.altitude ?? double.negativeInfinity,
                    ),
                  );
          case "Bike":
            _sortAscending
                ? setups.sort((a, b) => (bikes[a.bike]?.name ?? '').compareTo(bikes[b.bike]?.name ?? ''))
                : setups.sort((a, b) => (bikes[b.bike]?.name ?? '').compareTo(bikes[a.bike]?.name ?? ''));
          case "Weather Code":
            _sortAscending
                ? setups.sort(
                    (a, b) =>
                        (a.weather?.getWeatherCodeLabel() ?? '').compareTo(b.weather?.getWeatherCodeLabel() ?? ''),
                  )
                : setups.sort(
                    (a, b) =>
                        (b.weather?.getWeatherCodeLabel() ?? '').compareTo(a.weather?.getWeatherCodeLabel() ?? ''),
                  );
          case "Temperature":
            _sortAscending
                ? setups.sort(
                    (a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(
                      b.weather?.currentTemperature ?? double.negativeInfinity,
                    ),
                  )
                : setups.sort(
                    (a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(
                      a.weather?.currentTemperature ?? double.negativeInfinity,
                    ),
                  );
          case "Precipitation":
            _sortAscending
                ? setups.sort(
                    (a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(
                      b.weather?.currentTemperature ?? double.negativeInfinity,
                    ),
                  )
                : setups.sort(
                    (a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(
                      a.weather?.currentTemperature ?? double.negativeInfinity,
                    ),
                  );
          case "Humidity":
            _sortAscending
                ? setups.sort(
                    (a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(
                      b.weather?.currentTemperature ?? double.negativeInfinity,
                    ),
                  )
                : setups.sort(
                    (a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(
                      a.weather?.currentTemperature ?? double.negativeInfinity,
                    ),
                  );
          case "Windspeed":
            _sortAscending
                ? setups.sort(
                    (a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(
                      b.weather?.currentTemperature ?? double.negativeInfinity,
                    ),
                  )
                : setups.sort(
                    (a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(
                      a.weather?.currentTemperature ?? double.negativeInfinity,
                    ),
                  );
          case "Soil Moisture":
            _sortAscending
                ? setups.sort(
                    (a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(
                      b.weather?.currentTemperature ?? double.negativeInfinity,
                    ),
                  )
                : setups.sort(
                    (a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(
                      a.weather?.currentTemperature ?? double.negativeInfinity,
                    ),
                  );
          case "Condition":
            _sortAscending
                ? setups.sort(
                    (a, b) => (a.weather?.condition?.value ?? '').compareTo(b.weather?.condition?.value ?? ''),
                  )
                : setups.sort(
                    (a, b) => (b.weather?.condition?.value ?? '').compareTo(a.weather?.condition?.value ?? ''),
                  );
        }
      case TableColumnSection.ratingScore || TableColumnSection.ratingMetrics:
        double rs(Setup s) => (_rawValue(s, _sortColumn!) as double?) ?? double.negativeInfinity;
        _sortAscending ? setups.sort((a, b) => rs(a).compareTo(rs(b))) : setups.sort((a, b) => rs(b).compareTo(rs(a)));
      case TableColumnSection.componentAdjustments || TableColumnSection.personAttributes:
        final Adjustment? adjustment = _findAdjustment(_sortColumn!, componentAdjustments, personAdjustments);
        if (adjustment == null) return setups;

        dynamic v(Setup s) => _rawValue(s, _sortColumn!);

        switch (adjustment) {
          case BooleanAdjustment():
            _sortAscending
                ? setups.sort((a, b) => ((v(a) as bool? ?? false) ? 1 : 0).compareTo((v(b) as bool? ?? false) ? 1 : 0))
                : setups.sort((a, b) => ((v(b) as bool? ?? false) ? 1 : 0).compareTo((v(a) as bool? ?? false) ? 1 : 0));
          case StepAdjustment():
            _sortAscending
                ? setups.sort((a, b) => ((v(a) ?? 0) as int).compareTo((v(b) ?? 0) as int))
                : setups.sort((a, b) => ((v(b) ?? 0) as int).compareTo((v(a) ?? 0) as int));
          case NumericalAdjustment():
            _sortAscending
                ? setups.sort(
                    (a, b) => ((v(a) ?? double.negativeInfinity) as double).compareTo(
                      (v(b) ?? double.negativeInfinity) as double,
                    ),
                  )
                : setups.sort(
                    (a, b) => ((v(b) ?? double.negativeInfinity) as double).compareTo(
                      (v(a) ?? double.negativeInfinity) as double,
                    ),
                  );
          case CategoricalAdjustment():
            _sortAscending
                ? setups.sort(
                    (a, b) => Adjustment.formatValue(v(a) ?? '').compareTo(Adjustment.formatValue(v(b) ?? '')),
                  )
                : setups.sort(
                    (a, b) => Adjustment.formatValue(v(b) ?? '').compareTo(Adjustment.formatValue(v(a) ?? '')),
                  );
          case TextAdjustment():
            _sortAscending
                ? setups.sort((a, b) => ((v(a) ?? '') as String).compareTo((v(b) ?? '') as String))
                : setups.sort((a, b) => ((v(b) ?? '') as String).compareTo((v(a) ?? '') as String));
          case DurationAdjustment():
            _sortAscending
                ? setups.sort(
                    (a, b) => ((v(a) ?? Duration.zero) as Duration).compareTo((v(b) ?? Duration.zero) as Duration),
                  )
                : setups.sort(
                    (a, b) => ((v(b) ?? Duration.zero) as Duration).compareTo((v(a) ?? Duration.zero) as Duration),
                  );
        }
    }
    return setups;
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

    final setupsUnsorted = appRepository.filteredSetups.values
        .where((s) => component.adjustments.any((adj) => s.bikeAdjustmentValues.containsKey(adj.id)))
        .toList()
        .reversed
        .toList();

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
        case TableColumnSection.weatherContext:
          continue;
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
      _columns.addAll(
        personAdjustments.map(
          (a) => TableColumn(section: TableColumnSection.personAttributes, label: a.id, active: false),
        ),
      );
    }
    if (appSettings.enableRating) {
      _columns.add(TableColumn(section: TableColumnSection.ratingScore, label: "Rating Score", active: false));
      for (final id in ratingMetricIds) {
        _columns.add(TableColumn(section: TableColumnSection.ratingMetrics, label: id, active: false));
      }
    }

    final sortedColumns = _columns.sorted((a, b) => a.section.index.compareTo(b.section.index)); // sort by enum index
    final activeColumns = sortedColumns.where((c) => c.active).toList();
    if (!activeColumns.contains(_sortColumn)) _sortColumn = null;

    final setups = sortSetupsByColumn(
      setups: setupsUnsorted,
      componentAdjustments: componentAdjustments,
      personAdjustments: personAdjustments,
      bikes: bikes,
    );

    _selectedSetupIds ??= (setups.toList()..sort((a, b) => b.datetime.compareTo(a.datetime)))
        .take(_defaultSelectedSetupCount)
        .map((s) => s.id)
        .toSet();
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
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (appSettings.enableStrava && subscriptionService.hasStravaEntitlement) ...[
                ComponentStatsCard(
                  componentStats: ComponentStats(
                    distance: component.totalDistance,
                    elevationGain: component.totalElevationGain,
                    movingTime: component.totalMovingTime,
                    elapsedTime: component.totalElapsedTime,
                    activityCount: component.totalActivityCount,
                  ),
                ),
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

              const SectionTitle(
                title: "Adjustment History",
                infoText:
                    "Add or remove columns via the Columns button, or long-press a column header to remove it. Use the filter button to narrow down by bike or tags. Select rows to compare specific setups in the charts below. Green values are new (no prior value), orange values have changed from the previous setup.",
              ),

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
              if (setups.isNotEmpty && activeColumns.isNotEmpty)
                ComponentDetailsPageTable(
                  activeColumns: activeColumns,
                  setups: setups,
                  selectedSetupIds: _selectedSetupIds!,
                  sortAscending: _sortAscending,
                  sortColumn: _sortColumn,
                  bikes: bikes,
                  valueFor: _rawValue,
                  columnLabel: (column) => _columnLabel(
                    column,
                    componentAdjustments,
                    personAdjustments,
                  ),
                  onSort: (column, ascending) {
                    setState(() {
                      _sortAscending = ascending;
                      _sortColumn = column;
                    });
                  },
                  onColumnRemoved: (column) {
                    setState(() {
                      column.active = false;
                      if (_selectedLineChartColumn == column) {
                        _selectedLineChartColumn = null;
                      }
                    });
                  },
                  onSelectAll: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedSetupIds!.addAll(setups.map((setup) => setup.id));
                      } else {
                        _selectedSetupIds!.clear();
                      }
                    });
                  },
                  onSetupSelected: (setup, selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedSetupIds!.add(setup.id);
                      } else {
                        _selectedSetupIds!.remove(setup.id);
                      }
                    });
                  },
                ),
              if (setups.isNotEmpty && activeColumns.isEmpty)
                const EmptyStatePlaceholder(
                  icon: Icons.view_column_outlined,
                  title: "No columns",
                  subtitle: 'Select a column to display the table',
                ),
              if (setups.isEmpty)
                EmptyStatePlaceholder(
                  icon: Icons.history_rounded,
                  title: component.adjustments.isEmpty ? 'No adjustments' : 'No setups yet',
                  subtitle: component.adjustments.isEmpty ? 'No adjustments are defined for this component' : null,
                ),
              if (activeColumns.isNotEmpty && setups.isNotEmpty) const InitialChangedValueLegend(),
              const SizedBox(height: 16),

              const Divider(height: 1),
              const SectionTitle(
                title: "Line Chart",
                infoText:
                    "• Shows the setups selected in the table above in their current sort order.\n"
                    "• The y-axis represents adjustment values.\n"
                    "• Select at least two setups to display a trend.\n"
                    "• Tap a legend entry to highlight a specific line.\n"
                    "• Long-press a legend entry to remove it from the selection.",
              ),
              ComponentDetailsPageLineChart(
                activeColumns: activeColumns,
                setups: setups,
                selectedSetups: selectedSetups,
                showDateAxisLabels:
                    _sortColumn == null ||
                    (_sortColumn!.section == TableColumnSection.generalContext && _sortColumn!.label == "Date"),
                selectedLineChartColumn: _selectedLineChartColumn,
                valueFor: _rawValue,
                adjustmentFor: (column) => _findAdjustment(
                  column,
                  componentAdjustments,
                  personAdjustments,
                ),
                columnLabel: (column) => _columnLabel(
                  column,
                  componentAdjustments,
                  personAdjustments,
                ),
                onSelectedColumnChanged: (column) {
                  setState(() => _selectedLineChartColumn = column);
                },
                onColumnRemoved: (column) {
                  setState(() {
                    column.active = false;
                    if (_selectedLineChartColumn == column) {
                      _selectedLineChartColumn = null;
                    }
                  });
                },
              ),

              const Divider(height: 1),
              const SectionTitle(
                title: "Radial Chart",
                infoText:
                    "• Shows the setups selected in the table above.\n"
                    "• Axes are normalized across all data for stable comparison.\n"
                    "• Tap a legend entry to highlight a specific graph.\n"
                    "• Long-press a legend entry to remove it from the selection.",
              ),
              ComponentDetailsPageRadialChart(
                activeColumns: activeColumns,
                setups: setups,
                selectedSetups: selectedSetups,
                valueFor: _rawValue,
                adjustmentFor: (column) => _findAdjustment(
                  column,
                  componentAdjustments,
                  personAdjustments,
                ),
                columnLabel: (column) => _columnLabel(
                  column,
                  componentAdjustments,
                  personAdjustments,
                ),
                onSetupRemoved: (setupId) {
                  setState(() => _selectedSetupIds!.remove(setupId));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
