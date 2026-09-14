import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../icons/simple_icons.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/component_stats.dart';
import '../../models/person.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../services/setup_activity_analysis_service.dart';
import '../../services/subscription_service.dart';
import '../../utils/bike_actions.dart';
import '../../utils/component_actions.dart';
import '../../utils/table_column.dart';
import '../../utils/table_column_comparator.dart';
import '../../widgets/display_data/component_stats_card.dart';
import '../../widgets/display_data/setup_table.dart';
import '../../widgets/empty_state_placeholder.dart';
import '../../widgets/empty_state_placeholder2.dart';
import '../../widgets/initial_changed_value_legend.dart';
import '../../widgets/installation_timeline_table.dart';
import '../../widgets/items/component_list_card.dart';
import '../../widgets/notes_text.dart';
import '../../widgets/open_tasks_tile.dart';
import '../../widgets/sheets/column_filter.dart';
import '../../widgets/text/section_title.dart';

class BikeDetailsPage extends StatefulWidget {
  final String bikeId;

  const BikeDetailsPage({super.key, required this.bikeId});

  @override
  State<BikeDetailsPage> createState() => _BikeDetailsPageState();
}

class _BikeDetailsPageState extends State<BikeDetailsPage> {
  bool _sortAscending = true;
  TableColumn? _sortColumn;
  Set<TableColumn> _columns = {};

  Map<String, double?> _ratingScores = {};
  Map<String, Map<String, double>> _metricScores = {};
  // ratingMetricId -> display name, for the per-metric rating columns.
  Map<String, String> _ratingMetricNames = {};

  // Setup columns are rendered by the table itself; only data-driven columns resolve to a value here.
  dynamic _rawValue(Setup setup, TableColumn column) => switch (column) {
    PersonAttributeColumn(:final adjustmentId) => setup.personAdjustmentValues[adjustmentId],
    RatingMetricColumn(:final metricId) => _metricScores[setup.id]?[metricId],
    RatingScoreColumn() => _ratingScores[setup.id],
    ComponentAdjustmentColumn() || SetupTableColumn() => null,
  };

  String _columnLabel(TableColumn column, Iterable<Adjustment> personAdjustments) {
    return switch (column) {
      SetupTableColumn(column: final setupColumn) => setupColumn.label,
      RatingScoreColumn() => "Rating Score",
      RatingMetricColumn(:final metricId) => _ratingMetricNames[metricId] ?? metricId,
      PersonAttributeColumn(:final adjustmentId) =>
        personAdjustments.firstWhereOrNull((a) => a.id == adjustmentId)?.name ?? adjustmentId,
      ComponentAdjustmentColumn(:final adjustmentId) => adjustmentId,
    };
  }

  List<Setup> _sortSetupsByColumn({
    required List<Setup> setups,
    required Iterable<Adjustment> personAdjustments,
    required Map<String, Bike> bikes,
    required Map<String, int> setupActivityCounts,
  }) {
    final sortColumn = _sortColumn;
    if (sortColumn == null) return setups;

    final comparator = tableColumnComparator(
      sortColumn,
      valueFor: _rawValue,
      componentAdjustments: const [],
      personAdjustments: personAdjustments,
      bikes: bikes,
      setupActivityCounts: setupActivityCounts,
    );
    if (comparator == null) return setups;

    setups.sort(_sortAscending ? comparator : (a, b) => comparator(b, a));
    return setups;
  }

