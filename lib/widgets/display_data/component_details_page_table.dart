import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/context/context_weather.dart';
import '../../models/setup.dart';
import '../../theme.dart';
import '../../utils/table_column.dart';

class ComponentDetailsPageTable extends StatefulWidget {
  final List<TableColumn> activeColumns;
  final List<Setup> setups;
  final Set<String> selectedSetupIds;
  final bool sortAscending;
  final TableColumn? sortColumn;
  final Map<String, Bike> bikes;
  final Map<String, int> setupActivityCounts;
  final dynamic Function(Setup setup, TableColumn column) valueFor;
  final String Function(TableColumn column) columnLabel;
  final void Function(TableColumn column, bool ascending) onSort;
  final ValueChanged<TableColumn> onColumnRemoved;
  final ValueChanged<bool?> onSelectAll;
  final void Function(Setup setup, bool? selected) onSetupSelected;

  const ComponentDetailsPageTable({
    super.key,
    required this.activeColumns,
    required this.setups,
    required this.selectedSetupIds,
    required this.sortAscending,
    required this.sortColumn,
    required this.bikes,
    required this.setupActivityCounts,
    required this.valueFor,
    required this.columnLabel,
    required this.onSort,
    required this.onColumnRemoved,
    required this.onSelectAll,
    required this.onSetupSelected,
  });

  @override
  State<ComponentDetailsPageTable> createState() => _ComponentDetailsPageTableState();
}

class _ComponentDetailsPageTableState extends State<ComponentDetailsPageTable> {
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
  void didUpdateWidget(covariant ComponentDetailsPageTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final availableRowsPerPage = _availableRowsPerPage(widget.setups.length);
    if (!availableRowsPerPage.contains(_rowsPerPage)) {
      _rowsPerPage = _defaultRowsPerPage(widget.setups.length);
    }
  }

  bool get _allSetupsSelected =>
      widget.setups.every((setup) => widget.selectedSetupIds.contains(setup.id));

  bool? get _selectAllValue {
    final selectedCount = widget.setups.where((setup) => widget.selectedSetupIds.contains(setup.id)).length;
    if (selectedCount == 0) return false;
    if (selectedCount == widget.setups.length) return true;
    return null;
  }

  DataColumn _selectionColumn() {
    return DataColumn(
      label: Checkbox(
        key: const ValueKey('select-all-setups'),
        value: _selectAllValue,
        tristate: true,
        onChanged: (_) {
          unawaited(HapticFeedback.selectionClick());
          widget.onSelectAll(!_allSetupsSelected);
        },
      ),
    );
  }

