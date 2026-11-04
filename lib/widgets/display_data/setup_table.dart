import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/feedback/test_session.dart';
import '../../models/setup.dart';
import '../../models/setup_history.dart';
import '../../utils/automation_ids.dart';
import '../../utils/table_column.dart';
import 'setup_table_cells.dart';

class SetupTable extends StatefulWidget {
  final List<TableColumn> activeColumns;
  final List<Setup> setups;
  final Set<String>? selectedSetupIds;
  final bool sortAscending;
  final TableColumn? sortColumn;
  final Map<String, Bike> bikes;
  final Map<String, TestSession> testSessions;
  final SetupHistory setupHistory;
  final Map<String, int> setupActivityCounts;
  final AdjustmentValue? Function(Setup setup, TableColumn column) valueFor;
  final bool Function(Setup setup, TableColumn column)? isDangling;
  final AdjustmentValue? Function(Setup setup, TableColumn column)? previousValueFor;
  final String Function(TableColumn column) columnLabel;
  final String? Function(TableColumn column)? columnTooltip;
  final void Function(TableColumn column, bool ascending) onSort;
  final ValueChanged<TableColumn> onColumnRemoved;
  final ValueChanged<bool?>? onSelectAll;
  final void Function(Setup setup, bool? selected)? onSetupSelected;

  const SetupTable({
    super.key,
    required this.activeColumns,
    required this.setups,
    required this.sortAscending,
    required this.sortColumn,
    required this.bikes,
    required this.setupHistory,
    required this.setupActivityCounts,
    required this.valueFor,
    required this.columnLabel,
    required this.onSort,
    required this.onColumnRemoved,
    this.testSessions = const {},
    this.isDangling,
    this.previousValueFor,
    this.columnTooltip,
    this.selectedSetupIds,
    this.onSelectAll,
    this.onSetupSelected,
  }) : assert(
         (selectedSetupIds == null) == (onSelectAll == null) &&
             (selectedSetupIds == null) == (onSetupSelected == null),
         'Row selection needs selectedSetupIds, onSelectAll and onSetupSelected together',
       );

  @override
  State<SetupTable> createState() => _SetupTableState();
}

class _SetupTableState extends State<SetupTable> {
  int _rowsPerPage = 5;

  int _defaultRowsPerPage(int setupCount) {
    if (setupCount == 0) return 1;
    return setupCount < 5 ? setupCount : 5;
  }

  List<int> _availableRowsPerPage(int setupCount) {
    if (setupCount <= 5) return [_defaultRowsPerPage(setupCount)];

    return [
      5,
      if (setupCount > 10) 10,
      if (setupCount > 20) 20,
      if (setupCount > 50) 50 else setupCount,
    ];
  }

  @override
  void initState() {
    super.initState();
    _rowsPerPage = _defaultRowsPerPage(widget.setups.length);
  }

  @override
  void didUpdateWidget(covariant SetupTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final availableRowsPerPage = _availableRowsPerPage(widget.setups.length);
    if (!availableRowsPerPage.contains(_rowsPerPage)) {
      _rowsPerPage = _defaultRowsPerPage(widget.setups.length);
    }
  }

  bool get _selectable => widget.selectedSetupIds != null;

  bool get _allSetupsSelected =>
      widget.setups.every((setup) => widget.selectedSetupIds!.contains(setup.id));

  bool? get _selectAllValue {
    final selectedCount = widget.setups.where((setup) => widget.selectedSetupIds!.contains(setup.id)).length;
    if (selectedCount == 0) return false;
    if (selectedCount == widget.setups.length) return true;
    return null;
  }

  DataColumn _selectionColumn() {
    return DataColumn(
      label: Semantics(
        container: true,
        identifier: AutomationIds.setupTableSelectAll,
        child: Checkbox(
          key: const ValueKey('select-all-setups'),
          value: _selectAllValue,
          tristate: true,
          onChanged: (_) {
            unawaited(HapticFeedback.selectionClick());
            widget.onSelectAll!(!_allSetupsSelected);
          },
        ),
      ),
    );
  }

