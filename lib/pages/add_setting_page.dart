import 'package:bike_setup_tracker/models/adjustment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/setting.dart';
import '../models/component.dart';
import '../widgets/adjustment_set_list.dart';
import 'dart:async';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;

enum LocationStatus {
  findingLocation,
  noService,
  noPermission,
  locationFound,
}

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

  LocationStatus _locationStatus = LocationStatus.findingLocation;
  Location location = Location();
  LocationData? _currentPosition;
  geo.Placemark? _currentPlace;  

  @override
  void initState() {
    for (final component in widget.components) {
      if (component.currentSetting == null) continue;
      final componentAdjustmentValues = component.currentSetting?.adjustmentValues;
      if (componentAdjustmentValues == null) continue;
      for (final adjustmentValue in componentAdjustmentValues.entries) {
        adjustmentValues[adjustmentValue.key] = adjustmentValue.value;
      }
    }

    fetchLocation();

    super.initState();
  }

  fetchLocation() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        _locationStatus = LocationStatus.noService;
        return;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        _locationStatus = LocationStatus.noPermission;
        return;
      }
    }

    _currentPosition = await location.getLocation();
    if (_currentPosition != null) {
      updateAddress(_currentPosition!.latitude!, _currentPosition!.longitude!);
      _locationStatus = LocationStatus.locationFound;
    }
  }

  Future<void> updateAddress(double lat, double lng) async {
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        setState(() {
          _currentPlace = placemarks.first;
        });
      }
    } catch (e) {
      debugPrint("Failed to get address: $e");
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

    //TODO: Check if at least one value has changed from current setting. Or set adjustmentValues

    Navigator.pop(
      context,
      Setting(
        name: name,
        datetime: _selectedDateTime,
        notes: notes,
        adjustmentValues: adjustmentValues,
        position: _currentPosition,
        place: _currentPlace,
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
                avatar: _locationStatus == LocationStatus.locationFound
                    ? Icon(Icons.my_location)
                    : (_locationStatus == LocationStatus.findingLocation
                          ? Icon(Icons.location_searching)
                          : Icon(Icons.location_disabled)),
                label: _locationStatus == LocationStatus.locationFound
                    ? Text("${_currentPlace?.thoroughfare} ${_currentPlace?.subThoroughfare}, ${_currentPlace?.locality}, ${_currentPlace?.country}")
                    : (_locationStatus == LocationStatus.findingLocation
                          ? Text("Finding Location...")
                          : (_locationStatus == LocationStatus.noPermission
                                ? Text("No location permision")
                                : (_locationStatus == LocationStatus.noService
                                      ? Text("No location service")
                                      : Text("Error")))),
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
