import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../models/weather.dart';
import '../models/bike.dart';
import '../models/setup.dart';
import '../models/component.dart';
import '../models/adjustment.dart';
import '../services/weather_service.dart';
import '../services/address_service.dart';
import '../services/location_service.dart';
import '../widgets/adjustment_set_list.dart';
import '../widgets/dialogs/set_current_temperature.dart';
import '../widgets/dialogs/set_current_windspeed.dart';
import '../widgets/dialogs/set_current_humidity.dart';
import '../widgets/dialogs/set_current_soilMoisture0to7cm.dart';
import '../widgets/dialogs/set_dayAccumulated_precipitation.dart';
import '../widgets/dialogs/set_location.dart';
import '../widgets/dialogs/set_altitude.dart';
import '../widgets/dialogs/discard_changes.dart';

class SetupPage extends StatefulWidget {
  final Setup? setup;
  final List<Component> components;
  final List<Bike> bikes;

  const SetupPage({super.key, required this.components, required this.bikes, this.setup});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late Bike bike;
  List<Component> bikeComponents = [];
  late DateTime _selectedDateTime;
  late DateTime _initialDateTime;
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
    bike = widget.setup?.bike ?? widget.bikes.first;
    _onBikeChange();

    // Set initial adjustment values from components' current setups (for all bikes!)
    for (final component in widget.components) {
      if (component.currentSetup == null) continue;
      final componentAdjustmentValues = component.currentSetup?.adjustmentValues;
      if (componentAdjustmentValues == null) continue;
      for (final componentAdjustmentValue in componentAdjustmentValues.entries) {
        adjustmentValues[componentAdjustmentValue.key] = componentAdjustmentValue.value;
      }
    }

    if (widget.setup == null) {
      fetchLocationAddressWeather();
    } else {
      // Overwrite adjustment values with those from the setup being edited (no effect for current Setup)
      for (final adjustmentValue in widget.setup!.adjustmentValues.entries) {
        adjustmentValues[adjustmentValue.key] = adjustmentValue.value;
      }
    }

