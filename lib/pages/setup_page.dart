import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:image_picker/image_picker.dart';
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
import '../models/setup.dart';
import '../models/strava/strava_activity.dart';
import '../repositories/app_repository.dart';
import '../services/address_service.dart';
import '../services/elevation_service.dart';
import '../services/image_storage_service.dart';
import '../services/location_service.dart';
import '../services/setup_resolution_service.dart';
import '../services/weather_service.dart';
import '../theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/chips/utils.dart';
import '../widgets/dialogs/confirmation.dart';
import '../widgets/dialogs/discard_changes.dart';
import '../widgets/image_strip.dart';
import '../widgets/setup_page_tab_bike.dart';
import '../widgets/setup_page_tab_person.dart';
import '../widgets/sheets/pick_image_source.dart';
import '../widgets/sheets/set_condition.dart';
import '../widgets/sheets/set_location_place.dart';
import '../widgets/sheets/set_setup_tags.dart';
import '../widgets/sheets/set_weather.dart';
import '../widgets/sticky_section.dart';

enum SetupPageMode {
  add,
  edit,
  duplicate,
}

class SetupPage extends StatefulWidget {
  final Setup? setup;
  final SetupPageMode mode;
  final DateTime? initialDateTimeUtc;
  final DateTime? initialDateTimeLocal;
  final Bike? initialBike;

  const SetupPage._({
    super.key,
    this.setup,
    required this.mode,
    this.initialDateTimeUtc,
    this.initialDateTimeLocal,
    this.initialBike,
  });

  factory SetupPage.add({
    Key? key,
    DateTime? initialDateTimeUtc,
    DateTime? initialDateTimeLocal,
  }) =>
      SetupPage._(
        key: key,
        mode: SetupPageMode.add,
        initialDateTimeUtc: initialDateTimeUtc,
        initialDateTimeLocal: initialDateTimeLocal,
      );

  factory SetupPage.addFromStravaActivity({
    Key? key, 
    required BuildContext context,
    required StravaActivity stravaActivity,
  }) {
    final appRepository = context.read<AppRepository>();
    final bike = appRepository.bikes.values.firstWhereOrNull((b) => b.stravaGear == stravaActivity.gearId);
    
    return SetupPage._(
      key: key, 
      mode: SetupPageMode.add, 
      initialDateTimeUtc: stravaActivity.startDate,
      initialDateTimeLocal: stravaActivity.startDateLocal,
      initialBike: bike,
    );
  }

  factory SetupPage.edit({Key? key, required Setup setup}) => 
    SetupPage._(key: key, setup: setup, mode: SetupPageMode.edit);

  factory SetupPage.duplicate({Key? key, required Setup setup}) => 
    SetupPage._(key: key, setup: setup, mode: SetupPageMode.duplicate);
  
  @override
  State<SetupPage> createState() => _SetupPageState();
}
    
