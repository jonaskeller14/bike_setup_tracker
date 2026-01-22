import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../models/component.dart';
import '../models/setup.dart';
import '../models/adjustment/adjustment.dart';
import '../models/weather.dart';
import '../models/app_settings.dart';
import '../widgets/sheets/column_filter.dart';
import '../widgets/initial_changed_value_legend.dart';

class ComponentOverviewPage extends StatefulWidget{
  final Component component;

  const ComponentOverviewPage({super.key, required this.component});

  @override
  State<ComponentOverviewPage> createState() => _ComponentOverviewPageState();
}

class _ComponentOverviewPageState extends State<ComponentOverviewPage> {
  late List<Setup> _setups;
  bool _sortAscending = true;
  int? _sortColumnIndex;
  static const bool _highlighting = true;

  final Map<String, Map<String, bool>> _showColumns = {
    "General Context": {
      "Name": true,
      "Notes": false,
      "Date": true,
      "Time": false,
      "Place": false,
      "Altitude": false,
    },
    "Weather Context": {
      "Temperature": false,
      "Precipation": false,
      "Humidity": false,
      "Windspeed": false,
      "Soil Moisture": false,
      "Condition": false,
    },
    "Adjustments": {},
  };

  @override
  void initState() {
    super.initState();
    final appData = context.read<AppData>();

    _setups = List.from(appData.setups.values.where(
        (s) => !s.isDeleted &&
                widget.component.adjustments.any((adj) => s.bikeAdjustmentValues.containsKey(adj.id))
    ).toList().reversed);
    
    for (final adjustment in widget.component.adjustments) {
      _showColumns["Adjustments"]?[adjustment.id] = true;
    }
  }

