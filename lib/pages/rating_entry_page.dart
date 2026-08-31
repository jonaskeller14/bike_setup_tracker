import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/adjustment/adjustment.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/context/context_place.dart';
import '../models/context/context_position.dart';
import '../models/context/context_weather.dart';
import '../models/person.dart';
import '../models/rating.dart';
import '../models/rating_association.dart';
import '../models/rating_entry.dart';
import '../models/rating_metric.dart';
import '../repositories/app_repository.dart';
import '../services/address_service.dart';
import '../services/elevation_service.dart';
import '../services/location_service.dart';
import '../services/rating_score_service.dart';
import '../services/weather_service.dart';
import '../theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/dialogs/confirmation.dart';
import '../widgets/dialogs/discard_changes.dart';
import '../widgets/items/card_header_tile.dart';
import '../widgets/lists/adjustment_set_list.dart';
import '../widgets/sheets/set_condition.dart';
import '../widgets/sheets/set_location_place.dart';
import '../widgets/sheets/set_weather.dart';

enum RatingEntryPageMode {
  add,
  edit,
  duplicate,
}

class RatingEntryPage extends StatefulWidget {
  final RatingEntry? ratingEntry;
  final RatingEntryPageMode mode;
  final DateTime? initialDateTimeUtc;
  final DateTime? initialDateTimeLocal;
  final Bike? initialBike;
  final String? initialSetupId;

  const RatingEntryPage._({
    super.key,
    this.ratingEntry,
    required this.mode,
    this.initialDateTimeUtc,
    this.initialDateTimeLocal,
    this.initialBike,
    this.initialSetupId,
  });

  factory RatingEntryPage.add({
    Key? key,
    Bike? initialBike,
    DateTime? initialDateTimeUtc,
    DateTime? initialDateTimeLocal,
    String? initialSetupId,
  }) => RatingEntryPage._(
        key: key,
        mode: RatingEntryPageMode.add,
        initialBike: initialBike,
        initialDateTimeUtc: initialDateTimeUtc,
        initialDateTimeLocal: initialDateTimeLocal,
        initialSetupId: initialSetupId,
      );

  factory RatingEntryPage.edit({Key? key, required RatingEntry ratingEntry}) =>
      RatingEntryPage._(key: key, ratingEntry: ratingEntry, mode: RatingEntryPageMode.edit);

  factory RatingEntryPage.duplicate({Key? key, required RatingEntry ratingEntry}) =>
      RatingEntryPage._(key: key, ratingEntry: ratingEntry, mode: RatingEntryPageMode.duplicate);

  @override
  State<RatingEntryPage> createState() => _RatingEntryPageState();
}