    _nameController = TextEditingController(text: widget.setup?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: widget.setup?.notes);
    _notesController.addListener(_changeListener);
    _selectedDateTime = widget.setup?.datetime ?? DateTime.now();
    _initialDateTime = _selectedDateTime;
    _currentLocation = widget.setup?.position;
    _currentPlace = widget.setup?.place;
    _currentWeather = widget.setup?.weather;
  }

  void _onBikeChange (Bike? newBike) {
    if (newBike == null) return;
    setState(() {
      bike = newBike;
      bikeComponents = widget.components.where((c) => c.bike == bike).toList();
    });
    _changeListener();
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

  void _changeListener() {
    final nameHasChanges = _nameController.text.trim() != (widget.setup?.name ?? '');
    final noteHasChanges = _nameController.text.trim() != (widget.setup?.name ?? '');
    final dataTimeHasChanges = _initialDateTime != _selectedDateTime;
    //TODO: location, address, weather IF EDITING
    final bikeHasChanges = bike != (widget.setup?.bike ?? widget.bikes.first);
    //TODO: adjustmentValues
    final hasChanges = nameHasChanges || noteHasChanges || dataTimeHasChanges || bikeHasChanges || ;
    if (_formHasChanges != hasChanges) {
      setState(() {
        _formHasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_changeListener);
    _nameController.dispose();
    _notesController.removeListener(_changeListener);
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
    _changeListener();
    askAndUpdateWeather();
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
    _changeListener();
    askAndUpdateWeather();
  }

  Future<void> askAndUpdateWeather() async {
    if (_currentLocation == null) return;

    final shouldUpdate = await showDialog<bool>(
      context: context, // Assumes this function is inside a StatefulWidget's State class
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Weather?'),
          content: const Text('Do you want to fetch the latest weather data for this location, date and time?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Yes, Update'),
            ),
          ],
        );
      },
    );
    if (shouldUpdate == null || shouldUpdate == false) {
      return;
    }

    final currentWeather = await _weatherService.fetchWeather(
      lat: _currentLocation!.latitude!,
      lon: _currentLocation!.longitude!,
      datetime: _selectedDateTime,
    );
    
    if (!mounted) return;
    
    setState(() {
      _currentWeather = currentWeather;
    });
  }

  void _saveSetup() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();

    final notesText = _notesController.text.trim();
    final notes = notesText.isEmpty ? null : notesText;

    // Filter adjustmentValues to only include those relevant to the selected bike
    // Keep adjustments when editing (handle case: Component was moved to another bike and setting is edited)
    for (final component in widget.components.where((c) => c.bike != bike)) {
      for (final adjustment in component.adjustments) {
        if (widget.setup != null && widget.setup!.adjustmentValues.keys.contains(adjustment)) continue;
        adjustmentValues.remove(adjustment);
      }
    }

    _formHasChanges = false;
    if (!mounted) return;
    Navigator.pop(
      context,
      Setup(
        id: widget.setup?.id,
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
  }

  void _onAdjustmentValueChanged({required Adjustment adjustment, required dynamic newValue}) {
    adjustmentValues[adjustment] = newValue;
  }

  void _removeFromAdjustmentValues({required Adjustment adjustment}) {
    adjustmentValues.remove(adjustment);
  }

  void _handlePopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;
    if (!_formHasChanges) return;
    final shouldDiscard = await showDiscardChangesDialog(context);
    if (!mounted) return;
    if (!shouldDiscard) return;
    Navigator.of(context).pop(null);
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: widget.setup == null ? const Text('Add Setup') : const Text('Edit Setup'),
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveSetup),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                autofocus: widget.setup == null,
                decoration: const InputDecoration(
                  labelText: 'Setup Name',
                  border: OutlineInputBorder(),
                  hintText: 'Enter setup name',
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  ActionChip(
                    onPressed: () async {
                      final geo.Location? newLocation = await showSetLocationDialog(context);
                      if (newLocation == null) return;
                      final List<geo.Placemark> newPlaces = await geo.placemarkFromCoordinates(newLocation.latitude, newLocation.longitude);
                      final newPlace = newPlaces.first;
                      setState(() {
                        _currentLocation = LocationData.fromMap(newLocation.toJson());
                        _currentPlace = newPlace;
                      });
                      askAndUpdateWeather();
                    },
                    avatar: _locationService.status == LocationStatus.locationFound || _currentPlace != null
                        ? Icon(Icons.my_location)
                        : (_locationService.status == LocationStatus.findingLocation
                              ? Icon(Icons.location_searching)
                              : (_locationService.status == LocationStatus.idle
                                    ? Icon(Icons.location_searching)
                                    : Icon(Icons.location_disabled))),
                    label: _locationService.status == LocationStatus.locationFound || _currentPlace != null
                        ? Text("${_currentPlace?.locality}, ${_currentPlace?.isoCountryCode}")
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
                  ActionChip(
                    avatar: Icon(Icons.arrow_upward),
                    label: _currentLocation?.altitude == null ? const Text("-") : Text("Altitude: ${_currentLocation?.altitude?.round()} m"),
                    onPressed: () async {
                      final altitude = await showSetAltitudeDialog(context, _currentLocation?.altitude);
                      if (altitude == null) return;
                      final newMap = _currentLocation == null ? <String, dynamic>{} : Setup.locationDataToJson(_currentLocation!);
                      newMap['altitude'] = altitude;
                      setState(() {
                        _currentLocation = LocationData.fromMap(newMap);
                      });
                    },
                  ),
                  ActionChip(
                    avatar: Icon(Icons.thermostat), 
                    label: _currentWeather?.currentTemperature == null ? const Text("-") : Text("${_currentWeather?.currentTemperature?.round()} °C"),
                    onPressed: () async {
                      final temperature = await showSetCurrentTemperatureDialog(context, _currentWeather);
                      setState(() {
                        if (temperature != null) {
                          _currentWeather ??= Weather(currentDateTime: _selectedDateTime);
                          _currentWeather?.currentTemperature = temperature;
                        }
                      });
                    },
                  ),
                  ActionChip(
                    avatar: Icon(Icons.opacity), 
                    label: _currentWeather?.currentHumidity == null ? const Text("-") : Text("${_currentWeather?.currentHumidity?.round()} %"),
                    onPressed: () async {
                      final humidity = await showSetCurrentHumidityDialog(context, _currentWeather);
                      setState(() {
                        if (humidity != null) {
                          _currentWeather ??= Weather(currentDateTime: _selectedDateTime);
                          _currentWeather?.currentHumidity = humidity;
                        }
                      });
                    },
                  ),
                  ActionChip(
                    avatar: Icon(Icons.water_drop), 
                    label: _currentWeather?.dayAccumulatedPrecipitation == null ? const Text("-") : Text("${_currentWeather?.dayAccumulatedPrecipitation?.round()} mm"),
                    onPressed: () async{
                      final precipitation = await showSetDayAccumulatedPrecipitationDialog(context, _currentWeather);
                      setState(() {
                        if (precipitation != null) {
                          _currentWeather ??= Weather(currentDateTime: _selectedDateTime);
                          _currentWeather?.dayAccumulatedPrecipitation = precipitation;
                        }
                      });
                    },
                  ),
                  ActionChip(
                    avatar: Icon(Icons.air), 
                    label: _currentWeather?.currentWindSpeed == null ? const Text("-") : Text("${_currentWeather?.currentWindSpeed?.round()} km/h"),
                    onPressed: () async{
                      final windSpeed = await showSetCurrentWindSpeedDialog(context, _currentWeather);
                      setState(() {
                        if (windSpeed != null) {
                          _currentWeather ??= Weather(currentDateTime: _selectedDateTime);
                          _currentWeather?.currentWindSpeed = windSpeed;
                        }
                      });                    
                    },
                  ),
                  ActionChip(
                    avatar: Icon(Icons.spa), 
                    label: _currentWeather?.currentSoilMoisture0to7cm == null ? const Text("-") : Text("${_currentWeather?.currentSoilMoisture0to7cm?.toStringAsFixed(2)} m³/m³"),
                    onPressed: () async {
                      final soilMoisture = await showSetCurrentSoilMoisture0to7cmDialog(context, _currentWeather);
                      setState(() {
                        if (soilMoisture != null) {
                          _currentWeather ??= Weather(currentDateTime: _selectedDateTime);
                          _currentWeather?.currentSoilMoisture0to7cm = soilMoisture;
                        }
                      });
                    },
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: 'Bike',
                  border: OutlineInputBorder(),
                  hintText: "Choose a bike for this component",
                ),
                items: widget.bikes.map((b) {
                  return DropdownMenuItem<Bike>(
                    value: b,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.pedal_bike),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(b.name, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _onBikeChange,
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
                          leading: Component.getIcon(bikeComponent.componentType),
                        ),
                        AdjustmentSetList(
                          key: ValueKey(bikeComponent.id),
                          adjustments: bikeComponent.adjustments,
                          initialAdjustmentValues: bikeComponent.currentSetup?.adjustmentValues ?? <Adjustment, dynamic>{},
                          onAdjustmentValueChanged: _onAdjustmentValueChanged,
                          removeFromAdjustmentValues: _removeFromAdjustmentValues,
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
