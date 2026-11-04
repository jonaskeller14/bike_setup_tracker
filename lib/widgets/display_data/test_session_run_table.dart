import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/enum_labels.dart';
import '../../l10n/feedback_text.dart';
import '../../l10n/l10n.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/feedback/feedback_summary.dart';
import '../../models/feedback/ride_feedback.dart';
import '../../models/feedback/test_session.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../services/bike_adjustment_column_service.dart';
import '../../services/test_session_service.dart';
import '../../utils/table_column.dart';
import '../../utils/table_column_comparator.dart';
import '../empty_state_placeholder.dart';
import '../initial_changed_value_legend.dart';
import '../sheets/column_filter.dart';
import 'setup_table_cells.dart';

/// The runs of a session side by side, oldest first: one read-only row per run
/// with its values and what its feedbacks say.
class TestSessionRunTable extends StatefulWidget {
  final TestSession session;

  const TestSessionRunTable({super.key, required this.session});

  @override
  State<TestSessionRunTable> createState() => _TestSessionRunTableState();
}

class _TestSessionRunTableState extends State<TestSessionRunTable> {
  bool _sortAscending = true;
  SelectableColumn? _sortColumn;
  Set<SelectableColumn> _columns = {};

  BikeAdjustmentProjection? _projection;
  Object? _projectionSource;

  @override
  void didUpdateWidget(covariant TestSessionRunTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // An edited session tests something else, so the preselection starts over.
    if (!listEquals(oldWidget.session.adjustmentIds, widget.session.adjustmentIds)) _columns = {};
  }

  /// Rebuilds the projection only when the repository replaced its data.
  BikeAdjustmentProjection _projectionFor(AppRepository appRepository) {
    final source = (
      appRepository.setups,
      appRepository.components,
      appRepository.componentHierarchy,
      appRepository.setupHistory,
    );
    if (_projection case final projection? when source == _projectionSource) return projection;

    _projectionSource = source;
    return _projection = BikeAdjustmentColumnService.build(
      bikeId: widget.session.bike,
      setups: appRepository.setups.values,
      components: appRepository.components.values,
      hierarchy: appRepository.componentHierarchy,
      history: appRepository.setupHistory,
    );
  }

  /// Name and feedback columns plus what the session tests. For a Compare
  /// session, [TestSession.adjustmentIds] holds what its candidates differ in.
  Set<SelectableColumn> _buildColumns(
    AppSettings appSettings,
    BikeAdjustmentProjection projection,
    List<Adjustment> riderAdjustments,
  ) {
    final previous = _columns;
    SelectableColumn retained(SelectableColumn column) => previous.lookup(column) ?? column;
    final sessionIds = widget.session.adjustmentIds.toSet();
    final sessionColumns = TestSessionService.columnsOf(sessionIds, projection).toSet();

    return {
      for (final column in SetupColumn.values.where((column) => _isAvailable(column, appSettings)))
        retained(SetupTableColumn(column, active: column == SetupColumn.name)),
      for (final key in projection.columns) retained(BikeAdjustmentColumn(key, active: sessionColumns.contains(key))),
      for (final adjustment in riderAdjustments)
        retained(PersonAttributeColumn(adjustment.id, active: sessionIds.contains(adjustment.id))),
      if (appSettings.enableRating) retained(SetupRankColumn(active: false)),
      for (final field in RunFeedbackField.values) retained(RunFeedbackColumn(field, active: true)),
    };
  }