  void onSortColum(String column, int columnIndex, bool ascending) {
    _sortAscending = ascending;
    _sortColumnIndex = columnIndex;
    switch (column) {
      case "Name": setState(() {ascending 
          ? _setups.sort((a, b) => a.name.compareTo(b.name)) 
          : _setups.sort((a, b) => b.name.compareTo(a.name));
      });
      case "Notes": setState(() {ascending 
          ? _setups.sort((a, b) => (a.notes ?? '').compareTo(b.notes ?? '')) 
          : _setups.sort((a, b) => (b.notes ?? '').compareTo(a.notes ?? ''));
      });
      case "Date": setState(() {ascending 
          ? _setups.sort((a, b) => a.datetime.compareTo(b.datetime)) 
          : _setups.sort((a, b) => b.datetime.compareTo(a.datetime));
      });
      case "Time": setState(() {ascending 
          ? _setups.sort((a, b) => a.datetime.copyWith(year: 0, month: 0, day: 0).compareTo(b.datetime.copyWith(year: 0, month: 0, day: 0))) 
          : _setups.sort((a, b) => b.datetime.copyWith(year: 0, month: 0, day: 0).compareTo(a.datetime.copyWith(year: 0, month: 0, day: 0)));
      });
      case "Place": setState(() {ascending 
          ? _setups.sort((a, b) => (a.place?.locality ?? '').compareTo(b.place?.locality ?? '')) 
          : _setups.sort((a, b) => (b.place?.locality ?? '').compareTo(a.place?.locality ?? ''));
      });
      case "Altitude": setState(() {ascending 
          ? _setups.sort((a, b) => (a.position?.altitude ?? double.negativeInfinity).compareTo(b.position?.altitude ?? double.negativeInfinity)) 
          : _setups.sort((a, b) => (b.position?.altitude ?? double.negativeInfinity).compareTo(a.position?.altitude ?? double.negativeInfinity));
      });
      case "Temperature": setState(() {ascending 
          ? _setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) 
          : _setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));
      });
      case "Precipation": setState(() {ascending 
          ? _setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) 
          : _setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));
      });
      case "Humidity": setState(() {ascending 
          ? _setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) 
          : _setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));
      });
      case "Windspeed": setState(() {ascending 
          ? _setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) 
          : _setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));
      });
      case "Soil Moisture": setState(() {ascending 
          ? _setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) 
          : _setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));
      });
      case "Condition": setState(() {ascending 
          ? _setups.sort((a, b) => (a.weather?.condition?.value ?? '').compareTo(b.weather?.condition?.value ?? '')) 
          : _setups.sort((a, b) => (b.weather?.condition?.value ?? '').compareTo(a.weather?.condition?.value ?? ''));
      });
      default: 
        final Adjustment? adjustment = widget.component.adjustments.firstWhereOrNull((a) => a.id == column);
        switch (adjustment) {
          case null: return;
          case BooleanAdjustment(): setState(() {ascending 
              ? _setups.sort((a, b) => ((a.bikeAdjustmentValues[column] ?? false) ? 1 : 0).compareTo((b.bikeAdjustmentValues[column] ?? false) ? 1 : 0)) 
              : _setups.sort((a, b) => ((b.bikeAdjustmentValues[column] ?? false) ? 1 : 0).compareTo((a.bikeAdjustmentValues[column] ?? false) ? 1 : 0));
          });
          case StepAdjustment(): setState(() {ascending 
              ? _setups.sort((a, b) => ((a.bikeAdjustmentValues[column] ?? 0) as int).compareTo((b.bikeAdjustmentValues[column] ?? 0) as int)) 
              : _setups.sort((a, b) => ((b.bikeAdjustmentValues[column] ?? 0) as int).compareTo((a.bikeAdjustmentValues[column] ?? 0) as int));
          });
          case NumericalAdjustment(): setState(() {ascending 
              ? _setups.sort((a, b) => ((a.bikeAdjustmentValues[column] ?? double.negativeInfinity) as double).compareTo((b.bikeAdjustmentValues[column] ?? double.negativeInfinity) as double)) 
              : _setups.sort((a, b) => ((b.bikeAdjustmentValues[column] ?? double.negativeInfinity) as double).compareTo((a.bikeAdjustmentValues[column] ?? double.negativeInfinity) as double));
          });
          case CategoricalAdjustment(): setState(() {ascending 
              ? _setups.sort((a, b) => ((a.bikeAdjustmentValues[column] ?? '') as String).compareTo((b.bikeAdjustmentValues[column] ?? '') as String)) 
              : _setups.sort((a, b) => ((b.bikeAdjustmentValues[column] ?? '') as String).compareTo((a.bikeAdjustmentValues[column] ?? '') as String));
          });
          case TextAdjustment(): setState(() {ascending 
              ? _setups.sort((a, b) => ((a.bikeAdjustmentValues[column] ?? '') as String).compareTo((b.bikeAdjustmentValues[column] ?? '') as String)) 
              : _setups.sort((a, b) => ((b.bikeAdjustmentValues[column] ?? '') as String).compareTo((a.bikeAdjustmentValues[column] ?? '') as String));
          });
          case DurationAdjustment(): setState(() {ascending 
              ? _setups.sort((a, b) => ((a.bikeAdjustmentValues[column] ?? Duration.zero) as Duration).compareTo((b.bikeAdjustmentValues[column] ?? Duration.zero) as Duration)) 
              : _setups.sort((a, b) => ((b.bikeAdjustmentValues[column] ?? Duration.zero) as Duration).compareTo((a.bikeAdjustmentValues[column] ?? Duration.zero) as Duration));
          });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(widget.component.componentType.getIconData()),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.component.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsetsGeometry.all(16),
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 6,
                children: [
                  FilterChip(
                    avatar: const Icon(Icons.view_column_outlined),
                    showCheckmark: false,
                    label: const Text("Columns"),
                    selected: _showColumns.values.any((v) => v.values.any((v) => v  == true)),
                    onSelected: (bool newValue) async {
                      final Map<String, Map<String, bool>>? showColumnsCopy = await showColumnFilterSheet(context: context, showColumns: _showColumns, adjustments: widget.component.adjustments);
                      if (showColumnsCopy == null) return;
                      setState(() {
                        _showColumns.clear();
                        _showColumns.addEntries(showColumnsCopy.entries);
                      });
                    },
                  ),
                  //TODO: Use the same filter widgets as in componentList and update all filters simutanously
                ],
              ),
            ),
            if (_showColumns.values.any((v) => v.values.any((v) => v  == true)))
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  sortAscending: _sortAscending,
                  sortColumnIndex: _sortColumnIndex,
                  columnSpacing: 20,
                  headingTextStyle: TextStyle(fontWeight: FontWeight.bold),
                  columns: _showColumns.entries.expand((sectionShowColumnsEntry) {
                    return sectionShowColumnsEntry.value.entries.where((showColumnEntry) => showColumnEntry.value).map((showColumnEntry) {
                      if (sectionShowColumnsEntry.key == "Adjustments") {
                        final Adjustment? adjustment = widget.component.adjustments.firstWhereOrNull((a) => a.id == showColumnEntry.key);
                        return DataColumn(
                          label: Text(
                            (adjustment?.name ?? "-") + (adjustment?.unit != null ? " [${adjustment!.unit}]" : ""),
                            overflow: TextOverflow.ellipsis
                          ),
                          onSort: (columnIndex, ascending) => onSortColum(showColumnEntry.key, columnIndex, ascending),
                        );
                      } else {
                        return DataColumn(
                          label: Text(showColumnEntry.key, overflow: TextOverflow.ellipsis),
                          onSort: (columnIndex, ascending) => onSortColum(showColumnEntry.key, columnIndex, ascending),
                        );
                      }               
                    }).toList();
                  }).toList(),
                  rows: _setups.map((setup) {
                    return DataRow(
                      cells: _showColumns.entries.expand((sectionShowColumnsEntry) {
                        return sectionShowColumnsEntry.value.entries.where((showColumnEntry) => showColumnEntry.value).map((showColumnEntry) {
                          if (sectionShowColumnsEntry.key == "Adjustments") {
                            final value = setup.bikeAdjustmentValues[showColumnEntry.key];
                            final initialValue = setup.previousBikeSetup?.bikeAdjustmentValues[showColumnEntry.key];
                            
                            Color? highlightColor;
                            if (_highlighting) {
                              final bool isChanged = value != null && initialValue != value;
                              final bool isInitial = initialValue == null;
                              highlightColor = isChanged ? (isInitial ? Colors.green : Colors.orange) : null;
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
                          } else {
                            return switch(showColumnEntry.key) {
                              "Name" => DataCell(ConstrainedBox(constraints: BoxConstraints(maxWidth: 150), child: Text(setup.name, overflow: TextOverflow.ellipsis))),
                              "Notes" => DataCell(ConstrainedBox(constraints: BoxConstraints(maxWidth: 300), child: Text(setup.notes ?? '-', overflow: TextOverflow.ellipsis))),
                              "Date" => DataCell(Text(DateFormat(appSettings.dateFormat).format(setup.datetime))),
                              "Time" => DataCell(Text(DateFormat(appSettings.timeFormat).format(setup.datetime))),
                              "Place" => DataCell(ConstrainedBox(constraints: BoxConstraints(maxWidth: 150), child: Text(setup.place?.locality ?? '-', overflow: TextOverflow.ellipsis))),
                              "Altitude" => DataCell(Center(child: Text(setup.position?.altitude == null ? '-' : "${setup.position!.altitude!.round()} ${appSettings.altitudeUnit}"))),
                              "Temperature" => DataCell(Center(child: Text(setup.weather?.currentTemperature == null ? '-' : "${Weather.convertTemperatureFromCelsius(setup.weather!.currentTemperature!, appSettings.temperatureUnit)?.round()} ${appSettings.temperatureUnit}"))),
                              "Precipation" => DataCell(Center(child: Text(setup.weather?.dayAccumulatedPrecipitation == null ? '-' : "${Weather.convertPrecipitationFromMm(setup.weather!.dayAccumulatedPrecipitation!, appSettings.precipitationUnit)?.round()} ${appSettings.precipitationUnit}"))),
                              "Humidity" => DataCell(Center(child: Text(setup.weather?.currentHumidity == null ? '-' : "${setup.weather!.currentHumidity!.round()} %"))),
                              "Windspeed" => DataCell(Center(child: Text(setup.weather?.currentWindSpeed == null ? '-' : "${Weather.convertWindSpeedFromKmh(setup.weather!.currentWindSpeed!, appSettings.windSpeedUnit)?.round()} ${appSettings.windSpeedUnit}"))),
                              "Soil Moisture" => DataCell(Center(child: Text(setup.weather?.currentSoilMoisture0to7cm == null ? '-' : setup.weather!.currentSoilMoisture0to7cm!.toStringAsFixed(2)))),
                              "Condition" => DataCell(Center(child: Text(setup.weather?.condition == null ? '-' : setup.weather!.condition!.value))),
                              _ => const DataCell(Text("ERROR")),
                            };
                          }
                        }).toList();
                      }).toList(),
                    );
                  }).toList(),
                ),
              )
            else
              SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'Select a column to display the table',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            if (_setups.isEmpty)
              SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'No setups yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            const InitialChangedValueLegend(),
          ],
        ),
      ),
    );
  }
}
