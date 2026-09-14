import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../services/setup_activity_analysis_service.dart';
import '../../services/subscription_service.dart';
import '../../utils/component_actions.dart';
import '../../utils/installation_timeline_validation.dart';
import '../../utils/table_column.dart';
import '../../utils/table_column_comparator.dart';
import '../../widgets/chips/filter_sheet_chip.dart';
import '../../widgets/display_data/component_details_page_line_chart.dart';
import '../../widgets/display_data/component_details_page_radial_chart.dart';
import '../../widgets/display_data/component_stats_card.dart';
import '../../widgets/display_data/setup_table.dart';
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

  // Setup columns are rendered by the table itself; only data-driven columns resolve to a value here.
  dynamic _rawValue(Setup setup, TableColumn column) => switch (column) {
    ComponentAdjustmentColumn(:final adjustmentId) => setup.bikeAdjustmentValues[adjustmentId],
    PersonAttributeColumn(:final adjustmentId) => setup.personAdjustmentValues[adjustmentId],
    RatingMetricColumn(:final metricId) => _metricScores[setup.id]?[metricId],
    RatingScoreColumn() => _ratingScores[setup.id],
    SetupTableColumn() => null,
  };

  String _columnLabel(
    TableColumn column,
    Iterable<Adjustment> componentAdjustments,
    Iterable<Adjustment> personAdjustments,
  ) {
    return switch (column) {
      SetupTableColumn(column: final setupColumn) => setupColumn.label,
      RatingScoreColumn() => "Rating Score",
      RatingMetricColumn(:final metricId) => _ratingMetricNames[metricId] ?? metricId,
      ComponentAdjustmentColumn(:final adjustmentId) =>
        componentAdjustments.firstWhereOrNull((a) => a.id == adjustmentId)?.name ?? adjustmentId,
      PersonAttributeColumn(:final adjustmentId) =>
        personAdjustments.firstWhereOrNull((a) => a.id == adjustmentId)?.name ?? adjustmentId,
    };
  }

  Set<TableColumn> _columns = {};

  List<Setup> sortSetupsByColumn({
    required List<Setup> setups,
    required Iterable<Adjustment> componentAdjustments,
    required Iterable<Adjustment> personAdjustments,
    required Map<String, Bike> bikes,
    required Map<String, int> setupActivityCounts,
  }) {
    final sortColumn = _sortColumn;
    if (sortColumn == null) return setups;

    final comparator = tableColumnComparator(
      sortColumn,
      valueFor: _rawValue,
      componentAdjustments: componentAdjustments,
      personAdjustments: personAdjustments,
      bikes: bikes,
      setupActivityCounts: setupActivityCounts,
    );
    if (comparator == null) return setups;

    setups.sort(_sortAscending ? comparator : (a, b) => comparator(b, a));
    return setups;
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();
    final hasAnyActivity = context.select<SetupActivityAnalysisService, bool>(
      (service) => service.hasAnyActivity,
    );
    final setupActivityCounts = context.select<SetupActivityAnalysisService, Map<String, int>>(
      (service) => service.setupActivityCounts,
    );
    if (hasAnyActivity) {
      unawaited(context.read<SetupActivityAnalysisService>().getSetupActivityCounts());
    }

    final component = appRepository.components[widget.componentId];
    if (component == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const SafeArea(
          child: EmptyStatePlaceholder.error(
            title: "Component not found",
            subtitle: "This component was deleted or is no longer available.",
          ),
        ),
      );
    }
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

    // Built-in columns available under the current feature flags.
    final availableSetupColumns = SetupColumn.values.where(
      (column) => switch (column) {
        SetupColumn.tags => appSettings.enableSetupTags,
        SetupColumn.bookmarked => appSettings.enableSetupBookmark,
        SetupColumn.activities => hasAnyActivity,
        _ => true,
      },
    );

    // Rebuilt every frame so columns always appear in canonical order; lookup()
    // carries over the 'active' state of the columns that already existed.
    final previousColumns = _columns;
    T retained<T extends TableColumn>(T column) => previousColumns.lookup(column) as T? ?? column;

    _columns = {
      for (final column in availableSetupColumns) retained(SetupTableColumn(column, active: column.defaultActive)),
      for (final adjustment in componentAdjustments) retained(ComponentAdjustmentColumn(adjustment.id, active: true)),
      if (appSettings.enablePerson && person != null)
        for (final adjustment in personAdjustments) retained(PersonAttributeColumn(adjustment.id, active: false)),
      if (appSettings.enableRating) ...[
        for (final id in ratingMetricIds) retained(RatingMetricColumn(id, active: false)),
        retained(RatingScoreColumn(active: false)),
      ],
    };

    final orderedColumns = _columns.toList();
    final activeColumns = orderedColumns.where((c) => c.active).toList();
    if (!activeColumns.contains(_sortColumn)) _sortColumn = null;

    final sortColumn = _sortColumn;
    final showDateAxisLabels =
        sortColumn == null || (sortColumn is SetupTableColumn && sortColumn.column == SetupColumn.date);

    final setups = sortSetupsByColumn(
      setups: setupsUnsorted,
      componentAdjustments: componentAdjustments,
      personAdjustments: personAdjustments,
      bikes: bikes,
      setupActivityCounts: setupActivityCounts,
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
                ComponentStatsCard(componentStats: component.totalStats),
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

              if (shouldUseInstallationTimeline(
                featureEnabled: appSettings.enableInstallationTimeline,
                installations: component.installations,
              ) || appRepository.taskEntries.values.any((te) => te.componentId == widget.componentId)) ...[
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
                    DisplayInstallationTimeline(
                      component: component,
                      bikes: bikes,
                      taskEntries: appRepository.taskEntries.values.where(
                        (entry) => entry.componentId == component.id,
                      ),
                    ),
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
                          columns: orderedColumns,
                          columnLabel: (TableColumn c) => _columnLabel(c, componentAdjustments, personAdjustments),
                          onColumnStatusChanged: () => setState(() {}), // TableColumn.active is changed
                        );
                      },
                    ),
                    FilterSheetChip.componentDetailsPage,
                  ],
                ),
              ),
              if (setups.isNotEmpty && activeColumns.isNotEmpty)
                SetupTable(
                  activeColumns: activeColumns,
                  setups: setups,
                  selectedSetupIds: _selectedSetupIds!,
                  sortAscending: _sortAscending,
                  sortColumn: _sortColumn,
                  bikes: bikes,
                  setupActivityCounts: setupActivityCounts,
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
                showDateAxisLabels: showDateAxisLabels,
                selectedLineChartColumn: _selectedLineChartColumn,
                valueFor: _rawValue,
                adjustmentFor: (column) => adjustmentForColumn(
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
                adjustmentFor: (column) => adjustmentForColumn(
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