  bool _isAvailable(SetupColumn column, AppSettings appSettings) => switch (column) {
    SetupColumn.tags => appSettings.enableSetupTags,
    SetupColumn.bookmarked => appSettings.enableSetupBookmark,
    // All runs share the bike and the session; activity counts stay with the details pages.
    SetupColumn.bike || SetupColumn.testSession || SetupColumn.activities => false,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final l10n = context.l10n;

    final projection = _projectionFor(appRepository);
    final rider = appRepository.persons[appRepository.bikes[widget.session.bike]?.person];
    final riderAdjustments = (appSettings.enablePerson ? rider?.adjustments : null) ?? const <Adjustment>[];

    _columns = _buildColumns(appSettings, projection, riderAdjustments);
    final orderedColumns = _columns.toList();
    final activeColumns = orderedColumns.where((column) => column.active).toList();
    if (!activeColumns.contains(_sortColumn)) _sortColumn = null;

    AdjustmentValue? valueFor(Setup run, TableColumn column) => switch (column) {
      BikeAdjustmentColumn(:final key) => projection.valueFor(run, key),
      PersonAttributeColumn(:final adjustmentId) => run.personAdjustmentValues[adjustmentId],
      SetupRankColumn() => switch (appRepository.rankFor(run.id)) {
        final rank? when rank.isConfident => StepValue(rank.rank),
        _ => null,
      },
      ComponentAdjustmentColumn() || SetupTableColumn() => null,
    };

    bool isDangling(Setup run, TableColumn column) => switch (column) {
      BikeAdjustmentColumn(:final key) => projection.isDangling(run, key),
      PersonAttributeColumn() => run.person != rider?.id,
      _ => false,
    };

    String labelOf(SelectableColumn column) => switch (column) {
      RunFeedbackColumn(field: RunFeedbackField.issues) => l10n.testSessionRunTableIssues,
      RunFeedbackColumn(field: RunFeedbackField.evaluation) => l10n.testSessionRunTableEvaluation,
      RunFeedbackColumn(field: RunFeedbackField.notes) => l10n.testSessionRunTableNotes,
      SetupTableColumn(column: final setupColumn) => setupColumn.label(l10n),
      BikeAdjustmentColumn(:final key) => projection.columnLabel(key, l10n),
      PersonAttributeColumn(:final adjustmentId) =>
        riderAdjustments.firstWhereOrNull((adjustment) => adjustment.id == adjustmentId)?.name ?? adjustmentId,
      ComponentAdjustmentColumn(:final adjustmentId) => adjustmentId,
      SetupRankColumn() => l10n.setupColumnRank,
    };

    Comparator<Setup>? comparatorFor(SelectableColumn column) => switch (column) {
      RunFeedbackColumn(:final field) => _feedbackComparator(field, appRepository),
      TableColumn() => tableColumnComparator(
        column,
        l10n,
        valueFor: valueFor,
        componentAdjustments: const [],
        personAdjustments: riderAdjustments,
        bikes: appRepository.bikes,
        setupActivityCounts: const {},
        testSessions: appRepository.testSessions,
        bikeAdjustmentFor: (column) => projection.adjustmentFor(column.key),
      ),
    };

    DataCell cellFor(Setup run, SelectableColumn column) => switch (column) {
      RunFeedbackColumn(:final field) => _feedbackCell(
        _feedbackText(field, _feedbacksOf(run, appRepository), appRepository, l10n),
      ),
      SetupTableColumn(column: final setupColumn) => setupColumnCell(
        context,
        run,
        setupColumn,
        appSettings: appSettings,
        bikes: appRepository.bikes,
        testSessions: appRepository.testSessions,
        setupActivityCounts: const {},
      ),
      BikeAdjustmentColumn(:final key) => adjustmentValueCell(
        context,
        value: valueFor(run, column),
        previousValue: projection.previousValueFor(run, key),
        isDangling: isDangling(run, column),
      ),
      PersonAttributeColumn(:final adjustmentId) => adjustmentValueCell(
        context,
        value: valueFor(run, column),
        previousValue: appRepository.setupHistory.previousPersonValuesOf(run.id)[adjustmentId],
        isDangling: isDangling(run, column),
      ),
      SetupRankColumn() => DataCell(
        Center(
          child: Text(switch (valueFor(run, column)?.asNum) {
            final rank? => '#$rank',
            null => '-',
          }),
        ),
      ),
      // A bike's component adjustments are merged into its bike columns.
      ComponentAdjustmentColumn() => DataCell.empty,
    };

    final runs = appRepository.setupsInSession(widget.session.id);
    if (_sortColumn case final sortColumn?) {
      if (comparatorFor(sortColumn) case final comparator?) {
        runs.sort(_sortAscending ? comparator : (a, b) => comparator(b, a));
      }
    }

    final showLegend = activeColumns.any((column) => column is BikeAdjustmentColumn || column is PersonAttributeColumn);
    final hasDanglingValues = activeColumns.whereType<TableColumn>().any(
      (column) => runs.any((run) => valueFor(run, column) != null && isDangling(run, column)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilterChip(
            avatar: const Icon(Icons.view_column_outlined),
            showCheckmark: false,
            label: Text(l10n.columnsLabel),
            selected: activeColumns.isNotEmpty,
            onSelected: (_) => unawaited(
              showColumnFilterSheet<SelectableColumn>(
                context: context,
                columns: orderedColumns,
                columnLabel: (column) => switch (column) {
                  // The lane is shown as the group header.
                  BikeAdjustmentColumn(:final key) => projection.adjustmentFor(key)?.name ?? key.adjustment.name,
                  _ => labelOf(column),
                },
                columnGroup: (column) => switch (column) {
                  BikeAdjustmentColumn(:final key) => switch (projection.laneOf(key)) {
                    final lane? => (title: lane.label(l10n), info: null),
                    null => null,
                  },
                  _ => null,
                },
                onColumnStatusChanged: () => setState(() {}), // SelectableColumn.active is changed
              ),
            ),
          ),
        ),
        if (activeColumns.isEmpty)
          EmptyStatePlaceholder(
            icon: Icons.view_column_outlined,
            title: l10n.tableNoColumnsTitle,
            subtitle: l10n.tableNoColumnsSubtitle,
          )
        else ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DataTable(
              horizontalMargin: 8,
              columnSpacing: 20,
              // A cell holds one line per verdict or feedback.
              dataRowMaxHeight: double.infinity,
              sortAscending: _sortAscending,
              sortColumnIndex: _sortColumn == null ? null : activeColumns.indexOf(_sortColumn!),
              columns: [
                for (final column in activeColumns)
                  DataColumn(
                    label: SortableColumnLabel(
                      label: labelOf(column),
                      isSorted: _sortColumn == column,
                      sortAscending: _sortAscending,
                      onSort: () => setState(() {
                        _sortAscending = _sortColumn == column ? !_sortAscending : true;
                        _sortColumn = column;
                      }),
                      onRemove: () => setState(() => column.active = false),
                    ),
                  ),
              ],
              rows: [
                for (final run in runs)
                  DataRow(
                    key: ValueKey(run.id),
                    cells: [for (final column in activeColumns) cellFor(run, column)],
                  ),
              ],
            ),
          ),
          if (showLegend) InitialChangedValueLegend(showDangling: hasDanglingValues),
        ],
      ],
    );
  }
}

