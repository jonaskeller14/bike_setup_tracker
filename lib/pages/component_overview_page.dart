import 'package:bike_setup_tracker/models/adjustment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/component.dart';
import '../models/setup.dart';

class ComponentOverviewPage extends StatefulWidget{
  final Component component;
  final List<Setup> setups;

  const ComponentOverviewPage({
    super.key, 
    required this.component, 
    required this.setups,
  });

  @override
  State<ComponentOverviewPage> createState() => _ComponentOverviewPageState();
}

class _ComponentOverviewPageState extends State<ComponentOverviewPage> {
  late List<Setup> _setups;
  bool _sortAscending = true;
  int? _sortColumnIndex;

  bool _showName = true;
  bool _showNotes = false;
  bool _showDate = true;
  bool _showTime = false;
  bool _showPlace = false;
  bool _showCurrentTemperature = false;
  bool _showDayAccumulatedPrecipitation = false;
  bool _showCurrentHumidity = false;
  bool _showCurrentWindSpeed = false;
  bool _showCurrentSoilMoisture0to7cm = false;
  final Map<Adjustment, bool> _showAdjustment = {};

  @override
  void initState() {
    super.initState();
    _setups = List.from(widget.setups.reversed);
    for (final adjustment in widget.component.adjustments) {
      _showAdjustment[adjustment] = true;
    }
  }