class _RatingEntryPageState extends State<RatingEntryPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late String _bike;
  late String _initialBike;

  // Write-once setup provenance. Null while a new entry hasn't been resolved yet;
  // resolved on save. In edit mode it starts from the stored value and can be
  // re-pointed via the drift warning's "Relink" action.
  String? _setupId;

  late DateTime _selectedDateTimeUtc;
  late DateTime _initialDateTimeUtc;
  late DateTime _selectedDateTimeLocal;
  late DateTime _initialDateTimeLocal;

  // Metric answers, keyed by RatingMetric id (== inner Adjustment id).
  final Map<String, dynamic> _metricValues = {};
  final Map<String, dynamic> _initialMetricValues = {};

  final LocationService _locationService = LocationService();
  final ElevationService _elevationService = ElevationService();
  final ValueNotifier<ContextPosition?> _currentLocation = ValueNotifier<ContextPosition?>(null);

  final AddressService _addressService = AddressService();
  final ValueNotifier<geo.Placemark?> _currentPlace = ValueNotifier<geo.Placemark?>(null);

  final WeatherService _weatherService = WeatherService();
  final ValueNotifier<ContextWeather?> _currentWeather = ValueNotifier<ContextWeather?>(null);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ratingEntry?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: widget.ratingEntry?.notes);
    _notesController.addListener(_changeListener);

    final now = DateTime.now();
    _selectedDateTimeLocal = widget.ratingEntry?.dateTimeLocal ?? widget.initialDateTimeLocal ?? now;
    _initialDateTimeLocal = _selectedDateTimeLocal;

    _selectedDateTimeUtc = widget.ratingEntry?.dateTimeUTC.copyWith(isUtc: true) ??
        widget.initialDateTimeUtc?.copyWith(isUtc: true) ??
        _selectedDateTimeLocal.toUtc();
    _initialDateTimeUtc = _selectedDateTimeUtc;

    _currentLocation.value = widget.ratingEntry?.position;
    _currentPlace.value = widget.ratingEntry?.place;
    _currentWeather.value = widget.ratingEntry?.weather;

    if (widget.ratingEntry != null) {
      _metricValues.addAll(widget.ratingEntry!.metricValues);
      _initialMetricValues.addAll(widget.ratingEntry!.metricValues);
    }
    // Duplicate re-resolves on save; edit keeps the stored provenance.
    _setupId = widget.mode == RatingEntryPageMode.edit ? widget.ratingEntry?.setupId : null;

    final appRepository = context.read<AppRepository>();
    _initialBike = widget.ratingEntry?.bike ??
        widget.initialBike?.id ??
        appRepository.filteredBikes.keys.firstOrNull ??
        appRepository.bikes.keys.firstOrNull ??
        '';
    _bike = _initialBike;
    _setupId = widget.ratingEntry?.setupId ?? widget.initialSetupId;

    if (widget.ratingEntry == null || widget.mode == RatingEntryPageMode.duplicate) {
      unawaited(fetchLocationAddressWeather());
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_changeListener);
    _nameController.dispose();
    _notesController.removeListener(_changeListener);
    _notesController.dispose();
    _currentLocation.dispose();
    _currentPlace.dispose();
    _currentWeather.dispose();
    super.dispose();
  }

  /// Ratings (and therefore their metrics) that apply to the selected bike.
  /// Mirrors [AppRepository.scoreForSetup]'s applicable-metrics logic so the
  /// captured values and the live score stay aligned.
  Map<String, Rating> _applicableRatings() {
    final appRepository = context.read<AppRepository>();
    final person = appRepository.bikes[_bike]?.person;
    final bikeComponents = appRepository.components.values.where((c) => c.bike == _bike);
    final componentIds = bikeComponents.map((c) => c.id).toSet();
    final componentTypes = bikeComponents.map((c) => c.componentType.toString()).toSet();

    final result = <String, Rating>{};
    for (final rating in appRepository.ratings.values) {
      final applies = switch (rating.filterType) {
        FilterType.global => true,
        FilterType.bike => rating.filter == _bike,
        FilterType.person => rating.filter != null && rating.filter == person,
        FilterType.component => componentIds.contains(rating.filter),
        FilterType.componentType => componentTypes.contains(rating.filter),
      };
      if (applies) result[rating.id] = rating;
    }
    return result;
  }

  void _onBikeChange(String? newBike) {
    if (newBike == null) return;
    setState(() => _bike = newBike);
    _changeListener();
  }

  Future<void> fetchLocationAddressWeather() async {
    final coordinatesChanged = await updateLocation();
    if (!coordinatesChanged) return;

    unawaited(updateWeather());
    unawaited(updateAddress());
  }

  Future<bool> updateLocation() async {
    final previousLocation = _currentLocation.value;
    final fetchedLocation = await _locationService.fetchLocation();
    final newLocation = fetchedLocation == null
        ? null
        : await _elevationService.addMissingElevation(fetchedLocation);

    if (!mounted) return false;
    if (newLocation == null) {
      final message = switch (_locationService.status) {
        LocationStatus.noService => 'Location services are disabled.',
        LocationStatus.noPermission => 'Location permission was not granted.',
        LocationStatus.permissionDeniedForever => 'Location permission is permanently denied.',
        LocationStatus.timeout => 'Location request timed out.',
        _ => 'Error fetching location.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(context, message, duration: const Duration(seconds: 2)),
      );
      return false;
    }

    if (!mounted) return false;
    _currentLocation.value = newLocation;
    _changeListener();
    return ContextPosition.hasValidCoordinateChange(previousLocation, newLocation);
  }

  Future<void> updateAddress() async {
    if (_currentLocation.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error(context, 'Cannot update address without location.'));
      return;
    }

    final newAddress = await _addressService.fetchAddress(
      lat: _currentLocation.value!.latitude!,
      lon: _currentLocation.value!.longitude!,
    );

    if (!mounted) return;
    if (newAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(context, 'Error fetching address.', duration: const Duration(seconds: 2)),
      );
      return;
    }

    if (!mounted) return;
    _currentPlace.value = newAddress;
    _changeListener();
  }

  void _changeListener() {
    const equality = DeepCollectionEquality();

    final hasChanges = _nameController.text.trim() != (widget.ratingEntry?.name ?? '') ||
        _notesController.text.trim() != (widget.ratingEntry?.notes ?? '') ||
        _initialDateTimeUtc != _selectedDateTimeUtc ||
        _initialDateTimeLocal != _selectedDateTimeLocal ||
        !ContextPosition.equal(_currentLocation.value, widget.ratingEntry?.position) ||
        !ContextPlace.equal(_currentPlace.value, widget.ratingEntry?.place) ||
        _currentWeather.value != widget.ratingEntry?.weather ||
        _bike != _initialBike ||
        _setupId != widget.ratingEntry?.setupId ||
        !equality.equals(_metricValues, _initialMetricValues);

    if (_formHasChanges != hasChanges) {
      setState(() {
        _formHasChanges = hasChanges;
      });
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      helpText: "Select Rating Date",
      errorInvalidText: "Date cannot be in the future",
      selectableDayPredicate: (DateTime pickedDate) => !_selectedDateTimeLocal.copyWith(
        day: pickedDate.day,
        month: pickedDate.month,
        year: pickedDate.year,
      ).isAfter(DateTime.now()),
      initialDate: _selectedDateTimeLocal,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (!mounted || pickedDate == null) return;

    final DateTime newDateTimeLocal = _selectedDateTimeLocal.copyWith(
      day: pickedDate.day,
      month: pickedDate.month,
      year: pickedDate.year,
    );
    if (newDateTimeLocal == _selectedDateTimeLocal) return;

    setState(() {
      _selectedDateTimeLocal = newDateTimeLocal;
      _selectedDateTimeUtc = newDateTimeLocal.toUtc();
    });
    _changeListener();
    unawaited(askAndUpdateWeather());
  }

  Future<void> _pickTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      helpText: "Select Rating Time",
      initialTime: TimeOfDay.fromDateTime(_selectedDateTimeLocal),
    );

    if (!mounted || pickedTime == null) return;

    final DateTime newDateTimeLocal = _selectedDateTimeLocal.copyWith(hour: pickedTime.hour, minute: pickedTime.minute);
    if (newDateTimeLocal == _selectedDateTimeLocal) return;
    if (newDateTimeLocal.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error(context, 'Date and Time cannot be in the future.'));
      return;
    }

    setState(() {
      _selectedDateTimeLocal = newDateTimeLocal;
      _selectedDateTimeUtc = newDateTimeLocal.toUtc();
    });
    _changeListener();
    unawaited(askAndUpdateWeather());
  }

  Future<void> askAndUpdateWeather() async {
    if (_currentLocation.value == null) return;
    if (_currentWeather.value != null) {
      final result = await showConfirmationDialog(
        context,
        title: 'Update Weather?',
        content: 'Do you want to fetch the latest weather data for this location, date and time?',
        trueText: "Yes",
        falseText: "No",
      );
      if (!result) return;
    }
    await updateWeather();
  }

  Future<void> updateWeather() async {
    if (_currentLocation.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(context, 'Cannot update weather without location.', duration: const Duration(seconds: 2)),
      );
      return;
    }

    final currentWeather = await _weatherService.fetchWeather(
      lat: _currentLocation.value!.latitude!,
      lon: _currentLocation.value!.longitude!,
      datetime: _selectedDateTimeLocal,
    );

    if (!mounted) return;
    if (currentWeather == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(context, 'Error fetching weather.', duration: const Duration(seconds: 2)),
      );
      return;
    }

    if (!mounted) return;
    _currentWeather.value = currentWeather;
    _changeListener();
  }

  void _saveRatingEntry() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(
          context,
          'Please check all fields for missing or invalid input.',
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    final nameText = _nameController.text.trim();
    final name = nameText.isEmpty ? null : nameText;
    final notesText = _notesController.text.trim();
    final notes = notesText.isEmpty ? null : notesText;

    // Resolve the write-once setup provenance. A rating only makes sense relative
    // to a preceding setup, so block the save if none exists for this bike/time.
    final appRepository = context.read<AppRepository>();
    final setupId = _setupId ?? appRepository.resolveSetupId(bikeId: _bike, atUtc: _selectedDateTimeUtc);
    if (setupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(
          context,
          'No setup exists before this date/time for the selected bike. Create a setup first.',
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Keep only answers for metrics that still apply to the selected bike.
    final applicableIds = _applicableRatings().values.expand((r) => r.metrics).map((m) => m.id).toSet();
    final metricValues = {
      for (final entry in _metricValues.entries)
        if (applicableIds.contains(entry.key)) entry.key: entry.value,
    };

    _formHasChanges = false;
    if (!mounted) return;
    Navigator.pop(
      context,
      RatingEntry(
        id: widget.mode == RatingEntryPageMode.edit ? widget.ratingEntry?.id : null,
        isDeleted: widget.ratingEntry?.isDeleted,
        lastModified: DateTime.now(),
        name: name,
        bike: _bike,
        setupId: setupId,
        dateTimeUTC: _selectedDateTimeUtc,
        dateTimeLocal: _selectedDateTimeLocal,
        notes: notes,
        metricValues: metricValues,
        position: _currentLocation.value,
        place: _currentPlace.value,
        weather: _currentWeather.value,
      ),
    );
  }

  void _onMetricValueChanged({required Adjustment adjustment, required dynamic newValue}) {
    setState(() => _metricValues[adjustment.id] = newValue);
    _changeListener();
  }

  void _removeFromMetricValues({required Adjustment adjustment}) {
    setState(() => _metricValues.remove(adjustment.id));
    _changeListener();
  }

  Future<void> _onAddMetricCategoricalOption({required CategoricalAdjustment adjustment, required String option}) async {
    final appRepository = context.read<AppRepository>();
    final rating = appRepository.ratings.values.firstWhereOrNull((r) => r.metrics.any((m) => m.adjustment.id == adjustment.id));
    if (rating == null) return;
    final updated = rating.metrics
        .map((m) => m.adjustment.id == adjustment.id && m.adjustment is CategoricalAdjustment
            ? m.copyWith(adjustment: (m.adjustment as CategoricalAdjustment).copyWith(options: {...(m.adjustment as CategoricalAdjustment).options, option}))
            : m)
        .toList();
    await appRepository.editRating(rating.copyWith(metrics: updated));
  }

  void _handlePopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;
    if (!_formHasChanges) return;
    final shouldDiscard = await showDiscardChangesDialog(context);
    if (!mounted) return;
    if (!shouldDiscard) return;
    Navigator.of(context).pop(null);
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

  TextFormField _nameTextFormField() {
    return TextFormField(
      controller: _nameController,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (text) => setState(() {}),
      decoration: InputDecoration(
        labelText: 'Rating Name',
        border: const OutlineInputBorder(),
        hintText: 'Enter rating name (optional)',
        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
        filled: widget.mode == RatingEntryPageMode.edit && _nameController.text.trim() != (widget.ratingEntry?.name ?? ''),
      ),
    );
  }

  TextFormField _notesTextFormField() {
    return TextFormField(
      controller: _notesController,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      minLines: 2,
      onChanged: (text) => setState(() {}),
      maxLines: null,
      decoration: InputDecoration(
        labelText: 'Notes (optional)',
        border: const OutlineInputBorder(),
        hintText: 'Add notes (optional)',
        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
        filled: widget.mode == RatingEntryPageMode.edit && (_notesController.text.trim() != (widget.ratingEntry?.notes ?? '')),
      ),
    );
  }

  Widget _wrap() {
    final appSettings = context.read<AppSettings>();
    return ListenableBuilder(
      listenable: Listenable.merge([
        _locationService,
        _addressService,
        _weatherService,
        _currentLocation,
        _currentPlace,
        _currentWeather,
      ]),
      builder: (context, child) {
        return Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            ActionChip(
              avatar: const Icon(Icons.calendar_month),
              label: Text(DateFormat(appSettings.dateFormat).format(_selectedDateTimeLocal)),
              backgroundColor: widget.mode == RatingEntryPageMode.edit && (_selectedDateTimeUtc.year != _initialDateTimeUtc.year || _selectedDateTimeUtc.month != _initialDateTimeUtc.month || _selectedDateTimeUtc.day != _initialDateTimeUtc.day) ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill : null,
              onPressed: _pickDate,
            ),
            ActionChip(
              avatar: const Icon(Icons.access_time),
              label: Text(DateFormat(appSettings.timeFormat).format(_selectedDateTimeLocal)),
              backgroundColor: widget.mode == RatingEntryPageMode.edit && (_selectedDateTimeUtc.hour != _initialDateTimeUtc.hour || _selectedDateTimeUtc.minute != _initialDateTimeUtc.minute) ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill : null,
              onPressed: _pickTime,
            ),
            ActionChip(
              backgroundColor: widget.mode == RatingEntryPageMode.edit && (!ContextPosition.equal(_currentLocation.value, widget.ratingEntry?.position) || !ContextPlace.equal(_currentPlace.value, widget.ratingEntry?.place)) ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill : null,
              onPressed: _locationService.status == LocationStatus.searching || _addressService.status == AddressStatus.searching
                  ? null
                  : () async {
                      final result = await showSetLocationPlaceSheet(context: context, locationService: _locationService, currentLocation: _currentLocation.value, addressService: _addressService, currentPlace: _currentPlace.value);
                      if (result == null) return;

                      final requestWeatherUpdate = ContextPosition.hasValidCoordinateChange(
                        _currentLocation.value,
                        result.location,
                      );

                      if (result.location != null) {
                        _locationService.setStatus(LocationStatus.success);
                        _currentLocation.value = result.location;
                      }

                      if (result.place != null) {
                        _addressService.setStatus(AddressStatus.success);
                        _currentPlace.value = result.place;
                      }

                      if (requestWeatherUpdate) {
                        unawaited(askAndUpdateWeather());
                      }

                      _changeListener();
                    },
              avatar: switch (_locationService.status) {
                LocationStatus.idle || LocationStatus.success => switch (_addressService.status) {
                  AddressStatus.idle ||
                  AddressStatus.searching ||
                  AddressStatus.success => _currentLocation.value == null ? const Icon(Icons.location_searching) : const Icon(Icons.my_location),
                  AddressStatus.error => Icon(Icons.error, color: Theme.of(context).colorScheme.error),
                },
                LocationStatus.searching => switch (_addressService.status) {
                  _ => const Icon(Icons.location_searching),
                },
                LocationStatus.noPermission || LocationStatus.permissionDeniedForever || LocationStatus.noService || LocationStatus.timeout || LocationStatus.error => switch (_addressService.status) {
                  _ => Icon(Icons.location_disabled, color: Theme.of(context).colorScheme.error)
                },
              },
              label: switch (_locationService.status) {
                LocationStatus.idle || LocationStatus.success => switch (_addressService.status) {
                  AddressStatus.searching => _loadingIndicator(),
                  AddressStatus.idle || AddressStatus.success => _currentPlace.value != null
                      ? Text("${_currentPlace.value?.locality}, ${_currentPlace.value?.isoCountryCode}")
                      : const Text("-"),
                  AddressStatus.error => _currentPlace.value != null
                      ? Text("${_currentPlace.value?.locality}, ${_currentPlace.value?.isoCountryCode}")
                      : const Text("Address Error"),
                },
                LocationStatus.searching => switch (_addressService.status) {
                  _ => _loadingIndicator(),
                },
                LocationStatus.noService => switch (_addressService.status) {
                  AddressStatus.searching => _loadingIndicator(),
                  AddressStatus.idle || AddressStatus.success || AddressStatus.error => _currentPlace.value != null
                      ? Text("${_currentPlace.value?.locality}, ${_currentPlace.value?.isoCountryCode}")
                      : const Text("No GPS Service"),
                },
                LocationStatus.noPermission || LocationStatus.permissionDeniedForever => switch (_addressService.status) {
                  AddressStatus.searching => _loadingIndicator(),
                  AddressStatus.idle || AddressStatus.success || AddressStatus.error => _currentPlace.value != null
                      ? Text("${_currentPlace.value?.locality}, ${_currentPlace.value?.isoCountryCode}")
                      : const Text("No GPS Permission"),
                },
                LocationStatus.timeout => switch (_addressService.status) {
                  AddressStatus.searching => _loadingIndicator(),
                  AddressStatus.idle || AddressStatus.success || AddressStatus.error => _currentPlace.value != null
                      ? Text("${_currentPlace.value?.locality}, ${_currentPlace.value?.isoCountryCode}")
                      : const Text("GPS Timeout"),
                },
                LocationStatus.error => switch (_addressService.status) {
                  AddressStatus.searching => _loadingIndicator(),
                  AddressStatus.idle || AddressStatus.success || AddressStatus.error => _currentPlace.value != null
                      ? Text("${_currentPlace.value?.locality}, ${_currentPlace.value?.isoCountryCode}")
                      : const Text("Location Error"),
                },
              },
            ),
            ActionChip(
              avatar: switch (_weatherService.status) {
                WeatherIdle() => Icon(_currentWeather.value?.getIconData() ?? Icons.cloudy_snowing),
                WeatherSearching() => const Icon(Icons.cloudy_snowing),
                WeatherSuccess() => Icon(_currentWeather.value?.getIconData() ?? Icons.cloudy_snowing),
                WeatherError() => Icon(Icons.error, color: Theme.of(context).colorScheme.error),
              },
              label: switch (_weatherService.status) {
                WeatherIdle() => Text(_currentWeather.value?.getWeatherCodeLabel() ?? "-"),
                WeatherSearching() => _loadingIndicator(),
                WeatherSuccess() => Text(_currentWeather.value?.getWeatherCodeLabel() ?? "-"),
                WeatherError() => const Text("Weather Error"),
              },
              backgroundColor: widget.mode == RatingEntryPageMode.edit && _currentWeather.value?.withoutCondition() != widget.ratingEntry?.weather?.withoutCondition() ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill : null,
              onPressed: _locationService.status == LocationStatus.searching || _weatherService.status is WeatherSearching
                  ? null
                  : () async {
                      final ContextWeather? newWeather = await showSetWeatherSheet(
                        context: context,
                        currentWeather: _currentWeather.value,
                        weatherService: _weatherService,
                        locationService: _locationService,
                        currentLocation: _currentLocation.value,
                        selectedDateTime: _selectedDateTimeLocal,
                      );
                      if (newWeather == null) return;
                      _weatherService.setStatus(const WeatherSuccess());
                      _currentWeather.value = newWeather;
                      _changeListener();
                    },
            ),
            ActionChip(
              avatar: Icon(_currentWeather.value?.condition?.iconData ?? Icons.edit_road, color: _currentWeather.value?.condition?.color),
              label: _weatherService.status is WeatherSearching
                  ? _loadingIndicator()
                  : Text(_currentWeather.value?.condition?.value ?? "-"),
              backgroundColor: widget.mode == RatingEntryPageMode.edit && _currentWeather.value?.condition != widget.ratingEntry?.weather?.condition ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill : null,
              onPressed: _locationService.status == LocationStatus.searching || _weatherService.status is WeatherSearching
                  ? null
                  : () => showSetConditionSheet(
                        context: context,
                        currentCondition: _currentWeather.value?.condition,
                        onSelected: (Condition newValue) {
                          setState(() {
                            _currentWeather.value ??= ContextWeather(currentDateTime: _selectedDateTimeLocal);
                            _currentWeather.value = _currentWeather.value?.copyWith(
                              condition: newValue,
                              conditionManuallySet: true,
                            );
                          });
                          _changeListener();
                        },
                      ),
            ),
          ],
        );
      },
    );
  }

  Widget _bikeField({required Map<String, Bike> bikes}) {
    return DropdownButtonFormField<String>(
      initialValue: _bike,
      isExpanded: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: 'Bike',
        border: const OutlineInputBorder(),
        hintText: "Choose a bike for this rating",
        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
        filled: widget.mode == RatingEntryPageMode.edit && _bike != widget.ratingEntry?.bike,
      ),
      validator: (String? newBike) {
        if (newBike == null) return "Bike cannot be empty.";
        if (!bikes.keys.contains(newBike)) return "Please select a valid bike";
        return null;
      },
      items: bikes.values.map((b) {
        return DropdownMenuItem<String>(
          value: b.id,
          child: Row(
            spacing: 8,
            children: [
              const Icon(Bike.iconData),
              Expanded(child: Text(b.name, overflow: TextOverflow.ellipsis)),
            ],
          ),
        );
      }).toList() +
          [
            if (!bikes.containsKey(_bike))
              DropdownMenuItem<String>(
                value: _bike,
                child: Row(
                  spacing: 8,
                  children: [
                    Icon(Bike.iconData, color: Theme.of(context).colorScheme.error),
                    Expanded(child: Text("BIKE NOT FOUND", overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                  ],
                ),
              ),
          ],
      onChanged: (String? newBike) => _onBikeChange(newBike),
    );
  }

  Widget _scoreBanner(List<RatingMetric> metrics) {
    final score = RatingScoreService.scoreEntry(metrics, _metricValues);
    final scheme = Theme.of(context).colorScheme;

    if (score == null) {
      return const Card.outlined(
        margin: EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Icon(RatingEntry.iconData),
          title: Text("No score yet"),
          subtitle: Text("Answer at least one scored metric to compute a score."),
        ),
      );
    }

    return Card.outlined(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Text(
            score.weightedAvg.toStringAsFixed(1),
            style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text("Score ${score.weightedAvg.toStringAsFixed(1)} / 10"),
        subtitle: Text(
          "Weighted sum ${score.weightedSum.toStringAsFixed(2)} • ${score.answeredScored} of ${score.totalScored} scored metrics",
        ),
        trailing: score.isComplete
            ? null
            : Tooltip(
                message: "Some scored metrics are unanswered",
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(Icons.info_outline, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
              ),
      ),
    );
  }

  Widget? _driftWarning() {
    final stored = _setupId;
    if (stored == null) return null;

    final appRepository = context.read<AppRepository>();
    final resolved = appRepository.resolveSetupId(bikeId: _bike, atUtc: _selectedDateTimeUtc);
    if (resolved == stored) return null;

    final storedName = appRepository.setups[stored]?.displayName ?? "a deleted setup";
    final resolvedName = resolved == null ? "no setup" : (appRepository.setups[resolved]?.displayName ?? "another setup");
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: scheme.errorContainer,
      child: ListTile(
        dense: true,
        titleAlignment: ListTileTitleAlignment.titleHeight,
        leading: Icon(Icons.link_off, color: scheme.onErrorContainer, size: 20),
        title: Text(
          "Setup link changed",
          style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          "Originally '$storedName', now resolves to '$resolvedName'. Score follows the current resolution.",
          style: TextStyle(color: scheme.onErrorContainer.withValues(alpha: 0.9), fontSize: 12),
        ),
        trailing: TextButton(
          onPressed: () {
            setState(() => _setupId = resolved);
            _changeListener();
          },
          style: TextButton.styleFrom(foregroundColor: scheme.onErrorContainer),
          child: const Text("Relink"),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final components = appRepository.components;

    final applicableRatings = _applicableRatings();
    final allMetrics = applicableRatings.values.expand((r) => r.metrics).toList();
    final driftWarning = _driftWarning();

    return PopScope(
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: switch (widget.mode) {
            RatingEntryPageMode.add || RatingEntryPageMode.duplicate => const Text('Add Rating'),
            RatingEntryPageMode.edit => const Text('Edit Rating'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveRatingEntry),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _nameTextFormField(),
                  const SizedBox(height: 12),
                  _notesTextFormField(),
                  const SizedBox(height: 12),
                  _wrap(),
                  const SizedBox(height: 12),
                  _bikeField(bikes: bikes),
                  const SizedBox(height: 12),
                  ?driftWarning,
                  _scoreBanner(allMetrics),
                  const SizedBox(height: 4),
                  if (applicableRatings.isEmpty)
                    SizedBox(
                      height: 100,
                      child: Center(
                        child: Text(
                          'No ratings apply to this bike.\nDefine a rating procedure first.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        ),
                      ),
                    )
                  else
                    ...applicableRatings.values.map((rating) {
                      final ratingAdjustments = rating.metrics.map((m) => m.adjustment).toList();
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CardHeaderTile(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: ListTile(
                                leading: const Icon(Rating.iconData),
                                title: Text(rating.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(Intl.plural(
                                  ratingAdjustments.length,
                                  zero: "No metrics yet.",
                                  one: "1 metric",
                                  other: '${ratingAdjustments.length} metrics',
                                )),
                                trailing: _ratingFilterIcon(rating, components),
                                enabled: ratingAdjustments.isNotEmpty,
                              ),
                            ),
                            AdjustmentSetList(
                              key: ValueKey(Object.hash(rating.id, _bike)),
                              adjustments: ratingAdjustments,
                              initialAdjustmentValues: _initialMetricValues,
                              adjustmentValues: _metricValues,
                              onAdjustmentValueChanged: _onMetricValueChanged,
                              removeFromAdjustmentValues: _removeFromMetricValues,
                              onAddCategoricalOption: _onAddMetricCategoricalOption,
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ratingFilterIcon(Rating rating, Map<String, Component> components) {
    return switch (rating.filterType) {
      FilterType.global => const Icon(Icons.circle_outlined),
      FilterType.bike => const Icon(Bike.iconData),
      FilterType.person => const Icon(Person.iconData),
      FilterType.component => Icon((components[rating.filter]?.componentType ?? ComponentType.other).getIconData()),
      FilterType.componentType => Icon(ComponentType.fromString(rating.filter ?? '').getIconData()),
    };
  }
}
