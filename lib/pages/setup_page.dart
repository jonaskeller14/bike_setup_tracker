import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:provider/provider.dart';
import '../models/weather.dart';
import '../models/person.dart';
import '../models/rating.dart';
import '../models/bike.dart';
import '../models/setup.dart';
import '../models/component.dart';
import '../models/adjustment/adjustment.dart';
import '../models/app_settings.dart';
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
import '../widgets/dialogs/update_location_address_weather.dart';
import '../widgets/setup_page_legend.dart';

class SetupPage extends StatefulWidget {
  final Setup? setup;
  final List<Component> components;
  final Map<String, Bike> bikes;
  final Map<String, Person> persons;
  final Map<String, Rating> ratings;
  final Setup? Function({required DateTime datetime, String? bike, String? person}) getPreviousSetupbyDateTime;

  const SetupPage({
    super.key,
    required this.components,
    required this.bikes,
    required this.persons,
    required this.ratings,
    this.setup,
    required this.getPreviousSetupbyDateTime,
  });

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TabController _tabController;
  int? _tabControllerLength;
  
  Setup? _previousBikeSetup;
  Setup? _previousPersonSetup;
  late String bike;
  late String? _person;
  List<Component> bikeComponents = [];
  late DateTime _selectedDateTime;
  late DateTime _initialDateTime;
  Map<String, dynamic> _bikeAdjustmentValues = {};
  Map<String, dynamic> _personAdjustmentValues = {};
  final Map<String, dynamic> _ratingAdjustmentValues = {};
  final Map<String, dynamic> _initialBikeAdjustmentValues = {};
  final Map<String, dynamic> _initialPersonAdjustmentValues = {};
  final Map<String, dynamic> _initialRatingAdjustmentValues = {};
  Map<String, dynamic> _danglingBikeAdjustmentValues = {};
  Map<String, dynamic> _danglingPersonAdjustmentValues = {};
  final Map<String, dynamic> _danglingRatingAdjustmentValues = {};
  final Map<String, Rating> _filteredRatings = {};

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

    _onBikeChange(widget.setup?.bike ?? widget.bikes.keys.first);