  DataColumn _dataColumn(TableColumn column) {
    final isSorted = widget.sortColumn == column;

    void sort() {
      widget.onSort(column, isSorted ? !widget.sortAscending : true);
    }

    return DataColumn(
      label: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: sort,
        onLongPress: () {
          unawaited(HapticFeedback.selectionClick());
          widget.onColumnRemoved(column);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.columnLabel(column),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 4),
            Opacity(
              opacity: isSorted ? 1 : 0,
              child: AnimatedRotation(
                turns: widget.sortAscending ? 0 : 0.5,
                duration: const Duration(milliseconds: 150),
                child: const Icon(Icons.arrow_upward, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataCell _scrollableTextCell(String text, {double maxWidth = 150}) {
    return DataCell(
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(text, overflow: TextOverflow.ellipsis),
        ),
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
        return switch (setupColumn) {
          SetupColumn.name => _scrollableTextCell(setup.displayName),
          SetupColumn.notes => _scrollableTextCell(setup.notes ?? '-', maxWidth: 300),
          SetupColumn.tags => _scrollableTextCell(setup.tags.isEmpty ? '-' : setup.tags.join('; '), maxWidth: 300),
          SetupColumn.date => DataCell(Text(DateFormat(appSettings.dateFormat).format(setup.datetimeLocal))),
          SetupColumn.time => DataCell(Text(DateFormat(appSettings.timeFormat).format(setup.datetimeLocal))),
          SetupColumn.place => _scrollableTextCell(setup.place?.locality ?? '-'),
          SetupColumn.altitude => DataCell(
            Center(
              child: Text(
                setup.position?.altitude == null
                    ? '-'
                    : "${setup.position!.altitude!.round()} ${appSettings.altitudeUnit}",
              ),
            ),
          ),
          SetupColumn.bike => _scrollableTextCell(widget.bikes[setup.bike]?.name ?? '-'),
          SetupColumn.bookmarked => DataCell(
            Center(
              child: setup.isBookmarked
                  ? Icon(Icons.bookmark, size: 16, color: Theme.of(context).colorScheme.primary)
                  : const Text('-'),
            ),
          ),
          SetupColumn.activities => DataCell(
            Center(
              child: Text(
                '${widget.setupActivityCounts[setup.id] ?? 0}',
                key: ValueKey('setup-activity-count-${setup.id}'),
              ),
            ),
          ),
          SetupColumn.weatherCode => DataCell(Center(child: Text(setup.weather?.getWeatherCodeLabel() ?? "-"))),
          SetupColumn.temperature => DataCell(
            Center(
              child: Text(
                setup.weather?.currentTemperature == null
                    ? '-'
                    : "${ContextWeather.convertTemperatureFromCelsius(setup.weather!.currentTemperature!, appSettings.temperatureUnit)?.round()} ${appSettings.temperatureUnit}",
              ),
            ),
          ),
          SetupColumn.precipitation => DataCell(
            Center(
              child: Text(
                setup.weather?.dayAccumulatedPrecipitation == null
                    ? '-'
                    : "${ContextWeather.convertPrecipitationFromMm(setup.weather!.dayAccumulatedPrecipitation!, appSettings.precipitationUnit)?.round()} ${appSettings.precipitationUnit}",
              ),
            ),
          ),
          SetupColumn.humidity => DataCell(
            Center(
              child: Text(
                setup.weather?.currentHumidity == null ? '-' : "${setup.weather!.currentHumidity!.round()} %",
              ),
            ),
          ),
          SetupColumn.windSpeed => DataCell(
            Center(
              child: Text(
                setup.weather?.currentWindSpeed == null
                    ? '-'
                    : "${ContextWeather.convertWindSpeedFromKmh(setup.weather!.currentWindSpeed!, appSettings.windSpeedUnit)?.round()} ${appSettings.windSpeedUnit}",
              ),
            ),
          ),
          SetupColumn.soilMoisture => DataCell(
            Center(
              child: Text(
                setup.weather?.currentSoilMoisture0to7cm == null
                    ? '-'
                    : setup.weather!.currentSoilMoisture0to7cm!.toStringAsFixed(2),
              ),
            ),
          ),
          SetupColumn.condition => DataCell(
            Center(child: Text(setup.weather?.condition?.value ?? "-")),
          ),
        };
      case ComponentAdjustmentColumn(:final adjustmentId):
        return _adjustmentCell(context, setup, column, setup.previousBikeAdjustmentValues[adjustmentId]);
      case PersonAttributeColumn(:final adjustmentId):
        return _adjustmentCell(context, setup, column, setup.previousPersonAdjustmentValues[adjustmentId]);
      case RatingScoreColumn() || RatingMetricColumn():
        final score = widget.valueFor(setup, column) as double?;
        return DataCell(
          Center(child: Text(score == null ? '-' : "${score.toStringAsFixed(1)} / 10")),
        );
    }
  }

  DataCell _adjustmentCell(BuildContext context, Setup setup, TableColumn column, dynamic previousValue) {
    final value = widget.valueFor(setup, column);
    final bool isChanged = value != null && previousValue != value;
    final bool isInitial = previousValue == null;
    final highlights = Theme.of(context).extension<ValueHighlightColors>();
    final highlightColor = isChanged
        ? (isInitial ? highlights?.initial ?? Colors.green : highlights?.changed ?? Colors.orange)
        : null;

    return DataCell(
      Center(
        child: Text(
          Adjustment.formatValue(value),
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: highlightColor,
            fontWeight: highlightColor != null ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }

  DataRow _dataRow(BuildContext context, Setup setup, AppSettings appSettings) {
    final isSelected = widget.selectedSetupIds.contains(setup.id);

    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        unawaited(HapticFeedback.selectionClick());
        widget.onSetupSelected(setup, selected);
      },
      cells: [
        DataCell(
          Checkbox(
            key: ValueKey('select-setup-${setup.id}'),
            value: isSelected,
            onChanged: (selected) {
              unawaited(HapticFeedback.selectionClick());
              widget.onSetupSelected(setup, selected);
            },
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
              ? widget.activeColumns.indexOf(widget.sortColumn!) + 1
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
          columns: [_selectionColumn(), ...widget.activeColumns.map(_dataColumn)],
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
  final Set<String> selectedSetupIds;
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
  int get selectedRowCount => setups.where((setup) => selectedSetupIds.contains(setup.id)).length;
}
