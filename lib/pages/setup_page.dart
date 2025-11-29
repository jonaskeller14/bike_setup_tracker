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
import '../widgets/dialogs/confirmation.dart';
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
  final Setup? Function({required DateTime datetime, required Bike bike}) getPreviousSetupbyDateTime;

  const SetupPage({
    super.key,
    required this.components,
    required this.bikes,
    this.setup,
    required this.getPreviousSetupbyDateTime,
  });

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  Setup? _previousSetup;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late Bike bike;
  List<Component> bikeComponents = [];
  late DateTime _selectedDateTime;
  late DateTime _initialDateTime;
  Map<Adjustment, dynamic> adjustmentValues = {};
  Map<Adjustment, dynamic> _initialAdjustmentValues = {};

  final LocationService _locationService = LocationService();
  LocationData? _currentLocation;

  final AddressService _addressService = AddressService();
  geo.Placemark? _currentPlace;

  final WeatherService _weatherService = WeatherService();
  Weather? _currentWeather;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.setup?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: widget.setup?.notes);
    _notesController.addListener(_changeListener);
    _selectedDateTime = widget.setup?.datetime ?? DateTime.now();
    _initialDateTime = _selectedDateTime;
    _currentLocation = widget.setup?.position;
    _currentPlace = widget.setup?.place;
    _currentWeather = widget.setup?.weather;

    _onBikeChange(widget.setup?.bike ?? widget.bikes.first);

    if (widget.setup == null) fetchLocationAddressWeather();
  }

  void _setAdjustmentValuesFromInitialAdjustmentValues() {
    adjustmentValues.clear();
    adjustmentValues = Map.from(_initialAdjustmentValues);
    if (widget.setup != null) {
      // Overwrite adjustment values with those from the setup being edited (no effect for current Setup)
      for (final adjustmentValue in widget.setup!.adjustmentValues.entries) {
        adjustmentValues[adjustmentValue.key] = adjustmentValue.value; // overwrite and also set values from other bikes
      }
    }
  }

  void _setInitialAdjustmentValues() {
    // Case: Component added after setups --> Date is changed to Setup without new component --> initial values need to be null
    _initialAdjustmentValues.clear();
    
    // All components of a bike have the same current Setup! see _HomePageState.updateSetupsAfter()
    if (_previousSetup != null) _initialAdjustmentValues.addAll(_previousSetup!.adjustmentValues);
  }

  void _onBikeChange (Bike? newBike) {
    if (newBike == null) return;
    setState(() {
      bike = newBike;
      bikeComponents = widget.components.where((c) => c.bike == bike).toList();
      _previousSetup = widget.getPreviousSetupbyDateTime(datetime: _selectedDateTime, bike: bike);
      _setInitialAdjustmentValues();
      _setAdjustmentValuesFromInitialAdjustmentValues();
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
    //TODO: make this more efficient: hasChanges = ... if !hasChanges: hasChanges = ... ......
    final nameHasChanges = _nameController.text.trim() != (widget.setup?.name ?? '');
    final noteHasChanges = _nameController.text.trim() != (widget.setup?.name ?? '');
    final dataTimeHasChanges = _initialDateTime != _selectedDateTime;

    final locationHasChanges = 
    _currentLocation?.latitude != widget.setup?.position?.latitude || 
    _currentLocation?.longitude != widget.setup?.position?.longitude || 
    _currentLocation?.altitude != widget.setup?.position?.altitude;
    
    final weatherHasChanges = 
    _currentWeather?.currentTemperature != widget.setup?.weather?.currentTemperature ||
    _currentWeather?.currentHumidity != widget.setup?.weather?.currentHumidity ||
    _currentWeather?.dayAccumulatedPrecipitation != widget.setup?.weather?.dayAccumulatedPrecipitation ||
    _currentWeather?.currentWindSpeed != widget.setup?.weather?.currentWindSpeed ||
    _currentWeather?.currentSoilMoisture0to7cm != widget.setup?.weather?.currentSoilMoisture0to7cm;

    final bikeHasChanges = bike != (widget.setup?.bike ?? widget.bikes.first);
    bool adjustmentValuesHaveChanges = false;
    for (final initialAdjustmentValue in filterForValidAdjustmentValues(_initialAdjustmentValues).entries) {
      final adj = initialAdjustmentValue.key;
      if (_initialAdjustmentValues[adj] != adjustmentValues[adj]) {
        adjustmentValuesHaveChanges = true;
        break;
      }
    }

    final hasChanges = nameHasChanges || noteHasChanges || dataTimeHasChanges || bikeHasChanges || locationHasChanges || weatherHasChanges || adjustmentValuesHaveChanges;
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
    final tmpPreviousSetup = _previousSetup;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (!mounted || pickedDate == null) return;

    DateTime newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      _selectedDateTime.hour,
      _selectedDateTime.minute,
    );
    if (newDateTime == _selectedDateTime) return;
    if (newDateTime.isAfter(DateTime.now())) {
      newDateTime = DateTime.now();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Date and Time must be in the past.')));
    }

    setState(() {
      _selectedDateTime = newDateTime;
      _previousSetup = widget.getPreviousSetupbyDateTime(datetime: _selectedDateTime, bike: bike);
      _setInitialAdjustmentValues();
    });
    _changeListener();
    askAndUpdateWeather();
    

    if (_previousSetup == tmpPreviousSetup) return;
    final result = await showConfirmationDialog(
      context, 
      title: "Previous Setup has changed. Reset Values?", 
      content: "Your current unsaved adjustments were based on the old setup. Reseting the values will discard these changes.", 
      trueText: "Yes", 
      falseText: "No"
    );
    if (result == false) return;
    setState(() {
      _setAdjustmentValuesFromInitialAdjustmentValues();
    });
    _changeListener();
  }

  Future<void> _pickTime() async {
    final tmpPreviousSetup = _previousSetup;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (!mounted || pickedTime == null) return;
    
    DateTime newDateTime = _selectedDateTime.copyWith(hour: pickedTime.hour, minute: pickedTime.minute);
    if (newDateTime == _selectedDateTime) return;
    if (newDateTime.isAfter(DateTime.now())) {
      newDateTime = DateTime.now();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Date and Time must be in the past.')));
    }

    setState(() {
      _selectedDateTime = newDateTime;
      _previousSetup = widget.getPreviousSetupbyDateTime(datetime: _selectedDateTime, bike: bike);
      _setInitialAdjustmentValues();
    });
    _changeListener();
    askAndUpdateWeather();

    if (_previousSetup == tmpPreviousSetup) return;
    final result = await showConfirmationDialog(
      context, 
      title: "Update Values?", 
      content: "By updating all changes made to the adjustments will be lost.", 
      trueText: "Yes", 
      falseText: "No"
    );
    if (result == false) return;
    setState(() {
      _setAdjustmentValuesFromInitialAdjustmentValues();
    });
    _changeListener();
  }

  Future<void> askAndUpdateWeather() async {
    if (_currentLocation == null) return;

    final result = await showConfirmationDialog(
      context,
      title: 'Update Weather?',
      content: 'Do you want to fetch the latest weather data for this location, date and time?',
      trueText: "Yes",
      falseText: "No",
    );
    if (!result) return;

    final currentWeather = await _weatherService.fetchWeather(
      lat: _currentLocation!.latitude!,
      lon: _currentLocation!.longitude!,
      datetime: _selectedDateTime,
    );
    
    if (!mounted) return;
    
    setState(() {
      _currentWeather = currentWeather;
    });
    _changeListener();
  }

  Map<Adjustment, dynamic> filterForValidAdjustmentValues(Map<Adjustment, dynamic> adjustmentValues) {
    // Filter adjustmentValues to only include those relevant to the selected bike
    // Keep adjustments when editing (handle case: Component was moved to another bike and setting is edited)
    Map<Adjustment, dynamic> filteredAdjustmentValues = Map.from(adjustmentValues);
    for (final component in widget.components.where((c) => c.bike != bike)) {
      for (final adjustment in component.adjustments) {
        if (widget.setup != null && widget.setup!.adjustmentValues.keys.contains(adjustment)) continue;
        filteredAdjustmentValues.remove(adjustment);
      }
    }
    return filteredAdjustmentValues;
  }

  void _saveSetup() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();

    final notesText = _notesController.text.trim();
    final notes = notesText.isEmpty ? null : notesText;

    adjustmentValues = filterForValidAdjustmentValues(adjustmentValues);

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
                autovalidateMode: AutovalidateMode.onUserInteraction,
                minLines: 2,
                maxLines: null,
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
                      _changeListener();
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
                    label: _currentLocation?.altitude == null ? const Text("-") : Text("${_currentLocation?.altitude?.round()} m"),
                    onPressed: () async {
                      final altitude = await showSetAltitudeDialog(context, _currentLocation?.altitude);
                      if (altitude == null) return;
                      final newMap = _currentLocation == null ? <String, dynamic>{} : Setup.locationDataToJson(_currentLocation!);
                      newMap['altitude'] = altitude;
                      newMap['time'] = newMap['time'] != null ? DateTime.parse(newMap['time']).millisecondsSinceEpoch.toDouble() : null;  // convert String -> DateTime
                      setState(() {
                        _currentLocation = LocationData.fromMap(newMap);
                      });
                      _changeListener();
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
                      _changeListener();
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
                      _changeListener();
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
                      _changeListener();
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
                      _changeListener();
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
                      _changeListener();
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
                          key: ValueKey([bikeComponent.id, _previousSetup, adjustmentValues.values]),
                          adjustments: bikeComponent.adjustments,
                          initialAdjustmentValues: _initialAdjustmentValues,
                          adjustmentValues: adjustmentValues,
                          onAdjustmentValueChanged: _onAdjustmentValueChanged,
                          removeFromAdjustmentValues: _removeFromAdjustmentValues,
                          changeListener: _changeListener,
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
