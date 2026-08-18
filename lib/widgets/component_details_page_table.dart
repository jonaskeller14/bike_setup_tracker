import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/adjustment/adjustment.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/context/context_weather.dart';
import '../models/setup.dart';
import '../theme.dart';
import '../utils/table_column.dart';

class ComponentDetailsPageTable extends StatefulWidget {
  final List<TableColumn> activeColumns;
  final List<Setup> setups;
  final Set<String> selectedSetupIds;
  final bool sortAscending;
  final TableColumn? sortColumn;
  final Map<String, Bike> bikes;
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

  DataColumn _dataColumn(TableColumn column) {
    return DataColumn(
      label: GestureDetector(
        onLongPress: () {
          unawaited(HapticFeedback.selectionClick());
          widget.onColumnRemoved(column);
        },
        child: Text(
          widget.columnLabel(column),
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      onSort: (int _, bool ascending) => widget.onSort(column, ascending),
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
    switch (column.section) {
      case TableColumnSection.generalContext:
        return switch (column.label) {
          "Name" => _scrollableTextCell(setup.displayName),
          "Notes" => _scrollableTextCell(setup.notes ?? '-', maxWidth: 300),
          "Tags" => _scrollableTextCell(setup.tags.isEmpty ? '-' : setup.tags.join('; '), maxWidth: 300),
          "Date" => DataCell(Text(DateFormat(appSettings.dateFormat).format(setup.datetimeLocal))),
          "Time" => DataCell(Text(DateFormat(appSettings.timeFormat).format(setup.datetimeLocal))),
          "Place" => _scrollableTextCell(setup.place?.locality ?? '-'),
          "Altitude" => DataCell(
            Center(
              child: Text(
                setup.position?.altitude == null
                    ? '-'
                    : "${setup.position!.altitude!.round()} ${appSettings.altitudeUnit}",
              ),
            ),
          ),
          "Bike" => _scrollableTextCell(widget.bikes[setup.bike]?.name ?? '-'),
          _ => const DataCell(Text("ERROR")),
        };
      case TableColumnSection.weatherContext:
        return switch (column.label) {
          "Weather Code" => DataCell(Center(child: Text(setup.weather?.getWeatherCodeLabel() ?? "-"))),
          "Temperature" => DataCell(
            Center(
              child: Text(
                setup.weather?.currentTemperature == null
                    ? '-'
                    : "${ContextWeather.convertTemperatureFromCelsius(setup.weather!.currentTemperature!, appSettings.temperatureUnit)?.round()} ${appSettings.temperatureUnit}",
              ),
            ),
          ),
          "Precipitation" => DataCell(
            Center(
              child: Text(
                setup.weather?.dayAccumulatedPrecipitation == null
                    ? '-'
                    : "${ContextWeather.convertPrecipitationFromMm(setup.weather!.dayAccumulatedPrecipitation!, appSettings.precipitationUnit)?.round()} ${appSettings.precipitationUnit}",
              ),
            ),
          ),
          "Humidity" => DataCell(
            Center(
              child: Text(
                setup.weather?.currentHumidity == null ? '-' : "${setup.weather!.currentHumidity!.round()} %",
              ),
            ),
          ),
          "Windspeed" => DataCell(
            Center(
              child: Text(
                setup.weather?.currentWindSpeed == null
                    ? '-'
                    : "${ContextWeather.convertWindSpeedFromKmh(setup.weather!.currentWindSpeed!, appSettings.windSpeedUnit)?.round()} ${appSettings.windSpeedUnit}",
              ),
            ),
          ),
          "Soil Moisture" => DataCell(
            Center(
              child: Text(
                setup.weather?.currentSoilMoisture0to7cm == null
                    ? '-'
                    : setup.weather!.currentSoilMoisture0to7cm!.toStringAsFixed(2),
              ),
            ),
          ),
          "Condition" => DataCell(
            Center(child: Text(setup.weather?.condition?.value ?? "-")),
          ),
          _ => const DataCell(Text("ERROR")),
        };
      case TableColumnSection.componentAdjustments || TableColumnSection.personAttributes:
        final value = widget.valueFor(setup, column);
        final initialValue = switch (column.section) {
          TableColumnSection.componentAdjustments => setup.previousBikeAdjustmentValues[column.label],
          TableColumnSection.personAttributes => setup.previousPersonAdjustmentValues[column.label],
          _ => null,
        };
        final bool isChanged = value != null && initialValue != value;
        final bool isInitial = initialValue == null;
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
      case TableColumnSection.ratingScore || TableColumnSection.ratingMetrics:
        final score = widget.valueFor(setup, column) as double?;
        return DataCell(
          Center(child: Text(score == null ? '-' : "${score.toStringAsFixed(1)} / 10")),
        );
    }
  }

  DataRow _dataRow(BuildContext context, Setup setup, AppSettings appSettings) {
    return DataRow(
      selected: widget.selectedSetupIds.contains(setup.id),
      onSelectChanged: (selected) {
        unawaited(HapticFeedback.selectionClick());
        widget.onSetupSelected(setup, selected);
      },
      cells: widget.activeColumns.map((column) => _dataCell(context, setup, column, appSettings)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();
    final theme = Theme.of(context);
    final availableRowsPerPage = {
      5,
      10,
      20,
      50,
      _rowsPerPage,
      if (widget.setups.length <= 50) widget.setups.length,
    }.where((value) => value > 0).toList()..sort();

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
          onSelectAll: (selected) {
            unawaited(HapticFeedback.selectionClick());
            widget.onSelectAll(selected);
          },
          sortAscending: widget.sortAscending,
          sortColumnIndex: widget.activeColumns.contains(widget.sortColumn)
              ? widget.activeColumns.indexOf(widget.sortColumn!)
              : null,
          columnSpacing: 20,
          rowsPerPage: _rowsPerPage,
          availableRowsPerPage: availableRowsPerPage,
          onRowsPerPageChanged: (value) {
            if (value != null) setState(() => _rowsPerPage = value);
          },
          showEmptyRows: false,
          showFirstLastButtons: true,
          columns: widget.activeColumns.map(_dataColumn).toList(),
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
