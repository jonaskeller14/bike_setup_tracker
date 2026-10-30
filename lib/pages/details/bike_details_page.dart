import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../icons/simple_icons.dart';
import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/attachment.dart';
import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../models/feedback/test_session.dart';
import '../../models/person.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../services/bike_adjustment_column_service.dart';
import '../../services/setup_activity_analysis_service.dart';
import '../../services/subscription_service.dart';
import '../../utils/bike_actions.dart';
import '../../utils/component_actions.dart';
import '../../utils/filter_actions.dart';
import '../../utils/table_column.dart';
import '../../utils/table_column_comparator.dart';
import '../../utils/test_session_actions.dart';
import '../../widgets/attachment_row.dart';
import '../../widgets/chips/filter_sheet_chip.dart';
import '../../widgets/display_data/component_stats_card.dart';
import '../../widgets/display_data/setup_histogram_chart.dart';
import '../../widgets/display_data/setup_line_chart.dart';
import '../../widgets/display_data/setup_radial_chart.dart';
import '../../widgets/display_data/setup_table.dart';
import '../../widgets/empty_state_placeholder.dart';
import '../../widgets/empty_state_placeholder2.dart';
import '../../widgets/initial_changed_value_legend.dart';
import '../../widgets/installation_timeline_table.dart';
import '../../widgets/items/component_list_card.dart';
import '../../widgets/items/test_session_tile.dart';
import '../../widgets/notes_text.dart';
import '../../widgets/open_tasks_tile.dart';
import '../../widgets/sheets/column_filter.dart';
import '../../widgets/sheets/set_initial_stats.dart' as initial_stats;
import '../../widgets/sheets/strava.dart';
import '../../widgets/sheets/test_session_sheet.dart';
import '../../widgets/text/section_title.dart';

class BikeDetailsPage extends StatefulWidget {
  final String bikeId;

  const BikeDetailsPage({super.key, required this.bikeId});

  @override
  State<BikeDetailsPage> createState() => _BikeDetailsPageState();
}

class _BikeDetailsPageState extends State<BikeDetailsPage> {
  static const int _defaultSelectedSetupCount = 3;

  bool _sortAscending = true;
  TableColumn? _sortColumn;
  TableColumn? _selectedLineChartColumn;
  TableColumn? _selectedHistogramColumn;
  Set<String>? _selectedSetupIds;
  Set<TableColumn> _columns = {};

  BikeAdjustmentProjection? _projection;
  // Columns whose value changes at least once; these are active by default.
  Set<BikeAdjustmentColumnKey> _changingColumns = {};
  Object? _projectionSource;

  // Confident setup ranks only, as on the setup tiles.
  Map<String, int> _ranks = {};

  // Setup columns are rendered by the table itself; only data-driven columns resolve to a value here.
  AdjustmentValue? _rawValue(Setup setup, TableColumn column) => switch (column) {
    PersonAttributeColumn(:final adjustmentId) => setup.personAdjustmentValues[adjustmentId],
    BikeAdjustmentColumn(:final key) => _projection?.valueFor(setup, key),
    SetupRankColumn() => switch (_ranks[setup.id]) {
      final rank? => StepValue(rank),
      null => null,
    },
    ComponentAdjustmentColumn() || SetupTableColumn() => null,
  };

  /// Rebuilds the projection only when the repository replaced its data.
  BikeAdjustmentProjection _projectionFor(AppRepository appRepository) {
    final source = (appRepository.setups, appRepository.components, appRepository.componentHierarchy, appRepository.setupHistory);
    if (_projection case final projection? when source == _projectionSource) return projection;

    final projection = BikeAdjustmentColumnService.build(
      bikeId: widget.bikeId,
      setups: appRepository.setups.values,
      components: appRepository.components.values,
      hierarchy: appRepository.componentHierarchy,
      history: appRepository.setupHistory,
    );
    _projectionSource = source;
    _changingColumns = {
      for (final column in projection.columns)
        if (projection.hasChanges(column, appRepository.setups.values)) column,
    };
    return _projection = projection;
  }

