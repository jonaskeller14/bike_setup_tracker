import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../models/setting.dart';
import '../models/component.dart';
import '../models/adjustment.dart';
import '../services/weather_service.dart';
import '../services/address_service.dart';
import '../services/location_service.dart';
import '../widgets/adjustment_set_list.dart';

class AddSettingPage extends StatefulWidget {
  final List<Component> components;

  const AddSettingPage({super.key, required this.components});

  @override
  State<AddSettingPage> createState() => _AddSettingPageState();
}

class _AddSettingPageState extends State<AddSettingPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  Map<Adjustment, dynamic> adjustmentValues = {};

  final LocationService _locationService = LocationService();
  LocationData? _currentLocation;

  final AddressService _addressService = AddressService();
  geo.Placemark? _currentPlace;

  final WeatherService _weatherService = WeatherService(apiKey: const String.fromEnvironment("OWM_KEY"));
  double? temperature;

  @override
  void initState() {
    super.initState();

    // Set initial values by reading currentSetting
    for (final component in widget.components) {
      if (component.currentSetting == null) continue;
      final componentAdjustmentValues = component.currentSetting?.adjustmentValues;
      if (componentAdjustmentValues == null) continue;
      for (final adjustmentValue in componentAdjustmentValues.entries) {
        adjustmentValues[adjustmentValue.key] = adjustmentValue.value;
      }
    }

    fetchLocationAddressWeather();
  }

  Future<void> fetchLocationAddressWeather() async {
    setState(() {
      _locationService.status = LocationStatus.findingLocation;
    });

    // 1 Fetch location
    final location = await _locationService.fetchLocation();
    
    if (!mounted) return;

    if (location == null) {
      setState(() {});
      return;
    }

    setState(() {
      _currentLocation = location;
    });

    // 2 Fetch temperature (can run immediately)
    final tempFuture = _weatherService.fetchTemperature(
      location.latitude!,
      location.longitude!,
    );

    // 3 Fetch address (can run immediately)
    final placemarkFuture = _addressService.getPlacemark(
      lat: location.latitude!,
      lon: location.longitude!,
    );

    // Wait for both futures
    final results = await Future.wait([tempFuture, placemarkFuture]);

    if (!mounted) return;

    setState(() {
      temperature = results[0] as double?;
      _currentPlace = results[1] as geo.Placemark?;
    });

    if (temperature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching temperature.')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    // Pick date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (!mounted || pickedDate == null) return;

    // Pick time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (!mounted || pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _saveSetting() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final notesText = _notesController.text.trim();
    final notes = notesText.isEmpty ? null : notesText;

    Navigator.pop(
      context,
      Setting(
        name: name,
        datetime: _selectedDateTime,
        notes: notes,
        adjustmentValues: adjustmentValues,
        position: _currentLocation,
        place: _currentPlace,
        temperature: temperature,
      ),
    );
  }

  void _onAdjustmentValueChanged(Adjustment adjustment, dynamic newValue) {
    adjustmentValues[adjustment] = newValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Setting'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveSetting),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Setting Name',
              border: OutlineInputBorder(),
              hintText: 'Enter setting name',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
              hintText: 'Add notes (optional)',
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              ActionChip(
                avatar: const Icon(Icons.calendar_today),
                label: Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime),
                ),
                onPressed: _pickDateTime,
              ),
              Chip(
                avatar: _locationService.status == LocationStatus.locationFound
                    ? Icon(Icons.my_location)
                    : (_locationService.status == LocationStatus.findingLocation
                          ? Icon(Icons.location_searching)
                          : Icon(Icons.location_disabled)),
                label: _locationService.status == LocationStatus.locationFound
                    ? Text("${_currentPlace?.thoroughfare} ${_currentPlace?.subThoroughfare}, ${_currentPlace?.locality}, ${_currentPlace?.country}")
                    : (_locationService.status == LocationStatus.findingLocation
                          ? Text("Finding Location...")
                          : (_locationService.status == LocationStatus.noPermission
                                ? Text("No location permision")
                                : (_locationService.status == LocationStatus.noService
                                      ? Text("No location service")
                                      : Text("Error")))),
              ),
              if (_locationService.status == LocationStatus.locationFound) ... [
                Chip(
                  avatar: Icon(Icons.arrow_upward),
                  label: Text("Altitude: ${_currentLocation?.altitude?.round()} m"),
                ),
              ],
              Chip(
                avatar: Icon(Icons.thermostat), 
                label: temperature == null ? const Text("Fetching temperature...") : Text("${temperature?.toStringAsFixed(1)} °C")
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (widget.components.isEmpty)
            const Center(
              child: Text(
                'No components available.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...widget.components.map((component) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(component.name),
                      subtitle: Text('${component.adjustments.length} adjustments'),
                      leading: const Icon(Icons.casino),
                    ),
                    AdjustmentSetList(
                      adjustments: component.adjustments,
                      initialAdjustmentValues: component.currentSetting?.adjustmentValues ?? <Adjustment, dynamic>{},
                      onAdjustmentValueChanged: _onAdjustmentValueChanged,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