/// Oldest first, so a cell's lines follow the order they were given in.
List<RideFeedback> _feedbacksOf(Setup run, AppRepository appRepository) =>
    appRepository.feedbacksForSetup(run.id).reversed.toList();

/// Each feedback's issues or notes on a line of their own, or each comparison's
/// verdict.
String _feedbackText(
  RunFeedbackField field,
  List<RideFeedback> feedbacks,
  AppRepository appRepository,
  AppLocalizations l10n,
) => switch (field) {
  RunFeedbackField.issues =>
    feedbacks.map((feedback) => feedback.issuesSummaryText(l10n, separator: ', ')).nonNulls.join('\n'),
  RunFeedbackField.evaluation =>
    feedbacks.expand((feedback) => feedback.verdicts(appRepository.setups, l10n)).join('\n'),
  RunFeedbackField.notes => _notesText(feedbacks),
};

String _notesText(List<RideFeedback> feedbacks) =>
    feedbacks.map((feedback) => feedback.notes?.trim()).nonNulls.where((notes) => notes.isNotEmpty).join('\n');

DataCell _feedbackCell(String text) => DataCell(
  Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Text(text.isEmpty ? '-' : text),
    ),
  ),
);

/// Ascending puts the best run first and the runs without an answer last, like
/// the rank column: the fewest issues, the best mean verdict. Notes have no
/// best, so they sort alphabetically.
Comparator<Setup> _feedbackComparator(RunFeedbackField field, AppRepository appRepository) {
  Comparator<Setup> byScore(double Function(List<RideFeedback> feedbacks) score) =>
      (a, b) => score(_feedbacksOf(a, appRepository)).compareTo(score(_feedbacksOf(b, appRepository)));

  return switch (field) {
    RunFeedbackField.issues => byScore((feedbacks) {
      final answered = feedbacks.where((feedback) => feedback.nothingStoodOut || feedback.orderedIssues.isNotEmpty);
      return answered.isEmpty
          ? double.infinity
          : answered.map((feedback) => feedback.orderedIssues.length).sum.toDouble();
    }),
    RunFeedbackField.evaluation => byScore((feedbacks) {
      final outcomes = [
        for (final feedback in feedbacks)
          for (final comparison in feedback.overallComparisons(appRepository.setups)) comparison.outcome,
      ];
      return outcomes.isEmpty ? double.infinity : -outcomes.average;
    }),
    RunFeedbackField.notes => (a, b) {
      final notesA = _notesText(_feedbacksOf(a, appRepository));
      final notesB = _notesText(_feedbacksOf(b, appRepository));
      if (notesA.isEmpty != notesB.isEmpty) return notesA.isEmpty ? 1 : -1;
      return notesA.compareTo(notesB);
    },
  };
}