  /// One row per lane component: name, first setup, dash, last setup it was present at.
  /// Components still on this bike end with "now".
  List<List<String>> _laneHistory(SlotLane lane, AppRepository appRepository, String dateFormat) {
    final format = DateFormat(dateFormat);
    return lane.members.map((member) {
      final name = member.component.name;
      final dates = member.setupIds.map((id) => appRepository.setups[id]?.datetimeLocal).nonNulls.sorted();
      if (dates.isEmpty) return [name, '', '', ''];
      final first = format.format(dates.first);
      final last = appRepository.componentHierarchy.currentBike(member.component.id) == widget.bikeId
          ? context.l10n.bikeDetailsLaneNow
          : format.format(dates.last);
      return first == last ? [name, first, '', ''] : [name, first, '–', last];
    }).toList();
  }

  String _laneHistoryText(List<List<String>> rows) => rows
      .map((row) {
        final dates = row.skip(1).where((cell) => cell.isNotEmpty).join(' ');
        return dates.isEmpty ? row.first : '${row.first}: $dates';
      })
      .join('\n');

  String _columnLabel(TableColumn column, Iterable<Adjustment> personAdjustments) {
    return switch (column) {
      SetupTableColumn(column: final setupColumn) => setupColumn.label(context.l10n),
      PersonAttributeColumn(:final adjustmentId) =>
        personAdjustments.firstWhereOrNull((a) => a.id == adjustmentId)?.name ?? adjustmentId,
      ComponentAdjustmentColumn(:final adjustmentId) => adjustmentId,
      BikeAdjustmentColumn(:final key) => _projection?.columnLabel(key, context.l10n) ?? key.adjustment.name,
      SetupRankColumn() => context.l10n.setupColumnRank,
    };
  }

  List<Setup> _sortSetupsByColumn({
    required List<Setup> setups,
    required Iterable<Adjustment> personAdjustments,
    required Map<String, Bike> bikes,
    required Map<String, TestSession> testSessions,
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
      testSessions: testSessions,
      setupActivityCounts: setupActivityCounts,
      bikeAdjustmentFor: (column) => _projection?.adjustmentFor(column.key),
    );
    if (comparator == null) return setups;

    setups.sort(_sortAscending ? comparator : (a, b) => comparator(b, a));
    return setups;
  }

  void _removeColumn(TableColumn column) {
    setState(() {
      column.active = false;
      if (_selectedLineChartColumn == column) _selectedLineChartColumn = null;
      if (_selectedHistogramColumn == column) _selectedHistogramColumn = null;
    });
  }

  Widget _testSessions(BuildContext context, AppRepository appRepository, Bike bike) {
    final l10n = context.l10n;
    final sessions = appRepository.testSessions.values
        .where((session) => session.bike == bike.id)
        .sorted((a, b) => b.startedAtUTC.compareTo(a.startedAtUTC));

    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      leading: const Icon(TestSession.iconData),
      title: Text(
        l10n.bikeDetailsTestSessionsTitle(sessions.length),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      children: [
        if (sessions.isEmpty) ...[
          EmptyStatePlaceholder2(
            iconData: TestSession.iconData,
            title: l10n.bikeDetailsNoTestSessionsTitle,
            subtitle: l10n.bikeDetailsNoTestSessionsSubtitle,
            onTap: () => unawaited(TestSessionActions.startSession(context, initialBike: bike)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => unawaited(TestSessionActions.startSession(context, initialBike: bike)),
              icon: const Icon(Icons.add),
              label: Text(l10n.startTestSession),
            ),
          ),
        ] else ...[
          for (final session in sessions)
            Card(
              key: ValueKey(session.id),
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              clipBehavior: Clip.antiAlias, // Borderradius for InkWell
              child: TestSessionTile(
                session: session,
                onTap: () => unawaited(showTestSessionSheet(context: context, sessionId: session.id)),
              ),
            ),
          Center(
            child: TextButton.icon(
              onPressed: () => unawaited(TestSessionActions.startSession(context, initialBike: bike)),
              icon: const Icon(Icons.add),
              label: Text(l10n.startTestSession),
            ),
          ),
        ],
      ],
    );
  }

