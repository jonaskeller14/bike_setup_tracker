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
  bool _showName = true;
  bool _showNotes = false;
  bool _showDate = true;
  bool _showTime = false;
  bool _showCurrentTemperature = false;
  bool _showDayAccumulatedPrecipitation = false;
  bool _showCurrentHumidity = false;
  bool _showCurrentWindSpeed = false;
  bool _showCurrentSoilMoisture0to7cm = false;
  final Map<Adjustment, bool> _showAdjustment = {};

  @override
  void initState() {
    super.initState();
    for (final adjustment in widget.component.adjustments) {
      _showAdjustment[adjustment] = true;
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
                      });
                    },
                  ),
                  FilterChip(
                    selected: _showNotes,
                    label: const Text("Notes"),
                    onSelected: (bool value) {
                      setState(() {
                        _showNotes = value;
                      });
                    },
                  ),
                  FilterChip(
                    selected: _showDate,
                    label: const Text("Date"),
                    onSelected: (bool value) {
                      setState(() {
                        _showDate = value;
                      });
                    },
                  ),
                  FilterChip(
                    selected: _showTime,
                    label: const Text("Time"),
                    onSelected: (bool value) {
                      setState(() {
                        _showTime = value;
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
                      });
                    },
                  ),
                  FilterChip(
                    selected: _showDayAccumulatedPrecipitation,
                    label: const Text("Precipation"),
                    onSelected: (bool value) {
                      setState(() {
                        _showDayAccumulatedPrecipitation = value;
                      });
                    },
                  ),
                  FilterChip(
                    selected: _showCurrentHumidity,
                    label: const Text("Humidity"),
                    onSelected: (bool value) {
                      setState(() {
                        _showCurrentHumidity = value;
                      });
                    },
                  ),
                  FilterChip(
                    selected: _showCurrentWindSpeed,
                    label: const Text("Windspeed"),
                    onSelected: (bool value) {
                      setState(() {
                        _showCurrentWindSpeed = value;
                      });
                    },
                  ),
                  FilterChip(
                    selected: _showCurrentSoilMoisture0to7cm,
                    label: const Text("Soil Moisture"),
                    onSelected: (bool value) {
                      setState(() {
                        _showCurrentSoilMoisture0to7cm = value;
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
                  columnSpacing: 20,
                  headingTextStyle: TextStyle(fontWeight: FontWeight.bold),
                  columns: [
                    if (_showName)
                      DataColumn(label: Text('Setup')),
                    if (_showNotes)
                      DataColumn(label: Text('Notes')),
                    if (_showDate)
                      DataColumn(label: Text('Date')),
                    if (_showTime)
                      DataColumn(label: Text('Time')),
                    
                    if (_showCurrentTemperature)
                      DataColumn(label: Text('Temperature')),
                    if (_showDayAccumulatedPrecipitation)
                      DataColumn(label: Text('Precipation')),
                    if (_showCurrentHumidity)
                      DataColumn(label: Text('Humidity')),
                    if (_showCurrentWindSpeed)
                      DataColumn(label: Text('Windspeed')),
                    if (_showCurrentSoilMoisture0to7cm)
                      DataColumn(label: Text('Soil Moisture')),
                    
                    for (final adjustment in widget.component.adjustments)
                      if (_showAdjustment[adjustment] == true)
                        DataColumn(
                          label: Text(
                            adjustment.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  ],
                  rows: widget.setups.reversed.where((setup) {
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