  Widget _setupHistory(
    BuildContext context,
    AppSettings appSettings,
    AppRepository appRepository,
    Person? person,
  ) {
    final hasAnyActivity = context.select<SetupActivityAnalysisService, bool>(
      (service) => service.hasAnyActivity,
    );
    final setupActivityCounts = context.select<SetupActivityAnalysisService, Map<String, int>>(
      (service) => service.setupActivityCounts,
    );
    if (hasAnyActivity) {
      unawaited(context.read<SetupActivityAnalysisService>().getSetupActivityCounts());
    }

    final personAdjustments = person?.adjustments ?? [];

    // Every setup of this bike, newest first - independent of the global bike filter.
    final setupsUnsorted = appRepository.setups.values
        .where((s) => s.bike == widget.bikeId)
        .toList()
        .reversed
        .toList();

    // Rating scores derived from RatingEntries that resolve to each setup:
    // overall (0-10) and per-metric sub-scores (0-10).
    _ratingScores = {for (final s in setupsUnsorted) s.id: appRepository.scoreForSetup(s.id)};
    _metricScores = {for (final s in setupsUnsorted) s.id: appRepository.metricScoresForSetup(s.id)};

    final allRatingMetrics = appRepository.allRatingMetricsById;
    final ratingMetricIds = <String>{for (final m in _metricScores.values) ...m.keys};
    _ratingMetricNames = {
      for (final id in ratingMetricIds) id: allRatingMetrics[id]?.adjustment.name ?? id,
    };

    // Built-in columns available under the current feature flags; the bike is fixed here.
    final availableSetupColumns = SetupColumn.values.where(
      (column) => switch (column) {
        SetupColumn.bike => false,
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

    final bikes = appRepository.bikes;
    final setups = _sortSetupsByColumn(
      setups: setupsUnsorted,
      personAdjustments: personAdjustments,
      bikes: bikes,
      setupActivityCounts: setupActivityCounts,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: "Setup History",
          infoText:
              "All setups of this bike. Add or remove columns via the Columns button, or long-press a column "
              "header to remove it. Green values are new (no prior value), orange values have changed from the "
              "previous setup.",
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              avatar: const Icon(Icons.view_column_outlined),
              showCheckmark: false,
              label: const Text("Columns"),
              selected: activeColumns.isNotEmpty,
              onSelected: (bool newValue) async {
                await showColumnFilterSheet(
                  context: context,
                  columns: orderedColumns,
                  columnLabel: (TableColumn c) => _columnLabel(c, personAdjustments),
                  onColumnStatusChanged: () => setState(() {}), // TableColumn.active is changed
                );
              },
            ),
          ),
        ),
        if (setups.isEmpty)
          const EmptyStatePlaceholder(
            icon: Icons.history_rounded,
            title: 'No setups yet',
            subtitle: 'No setups reference this bike',
          )
        else if (activeColumns.isEmpty)
          const EmptyStatePlaceholder(
            icon: Icons.view_column_outlined,
            title: 'No columns',
            subtitle: 'Select a column to display the table',
          )
        else ...[
          SetupTable(
            activeColumns: activeColumns,
            setups: setups,
            sortAscending: _sortAscending,
            sortColumn: _sortColumn,
            bikes: bikes,
            setupActivityCounts: setupActivityCounts,
            valueFor: _rawValue,
            columnLabel: (column) => _columnLabel(column, personAdjustments),
            onSort: (column, ascending) {
              setState(() {
                _sortAscending = ascending;
                _sortColumn = column;
              });
            },
            onColumnRemoved: (column) {
              setState(() => column.active = false);
            },
          ),
          if (activeColumns.any((c) => c is PersonAttributeColumn)) const InitialChangedValueLegend(),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();

    final bike = appRepository.bikes[widget.bikeId];
    if (bike == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const SafeArea(
          child: EmptyStatePlaceholder.error(
            title: "Bike not found",
            subtitle: "This bike was deleted or is no longer available.",
          ),
        ),
      );
    }

    final person = appRepository.persons[bike.person];
    final stravaGear = appRepository.stravaGears[bike.stravaGear];
    final components = appRepository.components.values.where((c) => c.bike == bike.id);
    final stats = appRepository.bikeStats[widget.bikeId] ?? ComponentStats.zero();
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          spacing: 8,
          children: [
            const Icon(Bike.iconData),
            Expanded(
              child: Text(bike.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => BikeActions.editBike(context, bike: bike),
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
                ComponentStatsCard(componentStats: stats),
                const Divider(height: 1),
              ],

              if (appSettings.enablePerson)
                ListTile(
                  leading: bike.person != null
                      ? const Icon(Person.iconData)
                      : const Icon(Icons.person_off),
                  title: Text(
                    person?.name ?? (bike.person == null ? "No bike owner person specified." : "PERSON NOT FOUND"),
                    style: TextStyle(
                      color: bike.person == null || person != null
                          ? null
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  dense: true,
                ),
              

              if (appSettings.enableStrava && subscriptionService.hasStravaEntitlement)
                ListTile(
                  leading: Badge(
                    label: const Icon(SimpleIcons.strava, size: 11),
                    backgroundColor: Colors.transparent,
                    child: bike.stravaGear != null
                        ? Icon(Icons.link, color: appRepository.stravaGears.containsKey(bike.stravaGear) ? null : Theme.of(context).colorScheme.error)
                        : const Icon(Icons.link_off),
                  ),                
                  title: Text(
                    stravaGear?.name ?? (bike.stravaGear == null ? "No Strava Gear linked to this bike." : "STRAVA GEAR NOT FOUND"),
                    style: TextStyle(
                      color: bike.stravaGear == null || stravaGear != null
                          ? null
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  dense: true,
                ),

              if (bike.notes != null)
                ListTile(
                  leading: const Icon(Icons.notes),
                  titleAlignment: ListTileTitleAlignment.titleHeight,
                  title: NotesText(bike.notes!, maxLines: 10),
                  dense: true,
                ),

              if ((appSettings.enableStrava && subscriptionService.hasStravaEntitlement) || appSettings.enablePerson || bike.notes != null)
                const Divider(height: 1),

              if (appSettings.enableTask) ...[
                OpenTasksTile.bike(bikeId: widget.bikeId),
                const Divider(height: 1),
              ],

              ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                leading: const Icon(Component.iconData),
                title: Text(
                  "Components (${components.length})",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                children: [
                  if (components.isEmpty) ...[
                    EmptyStatePlaceholder2(
                      iconData: Component.iconData,
                      title: 'No components yet',
                      subtitle: 'Add a component to this bike',
                      onTap: () => ComponentActions.addComponent(context, initialBike: widget.bikeId),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => ComponentActions.addComponent(context, initialBike: widget.bikeId),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Component'),
                      ),
                    ),
                  ] else ...[
                    ...components.map(
                      (component) => ComponentListCard(
                        component: component,
                        showCurrentAdjustmentValues: false,
                      ),
                    ),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => ComponentActions.addComponent(context, initialBike: widget.bikeId),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Component'),
                      ),
                    ),
                  ],
                ],
              ),
              const Divider(height: 1),
              _setupHistory(context, appSettings, appRepository, person),
              if (kDebugMode) ...[
                const Divider(height: 1),
                InstallationTimelineTable(
                  bikeId: widget.bikeId,
                  allComponents: appRepository.components.values.toList(),
                ),
              ]
            ],
          ),
        )
      ),
    );
  }
}