  Widget _setupHistory(
    BuildContext context,
    AppSettings appSettings,
    AppRepository appRepository,
    SubscriptionService subscriptionService,
    Person? person,
  ) {
    final hasAnyActivity = context.select<SetupActivityAnalysisService, bool>(
      (service) => service.hasAnyActivity,
    );
    final setupActivityCounts = context.select<SetupActivityAnalysisService, Map<String, int>>(
      (service) => service.setupActivityCounts,
    );
    final setupActivityCountsLoaded = context.select<SetupActivityAnalysisService, bool>(
      (service) => service.setupActivityCountsLoaded,
    );
    final setupActivityCountsFailed = context.select<SetupActivityAnalysisService, bool>(
      (service) => service.setupActivityCountsFailed,
    );
    if (hasAnyActivity) {
      unawaited(context.read<SetupActivityAnalysisService>().getSetupActivityCounts());
    }

    final l10n = context.l10n;
    final personAdjustments = person?.adjustments ?? [];
    final projection = _projectionFor(appRepository);

    // Every setup of this bike - independent of the global bike filter.
    final bikeSetups = appRepository.setups.values.where((s) => s.bike == widget.bikeId).toList();
    // Newest first, narrowed by the tag and bookmark filters.
    final setupsUnsorted = bikeSetups
        .where((s) => appRepository.filters.setup.matches(s, testSessions: appRepository.testSessions))
        .toList()
        .reversed
        .toList();

    _ranks = {
      if (appSettings.enableRating)
        for (final s in bikeSetups)
          if (appRepository.rankFor(s.id) case final rank? when rank.isConfident) s.id: rank.rank,
    };

    // Built-in columns available under the current feature flags; the bike is fixed here.
    final availableSetupColumns = SetupColumn.values.where(
      (column) => switch (column) {
        SetupColumn.bike => false,
        SetupColumn.tags => appSettings.enableSetupTags,
        SetupColumn.bookmarked => appSettings.enableSetupBookmark,
        SetupColumn.activities => hasAnyActivity,
        SetupColumn.testSession => appSettings.enableRating,
        _ => true,
      },
    );

    // Rebuilt every frame so columns always appear in canonical order; lookup()
    // carries over the 'active' state of the columns that already existed.
    final previousColumns = _columns;
    T retained<T extends TableColumn>(T column) => previousColumns.lookup(column) as T? ?? column;

    _columns = {
      for (final column in availableSetupColumns) retained(SetupTableColumn(column, active: column.defaultActive)),
      for (final key in projection.columns) retained(BikeAdjustmentColumn(key, active: _changingColumns.contains(key))),
      if (appSettings.enablePerson && person != null)
        for (final adjustment in personAdjustments) retained(PersonAttributeColumn(adjustment.id, active: false)),
      if (appSettings.enableRating) retained(SetupRankColumn(active: false)),
    };

    final orderedColumns = _columns.toList();
    final activeColumns = orderedColumns.where((c) => c.active).toList();
    if (!activeColumns.contains(_sortColumn)) _sortColumn = null;

    bool isDangling(Setup setup, TableColumn column) => switch (column) {
      PersonAttributeColumn() => setup.person != person?.id,
      BikeAdjustmentColumn(:final key) => projection.isDangling(setup, key),
      _ => false,
    };
    final hasDanglingValues = activeColumns.any(
      (column) => setupsUnsorted.any((setup) => _rawValue(setup, column) != null && isDangling(setup, column)),
    );

    final bikes = appRepository.bikes;
    final setups = _sortSetupsByColumn(
      setups: setupsUnsorted,
      personAdjustments: personAdjustments,
      bikes: bikes,
      testSessions: appRepository.testSessions,
      setupActivityCounts: setupActivityCounts,
    );

    final selectedSetupIds = _selectedSetupIds ??= (setups.toList()..sort((a, b) => b.datetime.compareTo(a.datetime)))
        .take(_defaultSelectedSetupCount)
        .map((s) => s.id)
        .toSet();
    selectedSetupIds.removeWhere((id) => !setups.any((s) => s.id == id));
    final selectedSetups = setups.where((s) => selectedSetupIds.contains(s.id)).toList();

    final sortColumn = _sortColumn;
    final showDateAxisLabels =
        sortColumn == null || (sortColumn is SetupTableColumn && sortColumn.column == SetupColumn.date);
    Adjustment? adjustmentFor(TableColumn column) => adjustmentForColumn(
      column,
      const [],
      personAdjustments,
      bikeAdjustmentFor: (column) => projection.adjustmentFor(column.key),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: l10n.bikeDetailsSetupHistoryTitle,
          infoText: l10n.bikeDetailsSetupHistoryInfo + l10n.bikeDetailsMergedColumnsInfo,
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
                label: Text(l10n.columnsLabel),
                selected: activeColumns.isNotEmpty,
                onSelected: (bool newValue) async {
                  await showColumnFilterSheet(
                    context: context,
                    columns: orderedColumns,
                    columnLabel: (TableColumn c) => switch (c) {
                      // The lane is shown as the group header.
                      BikeAdjustmentColumn(:final key) => projection.adjustmentFor(key)?.name ?? key.adjustment.name,
                      _ => _columnLabel(c, personAdjustments),
                    },
                    columnGroup: (TableColumn c) => switch (c) {
                      BikeAdjustmentColumn(:final key) => switch (projection.laneOf(key)) {
                        final lane? => (
                          title: lane.label(context.l10n),
                          info: _laneHistory(lane, appRepository, appSettings.dateFormat),
                        ),
                        null => null,
                      },
                      _ => null,
                    },
                    onColumnStatusChanged: () => setState(() {}), // TableColumn.active is changed
                  );
                },
              ),
              if (appSettings.enableSetupTags || appSettings.enableSetupBookmark || appSettings.enableRating)
                FilterSheetChip.bikeDetailsPage,
            ],
          ),
        ),
        if (bikeSetups.isEmpty)
          EmptyStatePlaceholder(
            icon: Icons.history_rounded,
            title: l10n.noSetupsTitle,
            subtitle: l10n.bikeDetailsNoSetupsSubtitle,
          )
        else if (setups.isEmpty)
          EmptyStatePlaceholder(
            icon: Icons.filter_alt_off,
            title: l10n.bikeDetailsFilterEmptyTitle,
            subtitle: l10n.bikeDetailsFilterEmptySubtitle,
            actionLabel: l10n.clearFilters,
            actionIcon: Icons.filter_alt_off,
            onAction: () => FilterActions.clear(context, FilterSheetChip.bikeDetailsPage.sections),
          )
        else if (activeColumns.isEmpty)
          EmptyStatePlaceholder(
            icon: Icons.view_column_outlined,
            title: l10n.tableNoColumnsTitle,
            subtitle: l10n.tableNoColumnsSubtitle,
          )
        else ...[
          SetupTable(
            activeColumns: activeColumns,
            setups: setups,
            sortAscending: _sortAscending,
            sortColumn: _sortColumn,
            bikes: bikes,
            testSessions: appRepository.testSessions,
            setupHistory: appRepository.setupHistory,
            setupActivityCounts: setupActivityCounts,
            valueFor: _rawValue,
            isDangling: isDangling,
            previousValueFor: (setup, column) =>
                column is BikeAdjustmentColumn ? projection.previousValueFor(setup, column.key) : null,
            columnLabel: (column) => _columnLabel(column, personAdjustments),
            columnTooltip: (column) => switch (column) {
              BikeAdjustmentColumn(:final key) => switch (projection.laneOf(key)) {
                final lane? => _laneHistoryText(_laneHistory(lane, appRepository, appSettings.dateFormat)),
                null => null,
              },
              _ => null,
            },
            onSort: (column, ascending) {
              setState(() {
                _sortAscending = ascending;
                _sortColumn = column;
              });
            },
            onColumnRemoved: _removeColumn,
            selectedSetupIds: selectedSetupIds,
            onSelectAll: (selected) => setState(() {
              if (selected == true) {
                selectedSetupIds.addAll(setups.map((setup) => setup.id));
              } else {
                selectedSetupIds.clear();
              }
            }),
            onSetupSelected: (setup, selected) => setState(() {
              if (selected == true) {
                selectedSetupIds.add(setup.id);
              } else {
                selectedSetupIds.remove(setup.id);
              }
            }),
          ),
          if (activeColumns.any((c) => c is PersonAttributeColumn || c is BikeAdjustmentColumn))
            InitialChangedValueLegend(showDangling: hasDanglingValues),
        ],
        const SizedBox(height: 16),
        const Divider(height: 1),
        SectionTitle(
          title: l10n.chartLineTitle,
          infoText: l10n.bikeDetailsLineChartInfo,
        ),
        SetupLineChart(
          activeColumns: activeColumns,
          setups: setups,
          selectedSetups: selectedSetups,
          showDateAxisLabels: showDateAxisLabels,
          selectedLineChartColumn: _selectedLineChartColumn,
          valueFor: _rawValue,
          adjustmentFor: adjustmentFor,
          columnLabel: (column) => _columnLabel(column, personAdjustments),
          onSelectedColumnChanged: (column) {
            setState(() => _selectedLineChartColumn = column);
          },
          onColumnRemoved: _removeColumn,
        ),
        const Divider(height: 1),
        SectionTitle(
          title: l10n.chartRadialTitle,
          infoText: l10n.chartRadialInfo,
        ),
        SetupRadialChart(
          activeColumns: activeColumns,
          setups: setups,
          selectedSetups: selectedSetups,
          valueFor: _rawValue,
          adjustmentFor: adjustmentFor,
          columnLabel: (column) => _columnLabel(column, personAdjustments),
          onSetupRemoved: (setupId) {
            setState(() => selectedSetupIds.remove(setupId));
          },
        ),
        if (appSettings.enableStrava) ...[
          const Divider(height: 1),
          SectionTitle(
            title: l10n.chartHistogramTitle,
            infoText: l10n.bikeDetailsHistogramInfo,
          ),
          if (!subscriptionService.hasStravaEntitlement)
            EmptyStatePlaceholder(
              icon: Icons.lock_outline,
              title: l10n.chartHistogramLockedTitle,
              subtitle: l10n.chartHistogramLockedSubtitle,
              actionLabel: l10n.viewPlans,
              actionIcon: Icons.auto_awesome,
              onAction: () => showStravaSheet(context: context),
            )
          else
            SetupHistogramChart(
              activeColumns: activeColumns,
              setups: setups,
              setupActivityCounts: setupActivityCounts,
              hasAnyActivity: hasAnyActivity,
              activityCountsLoaded: setupActivityCountsLoaded,
              activityCountsFailed: setupActivityCountsFailed,
              selectedHistogramColumn: _selectedHistogramColumn,
              valueFor: _rawValue,
              adjustmentFor: adjustmentFor,
              columnLabel: (column) => _columnLabel(column, personAdjustments),
              onSelectedColumnChanged: (column) {
                setState(() => _selectedHistogramColumn = column);
              },
              onColumnRemoved: _removeColumn,
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();
    final l10n = context.l10n;

    final bike = appRepository.bikes[widget.bikeId];
    if (bike == null) {
      return Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: EmptyStatePlaceholder.error(
            title: l10n.bikeDetailsNotFoundTitle,
            subtitle: l10n.bikeDetailsNotFoundSubtitle,
          ),
        ),
      );
    }

    final person = appRepository.persons[bike.person];
    final stravaGear = appRepository.stravaGears[bike.stravaGear];
    final components = appRepository.components.values.where(
      (component) => appRepository.componentHierarchy.currentBike(component.id) == bike.id,
    );
    final stats = appRepository.bikeStats[widget.bikeId] ?? bike.initialStats;
    final initialStatsSummary = initial_stats.initialStatsSummary(bike.initialStats, appSettings, l10n);
    final attachments = appSettings.enableAttachments ? bike.attachments : const <Attachment>[];

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
                    person?.name ?? (bike.person == null ? l10n.bikeDetailsNoRider : l10n.riderNotFound),
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
                    stravaGear?.name ?? (bike.stravaGear == null ? l10n.bikeDetailsNoStravaGear : l10n.bikeDetailsStravaGearNotFound),
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

              if (initialStatsSummary != null)
                ListTile(
                  leading: const Icon(Icons.start),
                  title: Text(l10n.initialStatsChip(initialStatsSummary)),
                  dense: true,
                ),

              if (attachments.isNotEmpty) AttachmentRow(attachments: attachments),

              if ((appSettings.enableStrava && subscriptionService.hasStravaEntitlement) || appSettings.enablePerson || bike.notes != null || initialStatsSummary != null || attachments.isNotEmpty)
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
                  l10n.bikeDetailsComponentsTitle(components.length),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                children: [
                  if (components.isEmpty) ...[
                    EmptyStatePlaceholder2(
                      iconData: Component.iconData,
                      title: l10n.noComponentsTitle,
                      subtitle: l10n.bikeDetailsNoComponentsSubtitle,
                      onTap: () => ComponentActions.addComponent(context, initialBike: widget.bikeId),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => ComponentActions.addComponent(context, initialBike: widget.bikeId),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.addComponent),
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
                        label: Text(l10n.addComponent),
                      ),
                    ),
                  ],
                ],
              ),
              const Divider(height: 1),
              if (appSettings.enableRating) ...[
                _testSessions(context, appRepository, bike),
                const Divider(height: 1),
              ],
              _setupHistory(context, appSettings, appRepository, subscriptionService, person),
              if (appSettings.enableInstallationTimeline) ...[
                const Divider(height: 1),
                InstallationTimelineTable(
                  bikeId: widget.bikeId,
                  componentHierarchy: appRepository.componentHierarchy,
                ),
              ]
            ],
          ),
        )
      ),
    );
  }
}