    if (widget.setup == null) fetchLocationAddressWeather();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final int newLength = 1 + (context.read<AppSettings>().enablePerson ? 1 : 0) + (context.read<AppSettings>().enableRating ? 1 : 0);
    if (_tabControllerLength == null || _tabControllerLength != newLength) {
      _tabControllerLength = newLength;
      _tabController = TabController(
        initialIndex: 0,
        length: newLength,
        vsync: this,
      );
    }
  }

  void _setAdjustmentValuesFromInitialAdjustmentValues() {
    _bikeAdjustmentValues.clear();
    _bikeAdjustmentValues = Map.from(_initialBikeAdjustmentValues);
    if (widget.setup != null) {
      // Overwrite adjustment values with those from the setup being edited (no effect for current Setup)
      _bikeAdjustmentValues.addAll(widget.setup!.bikeAdjustmentValues);
    }

    _personAdjustmentValues.clear();
    _personAdjustmentValues = Map.from(_initialPersonAdjustmentValues);
    if (widget.setup != null) {
      // Overwrite adjustment values with those from the setup being edited (no effect for current Setup)
      _personAdjustmentValues.addAll(widget.setup!.personAdjustmentValues);
    }

    _ratingAdjustmentValues.clear();
    if (widget.setup != null) {
      _ratingAdjustmentValues.addAll(widget.setup!.ratingAdjustmentValues);
    }
  }

  void _setInitialAdjustmentValues() {
    // Case: Component added after setups --> Date is changed to Setup without new component --> initial values need to be null
    _initialBikeAdjustmentValues.clear();
    // All components of a bike have the same current Setup! see _HomePageState.updateSetupsAfter()
    if (_previousBikeSetup != null) _initialBikeAdjustmentValues.addAll(_previousBikeSetup!.bikeAdjustmentValues);


    _initialPersonAdjustmentValues.clear();
    if (_previousPersonSetup != null) _initialPersonAdjustmentValues.addAll(_previousPersonSetup!.personAdjustmentValues);

    _initialRatingAdjustmentValues.clear();
  }

  void _setDanglingAdjustmentValues() {
    if (widget.setup == null) return;
    
    _danglingBikeAdjustmentValues = Map.from(_bikeAdjustmentValues);
    for (final bikeComponent in bikeComponents) {
      for (final bikeComponentAdj in bikeComponent.adjustments) {
        _danglingBikeAdjustmentValues.remove(bikeComponentAdj.id);
      }
    }

    _danglingPersonAdjustmentValues = Map.from(_personAdjustmentValues);
    if (widget.persons[_person] != null) {
      for (final personAdj in widget.persons[_person]!.adjustments) {
        _danglingPersonAdjustmentValues.remove(personAdj.id);
      }
    }

    _danglingRatingAdjustmentValues.clear();
    _danglingRatingAdjustmentValues.addAll(_ratingAdjustmentValues);
    _danglingRatingAdjustmentValues.removeWhere((ratingId, _) => 
        widget.ratings[ratingId] == null || 
        widget.ratings[ratingId]!.filterType == FilterType.global || 
        (widget.ratings[ratingId]!.filterType == FilterType.person && widget.ratings[ratingId]!.filter == _person) || 
        (widget.ratings[ratingId]!.filterType == FilterType.bike && widget.ratings[ratingId]!.filter == bike) || 
        (widget.ratings[ratingId]!.filterType == FilterType.componentType && bikeComponents.map((c) => c.componentType.toString()).contains(widget.ratings[ratingId]!.filter)) || 
        (widget.ratings[ratingId]!.filterType == FilterType.component && bikeComponents.map((c) => c.id).contains(widget.ratings[ratingId]!.filter))
    );
  }

  void _setFilteredRatings() {
    _filteredRatings.clear();
    for (final rating in widget.ratings.values) {
      switch (rating.filterType) {
        case FilterType.global:
          _filteredRatings[rating.id] = rating;
        case FilterType.bike:
          if (rating.filter == bike) _filteredRatings[rating.id] = rating;
        case FilterType.componentType:
          if (bikeComponents.any((c) => c.componentType.toString() == rating.filter)) _filteredRatings[rating.id] = rating;
        case FilterType.component:
          if (bikeComponents.any((c) => c.id == rating.filter)) _filteredRatings[rating.id] = rating;
        case FilterType.person:
          if (rating.filter == _person) _filteredRatings[rating.id] = rating;
      }
    }
  }

  void _onBikeChange (String? newBike) {
    if (newBike == null) return;
    setState(() {
      bike = newBike;
      _person = widget.bikes[bike]?.person;
      bikeComponents = widget.components.where((c) => c.bike == bike).toList();
      _previousBikeSetup = widget.getPreviousSetupbyDateTime(datetime: _selectedDateTime, bike: bike);
      _previousPersonSetup = widget.getPreviousSetupbyDateTime(datetime: _selectedDateTime, person: _person);
      _setInitialAdjustmentValues();
      _setAdjustmentValuesFromInitialAdjustmentValues();
      _setDanglingAdjustmentValues();
      _setFilteredRatings();
    });
    _changeListener();
  }

  Future<void> fetchLocationAddressWeather() async {
    await updateLocation();
    if (_currentLocation == null) return;

    updateWeather();
    updateAddress();
  }

  Future<void> updateLocation() async {
    setState(() {
      _locationService.status = LocationStatus.searching;
    });

    final newLocation = await _locationService.fetchLocation();
    
    if (!mounted) return;
    if (newLocation == null) {
      setState(() {});  // LocationStatus Error was set in _locationService.fetchLocation()
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true,
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        duration: Duration(seconds: 2),
        content: Text('Error fetching location.', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
      ));
      return;
    }

    if (!mounted) return;
    setState(() {
      _currentLocation = newLocation;
    });
    _changeListener();
  }

  Future<void> updateAddress() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true,
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        content: Text('Cannot update address without location.', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
        backgroundColor: Theme.of(context).colorScheme.errorContainer
      ));
      
      return;
    }

    setState(() {
      _addressService.status = AddressStatus.searching;
    });

    final newAddress = await _addressService.fetchAddress(
      lat: _currentLocation!.latitude!,
      lon: _currentLocation!.longitude!,
    );

    if (!mounted) return;
    if (newAddress == null) {
      setState(() {
        _addressService.status = AddressStatus.error;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true,
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        duration: Duration(seconds: 2),
        content: Text('Error fetching address.', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
        backgroundColor: Theme.of(context).colorScheme.errorContainer
      ));
      return;
    }

    if (!mounted) return;
    setState(() {
      _currentPlace = newAddress;
    });
    _changeListener();
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.setup?.name ?? '') || 
        _notesController.text.trim() != (widget.setup?.notes ?? '') || 
        _initialDateTime != _selectedDateTime || 

        _currentLocation?.latitude != widget.setup?.position?.latitude || 
        _currentLocation?.longitude != widget.setup?.position?.longitude || 
        _currentLocation?.altitude != widget.setup?.position?.altitude || 

        _currentWeather?.currentTemperature != widget.setup?.weather?.currentTemperature ||
        _currentWeather?.currentHumidity != widget.setup?.weather?.currentHumidity ||
        _currentWeather?.dayAccumulatedPrecipitation != widget.setup?.weather?.dayAccumulatedPrecipitation ||
        _currentWeather?.currentWindSpeed != widget.setup?.weather?.currentWindSpeed ||
        _currentWeather?.currentSoilMoisture0to7cm != widget.setup?.weather?.currentSoilMoisture0to7cm || 
        
        bike != (widget.setup?.bike ?? widget.bikes.keys.first) || 
        _person != (widget.setup?.person ?? widget.bikes[bike]?.person) ||

        //FIXME: Iterate over adjustmentValues instead initialADjustmentValues?
        filterForValidBikeAdjustmentValues(_initialBikeAdjustmentValues).keys.any((adj) => _initialBikeAdjustmentValues[adj] != _bikeAdjustmentValues[adj]) || 
        filterForValidPersonAdjustmentValues(_initialPersonAdjustmentValues).keys.any((adj) => _initialPersonAdjustmentValues[adj] != _personAdjustmentValues[adj]) || 
        _ratingAdjustmentValues.keys.any((adj) => widget.setup?.ratingAdjustmentValues[adj] != _ratingAdjustmentValues[adj]);

    if (_formHasChanges != hasChanges) {
      setState(() {
        _formHasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.removeListener(_changeListener);
    _nameController.dispose();
    _notesController.removeListener(_changeListener);
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final tmpPreviousBikeSetup = _previousBikeSetup;
    final tmpPreviousPersonSetup = _previousPersonSetup;

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true,
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        content: Text('Date and Time must be in the past.', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
        backgroundColor: Theme.of(context).colorScheme.errorContainer
      ));
    }

    setState(() {
      _selectedDateTime = newDateTime;
      _previousBikeSetup = widget.getPreviousSetupbyDateTime(datetime: _selectedDateTime, bike: bike);
      _previousPersonSetup = widget.getPreviousSetupbyDateTime(datetime: _selectedDateTime, person: _person);
      _setInitialAdjustmentValues();
    });
    _changeListener();
    askAndUpdateWeather();
    

    if (_previousBikeSetup == tmpPreviousBikeSetup && _previousPersonSetup == tmpPreviousPersonSetup) return;
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
    final tmpPreviousBikeSetup = _previousBikeSetup;
    final tmpPreviousPersonSetup = _previousPersonSetup;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (!mounted || pickedTime == null) return;
    
    DateTime newDateTime = _selectedDateTime.copyWith(hour: pickedTime.hour, minute: pickedTime.minute);
    if (newDateTime == _selectedDateTime) return;
    if (newDateTime.isAfter(DateTime.now())) {
      newDateTime = DateTime.now();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true,
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        content: Text('Date and Time must be in the past.', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
        backgroundColor: Theme.of(context).colorScheme.errorContainer
      ));
    }

    setState(() {
      _selectedDateTime = newDateTime;
      _previousBikeSetup = widget.getPreviousSetupbyDateTime(datetime: _selectedDateTime, bike: bike);
      _previousPersonSetup = widget.getPreviousSetupbyDateTime(datetime: _selectedDateTime, person: _person);
      _setInitialAdjustmentValues();
    });
    _changeListener();
    askAndUpdateWeather();

    if (_previousBikeSetup == tmpPreviousBikeSetup && _previousPersonSetup == tmpPreviousPersonSetup) return;
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
    await updateWeather();
  }

  Future<void> updateWeather() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true,
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        duration: Duration(seconds: 2),
        content: Text('Cannot update weather without location.', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
        backgroundColor: Theme.of(context).colorScheme.errorContainer
      ));
      return;
    }

    setState(() {
      _weatherService.status = WeatherStatus.searching;
    });

    final currentWeather = await _weatherService.fetchWeather(
      lat: _currentLocation!.latitude!,
      lon: _currentLocation!.longitude!,
      datetime: _selectedDateTime,
    );

    if (!mounted) return;
    if (currentWeather == null) {
      setState(() {
        _weatherService.status = WeatherStatus.error;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true,
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        duration: Duration(seconds: 2),
        content: Text('Error fetching weather.', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
        backgroundColor: Theme.of(context).colorScheme.errorContainer
      ));
      return;
    }
    
    if (!mounted) return;
    setState(() {
      _currentWeather = currentWeather;
    });
    _changeListener();
  }

  Map<String, dynamic> filterForValidBikeAdjustmentValues(Map<String, dynamic> bikeAdjustmentValues) {
    // Filter adjustmentValues to only include those relevant to the selected bike
    // Keep adjustments when editing (handle case: Component was moved to another bike and setting is edited)
    Map<String, dynamic> filteredBikeAdjustmentValues = Map.from(bikeAdjustmentValues);
    for (final component in widget.components.where((c) => c.bike != bike)) {
      for (final adjustment in component.adjustments) {
        if (widget.setup != null && widget.setup!.bikeAdjustmentValues.keys.contains(adjustment.id)) continue;
        filteredBikeAdjustmentValues.remove(adjustment.id);
      }
    }
    return filteredBikeAdjustmentValues;
  }

  Map<String, dynamic> filterForValidPersonAdjustmentValues(Map<String, dynamic> personAdjustmentValues) {
    // Filter adjustmentValues to only include those relevant to the selected person
    // Keep adjustments when editing (handle case: bike was moved to another person and setting is edited)
    Map<String, dynamic> filteredPersonAdjustmentValues = Map.from(personAdjustmentValues);
    for (final person in widget.persons.values.where((p) => p.id != _person)) {
      for (final adjustment in person.adjustments) {
        if (widget.setup != null && widget.setup!.personAdjustmentValues.keys.contains(adjustment.id)) continue;
        filteredPersonAdjustmentValues.remove(adjustment.id);
      }
    }
    return filteredPersonAdjustmentValues;
  }

  void _saveSetup() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();

    final notesText = _notesController.text.trim();
    final notes = notesText.isEmpty ? null : notesText;

    _bikeAdjustmentValues = filterForValidBikeAdjustmentValues(_bikeAdjustmentValues);
    _personAdjustmentValues = filterForValidPersonAdjustmentValues(_personAdjustmentValues);

    _formHasChanges = false;
    if (!mounted) return;
    Navigator.pop(
      context,
      Setup(
        id: widget.setup?.id,
        isDeleted: widget.setup?.isDeleted,
        lastModified: DateTime.now(),
        name: name,
        datetime: _selectedDateTime,
        notes: notes,
        bike: bike,
        person: _person,
        bikeAdjustmentValues: _bikeAdjustmentValues,
        personAdjustmentValues: _personAdjustmentValues,
        ratingAdjustmentValues: _ratingAdjustmentValues,
        position: _currentLocation,
        place: _currentPlace,
        weather: _currentWeather,
        isCurrent: false,
      ),
    );
  }

  void _onBikeAdjustmentValueChanged({required Adjustment adjustment, required dynamic newValue}) {
    _bikeAdjustmentValues[adjustment.id] = newValue;
  }

  void _onPersonAdjustmentValueChanged({required Adjustment adjustment, required dynamic newValue}) {
    _personAdjustmentValues[adjustment.id] = newValue;
  }

  void _onRatingAdjustmentValueChanged({required Adjustment adjustment, required dynamic newValue}) {
    _ratingAdjustmentValues[adjustment.id] = newValue;
  }

  void _removeFromBikeAdjustmentValues({required Adjustment adjustment}) {
    _bikeAdjustmentValues.remove(adjustment.id);
  }

  void _removeFromPersonAdjustmentValues({required Adjustment adjustment}) {
    _personAdjustmentValues.remove(adjustment.id);
  }

  void _removeFromRatingAdjustmentValues({required Adjustment adjustment}) {
    _ratingAdjustmentValues.remove(adjustment.id);
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

  Widget _loadingIndicator() {
    return Builder(
      builder: (BuildContext context) {
        final double indicatorSize = DefaultTextStyle.of(context).style.fontSize ?? 15;
        return SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: CircularProgressIndicator(
            strokeWidth: indicatorSize / 6, 
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();

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
          child: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              onChanged: (text) {
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                labelText: 'Setup Name',
                                border: OutlineInputBorder(),
                                hintText: 'Enter setup name',
                                fillColor: Colors.orange.withValues(alpha: 0.08),
                                filled: widget.setup != null && _nameController.text.trim() != widget.setup?.name,
                              ),
                              validator: _validateName,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _notesController,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              minLines: 2,
                              onChanged: (text) {
                                setState(() {});
                              },
                              maxLines: null,
                              decoration: InputDecoration(
                                labelText: 'Notes (optional)',
                                border: OutlineInputBorder(),
                                hintText: 'Add notes (optional)',
                                fillColor: Colors.orange.withValues(alpha: 0.08),
                                filled: widget.setup != null && (_notesController.text.trim() != (widget.setup?.notes ?? '')),
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
                                    DateFormat(appSettings.dateFormat).format(_selectedDateTime),
                                  ),
                                  backgroundColor: widget.setup != null && (_selectedDateTime.year != widget.setup?.datetime.year || _selectedDateTime.month != widget.setup?.datetime.month || _selectedDateTime.day != widget.setup?.datetime.day) ? Colors.orange.withValues(alpha: 0.08) : null,
                                  onPressed: _pickDate,
                                ),
                                ActionChip(
                                  avatar: const Icon(Icons.access_time),
                                  label: Text(
                                    DateFormat(appSettings.timeFormat).format(_selectedDateTime),
                                  ),
                                  backgroundColor: widget.setup != null && (_selectedDateTime.hour != widget.setup?.datetime.hour || _selectedDateTime.minute != widget.setup?.datetime.minute) ? Colors.orange.withValues(alpha: 0.08) : null,
                                  onPressed: _pickTime,
                                ),
                                ActionChip(
                                  backgroundColor: widget.setup != null && (_currentLocation?.latitude != widget.setup?.position?.latitude || _currentLocation?.longitude != widget.setup?.position?.longitude) ? Colors.orange.withValues(alpha: 0.08) : null,
                                  onPressed: () async {
                                    _locationService.status = LocationStatus.idle;
                                    _addressService.status = AddressStatus.idle;
                                    final result = await showSetLocationDialog(context: context, location: _currentLocation, address: _currentPlace);
                                    if (result == null) return;
                                    setState(() {
                                      _locationService.status = LocationStatus.success;
                                      _addressService.status = AddressStatus.success;
                                      _currentLocation = result[0];
                                      _currentPlace = result[1];
                                    });
                                    askAndUpdateWeather();
                                    _changeListener();
                                  },
                                  avatar: (_locationService.status == LocationStatus.searching || _addressService.status == AddressStatus.searching)
                                    ? const Icon(Icons.location_searching)
                                    : _currentPlace != null
                                      ? const Icon(Icons.my_location)
                                      : _locationService.status == LocationStatus.noPermission
                                        ? const Icon(Icons.location_disabled)
                                        : _locationService.status == LocationStatus.noService
                                          ? const Icon(Icons.location_disabled)
                                          : const Icon(Icons.my_location),
                                  label: (_locationService.status == LocationStatus.searching || _addressService.status == AddressStatus.searching)
                                    ? _loadingIndicator()
                                    : _currentPlace != null
                                      ? Text("${_currentPlace?.locality}, ${_currentPlace?.isoCountryCode}")
                                      : _locationService.status == LocationStatus.noPermission
                                        ? const Text("No location permision")
                                        : _locationService.status == LocationStatus.noService
                                          ? const Text("No location service")
                                          : const Text("-"),
                                ),
                                ActionChip(
                                  avatar: Icon(Icons.arrow_upward),
                                  label: _locationService.status == LocationStatus.searching 
                                    ? _loadingIndicator() 
                                    : (_currentLocation?.altitude == null 
                                      ? const Text("-") 
                                      : Text("${Setup.convertAltitudeFromMeters(_currentLocation!.altitude!, appSettings.altitudeUnit).round()} ${appSettings.altitudeUnit}")),
                                  backgroundColor: widget.setup != null && _currentLocation?.altitude != widget.setup?.position?.altitude ? Colors.orange.withValues(alpha: 0.08) : null,
                                  onPressed: () async {
                                    final altitude = await showSetAltitudeDialog(context, _currentLocation?.altitude);
                                    if (altitude == null) return;
                                    final newMap = _currentLocation == null ? <String, dynamic>{} : Setup.locationDataToJson(_currentLocation!);
                                    newMap['altitude'] = altitude;
                                    newMap['time'] = newMap['time'] != null ? DateTime.parse(newMap['time']).millisecondsSinceEpoch.toDouble() : null; // convert String -> DateTime
                                    setState(() {
                                      _currentLocation = LocationData.fromMap(newMap);
                                    });
                                    _changeListener();
                                  },
                                ),
                                ActionChip(
                                  avatar: Icon(Icons.thermostat), 
                                  label: _weatherService.status == WeatherStatus.searching 
                                    ? _loadingIndicator()
                                    : (_currentWeather?.currentTemperature == null 
                                      ? const Text("-") 
                                      : Text("${Weather.convertTemperatureFromCelsius(_currentWeather!.currentTemperature!, appSettings.temperatureUnit).round()} ${appSettings.temperatureUnit}")),
                                  backgroundColor: widget.setup != null && _currentWeather?.currentTemperature != widget.setup?.weather?.currentTemperature ? Colors.orange.withValues(alpha: 0.08) : null,
                                  onPressed: () async {
                                    final temperature = await showSetCurrentTemperatureDialog(context, _currentWeather);
                                    setState(() {
                                      if (temperature != null) {
                                        _currentWeather ??= Weather(currentDateTime: _selectedDateTime);
                                        _currentWeather = _currentWeather?.copyWith(currentTemperature: temperature);
                                      }
                                    });
                                    _changeListener();
                                  },
                                ),
                                ActionChip(
                                  avatar: Icon(Icons.opacity), 
                                  label: _weatherService.status == WeatherStatus.searching 
                                    ? _loadingIndicator()
                                    : (_currentWeather?.currentHumidity == null 
                                      ? const Text("-") 
                                      : Text("${_currentWeather?.currentHumidity?.round()} %")),
                                  backgroundColor: widget.setup != null && _currentWeather?.currentHumidity != widget.setup?.weather?.currentHumidity ? Colors.orange.withValues(alpha: 0.08) : null,
                                  onPressed: () async {
                                    final humidity = await showSetCurrentHumidityDialog(context, _currentWeather);
                                    setState(() {
                                      if (humidity != null) {
                                        _currentWeather ??= Weather(currentDateTime: _selectedDateTime);
                                        _currentWeather = _currentWeather?.copyWith(currentHumidity: humidity);
                                      }
                                    });
                                    _changeListener();
                                  },
                                ),
                                ActionChip(
                                  avatar: Icon(Icons.water_drop), 
                                  label: _weatherService.status == WeatherStatus.searching 
                                    ? _loadingIndicator()
                                    : (_currentWeather?.dayAccumulatedPrecipitation == null 
                                      ? const Text("-") 
                                      : Text("${Weather.convertPrecipitationFromMm(_currentWeather!.dayAccumulatedPrecipitation!, appSettings.precipitationUnit).round()} ${appSettings.precipitationUnit}")),
                                  backgroundColor: widget.setup != null && _currentWeather?.dayAccumulatedPrecipitation != widget.setup?.weather?.dayAccumulatedPrecipitation ? Colors.orange.withValues(alpha: 0.08) : null,
                                  onPressed: () async{
                                    final precipitation = await showSetDayAccumulatedPrecipitationDialog(context, _currentWeather);
                                    setState(() {
                                      if (precipitation != null) {
                                        _currentWeather ??= Weather(currentDateTime: _selectedDateTime);
                                        _currentWeather = _currentWeather?.copyWith(dayAccumulatedPrecipitation: precipitation);
                                      }
                                    });
                                    _changeListener();
                                  },
                                ),
                                ActionChip(
                                  avatar: Icon(Icons.air), 
                                  label: _weatherService.status == WeatherStatus.searching 
                                    ? _loadingIndicator()
                                    : (_currentWeather?.currentWindSpeed == null 
                                      ? const Text("-") 
                                      : Text("${Weather.convertWindSpeedFromKmh(_currentWeather!.currentWindSpeed!, appSettings.windSpeedUnit).round()} ${appSettings.windSpeedUnit}")),
                                  backgroundColor: widget.setup != null && _currentWeather?.currentWindSpeed != widget.setup?.weather?.currentWindSpeed ? Colors.orange.withValues(alpha: 0.08) : null,
                                  onPressed: () async{
                                    final windSpeed = await showSetCurrentWindSpeedDialog(context, _currentWeather);
                                    setState(() {
                                      if (windSpeed != null) {
                                        _currentWeather ??= Weather(currentDateTime: _selectedDateTime);
                                        _currentWeather = _currentWeather?.copyWith(currentWindSpeed: windSpeed);
                                      }
                                    });
                                    _changeListener();
                                  },
                                ),
                                ActionChip(
                                  avatar: Icon(Icons.spa), 
                                  label: _weatherService.status == WeatherStatus.searching 
                                    ? _loadingIndicator()
                                    : (_currentWeather?.currentSoilMoisture0to7cm == null 
                                      ? const Text("-") 
                                      : Text("${_currentWeather?.currentSoilMoisture0to7cm?.toStringAsFixed(2)} m³/m³")),
                                  backgroundColor: widget.setup != null && _currentWeather?.currentSoilMoisture0to7cm != widget.setup?.weather?.currentSoilMoisture0to7cm ? Colors.orange.withValues(alpha: 0.08) : null,
                                  onPressed: () async {
                                    final soilMoisture = await showSetCurrentSoilMoisture0to7cmDialog(context, _currentWeather);
                                    setState(() {
                                      if (soilMoisture != null) {
                                        _currentWeather ??= Weather(currentDateTime: _selectedDateTime);
                                        _currentWeather = _currentWeather?.copyWith(currentSoilMoisture0to7cm: soilMoisture);
                                      }
                                    });
                                    _changeListener();
                                  },
                                ),
                                PopupMenuButton<Condition>(
                                  onSelected: (value) {
                                    setState(() {
                                      _currentWeather ??= Weather(currentDateTime: _selectedDateTime);
                                      _currentWeather = _currentWeather?.copyWith(condition: value);
                                    });
                                  },
                                  itemBuilder: (BuildContext context) => Condition.values.map((c) => 
                                    PopupMenuItem<Condition>(
                                      value: c,
                                      child: Row(
                                        spacing: 10, 
                                        children: [
                                          c.getConditionsIcon(),
                                          Text(c.value)
                                        ]
                                      ),
                                    ),
                                  ).toList(),
                                  child: Chip(
                                    avatar: _currentWeather?.getConditionsIcon() ?? const Icon(Icons.question_mark_sharp),
                                    label: _weatherService.status == WeatherStatus.searching 
                                      ? _loadingIndicator()
                                      : Text(_currentWeather?.condition?.value ?? "-"),
                                  ),
                                ),
                                ActionChip(
                                  avatar: const Icon(Icons.autorenew),
                                  label: const Text(""),
                                  labelPadding: EdgeInsets.zero,
                                  onPressed: _locationService.status == LocationStatus.searching || _addressService.status == AddressStatus.searching || _weatherService.status == WeatherStatus.searching ? null : () async {
                                    final result = await showUpdateLocationAddressWeatherDialog(context);
                                    switch (result) {
                                      case 0: {
                                        await updateLocation();
                                        if (_currentLocation != null) {
                                          await updateAddress(); 
                                          askAndUpdateWeather();
                                        }
                                      }
                                      case 1: updateAddress();
                                      case 2: updateWeather();
                                      default: return; 
                                    }
                                  }, 
                                ),
                              ],
                            ),
                            Text(
                              "Weather data by Open-Meteo.com",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<Bike>(
                              initialValue: widget.bikes[bike],
                              isExpanded: true,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: 'Bike',
                                border: OutlineInputBorder(),
                                hintText: "Choose a bike for this component",
                                fillColor: Colors.orange.withValues(alpha: 0.08),
                                filled: widget.setup != null && bike != widget.setup?.bike,
                              ),
                              validator: (Bike? newBike) {
                                if (newBike == null) return "Bike cannot be empty.";
                                if (!widget.bikes.values.contains(newBike)) return "Please select valid bike";
                                return null;
                              },
                              items: widget.bikes.values.map((b) {
                                return DropdownMenuItem<Bike>(
                                  value: b,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Icon(Bike.iconData),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(b.name, overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (Bike? b) => _onBikeChange(b?.id),
                            ),
                            const SizedBox(height: 12),
                            if (context.read<AppSettings>().enablePerson || context.read<AppSettings>().enableRating)
                              TabBar.secondary(
                                controller: _tabController,
                                tabs: <Widget>[
                                  const Tab(icon: Icon(Bike.iconData)),
                                  if (context.read<AppSettings>().enablePerson)
                                    const Tab(icon: Icon(Person.iconData)),
                                  if (context.read<AppSettings>().enableRating)
                                  const Tab(icon: Icon(Rating.iconData)),
                                ],
                              ),
                          ],
                        ),
                      ),    
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: <Widget>[
                CustomScrollView(
                  key: const PageStorageKey<String>('tab1_bike'), // Key to keep scroll position
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            if (bikeComponents.isEmpty)
                              SizedBox(
                                height: 100,
                                child: Center(
                                  child: Text(
                                    'No components available.',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                  ),
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
                                        title: Text(bikeComponent.name, style: TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text(Intl.plural(
                                          bikeComponent.adjustments.length,
                                          zero: "No adjustments yet.",
                                          one: "1 adjustment",
                                          other: '${bikeComponent.adjustments.length} adjustments',
                                        )),
                                        leading: Icon(bikeComponent.componentType.getIconData()),
                                      ),
                                      AdjustmentSetList(
                                        key: ValueKey([bikeComponent.id, _previousBikeSetup, _bikeAdjustmentValues.values]),
                                        adjustments: bikeComponent.adjustments,
                                        initialAdjustmentValues: _initialBikeAdjustmentValues,
                                        adjustmentValues: _bikeAdjustmentValues,
                                        onAdjustmentValueChanged: _onBikeAdjustmentValueChanged,
                                        removeFromAdjustmentValues: _removeFromBikeAdjustmentValues,
                                        changeListener: _changeListener,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            if (_danglingBikeAdjustmentValues.isNotEmpty)
                              Opacity(
                                opacity: 0.4,
                                child: Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        title: const Text("Dangling Adjustment Values", style: TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('${_danglingBikeAdjustmentValues.length} adjustments found that are not associated with this bike. Cannot be edited.'),
                                        leading: Icon(Icons.question_mark),
                                      ),
                                      Column(
                                        children: _danglingBikeAdjustmentValues.entries.map((danglingAdjustmentValue) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              spacing: 20,
                                              children: [
                                                Flexible(
                                                  flex: 2,
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text(danglingAdjustmentValue.key),
                                                  ),
                                                ),
                                                Flexible(
                                                  flex: 1,
                                                  child: Align(
                                                    alignment: Alignment.centerRight,
                                                    child: Text(Adjustment.formatValue(danglingAdjustmentValue.value), style: TextStyle(fontFamily: "monospace")),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList()
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const ValueChangeLegend(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (context.read<AppSettings>().enablePerson)
                  CustomScrollView(
                    key: const PageStorageKey<String>('tab2_person'), // Key to keep scroll position
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                            [
                              if (widget.persons[_person] == null)
                                SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: Text(
                                      'No person linked to this bike. \nExit and edit bike to link a person.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                    ),
                                  ),
                                )
                              else
                                Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        title: Text(widget.persons[_person]!.name, style: TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('${widget.persons[_person]!.adjustments.length} attributes'),
                                        leading: const Icon(Person.iconData),
                                      ),
                                      AdjustmentSetList(
                                        key: ValueKey([_person, _previousPersonSetup, _personAdjustmentValues.values]),
                                        adjustments: widget.persons[_person]!.adjustments,
                                        initialAdjustmentValues: _initialPersonAdjustmentValues,
                                        adjustmentValues: _personAdjustmentValues,
                                        onAdjustmentValueChanged: _onPersonAdjustmentValueChanged,
                                        removeFromAdjustmentValues: _removeFromPersonAdjustmentValues,
                                        changeListener: _changeListener,
                                      ),
                                    ],
                                  ),
                                ),
                              if (_danglingPersonAdjustmentValues.isNotEmpty)
                                Opacity(
                                  opacity: 0.4,
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          title: const Text("Dangling Adjustment Values", style: TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text('${_danglingPersonAdjustmentValues.length} attributes found that are not associated with this person. Cannot be edited.'),
                                          leading: Icon(Icons.question_mark),
                                        ),
                                        Column(
                                          children: _danglingPersonAdjustmentValues.entries.map((danglingAdjustmentValue) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                spacing: 20,
                                                children: [
                                                  Flexible(
                                                    flex: 2,
                                                    child: Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Text(danglingAdjustmentValue.key),
                                                    ),
                                                  ),
                                                  Flexible(
                                                    flex: 1,
                                                    child: Align(
                                                      alignment: Alignment.centerRight,
                                                      child: Text(Adjustment.formatValue(danglingAdjustmentValue.value), style: TextStyle(fontFamily: "monospace")),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList()
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ]
                          ),
                        ),
                      ),
                    ],
                  ),
                if (context.read<AppSettings>().enableRating)
                  CustomScrollView(
                    key: const PageStorageKey<String>('tab3_rating'), // Key to keep scroll position
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                            [
                              if (_filteredRatings.isEmpty)
                                SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: Text(
                                      'No ratings available. \nExit and add rating procedure.',
                                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                    ),
                                  ),
                                )
                              else
                                ..._filteredRatings.values.map((rating) {
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          title: Text(rating.name, style: TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(Intl.plural(
                                                rating.adjustments.length,
                                                zero: "No adjustments yet.",
                                                one: "1 adjustment",
                                                other: '${rating.adjustments.length} adjustments',
                                              )),
                                              Spacer(),
                                              if (rating.filterType == FilterType.bike)
                                                Icon(Bike.iconData),
                                              if (rating.filterType == FilterType.person)
                                                Icon(Person.iconData),
                                              if (rating.filterType == FilterType.componentType)
                                                Icon((ComponentType.values.firstWhereOrNull((ct) => ct.toString() == rating.filter) ?? ComponentType.other).getIconData()),
                                              if (rating.filterType == FilterType.component)
                                                Icon((widget.components.firstWhereOrNull((c) => c.id == rating.filter)?.componentType ?? ComponentType.other).getIconData()),
                                              const SizedBox(width: 2),
                                              if (rating.filterType == FilterType.bike)
                                                Text(
                                                  widget.bikes[rating.filter]?.name ?? "-",
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              if (rating.filterType == FilterType.person)
                                                Text(
                                                  widget.persons[rating.filter]?.name ?? "-",
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              if (rating.filterType == FilterType.componentType)
                                                Text(
                                                  ComponentType.values.firstWhereOrNull((ct) => ct.toString() == rating.filter)?.value ?? "-",
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              if (rating.filterType == FilterType.component)
                                                Text(
                                                  widget.components.firstWhereOrNull((c) => c.id == rating.filter)?.name ?? "-",
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                          leading: const Icon(Rating.iconData),
                                        ),
                                        AdjustmentSetList(
                                          key: ValueKey([rating.id, _previousBikeSetup, _bikeAdjustmentValues.values]),
                                          adjustments: rating.adjustments,
                                          initialAdjustmentValues: _initialRatingAdjustmentValues,
                                          adjustmentValues: _ratingAdjustmentValues,
                                          onAdjustmentValueChanged: _onRatingAdjustmentValueChanged,
                                          removeFromAdjustmentValues: _removeFromRatingAdjustmentValues,
                                          changeListener: _changeListener,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              if (_danglingRatingAdjustmentValues.isNotEmpty)
                              Opacity(
                                opacity: 0.4,
                                child: Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        title: const Text("Dangling Rating Values", style: TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('${_danglingRatingAdjustmentValues.length} rating values found that are not associated with this bike/person/components. Cannot be edited.'),
                                        leading: Icon(Icons.question_mark),
                                      ),
                                      Column(
                                        children: _danglingRatingAdjustmentValues.entries.map((danglingAdjustmentValue) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              spacing: 20,
                                              children: [
                                                Flexible(
                                                  flex: 2,
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text(danglingAdjustmentValue.key),
                                                  ),
                                                ),
                                                Flexible(
                                                  flex: 1,
                                                  child: Align(
                                                    alignment: Alignment.centerRight,
                                                    child: Text(Adjustment.formatValue(danglingAdjustmentValue.value), style: TextStyle(fontFamily: "monospace")),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList()
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