  void onSortColum(dynamic column, int columnIndex, bool ascending) {
    _sortAscending = ascending;
    _sortColumnIndex = columnIndex;
    if (column is String) {
      switch (column) {
        case "name": setState(() {ascending ? _setups.sort((a, b) => a.name.compareTo(b.name)) : _setups.sort((a, b) => b.name.compareTo(a.name));});
        case "notes": setState(() {ascending ? _setups.sort((a, b) => (a.notes ?? '').compareTo(b.notes ?? '')) : _setups.sort((a, b) => (b.notes ?? '').compareTo(a.notes ?? ''));});
        case "date": setState(() {ascending ? _setups.sort((a, b) => a.datetime.compareTo(b.datetime)) : _setups.sort((a, b) => b.datetime.compareTo(a.datetime));});
        case "time": setState(() {ascending ? _setups.sort((a, b) => a.datetime.copyWith(year: 0, month: 0, day: 0).compareTo(b.datetime.copyWith(year: 0, month: 0, day: 0))) : _setups.sort((a, b) => b.datetime.copyWith(year: 0, month: 0, day: 0).compareTo(a.datetime.copyWith(year: 0, month: 0, day: 0)));});
        case "place": setState(() {ascending ? _setups.sort((a, b) => (a.place?.locality ?? '').compareTo(b.place?.locality ?? '')) : _setups.sort((a, b) => (b.place?.locality ?? '').compareTo(a.place?.locality ?? ''));});
        case "currentTemperature": setState(() {ascending ? _setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) : _setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));});
        case "dayAccumulatedPrecipitation": setState(() {ascending ? _setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) : _setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));});
        case "currentHumidity": setState(() {ascending ? _setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) : _setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));});
        case "currentWindSpeed": setState(() {ascending ? _setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) : _setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));});
        case "currentSoilMoisture0to7cm": setState(() {ascending ? _setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) : _setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));});
      }
    } else if (column is Adjustment) {
      if (column is BooleanAdjustment) {
        setState(() {ascending ? _setups.sort((a, b) => ((a.adjustmentValues[column] ?? false) ? 1 : 0).compareTo((b.adjustmentValues[column] ?? false) ? 1 : 0)) : _setups.sort((a, b) => ((b.adjustmentValues[column] ?? false) ? 1 : 0).compareTo((a.adjustmentValues[column] ?? false) ? 1 : 0));});
      } else if (column is StepAdjustment) {
        setState(() {ascending ? _setups.sort((a, b) => (a.adjustmentValues[column] ?? 0).compareTo(b.adjustmentValues[column] ?? 0)) : _setups.sort((a, b) => (b.adjustmentValues[column] ?? 0).compareTo(a.adjustmentValues[column] ?? 0));});
      } else if (column is NumericalAdjustment) {
        setState(() {ascending ? _setups.sort((a, b) => (a.adjustmentValues[column] ?? double.negativeInfinity).compareTo(b.adjustmentValues[column] ?? double.negativeInfinity)) : _setups.sort((a, b) => (b.adjustmentValues[column] ?? double.negativeInfinity).compareTo(a.adjustmentValues[column] ?? double.negativeInfinity));});
      } else if (column is CategoricalAdjustment) {
        setState(() {ascending ? _setups.sort((a, b) => (a.adjustmentValues[column] ?? '').compareTo(b.adjustmentValues[column] ?? '')) : _setups.sort((a, b) => (b.adjustmentValues[column] ?? '').compareTo(a.adjustmentValues[column] ?? ''));});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Component.getIcon(widget.component.componentType),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.component.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 6,
                children: [
                  FilterChip(
                    selected: _showName,
                    label: const Text("Name"),
                    onSelected: (bool value) {
                      setState(() {
                        _showName = value;
                        _sortColumnIndex = null;
                      });
                    },
                  ),
                  FilterChip(
                    selected: _showNotes,
                    label: const Text("Notes"),
                    onSelected: (bool value) {
                      setState(() {
                        _showNotes = value;
                        _sortColumnIndex = null;
                      });
                    },
                  ),
                  FilterChip(
                    selected: _showDate,
                    label: const Text("Date"),
                    onSelected: (bool value) {
                      setState(() {
                        _showDate = value;
                        _sortColumnIndex = null;
                      });
                    },
                  ),
                  FilterChip(
                    selected: _showTime,
                    label: const Text("Time"),
                    onSelected: (bool value) {
                      setState(() {
                        _showTime = value;
                        _sortColumnIndex = null;
                      });
                    },
                  ),
                  FilterChip(
                    selected: _showPlace,
                    label: const Text("Place"),
                    onSelected: (bool value) {
                      setState(() {
                        _showPlace = value;
                        _sortColumnIndex = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 6,
                children: [
                  FilterChip(
                    selected: _showCurrentTemperature,
                    label: const Text("Temperature"),
                    onSelected: (bool value) {
                      setState(() {
                        _showCurrentTemperature = value;
                        _sortColumnIndex = null;
                      });
                    },
                  ),
                  FilterChip(
                    selected: _showDayAccumulatedPrecipitation,
                    label: const Text("Precipation"),
                    onSelected: (bool value) {
                      setState(() {
                        _showDayAccumulatedPrecipitation = value;
                        _sortColumnIndex = null;
                      });
                    },
                  ),
                  FilterChip(
                    selected: _showCurrentHumidity,
                    label: const Text("Humidity"),
                    onSelected: (bool value) {
                      setState(() {
                        _showCurrentHumidity = value;
                        _sortColumnIndex = null;
                      });
                    },
                  ),
                  FilterChip(
                    selected: _showCurrentWindSpeed,
                    label: const Text("Windspeed"),
                    onSelected: (bool value) {
                      setState(() {
                        _showCurrentWindSpeed = value;
                        _sortColumnIndex = null;
                      });
                    },
                  ),
                  FilterChip(
                    selected: _showCurrentSoilMoisture0to7cm,
                    label: const Text("Soil Moisture"),
                    onSelected: (bool value) {
                      setState(() {
                        _showCurrentSoilMoisture0to7cm = value;
                        _sortColumnIndex = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 6,
                children: [
                  for (final adjustment in widget.component.adjustments)
                    FilterChip(
                      selected: _showAdjustment[adjustment]!,
                      label: Text(adjustment.name),
                      onSelected: (bool value) {
                        setState(() {
                          _showAdjustment[adjustment] = value;
                          _sortColumnIndex = null;
                        });
                      },
                    ),
                ],
              ),
            ),
            if (_showName || _showNotes || _showDate || _showNotes || _showCurrentTemperature || _showDayAccumulatedPrecipitation || _showCurrentHumidity || _showCurrentWindSpeed || _showCurrentSoilMoisture0to7cm || _showAdjustment.values.any((e) => e))
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  sortAscending: _sortAscending,
                  sortColumnIndex: _sortColumnIndex,
                  columnSpacing: 20,
                  headingTextStyle: TextStyle(fontWeight: FontWeight.bold),
                  columns: [
                    if (_showName)
                      DataColumn(label: const Text('Setup'), onSort: (columnIndex, ascending) => onSortColum("name", columnIndex, ascending)),
                    if (_showNotes)
                      DataColumn(label: const Text('Notes'), onSort: (columnIndex, ascending) => onSortColum("notes", columnIndex, ascending)),
                    if (_showDate)
                      DataColumn(label: const Text('Date'), onSort: (columnIndex, ascending) => onSortColum("date", columnIndex, ascending)),
                    if (_showTime)
                      DataColumn(label: const Text('Time'), onSort: (columnIndex, ascending) => onSortColum("time", columnIndex, ascending)),
                    if (_showPlace)
                      DataColumn(label: const Text('Place'), onSort: (columnIndex, ascending) => onSortColum("place", columnIndex, ascending)),
                    
                    if (_showCurrentTemperature)
                      DataColumn(label: const Text('Temperature'), onSort: (columnIndex, ascending) => onSortColum("currentTemperature", columnIndex, ascending)),
                    if (_showDayAccumulatedPrecipitation)
                      DataColumn(label: const Text('Precipation'), onSort: (columnIndex, ascending) => onSortColum("dayAccumulatedPrecipitation", columnIndex, ascending)),
                    if (_showCurrentHumidity)
                      DataColumn(label: const Text('Humidity'), onSort: (columnIndex, ascending) => onSortColum("currentHumidity", columnIndex, ascending)),
                    if (_showCurrentWindSpeed)
                      DataColumn(label: const Text('Windspeed'), onSort: (columnIndex, ascending) => onSortColum("currentWindSpeed", columnIndex, ascending)),
                    if (_showCurrentSoilMoisture0to7cm)
                      DataColumn(label: const Text('Soil Moisture'), onSort: (columnIndex, ascending) => onSortColum("currentSoilMoisture0to7cm", columnIndex, ascending)),
                    
                    for (final adjustment in widget.component.adjustments)
                      if (_showAdjustment[adjustment] == true)
                        DataColumn(
                          label: Text(
                            adjustment.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          onSort: (columnIndex, ascending) => onSortColum(adjustment, columnIndex, ascending),
                        ),
                  ],
                  rows: _setups.where((setup) {
                    return widget.component.adjustments.any(
                      (componentAdjustment) => setup.adjustmentValues.containsKey(componentAdjustment)
                    );
                  }).map((setup) {
                    return DataRow(
                      cells: [
                        if (_showName)
                          DataCell(ConstrainedBox(constraints: BoxConstraints(maxWidth: 150), child: Text(setup.name, overflow: TextOverflow.ellipsis))),
                        if (_showNotes)
                          DataCell(ConstrainedBox(constraints: BoxConstraints(maxWidth: 300), child: Text(setup.notes ?? '-', overflow: TextOverflow.ellipsis))),
                        if (_showDate)
                          DataCell(Text(DateFormat('yyyy-MM-dd').format(setup.datetime))),
                        if (_showTime)
                          DataCell(Text(DateFormat('HH:mm').format(setup.datetime))),
                        if (_showPlace)
                          DataCell(ConstrainedBox(constraints: BoxConstraints(maxWidth: 150), child: Text(setup.place?.locality ?? '-', overflow: TextOverflow.ellipsis))),
                        
                        if (_showCurrentTemperature)
                          DataCell(Center(child: Text(setup.weather?.currentTemperature == null ? '-' : "${setup.weather!.currentTemperature!.round()} °C"))),
                        if (_showDayAccumulatedPrecipitation)
                          DataCell(Center(child: Text(setup.weather?.dayAccumulatedPrecipitation == null ? '-' : "${setup.weather!.dayAccumulatedPrecipitation!.round()} mm"))),
                        if (_showCurrentHumidity)
                          DataCell(Center(child: Text(setup.weather?.currentHumidity == null ? '-' : "${setup.weather!.currentHumidity!.round()} %"))),
                        if (_showCurrentWindSpeed)
                          DataCell(Center(child: Text(setup.weather?.currentWindSpeed == null ? '-' : "${setup.weather!.currentWindSpeed!.round()} km/h"))),
                        if (_showCurrentSoilMoisture0to7cm)
                          DataCell(Center(child: Text(setup.weather?.currentSoilMoisture0to7cm == null ? '-' : setup.weather!.currentSoilMoisture0to7cm!.toStringAsFixed(2)))),
                        
                        for (final adjustment in widget.component.adjustments)
                          if (_showAdjustment[adjustment] == true)
                            DataCell(
                              Center(
                                child: Text(Adjustment.formatValue(setup.adjustmentValues[adjustment])),
                              ),
                            ),
                      ],
                    );
                  }).toList(),
                ),
              ), 
          ],
        ),
      ),
    );
  }
}
