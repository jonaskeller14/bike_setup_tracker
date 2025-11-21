import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../models/bike.dart';
import '../models/setting.dart';
import '../models/component.dart';
import '../models/adjustment.dart';
import '../services/weather_service.dart';
import '../services/address_service.dart';
import '../services/location_service.dart';
import '../widgets/adjustment_set_list.dart';

class SettingPage extends StatefulWidget {
  final Setting? setting;
  final List<Component> components;
  final List<Bike> bikes;

  const SettingPage({super.key, required this.components, required this.bikes, this.setting});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late Bike bike;
  List<Component> bikeComponents = [];
  late DateTime _selectedDateTime;
  Map<Adjustment, dynamic> adjustmentValues = {};

  final LocationService _locationService = LocationService();
  late LocationData? _currentLocation;

  final AddressService _addressService = AddressService();
  late geo.Placemark? _currentPlace;

  final WeatherService _weatherService = WeatherService();
  late double? temperature;

  @override
  void initState() {
    super.initState();
    bike = widget.setting?.bike ?? widget.bikes.first;
    onBikeChange();
    if (widget.setting == null) fetchLocationAddressWeather();

    _nameController = TextEditingController(text: widget.setting?.name);
    _notesController = TextEditingController(text: widget.setting?.notes ?? '');
    _selectedDateTime = widget.setting?.datetime ?? DateTime.now();
    _currentLocation = widget.setting?.position;
    _currentPlace = widget.setting?.place;
    temperature = widget.setting?.temperature;
  }

  Future<void> onBikeChange () async {
    bikeComponents = widget.components.where((c) => c.bike == bike).toList();

    // Set initial values by reading currentSetting
    adjustmentValues.clear();
    if (widget.setting?.bike == bike) {
      for (final adjustmentValue in widget.setting!.adjustmentValues.entries) {
        adjustmentValues[adjustmentValue.key] = adjustmentValue.value;
      }
    } else {
      for (final component in bikeComponents) {
        if (component.currentSetting == null) continue;
        final componentAdjustmentValues = component.currentSetting?.adjustmentValues;
        if (componentAdjustmentValues == null) continue;
        for (final adjustmentValue in componentAdjustmentValues.entries) {
          adjustmentValues[adjustmentValue.key] = adjustmentValue.value;
        }
      }
    }
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

    final tempFuture = _weatherService.fetchTemperature(
      location.latitude!,
      location.longitude!,
    );

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

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (!mounted || pickedDate == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _selectedDateTime.hour,
        _selectedDateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (!mounted || pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        _selectedDateTime.year,
        _selectedDateTime.month,
        _selectedDateTime.day,
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

    if (widget.setting == null) {
      Navigator.pop(
        context,
        Setting(
          name: name,
          datetime: _selectedDateTime,
          notes: notes,
          bike: bike,
          adjustmentValues: adjustmentValues,
          position: _currentLocation,
          place: _currentPlace,
          temperature: temperature,
          isCurrent: false,
        ),
      );
    } else {
      Navigator.pop(
        context,
        Setting(
          id: widget.setting!.id,
          name: name,
          datetime: _selectedDateTime,
          notes: notes,
          bike: bike,
          adjustmentValues: adjustmentValues,
          position: widget.setting!.position,
          place: widget.setting!.place,
          temperature: widget.setting!.temperature,
          isCurrent: false,
        ),
      );
    }
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
        title: widget.setting == null ? const Text('Add Setting') : const Text('Edit Setting'),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              ActionChip(
                avatar: const Icon(Icons.calendar_today),
                label: Text(
                  DateFormat('yyyy-MM-dd').format(_selectedDateTime),
                ),
                onPressed: _pickDate,
              ),
              ActionChip(
                avatar: const Icon(Icons.access_time),
                label: Text(
                  DateFormat('HH:mm').format(_selectedDateTime),
                ),
                onPressed: _pickTime,
              ),
              Chip(
                avatar: _locationService.status == LocationStatus.locationFound
                    ? Icon(Icons.my_location)
                    : (_locationService.status == LocationStatus.findingLocation
                          ? Icon(Icons.location_searching)
                          : (_locationService.status == LocationStatus.idle
                                ? Icon(Icons.location_searching)
                                : Icon(Icons.location_disabled))),
                label: _locationService.status == LocationStatus.locationFound
                    ? Text("${_currentPlace?.thoroughfare} ${_currentPlace?.subThoroughfare}, ${_currentPlace?.locality}, ${_currentPlace?.country}")
                    : (_locationService.status == LocationStatus.idle
                          ? const Text("-")
                          : (_locationService.status == LocationStatus.findingLocation
                                ? const Text("Finding Location...")
                                : (_locationService.status == LocationStatus.noPermission
                                      ? const Text("No location permision")
                                      : (_locationService.status == LocationStatus.noService
                                            ? const Text("No location service")
                                            : const Text("Error"))))),
              ),
              Chip(
                avatar: Icon(Icons.arrow_upward),
                label: _currentLocation?.altitude == null ? const Text("-") : Text("Altitude: ${_currentLocation?.altitude?.round()} m"),
              ),
              Chip(
                avatar: Icon(Icons.thermostat), 
                label: temperature == null ? const Text("-") : Text("${temperature?.toStringAsFixed(1)} °C")
              ),
            ],
          ),
          Text(
            "Weather data by Open-Meteo.com",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Bike>(
            initialValue: bike,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Bike',
              border: OutlineInputBorder(),
              hintText: "Choose a bike for this component",
            ),
            items: widget.bikes.map((b) {
              return DropdownMenuItem<Bike>(
                value: b,
                child: Text(b.name, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (Bike? newBike) {
              if (newBike == null) return;
              setState(() {
                bike = newBike;
                onBikeChange();
              });
            },
          ),
          const SizedBox(height: 24),
          if (bikeComponents.isEmpty)
            const Center(
              child: Text(
                'No components available.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...bikeComponents.map((bikeComponent) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(bikeComponent.name),
                      subtitle: Text('${bikeComponent.adjustments.length} adjustments'),
                      leading: const Icon(Icons.tune),
                    ),
                    AdjustmentSetList(
                      key: ValueKey(bikeComponent.id),
                      adjustments: bikeComponent.adjustments,
                      initialAdjustmentValues: bikeComponent.currentSetting?.adjustmentValues ?? <Adjustment, dynamic>{},
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
