import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../models/weather.dart';
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
  final _formKey = GlobalKey<FormState>();
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
  Weather? _currentWeather;

  @override
  void initState() {
    super.initState();
    bike = widget.setting?.bike ?? widget.bikes.first;
    _onBikeChange();
    if (widget.setting == null) fetchLocationAddressWeather();

    _nameController = TextEditingController(text: widget.setting?.name);
    _notesController = TextEditingController(text: widget.setting?.notes ?? '');
    _selectedDateTime = widget.setting?.datetime ?? DateTime.now();
    _currentLocation = widget.setting?.position;
    _currentPlace = widget.setting?.place;
    _currentWeather = widget.setting?.weather;
  }

  Future<void> _onBikeChange () async {
    adjustmentValues.clear();
    bikeComponents = widget.components.where((c) => c.bike == bike).toList();

    // Set initial values by reading currentSetting
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

    final weatherFuture = _weatherService.fetchWeather(
      lat: location.latitude!,
      lon: location.longitude!,
      datetime: _selectedDateTime,
    );

    final placemarkFuture = _addressService.getPlacemark(
      lat: location.latitude!,
      lon: location.longitude!,
    );

    // Wait for both futures
    final results = await Future.wait([weatherFuture, placemarkFuture]);

    if (!mounted) return;

    setState(() {
      _currentWeather = results[0] as Weather?;
      _currentPlace = results[1] as geo.Placemark?;
    });

    if (_currentWeather == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching weather.')),
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
      lastDate: DateTime.now(),
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

    //TODO: Ask with dialog before updating weather
    if (_currentLocation == null) return;
    final currentWeather = await _weatherService.fetchWeather(lat: _currentLocation!.latitude!, lon: _currentLocation!.longitude!, datetime: _selectedDateTime);
    if (!mounted) return;
    setState(() {
      _currentWeather = currentWeather;
    });
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (!mounted || pickedTime == null) return;
    if (_selectedDateTime.copyWith(hour: pickedTime.hour, minute: pickedTime.minute).isAfter(DateTime.now())) {
      pickedTime = TimeOfDay.now();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date and Time must be in the past.')),
      );
    }

    if (!mounted) return;
    setState(() {
      _selectedDateTime = DateTime(
        _selectedDateTime.year,
        _selectedDateTime.month,
        _selectedDateTime.day,
        pickedTime!.hour,
        pickedTime.minute,
      );
    });
    
    //TODO: Ask with dialog before updating weather
    if (_currentLocation == null) return;
    final currentWeather = await _weatherService.fetchWeather(lat: _currentLocation!.latitude!, lon: _currentLocation!.longitude!, datetime: _selectedDateTime);
    if (!mounted) return;
    setState(() {
      _currentWeather = currentWeather;
    });
  }

  void _saveSetting() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();

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
          weather: _currentWeather,
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
          weather: widget.setting!.weather,
          isCurrent: false,
        ),
      );
    }
  }

  void _onAdjustmentValueChanged({required Adjustment adjustment, required dynamic newValue}) {
    adjustmentValues[adjustment] = newValue;
  }

  void _removeFromAdjustmentValues({required Adjustment adjustment}) {
    adjustmentValues.remove(adjustment);
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Setting Name',
                border: OutlineInputBorder(),
                hintText: 'Enter setting name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },            
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
                  label: _locationService.status == LocationStatus.locationFound || _currentPlace != null
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
                ActionChip(
                  avatar: Icon(Icons.thermostat), 
                  label: _currentWeather?.currentTemperature == null ? const Text("-") : Text("${_currentWeather?.currentTemperature?.toStringAsFixed(1)} °C"),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        final currentTempFormKey = GlobalKey<FormState>();
                        final currentTempController = TextEditingController(text: _currentWeather?.currentTemperature.toString() ?? '');
                        return AlertDialog(
                          scrollable: true,
                          title: Text('Set Weather'),
                          content: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Form(
                              key: currentTempFormKey,
                              child: Column(
                                children: <Widget>[
                                  TextFormField(
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),],
                                    controller: currentTempController,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      hintText: 'Temperature',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      suffixText: '°C',
                                      icon: Icon(Icons.thermostat),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter a temperature';
                                      }
                                      final parsedValue = double.tryParse(value);
                                      if (parsedValue == null) return "Please enter valid number";
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () {Navigator.of(context).pop();},
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (!currentTempFormKey.currentState!.validate()) return;
                                setState(() {
                                  _currentWeather ??= Weather(currentDateTime: _selectedDateTime);
                                  _currentWeather?.currentTemperature = double.parse(currentTempController.text.trim());
                                });
                                Navigator.of(context).pop();
                              },
                              child: const Text("Submit"),
                            ),
                          ],
                        );
                      }
                    );
                  },
                ),
                Chip(
                  avatar: Icon(Icons.water_drop), 
                  label: _currentWeather?.currentPrecipitation == null ? const Text("-") : Text("${_currentWeather?.currentPrecipitation?.round()} mm"),
                ),
                Chip(
                  avatar: Icon(Icons.air), 
                  label: _currentWeather?.currentWindSpeed == null ? const Text("-") : Text("${_currentWeather?.currentWindSpeed?.round()} km/h"),
                ),
                Chip(
                  avatar: Icon(Icons.spa), 
                  label: _currentWeather?.currentSoilMoisture0to7cm == null ? const Text("-") : Text("${_currentWeather?.currentSoilMoisture0to7cm?.toStringAsFixed(2)} m³/m³"),
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
                  _onBikeChange();
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
                        removeFromAdjustmentValues: _removeFromAdjustmentValues,
                        onBikeChange: _onBikeChange,
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