class _SetupPageState extends State<SetupPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _bikeTabKey = GlobalKey();
  final _personTabKey = GlobalKey();
  bool _formHasChanges = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TabController _tabController;
  int? _tabControllerLength;
  int _tabIndex = 0;
  Set<String> _tags = {};
  Set<String> _initialTags = {};
  late String _bike;
  late String _initialBike;
  String? get _person => context.read<AppRepository>().bikes[_bike]?.person;
  late String? _initialPerson;
  String? _linkedPerson;
    
  List<String> _images = [];
  List<String> _initialImages = [];
  String? _imagesDirPath;

  late DateTime _selectedDateTimeUtc;
  late DateTime _initialDateTimeUtc;
  late DateTime _selectedDateTimeLocal;
  late DateTime _initialDateTimeLocal;

  final Map<String, dynamic> _bikeAdjustmentValues = {};
  final Map<String, dynamic> _personAdjustmentValues = {};
  final Map<String, dynamic> _initialBikeAdjustmentValues = {};
  final Map<String, dynamic> _initialPersonAdjustmentValues = {};
  final Map<String, dynamic> _previousBikeAdjustmentValues = {};
  final Map<String, dynamic> _previousPersonAdjustmentValues = {};
  final Map<String, dynamic> _danglingBikeAdjustmentValues = {};
  final Map<String, dynamic> _danglingPersonAdjustmentValues = {};

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
    _nameController = TextEditingController(text: widget.setup?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: widget.setup?.notes);
    _notesController.addListener(_changeListener);

    final now = DateTime.now();
    _selectedDateTimeLocal = widget.setup?.datetimeLocal ?? widget.initialDateTimeLocal ?? now;
    _initialDateTimeLocal = _selectedDateTimeLocal;

    _selectedDateTimeUtc =
        widget.setup?.datetime.copyWith(isUtc: true) ??
        widget.initialDateTimeUtc?.copyWith(isUtc: true) ??
        _selectedDateTimeLocal.toUtc();
    _initialDateTimeUtc = _selectedDateTimeUtc;

    _currentLocation.value = widget.setup?.position;
    _currentPlace.value = widget.setup?.place;
    _currentWeather.value = widget.setup?.weather;

    final appRepository = context.read<AppRepository>();
    _tags.addAll(widget.setup?.tags ?? appRepository.selectedSetupTags);
    _initialTags = _tags;

    _images = List.from(widget.setup?.images ?? []);
    _initialImages = List.from(_images);
    unawaited(_initImagesDir());

    final bikes = appRepository.bikes;
    _initialBike = widget.setup?.bike ?? widget.initialBike?.id ?? appRepository.filteredBikes.keys.firstOrNull ?? '';

    _initialPerson = widget.setup?.person ?? bikes[_initialBike]?.person;

    _onBikeChange(_initialBike);

    if (widget.setup == null || widget.mode == SetupPageMode.duplicate) unawaited(fetchLocationAddressWeather());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final int newLength = 1 + (context.read<AppSettings>().enablePerson ? 1 : 0);
    if (_tabControllerLength == null || _tabControllerLength != newLength) {
      if (_tabControllerLength != null) {
        _tabController.removeListener(_onTabIndexChanged);
        _tabController.dispose();
      }
      _tabControllerLength = newLength;
      _tabIndex = 0;
      _tabController = TabController(
        initialIndex: 0,
        length: newLength,
        vsync: this,
      )..addListener(_onTabIndexChanged);
    }

    // The bike's rider can change while this page is open
    if (_linkedPerson != _person) {
      _linkedPerson = _person;
      _setPreviousAdjustmentValues();
      _setDanglingAdjustmentValues();
      _changeListener();
    }
  }

  void _setAdjustmentValuesFromPreviousAndInitialAdjustmentValues() {
    // ADD+EDIT SETUP
    _bikeAdjustmentValues.clear();
    _personAdjustmentValues.clear();

    _bikeAdjustmentValues.addAll(_previousBikeAdjustmentValues);
    // Person fields intentionally not pre-filled from previous history.
    // _previousPersonAdjustmentValues is used only for orange/green highlighting in the widget.

    if (widget.setup != null) {
      // EDIT / DUPLICATE
      _bikeAdjustmentValues.addAll(_initialBikeAdjustmentValues);
      _personAdjustmentValues.addAll(_initialPersonAdjustmentValues);
    }
  }

  void _setPreviousAdjustmentValues() {
    _previousBikeAdjustmentValues.clear();
    _previousPersonAdjustmentValues.clear();

    final appRepository = context.read<AppRepository>();
    final bikeComponents = appRepository.components.values.where((c) => c.bikeAt(_selectedDateTimeUtc) == _bike).toList();

    
    // Use the centralized resolution service to get the cumulative global state up to our current date/time.
    // This correctly handles chronological inheritance and component transfers across different bikes.
    final historicalState = SetupResolutionService.resolveHistoricalStateAt(
      datetime: _selectedDateTimeUtc,
      setups: appRepository.setups.values,
      persons: appRepository.persons,
      excludedSetupId: widget.mode == SetupPageMode.edit ? widget.setup?.id : null,
    );

    // 1. Resolve Bike Adjustments
    for (final bikeComponent in bikeComponents) {
      for (final adj in bikeComponent.adjustments) {
        if (historicalState.containsKey(adj.id)) {
          _previousBikeAdjustmentValues[adj.id] = historicalState[adj.id];
        }
      }
    }

    // 2. Resolve Person Adjustments
    if (_person != null) {
      final person = appRepository.persons[_person];
      if (person != null) {
        for (final adj in person.adjustments) {
          if (historicalState.containsKey(adj.id)) {
             _previousPersonAdjustmentValues[adj.id] = historicalState[adj.id];
          }
        }
      }
    }
  }

  void _setInitialAdjustmentValues() {
    if (widget.setup == null) {
      // ADD SETUP
      _initialBikeAdjustmentValues.clear();
      _initialBikeAdjustmentValues.addAll(_previousBikeAdjustmentValues);

      _initialPersonAdjustmentValues.clear();
    } else {
      // EDIT / DUPLIATE SETUP
      _initialBikeAdjustmentValues.clear();
      _initialBikeAdjustmentValues.addAll(widget.setup!.bikeAdjustmentValues);

      _initialPersonAdjustmentValues.clear();
      _initialPersonAdjustmentValues.addAll(widget.setup!.personAdjustmentValues);
    }
  }

  void _setDanglingAdjustmentValues() {
    if (widget.setup == null) return;

    final appRepository = context.read<AppRepository>();
    final bikeComponents = appRepository.components.values.where((c) => c.bikeAt(_selectedDateTimeUtc) == _bike).toList();
    
    _danglingBikeAdjustmentValues.clear();
    _danglingBikeAdjustmentValues.addAll(_bikeAdjustmentValues);
    for (final bikeComponent in bikeComponents) {
      for (final bikeComponentAdj in bikeComponent.adjustments) {
        _danglingBikeAdjustmentValues.remove(bikeComponentAdj.id);
      }
    }
    
    final persons = appRepository.persons;
    _danglingPersonAdjustmentValues.clear();
    _danglingPersonAdjustmentValues.addAll(_personAdjustmentValues);
    for (final personAdj in persons[_person]?.adjustments ?? []) {
      _danglingPersonAdjustmentValues.remove(personAdj.id);
    }
  }

  void _onBikeChange (String? newBike) {
    if (newBike == null) return;
    final appRepository = context.read<AppRepository>();
    final bikes = appRepository.bikes;

    setState(() {
      _bike = newBike;
      _linkedPerson = bikes[_bike]?.person;
      _setPreviousAdjustmentValues();
      _setInitialAdjustmentValues();
      _setAdjustmentValuesFromPreviousAndInitialAdjustmentValues();
      _setDanglingAdjustmentValues();
    });
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

  Future<void> _initImagesDir() async {
    final path = await ImageStorageService().getImagesPath();
    if (!mounted) return;
    setState(() => _imagesDirPath = path);
  }

  void _onImagesAdded(List<String> newFilenames) {
    setState(() => _images.addAll(newFilenames));
    _changeListener();
  }

  Future<void> _addImages() async {
    final picker = ImagePicker();
    final source = await showPickImageSourceSheet(context);
    if (source == null) return;
    final service = ImageStorageService();
    if (source == ImageSource.camera) {
      final picked = await picker.pickImage(source: ImageSource.camera);
      if (picked == null) return;
      _onImagesAdded([await service.importImage(picked)]);
    } else {
      final picked = await picker.pickMultiImage();
      if (picked.isEmpty) return;
      final filenames = <String>[];
      for (final x in picked) {
        filenames.add(await service.importImage(x));
      }
      _onImagesAdded(filenames);
    }
  }

  void _onImageRemoved(int index) {
    setState(() => _images.removeAt(index));
    _changeListener();
  }

  void _onImageReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
    _changeListener();
  }

  void _changeListener() {
    const equality = DeepCollectionEquality();

    final hasChanges = _nameController.text.trim() != (widget.setup?.name ?? '') ||
        _notesController.text.trim() != (widget.setup?.notes ?? '') || 
        _initialDateTimeUtc != _selectedDateTimeUtc || 
        _initialDateTimeLocal != _selectedDateTimeLocal ||

        !ContextPosition.equal(_currentLocation.value, widget.setup?.position) ||
        !ContextPlace.equal(_currentPlace.value, widget.setup?.place) ||
        _currentWeather.value != widget.setup?.weather || 
        !setEquals(_tags, _initialTags) ||
        
        _bike != _initialBike || 
        _person != _initialPerson ||

        !equality.equals(_bikeAdjustmentValues, _initialBikeAdjustmentValues) ||
        !equality.equals(_personAdjustmentValues, _initialPersonAdjustmentValues) ||
        !listEquals(_images, _initialImages);

    if (_formHasChanges != hasChanges) {
      setState(() {
        _formHasChanges = hasChanges;
      });
    }
  }

  void _onTabIndexChanged() {
    if (_tabIndex == _tabController.index) return;
    setState(() => _tabIndex = _tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabIndexChanged);
    _tabController.dispose();
    _nameController.removeListener(_changeListener);
    _nameController.dispose();
    _notesController.removeListener(_changeListener);
    _notesController.dispose();
    _currentLocation.dispose();
    _currentPlace.dispose();
    _currentWeather.dispose();
    super.dispose();
  }

  Future<void> _resetValuesIfPreviousSetupChanged({
    required Map<String, dynamic> previousBikeAdjustmentValues,
    required Map<String, dynamic> previousPersonAdjustmentValues,
  }) async {
    const mapEquality = DeepCollectionEquality();
    if (mapEquality.equals(_previousBikeAdjustmentValues, previousBikeAdjustmentValues) &&
        mapEquality.equals(_previousPersonAdjustmentValues, previousPersonAdjustmentValues)) {
      return;
    }

    final result = await showConfirmationDialog(
      context,
      title: "Previous Setup has changed. Reset Values?",
      content: "Your current unsaved adjustments were based on the old setup. Resetting the values will discard these changes.",
      trueText: "Yes",
      falseText: "No",
    );
    if (!result || !mounted) return;

    setState(_setAdjustmentValuesFromPreviousAndInitialAdjustmentValues);
    _changeListener();
  }

  Future<void> _pickDate() async {
    final tmpPreviousBikeAdjustmentValues = Map<String, dynamic>.from(_previousBikeAdjustmentValues);
    final tmpPreviousPersonAdjustmentValues = Map<String, dynamic>.from(_previousPersonAdjustmentValues);

    final pickedDate = await showDatePicker(
      context: context,
      helpText: "Select Setup Date",
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
      _setPreviousAdjustmentValues();
      _setInitialAdjustmentValues();
      _setDanglingAdjustmentValues();
    });
    _changeListener();
    unawaited(askAndUpdateWeather());

    await _resetValuesIfPreviousSetupChanged(
      previousBikeAdjustmentValues: tmpPreviousBikeAdjustmentValues,
      previousPersonAdjustmentValues: tmpPreviousPersonAdjustmentValues,
    );
  }
    
  Future<void> _pickTime() async {
    final tmpPreviousBikeAdjustmentValues = Map<String, dynamic>.from(_previousBikeAdjustmentValues);
    final tmpPreviousPersonAdjustmentValues = Map<String, dynamic>.from(_previousPersonAdjustmentValues);

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      helpText: "Select Setup Time",
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
      _setPreviousAdjustmentValues();
      _setInitialAdjustmentValues();
      _setDanglingAdjustmentValues();
    });
    _changeListener();
    unawaited(askAndUpdateWeather());

    await _resetValuesIfPreviousSetupChanged(
      previousBikeAdjustmentValues: tmpPreviousBikeAdjustmentValues,
      previousPersonAdjustmentValues: tmpPreviousPersonAdjustmentValues,
    );
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

  /// First [FormField] below [root] that is currently showing a validation
  /// error, in build order (which mirrors visual order here).
  BuildContext? _firstInvalidField(BuildContext root) {
    BuildContext? found;
    void visit(Element element) {
      if (found != null) return;
      final state = element is StatefulElement ? element.state : null;
      if (state is FormFieldState && state.hasError) {
        found = element;
        return;
      }
      element.visitChildren(visit);
    }

    root.visitChildElements(visit);
    return found;
  }

  /// Tab owning [fieldContext], or the current tab for fields above the tabs.
  int _tabIndexOf(BuildContext fieldContext) {
    int index = _tabIndex;
    fieldContext.visitAncestorElements((element) {
      if (element.widget.key == _bikeTabKey) {
        index = 0;
        return false;
      }
      if (element.widget.key == _personTabKey) {
        index = 1;
        return false;
      }
      return true;
    });
    return index;
  }

  void _revealFirstInvalidField() {
    final formContext = _formKey.currentContext;
    if (formContext == null) return;
    final invalidField = _firstInvalidField(formContext);
    if (invalidField == null) return;

    const duration = Duration(milliseconds: 250);
    final targetTab = _tabIndexOf(invalidField);
    if (targetTab == _tabIndex) {
      unawaited(Scrollable.ensureVisible(invalidField, alignment: 0.3, duration: duration));
      return;
    }

    _tabController.animateTo(targetTab);
    // The inactive tab is offstage and therefore unpositioned, so it can only
    // be scrolled to once the switched-in tab has been laid out and the tab
    // switch has finished resizing the section (see [AnimatedSize] below) —
    // scrolling into a still-shrinking extent lands short.
    unawaited(Future.delayed(kTabScrollDuration, () {
      if (!mounted || !invalidField.mounted) return;
      unawaited(Scrollable.ensureVisible(invalidField, alignment: 0.3, duration: duration));
    }));
  }

  void _saveSetup() {
    if (!_formKey.currentState!.validate()) {
      _revealFirstInvalidField();
      return;
    }
    final nameText = _nameController.text.trim();
    final name = nameText.isEmpty ? null : nameText;
    final notesText = _notesController.text.trim();
    final notes = notesText.isEmpty ? null : notesText;

    _formHasChanges = false;
    if (!mounted) return;
    Navigator.pop(
      context,
      Setup(
        id: widget.mode == SetupPageMode.edit ? widget.setup?.id : null,
        isDeleted: widget.setup?.isDeleted,
        lastModified: DateTime.now(),
        name: name,
        datetime: _selectedDateTimeUtc,
        datetimeLocal: _selectedDateTimeLocal,
        notes: notes,
        tags: _tags,
        bike: _bike,
        person: _person,
        bikeAdjustmentValues: _bikeAdjustmentValues,
        personAdjustmentValues: _personAdjustmentValues,
        position: _currentLocation.value,
        place: _currentPlace.value,
        weather: _currentWeather.value,
        images: _images,
      ),
    );
  }

  void _onBikeAdjustmentValueChanged({required Adjustment adjustment, required dynamic newValue}) {
    _bikeAdjustmentValues[adjustment.id] = newValue;
    _changeListener();
  }

  void _onPersonAdjustmentValueChanged({required Adjustment adjustment, required dynamic newValue}) {
    _personAdjustmentValues[adjustment.id] = newValue;
    _changeListener();
  }

  void _removeFromBikeAdjustmentValues({required Adjustment adjustment}) {
    _bikeAdjustmentValues.remove(adjustment.id);
    _changeListener();
  }

  void _removeFromPersonAdjustmentValues({required Adjustment adjustment}) {
    _personAdjustmentValues.remove(adjustment.id);
    _changeListener();
  }

  Future<void> _onAddBikeCategoricalOption({required CategoricalAdjustment adjustment, required String option}) async {
    final appRepository = context.read<AppRepository>();
    final component = appRepository.components.values.firstWhereOrNull((c) => c.adjustments.any((a) => a.id == adjustment.id));
    if (component == null) return;
    final updated = component.adjustments
        .map((a) => a.id == adjustment.id && a is CategoricalAdjustment ? a.copyWith(options: {...a.options, option}) : a)
        .toList();
    await appRepository.editComponent(component.copyWith(adjustments: updated));
  }

  Future<void> _onAddPersonCategoricalOption({required CategoricalAdjustment adjustment, required String option}) async {
    final appRepository = context.read<AppRepository>();
    final person = appRepository.persons.values.firstWhereOrNull((p) => p.adjustments.any((a) => a.id == adjustment.id));
    if (person == null) return;
    final updated = person.adjustments
        .map((a) => a.id == adjustment.id && a is CategoricalAdjustment ? a.copyWith(options: {...a.options, option}) : a)
        .toList();
    await appRepository.editPerson(person.copyWith(adjustments: updated));
  }

  void _handlePopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;
    if (!_formHasChanges) return;
    final shouldDiscard = await showDiscardChangesDialog(context);
    if (!mounted) return;
    if (!shouldDiscard) return;
    Navigator.of(context).pop(null);
  }

  TextFormField _nameTextFormField() {
    return TextFormField(
      controller: _nameController,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (text) {
        setState(() {});
      },
      decoration: InputDecoration(
        labelText: 'Setup Name',
        border: const OutlineInputBorder(),
        hintText: 'Enter setup name',
        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
        filled: widget.mode == SetupPageMode.edit && _nameController.text.trim() != (widget.setup?.name ?? ''),
      ),
    );
  }

  TextFormField _notesTextFormField() {
    return TextFormField(
      controller: _notesController,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      minLines: 2,
      onChanged: (text) {
        setState(() {});
      },
      maxLines: null,
      decoration: InputDecoration(
        labelText: 'Notes (optional)',
        border: const OutlineInputBorder(),
        hintText: 'Add notes (optional)',
        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
        filled: widget.mode == SetupPageMode.edit && (_notesController.text.trim() != (widget.setup?.notes ?? '')),
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
        _currentWeather]),
      builder: (context, child) { 
        return Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            ActionChip(
              avatar: const Icon(Icons.calendar_month),
              label: Text(
                DateFormat(appSettings.dateFormat).format(_selectedDateTimeLocal),
              ),
              backgroundColor: widget.mode == SetupPageMode.edit && (_selectedDateTimeUtc.year != _initialDateTimeUtc.year || _selectedDateTimeUtc.month != _initialDateTimeUtc.month || _selectedDateTimeUtc.day != _initialDateTimeUtc.day)
                  ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
                  : null,
              onPressed: _pickDate,
            ),
            ActionChip(
              avatar: const Icon(Icons.access_time),
              label: Text(
                DateFormat(appSettings.timeFormat).format(_selectedDateTimeLocal),
              ),
              backgroundColor: widget.mode == SetupPageMode.edit && (_selectedDateTimeUtc.hour != _initialDateTimeUtc.hour || _selectedDateTimeUtc.minute != _initialDateTimeUtc.minute)
                  ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
                  : null,
              onPressed: _pickTime,
            ),
            ActionChip(
              backgroundColor: widget.mode == SetupPageMode.edit && (!ContextPosition.equal(_currentLocation.value, widget.setup?.position) || !ContextPlace.equal(_currentPlace.value, widget.setup?.place))
                  ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
                  : null,
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

                      if (requestWeatherUpdate) { // After setting new location: _currentLocation = result.location
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
                  AddressStatus.searching => const ChipLoadingIndicator(),
                  AddressStatus.idle || AddressStatus.success => _currentPlace.value != null
                      ? Text("${_currentPlace.value?.locality}, ${_currentPlace.value?.isoCountryCode}") 
                      : const Text("-"),
                  AddressStatus.error => _currentPlace.value != null
                      ? Text("${_currentPlace.value?.locality}, ${_currentPlace.value?.isoCountryCode}") 
                      : const Text("Address Error"),
                },
                LocationStatus.searching => switch (_addressService.status) {
                  _ => const ChipLoadingIndicator(),
                },
                LocationStatus.noService => switch (_addressService.status) {
                  AddressStatus.searching => const ChipLoadingIndicator(),
                  AddressStatus.idle || AddressStatus.success || AddressStatus.error => _currentPlace.value != null
                      ? Text("${_currentPlace.value?.locality}, ${_currentPlace.value?.isoCountryCode}") 
                      : const Text("No GPS Service"),
                },
                LocationStatus.noPermission || LocationStatus.permissionDeniedForever => switch (_addressService.status) {
                  AddressStatus.searching => const ChipLoadingIndicator(),
                  AddressStatus.idle || AddressStatus.success || AddressStatus.error => _currentPlace.value != null
                      ? Text("${_currentPlace.value?.locality}, ${_currentPlace.value?.isoCountryCode}") 
                      : const Text("No GPS Permission"),
                },
                LocationStatus.timeout => switch (_addressService.status) {
                  AddressStatus.searching => const ChipLoadingIndicator(),
                  AddressStatus.idle || AddressStatus.success || AddressStatus.error => _currentPlace.value != null
                      ? Text("${_currentPlace.value?.locality}, ${_currentPlace.value?.isoCountryCode}")
                      : const Text("GPS Timeout"),
                },
                LocationStatus.error => switch (_addressService.status) {
                  AddressStatus.searching => const ChipLoadingIndicator(),
                  AddressStatus.idle || AddressStatus.success || AddressStatus.error => _currentPlace.value != null
                      ? Text("${_currentPlace.value?.locality}, ${_currentPlace.value?.isoCountryCode}") 
                      : const Text("Location Error"),
                },
              }
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
                WeatherSearching() => const ChipLoadingIndicator(),
                WeatherSuccess() => Text(_currentWeather.value?.getWeatherCodeLabel() ?? "-"),
                WeatherError() => const Text("Weather Error"),
              },
              backgroundColor: widget.mode == SetupPageMode.edit && _currentWeather.value?.withoutCondition() != widget.setup?.weather?.withoutCondition()
                  ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
                  : null,
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
                ? const ChipLoadingIndicator()
                : Text(_currentWeather.value?.condition?.value ?? "-"),
              backgroundColor: widget.mode == SetupPageMode.edit && _currentWeather.value?.condition != widget.setup?.weather?.condition
                  ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
                  : null,
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
            if (appSettings.enableSetupTags) ... [
              ..._tags.map((tag) => FilterChip(
                avatar: const Icon(Icons.tag),
                  showCheckmark: false,
                  selected: widget.mode != SetupPageMode.edit,
                  label: Text(tag), 
                  onSelected: (_) {
                    setState(() => _tags.remove(tag));
                    _changeListener();
                  },
                  onDeleted: () {
                    setState(() => _tags.remove(tag));
                    _changeListener();
                  },
                  backgroundColor: widget.mode == SetupPageMode.edit && !widget.setup!.tags.contains(tag)
                      ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
                      : null,
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.add),
                label: const Text("Tags"),
                onPressed: () async {
                  await showSetSetupTagsSheet(
                    context: context, 
                    tags: _tags,
                    onChanged: (Set<String> newTags) {
                      setState(() => _tags = newTags);
                      _changeListener();
                    },
                  );
                },
              ),
            ],
            if (appSettings.enableSetupImages && _imagesDirPath != null)
              ActionChip(
                avatar: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Image'),
                onPressed: _addImages,
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
        hintText: "Choose a bike for this component",
        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
        filled: widget.mode == SetupPageMode.edit && _bike != widget.setup?.bike,
      ),
      validator: (String? newBike) {
        if (newBike == null) return "Bike cannot be empty.";
        if (!bikes.keys.contains(newBike)) return "Please select valid bike";
        return null;
      },
      items: bikes.values.map((b) {
        return DropdownMenuItem<String>(
          value: b.id,
          child: Row(
            spacing: 8,
            children: [
              const Icon(Bike.iconData),
              Expanded(
                child: Text(b.name, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
      }).toList() + [
        if (!bikes.containsKey(_bike))
        DropdownMenuItem<String>(
          value: _bike,
          child: Row(
            spacing: 8,
            children: [
              Icon(Bike.iconData, color: Theme.of(context).colorScheme.error),
              Expanded(child: Text("BIKE NOT FOUND", overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.error)))
            ],
          ),
        ),
      ],
      onChanged: (String? newBike) => _onBikeChange(newBike),
    );
  }

  Widget _tabBar() {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar.secondary(
        controller: _tabController,
        tabs: const <Widget>[
          Tab(icon: Icon(Bike.iconData)),
          Tab(icon: Icon(Person.iconData)),
        ],
      ),
    );
  }

  Widget _bikeTab(AppRepository appRepository, List<Component> bikeComponents) {
    return SetupBikeTab(
      bike: _bike,
      bikeComponents: bikeComponents,
      allComponents: appRepository.components,
      bikeAdjustmentValues: _bikeAdjustmentValues,
      previousBikeAdjustmentValues: _previousBikeAdjustmentValues,
      initialBikeAdjustmentValues: _initialBikeAdjustmentValues,
      danglingBikeAdjustmentValues: _danglingBikeAdjustmentValues,
      onAdjustmentValueChanged: _onBikeAdjustmentValueChanged,
      onRemoveFromAdjustmentValues: _removeFromBikeAdjustmentValues,
      onAddCategoricalOption: _onAddBikeCategoricalOption,
      onDanglingRemove: (id) {
        setState(() {
          _danglingBikeAdjustmentValues.remove(id);
          _bikeAdjustmentValues.remove(id);
        });
        _changeListener();
      },
    );
  }

  Widget _personTab(AppRepository appRepository) {
    return SetupPersonTab(
      bike: _bike,
      personId: _person,
      persons: appRepository.persons,
      personAdjustmentValues: _personAdjustmentValues,
      previousPersonAdjustmentValues: _previousPersonAdjustmentValues,
      initialPersonAdjustmentValues: _initialPersonAdjustmentValues,
      danglingPersonAdjustmentValues: _danglingPersonAdjustmentValues,
      onAdjustmentValueChanged: _onPersonAdjustmentValueChanged,
      onRemoveFromAdjustmentValues: _removeFromPersonAdjustmentValues,
      onAddCategoricalOption: _onAddPersonCategoricalOption,
      changeListener: _changeListener,
      onDanglingRemove: (id) {
        setState(() {
          _danglingPersonAdjustmentValues.remove(id);
          _personAdjustmentValues.remove(id);
        });
        _changeListener();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final bikeComponents = appRepository.components.values.where((c) => c.bikeAt(_selectedDateTimeUtc) == _bike).toList();

    return PopScope(
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: switch (widget.mode) {
            SetupPageMode.add || SetupPageMode.duplicate => const Text('Add Setup'),
            SetupPageMode.edit => const Text('Edit Setup'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveSetup),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _nameTextFormField(),
                        const SizedBox(height: 12),
                        _notesTextFormField(),
                        const SizedBox(height: 12),
                        _wrap(),
                        if (context.read<AppSettings>().enableSetupImages && _imagesDirPath != null && _images.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ImageStrip(
                            images: _images,
                            imagesDir: _imagesDirPath!,
                            mode: ImageStripMode.edit,
                            onRemove: _onImageRemoved,
                            onReorder: _onImageReorder,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _bikeField(bikes: bikes),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: context.read<AppSettings>().enablePerson
                      // Both tabs stay in the tree so their fields keep their
                      // state; the inactive one takes no space.
                      ? StickySection(
                          header: _tabBar(),
                          // Tabs of differing height change the scroll extent,
                          // which the viewport corrects by clamping the offset
                          // in one frame. Animating the size spreads that
                          // correction over the switch instead of snapping.
                          content: AnimatedSize(
                            duration: kTabScrollDuration,
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Visibility(
                                  visible: _tabIndex == 0,
                                  maintainState: true,
                                  child: KeyedSubtree(key: _bikeTabKey, child: _bikeTab(appRepository, bikeComponents)),
                                ),
                                Visibility(
                                  visible: _tabIndex == 1,
                                  maintainState: true,
                                  child: KeyedSubtree(key: _personTabKey, child: _personTab(appRepository)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _bikeTab(appRepository, bikeComponents),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