  DataColumn _dataColumn(TableColumn column) {
    final isSorted = widget.sortColumn == column;
    return DataColumn(
      label: SortableColumnLabel(
        label: widget.columnLabel(column),
        tooltip: widget.columnTooltip?.call(column),
        isSorted: isSorted,
        sortAscending: widget.sortAscending,
        onSort: () => widget.onSort(column, isSorted ? !widget.sortAscending : true),
        onRemove: () => widget.onColumnRemoved(column),
      ),
    );
  }

  DataCell _dataCell(
    BuildContext context,
    Setup setup,
    TableColumn column,
    AppSettings appSettings,
  ) {
    switch (column) {
      case SetupTableColumn(column: final setupColumn):
        return setupColumnCell(
          context,
          setup,
          setupColumn,
          appSettings: appSettings,
          bikes: widget.bikes,
          testSessions: widget.testSessions,
          setupActivityCounts: widget.setupActivityCounts,
        );
      case ComponentAdjustmentColumn(:final adjustmentId):
        return _adjustmentCell(context, setup, column, widget.setupHistory.previousBikeValuesOf(setup.id)[adjustmentId]);
      case BikeAdjustmentColumn():
        return _adjustmentCell(context, setup, column, widget.previousValueFor?.call(setup, column));
      case PersonAttributeColumn(:final adjustmentId):
        return _adjustmentCell(context, setup, column, widget.setupHistory.previousPersonValuesOf(setup.id)[adjustmentId]);
      case SetupRankColumn():
        final rank = widget.valueFor(setup, column)?.asNum;
        return DataCell(Center(child: Text(rank == null ? '-' : '#$rank')));
    }
  }

  DataCell _adjustmentCell(BuildContext context, Setup setup, TableColumn column, AdjustmentValue? previousValue) {
    return adjustmentValueCell(
      context,
      value: widget.valueFor(setup, column),
      previousValue: previousValue,
      isDangling: widget.isDangling?.call(setup, column) ?? false,
    );
  }

  DataRow _dataRow(BuildContext context, Setup setup, AppSettings appSettings) {
    final isSelected = widget.selectedSetupIds?.contains(setup.id) ?? false;

    void select(bool? selected) {
      unawaited(HapticFeedback.selectionClick());
      widget.onSetupSelected!(setup, selected);
    }

    return DataRow(
      selected: isSelected,
      onSelectChanged: _selectable ? select : null,
      cells: [
        if (_selectable)
          DataCell(
            Checkbox(
              key: ValueKey('select-setup-${setup.id}'),
              value: isSelected,
              onChanged: select,
            ),
          ),
        ...widget.activeColumns.map((column) => _dataCell(context, setup, column, appSettings)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();
    final theme = Theme.of(context);
    final availableRowsPerPage = _availableRowsPerPage(widget.setups.length);

    return Theme(
      data: theme.copyWith(
        cardTheme: theme.cardTheme.copyWith(
          color: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: PaginatedDataTable(
          horizontalMargin: 8,
          sortAscending: widget.sortAscending,
          sortColumnIndex: widget.activeColumns.contains(widget.sortColumn)
              ? widget.activeColumns.indexOf(widget.sortColumn!) + (_selectable ? 1 : 0)
              : null,
          columnSpacing: 20,
          rowsPerPage: _rowsPerPage,
          availableRowsPerPage: availableRowsPerPage,
          onRowsPerPageChanged: (value) {
            if (value != null) setState(() => _rowsPerPage = value);
          },
          showEmptyRows: false,
          showCheckboxColumn: false,
          showFirstLastButtons: true,
          columns: [if (_selectable) _selectionColumn(), ...widget.activeColumns.map(_dataColumn)],
          source: _SetupDataSource(
            setups: widget.setups,
            selectedSetupIds: widget.selectedSetupIds,
            rowBuilder: (setup) => _dataRow(context, setup, appSettings),
          ),
        ),
      ),
    );
  }
}

class _SetupDataSource extends DataTableSource {
  final List<Setup> setups;
  final Set<String>? selectedSetupIds;
  final DataRow Function(Setup setup) rowBuilder;

  _SetupDataSource({
    required this.setups,
    required this.selectedSetupIds,
    required this.rowBuilder,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= setups.length) return null;
    return rowBuilder(setups[index]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => setups.length;

  @override
  int get selectedRowCount => setups.where((setup) => selectedSetupIds?.contains(setup.id) ?? false).length;
}
