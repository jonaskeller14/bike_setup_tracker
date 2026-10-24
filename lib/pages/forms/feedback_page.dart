import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/context/context_place.dart';
import '../../models/context/context_position.dart';
import '../../models/context/context_weather.dart';
import '../../models/feedback/custom_issue.dart';
import '../../models/feedback/feedback_comparison.dart';
import '../../models/feedback/feedback_key.dart';
import '../../models/feedback/feedback_observation.dart';
import '../../models/feedback/feedback_vocabulary.dart';
import '../../models/feedback/ride_feedback.dart';
import '../../models/setup.dart';
import '../../models/strava/strava_activity.dart';
import '../../repositories/app_repository.dart';
import '../../services/address_service.dart';
import '../../services/elevation_service.dart';
import '../../services/location_service.dart';
import '../../services/weather_service.dart';
import '../../theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/chips/utils.dart';
import '../../widgets/current_setup_badge.dart';
import '../../widgets/dialogs/confirmation.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/feedback/feedback_aspect_row.dart';
import '../../widgets/feedback/feedback_comparison_field.dart';
import '../../widgets/feedback/feedback_issue_chips.dart';
import '../../widgets/items/setup_tile_header.dart';
import '../../widgets/items/tile_meta_row.dart';
import '../../widgets/sheets/compare_setups.dart';
import '../../widgets/sheets/custom_issues_sheet.dart';
import '../../widgets/sheets/set_condition.dart';
import '../../widgets/sheets/set_location_place.dart';
import '../../widgets/sheets/set_weather.dart';
import '../../widgets/text/section_title.dart';

enum FeedbackPageMode {
  add,
  edit,
}

class FeedbackPage extends StatefulWidget {
  final RideFeedback? feedback;
  final FeedbackPageMode mode;
  final DateTime? initialDateTimeUtc;
  final DateTime? initialDateTimeLocal;
  final Bike? initialBike;
  final StravaActivity? initialStravaActivity;

  /// Shared with the setup tile header the form was opened from.
  final String? heroTag;

  const FeedbackPage._({
    super.key,
    this.feedback,
    required this.mode,
    this.initialDateTimeUtc,
    this.initialDateTimeLocal,
    this.initialBike,
    this.initialStravaActivity,
    this.heroTag,
  });

  factory FeedbackPage.add({
    Key? key,
    Bike? initialBike,
    DateTime? initialDateTimeUtc,
    DateTime? initialDateTimeLocal,
    String? heroTag,
  }) => FeedbackPage._(
    key: key,
    mode: FeedbackPageMode.add,
    initialBike: initialBike,
    initialDateTimeUtc: initialDateTimeUtc,
    initialDateTimeLocal: initialDateTimeLocal,
    heroTag: heroTag,
  );

  factory FeedbackPage.addFromStravaActivity({
    Key? key,
    required BuildContext context,
    required StravaActivity stravaActivity,
  }) {
    final appRepository = context.read<AppRepository>();
    final bike = appRepository.bikes.values.firstWhereOrNull((b) => b.stravaGear == stravaActivity.gearId);

    return FeedbackPage._(
      key: key,
      mode: FeedbackPageMode.add,
      initialBike: bike,
      initialDateTimeUtc: stravaActivity.startDate,
      initialDateTimeLocal: stravaActivity.startDateLocal,
      initialStravaActivity: stravaActivity,
    );
  }

  factory FeedbackPage.edit({Key? key, required RideFeedback feedback}) =>
      FeedbackPage._(key: key, feedback: feedback, mode: FeedbackPageMode.edit);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  late TextEditingController _notesController;

  /// Fixed by the entry point (the setup or ride the feedback is about).
  late final String _bike;

  // Write-once setup provenance: null for a new feedback (resolved on save),
  // the stored value in edit mode, re-pointed by the drift warning's "Relink".
  String? _setupId;

  late DateTime _selectedDateTimeUtc;
  late DateTime _initialDateTimeUtc;
  late DateTime _selectedDateTimeLocal;
  late DateTime _initialDateTimeLocal;

  /// The reference the rider picked (or the stored one); null follows the
  /// previous setup of the rated one.
  String? _referenceId;
  String? _initialReferenceId;
  int? _overallOutcome;
  final Map<FeedbackAspect, int> _aspectOutcomes = {};
  final Set<FeedbackAspect> _storedAspects = {};
  Set<IssueKey> _issues = {};
  List<CustomIssue> _customIssues = [];
  bool _nothingStoodOut = false;

  // Answers this form doesn't show (other references, unknown keys), written
  // back unchanged.
  Set<FeedbackComparison> _otherComparisons = {};
  Set<FeedbackObservation> _otherObservations = {};

  final LocationService _locationService = LocationService();
  final ElevationService _elevationService = ElevationService();
  final ValueNotifier<ContextPosition?> _currentLocation = ValueNotifier<ContextPosition?>(null);

  final AddressService _addressService = AddressService();
  final ValueNotifier<geo.Placemark?> _currentPlace = ValueNotifier<geo.Placemark?>(null);

  final WeatherService _weatherService = createWeatherService();
  final ValueNotifier<ContextWeather?> _currentWeather = ValueNotifier<ContextWeather?>(null);

  // The hero only flies in: it's switched off as soon as this route starts to
  // pop, before the hero controller collects the heroes a frame later.
  Animation<double>? _routeAnimation;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    final feedback = widget.feedback;
    _notesController = TextEditingController(text: feedback?.notes);
    _notesController.addListener(_changeListener);

    final now = DateTime.now();
    _selectedDateTimeLocal = feedback?.dateTimeLocal ?? widget.initialDateTimeLocal ?? now;
    _initialDateTimeLocal = _selectedDateTimeLocal;

    _selectedDateTimeUtc =
        feedback?.dateTimeUTC.copyWith(isUtc: true) ??
        widget.initialDateTimeUtc?.copyWith(isUtc: true) ??
        _selectedDateTimeLocal.toUtc();
    _initialDateTimeUtc = _selectedDateTimeUtc;

    _currentLocation.value = feedback?.position;
    _currentPlace.value = feedback?.place;
    _currentWeather.value = feedback?.weather;

    final appRepository = context.read<AppRepository>();
    _bike =
        feedback?.bike ??
        widget.initialBike?.id ??
        appRepository.view.bikes.keys.firstOrNull ??
        appRepository.bikes.keys.firstOrNull ??
        '';
    _setupId = feedback?.setupId;

    if (feedback != null) _initAnswers(feedback);

    final activity = widget.initialStravaActivity;
    if (feedback != null) return;
    // The ride's start, not wherever the rider is when filling this in later.
    if (activity == null) {
      unawaited(fetchLocationAddressWeather());
    } else if (activity.hasStartPosition) {
      unawaited(fetchActivityAddressWeather(activity));
    }
  }

  void _initAnswers(RideFeedback feedback) {
    final formComparisons = feedback.comparisons.where((c) => c.isValid && c.aspect is! UnknownAspect);
    // With several references, the form shows the answers against the most
    // recent one, preferring an overall answer.
    final setups = context.read<AppRepository>().setups;
    _initialReferenceId = formComparisons
        .sorted((a, b) {
          if ((a.aspect is OverallAspect) != (b.aspect is OverallAspect)) return a.aspect is OverallAspect ? -1 : 1;
          final (timeA, timeB) = (setups[a.referenceSetupId]?.datetime, setups[b.referenceSetupId]?.datetime);
          if (timeA != timeB) return timeB == null ? -1 : (timeA == null ? 1 : timeB.compareTo(timeA));
          return a.referenceSetupId.compareTo(b.referenceSetupId);
        })
        .firstOrNull
        ?.referenceSetupId;
    _referenceId = _initialReferenceId;

    final owned = formComparisons.where((c) => c.referenceSetupId == _initialReferenceId).toSet();
    for (final comparison in owned) {
      switch (comparison.aspect) {
        case OverallAspect():
          _overallOutcome = comparison.outcome;
        case EndAspect() || CustomAspect():
          _aspectOutcomes[comparison.aspect] = comparison.outcome;
          _storedAspects.add(comparison.aspect);
        case UnknownAspect():
          break;
      }
    }
    _otherComparisons = feedback.comparisons.difference(owned);

    _issues = feedback.issues;
    _customIssues = feedback.customIssues;
    _nothingStoodOut = feedback.nothingStoodOut;
    _otherObservations = feedback.observations
        .where((o) => o.key is! IssueKey && o.key is! CustomIssueKey && o.key is! NoIssueKey)
        .toSet();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.heroTag == null) return;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == _routeAnimation) return;
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
    _routeAnimation = animation?..addStatusListener(_onRouteAnimationStatus);
  }

  void _onRouteAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.reverse && !_isLeaving) setState(() => _isLeaving = true);
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
    _notesController.removeListener(_changeListener);
    _notesController.dispose();
    _currentLocation.dispose();
    _currentPlace.dispose();
    _currentWeather.dispose();
    super.dispose();
  }

  Setup? _ratedSetup() {
    final appRepository = context.read<AppRepository>();
    return appRepository.setups[appRepository.resolveSetupId(bikeId: _bike, atUtc: _selectedDateTimeUtc)];
  }

  /// Setups of the bike before [rated], newest first.
  List<Setup> _referenceCandidates(Setup? rated) {
    if (rated == null) return const [];
    return context
        .read<AppRepository>()
        .setups
        .values
        .where((setup) => setup.bike == _bike && setup.datetime.isBefore(rated.datetime))
        .sorted((a, b) => b.datetime.compareTo(a.datetime));
  }

  String? _effectiveReferenceId(Setup? rated, List<Setup> candidates) {
    if (rated == null) return null;
    final picked = _referenceId;
    // The stored reference stays even when it's no longer offered (deleted, or
    // later than the rated setup), as long as it isn't the rated setup itself.
    if (picked != null &&
        picked != rated.id &&
        (picked == _initialReferenceId || candidates.any((setup) => setup.id == picked))) {
      return picked;
    }
    return candidates.firstOrNull?.id;
  }

  /// Open issues of the reference, plus aspects already answered against it:
  /// built-in ones in vocabulary order, then custom ones by label.
  List<FeedbackIssue> _followUpIssues(String? referenceId) {
    if (referenceId == null) return const [];
    final appRepository = context.read<AppRepository>();
    final issues = {
      for (final issue in appRepository.openIssuesFor(referenceId)?.issues ?? const <FeedbackIssue>[])
        issue.aspect: issue,
    };
    if (referenceId == _initialReferenceId) {
      for (final aspect in _storedAspects) {
        switch (aspect) {
          case final EndAspect aspect:
            issues.putIfAbsent(aspect, () => FeedbackIssue.end(aspect));
          case final CustomAspect aspect:
            issues.putIfAbsent(
              aspect,
              () => FeedbackIssue.custom(CustomIssue(aspect.slug, appRepository.customIssues.labelOf(aspect.slug))),
            );
          default:
            break;
        }
      }
    }
    return [
      for (final aspect in EndAspect.values) ?issues[aspect],
      ...issues.values.where((issue) => issue.aspect is CustomAspect).sortedBy((issue) => issue.label.toLowerCase()),
    ];
  }

  Set<FeedbackComparison> _comparisons() {
    final rated = _ratedSetup();
    final referenceId = _effectiveReferenceId(rated, _referenceCandidates(rated));
    if (referenceId == null) return _otherComparisons;

    final answered = <FeedbackComparison>{
      if (_overallOutcome case final outcome?)
        FeedbackComparison(referenceSetupId: referenceId, aspect: const OverallAspect(), outcome: outcome),
      for (final issue in _followUpIssues(referenceId))
        if (_aspectOutcomes[issue.aspect] case final outcome?)
          FeedbackComparison(referenceSetupId: referenceId, aspect: issue.aspect, outcome: outcome),
    };
    bool isAnswered(FeedbackComparison c) =>
        answered.any((a) => a.referenceSetupId == c.referenceSetupId && a.aspect == c.aspect);
    return {..._otherComparisons.whereNot(isAnswered), ...answered};
  }

  void _setIssues(Set<IssueKey> issues, List<CustomIssue> customIssues, bool nothingStoodOut) {
    setState(() {
      _issues = issues;
      _customIssues = customIssues;
      _nothingStoodOut = nothingStoodOut;
    });
    _changeListener();
  }

  void _openCustomIssues({required bool addIssue}) {
    unawaited(
      showCustomIssuesSheet(
        context: context,
        selected: _customIssues,
        addIssue: addIssue,
        // Flagging an issue answers the question, so "Nothing stood out" goes.
        onChanged: (customIssues) =>
            _setIssues(_issues, customIssues, _nothingStoodOut && customIssues.isEmpty),
        onRenamed: _onCustomIssueRenamed,
        onRemoved: _onCustomIssueRemoved,
      ),
    );
  }

  /// The sheet rewrote the saved feedbacks; this form's unsaved answers follow,
  /// or saving would bring the old issue back.
  void _onCustomIssueRenamed(String from, CustomIssue to) {
    final fromAspect = CustomAspect(from);
    FeedbackAspect renamed(FeedbackAspect aspect) => aspect == fromAspect ? to.aspect : aspect;
    setState(() {
      // On a merge the answer the target already has wins.
      final outcomes = <FeedbackAspect, int>{
        for (final MapEntry(:key, :value) in _aspectOutcomes.entries)
          if (key != fromAspect) key: value,
      };
      if (_aspectOutcomes[fromAspect] case final outcome?) outcomes.putIfAbsent(to.aspect, () => outcome);
      _aspectOutcomes
        ..clear()
        ..addAll(outcomes);
      final stored = _storedAspects.map(renamed).toSet();
      _storedAspects
        ..clear()
        ..addAll(stored);
      _otherComparisons = _otherComparisons.map((c) => c.copyWith(aspect: renamed(c.aspect))).toSet();
    });
    _changeListener();
  }

  void _onCustomIssueRemoved(String slug) {
    final aspect = CustomAspect(slug);
    setState(() {
      _aspectOutcomes.remove(aspect);
      _storedAspects.remove(aspect);
      _otherComparisons = _otherComparisons.where((c) => c.aspect != aspect).toSet();
    });
    _changeListener();
  }

  Set<FeedbackObservation> _observations() => {
    ..._otherObservations,
    for (final key in _issues) FeedbackObservation.flag(key),
    for (final issue in _customIssues) issue.toObservation(),
    if (_nothingStoodOut) const FeedbackObservation.flag(NoIssueKey()),
  };

  Future<void> fetchLocationAddressWeather() async {
    final coordinatesChanged = await updateLocation();
    if (!coordinatesChanged) return;

    unawaited(updateWeather());
    unawaited(updateAddress());
  }

  Future<void> fetchActivityAddressWeather(StravaActivity activity) async {
    final position = await _elevationService.addMissingElevation(
      ContextPosition(latitude: activity.startLat, longitude: activity.startLon),
    );
    if (!mounted) return;

    _currentLocation.value = position;
    _changeListener();
    unawaited(updateWeather());
    unawaited(updateAddress());
  }

  Future<bool> updateLocation() async {
    final previousLocation = _currentLocation.value;
    final fetchedLocation = await _locationService.fetchLocation();
    final newLocation = fetchedLocation == null ? null : await _elevationService.addMissingElevation(fetchedLocation);

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

    _currentPlace.value = newAddress;
    _changeListener();
  }

  void _changeListener() {
    final feedback = widget.feedback;
    final hasChanges =
        _notesController.text.trim() != (feedback?.notes ?? '') ||
        _initialDateTimeUtc != _selectedDateTimeUtc ||
        _initialDateTimeLocal != _selectedDateTimeLocal ||
        !ContextPosition.equal(_currentLocation.value, feedback?.position) ||
        !ContextPlace.equal(_currentPlace.value, feedback?.place) ||
        _currentWeather.value != feedback?.weather ||
        _setupId != feedback?.setupId ||
        !setEquals(_comparisons(), feedback?.comparisons ?? const {}) ||
        !setEquals(_observations(), feedback?.observations ?? const {});

    if (_formHasChanges != hasChanges) {
      setState(() => _formHasChanges = hasChanges);
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      helpText: "Select Feedback Date",
      errorInvalidText: "Date cannot be in the future",
      selectableDayPredicate: (DateTime pickedDate) => !_selectedDateTimeLocal
          .copyWith(day: pickedDate.day, month: pickedDate.month, year: pickedDate.year)
          .isAfter(DateTime.now()),
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

    _setDateTime(newDateTimeLocal);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      helpText: "Select Feedback Time",
      initialTime: TimeOfDay.fromDateTime(_selectedDateTimeLocal),
    );

    if (!mounted || pickedTime == null) return;

    final DateTime newDateTimeLocal = _selectedDateTimeLocal.copyWith(hour: pickedTime.hour, minute: pickedTime.minute);
    if (newDateTimeLocal == _selectedDateTimeLocal) return;
    if (newDateTimeLocal.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error(context, 'Date and Time cannot be in the future.'));
      return;
    }

    _setDateTime(newDateTimeLocal);
  }

  void _setDateTime(DateTime newDateTimeLocal) {
    final previousRatedId = _ratedSetup()?.id;
    setState(() {
      _selectedDateTimeLocal = newDateTimeLocal;
      _selectedDateTimeUtc = newDateTimeLocal.toUtc();
    });
    _changeListener();

    // The rated setup card is far above the date chips, so say when it moved.
    final rated = _ratedSetup();
    if (rated?.id != previousRatedId) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          rated == null
              ? AppSnackBar.error(context, 'No setup was active at this time.')
              : AppSnackBar.info(context, "Now rating '${rated.displayName}'."),
        );
    }
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

    _currentWeather.value = currentWeather;
    _changeListener();
  }

  void _saveFeedback() {
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

    // Feedback rates the setup that was active at the ride's time, so it needs one.
    final rated = _ratedSetup();
    if (rated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(
          context,
          'No setup exists before this date/time for the selected bike. Create a setup first.',
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final notesText = _notesController.text.trim();
    final feedback = widget.feedback;
    _formHasChanges = false;
    Navigator.pop(
      context,
      RideFeedback(
        id: feedback?.id,
        isDeleted: feedback?.isDeleted,
        lastModified: DateTime.now(),
        bike: _bike,
        setupId: _setupId ?? rated.id,
        stravaActivityId: feedback?.stravaActivityId ?? widget.initialStravaActivity?.id,
        dateTimeUTC: _selectedDateTimeUtc,
        dateTimeLocal: _selectedDateTimeLocal,
        notes: notesText.isEmpty ? null : notesText,
        position: _currentLocation.value,
        place: _currentPlace.value,
        weather: _currentWeather.value,
        observations: _observations(),
        comparisons: _comparisons(),
      ),
    );
  }

  void _handlePopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;
    if (!_formHasChanges) return;
    final shouldDiscard = await showDiscardChangesDialog(context);
    if (!mounted) return;
    if (!shouldDiscard) return;
    Navigator.of(context).pop(null);
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
        helperText: FeedbackVocabulary.notesHelper,
        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
        filled: widget.mode == FeedbackPageMode.edit && _notesController.text.trim() != (widget.feedback?.notes ?? ''),
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
          runSpacing: 8.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ActionChip(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              avatar: const Icon(Icons.calendar_month),
              label: Text(DateFormat(appSettings.dateFormat).format(_selectedDateTimeLocal)),
              backgroundColor:
                  widget.mode == FeedbackPageMode.edit &&
                      (_selectedDateTimeUtc.year != _initialDateTimeUtc.year ||
                          _selectedDateTimeUtc.month != _initialDateTimeUtc.month ||
                          _selectedDateTimeUtc.day != _initialDateTimeUtc.day)
                  ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
                  : null,
              onPressed: _pickDate,
            ),
            ActionChip(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              avatar: const Icon(Icons.access_time),
              label: Text(DateFormat(appSettings.timeFormat).format(_selectedDateTimeLocal)),
              backgroundColor:
                  widget.mode == FeedbackPageMode.edit &&
                      (_selectedDateTimeUtc.hour != _initialDateTimeUtc.hour ||
                          _selectedDateTimeUtc.minute != _initialDateTimeUtc.minute)
                  ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
                  : null,
              onPressed: _pickTime,
            ),
            ActionChip(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor:
                  widget.mode == FeedbackPageMode.edit &&
                      (!ContextPosition.equal(_currentLocation.value, widget.feedback?.position) ||
                          !ContextPlace.equal(_currentPlace.value, widget.feedback?.place))
                  ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
                  : null,
              onPressed:
                  _locationService.status == LocationStatus.searching ||
                      _addressService.status == AddressStatus.searching
                  ? null
                  : () async {
                      final result = await showSetLocationPlaceSheet(
                        context: context,
                        locationService: _locationService,
                        currentLocation: _currentLocation.value,
                        addressService: _addressService,
                        currentPlace: _currentPlace.value,
                      );
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

                      if (requestWeatherUpdate) unawaited(askAndUpdateWeather());

                      _changeListener();
                    },
              avatar: switch (_locationService.status) {
                LocationStatus.idle || LocationStatus.success => switch (_addressService.status) {
                  AddressStatus.idle || AddressStatus.searching || AddressStatus.success =>
                    _currentLocation.value == null
                        ? const Icon(Icons.location_searching)
                        : const Icon(Icons.my_location),
                  AddressStatus.error => Icon(Icons.error, color: Theme.of(context).colorScheme.error),
                },
                LocationStatus.searching => const Icon(Icons.location_searching),
                LocationStatus.noPermission ||
                LocationStatus.permissionDeniedForever ||
                LocationStatus.noService ||
                LocationStatus.timeout ||
                LocationStatus.error => Icon(Icons.location_disabled, color: Theme.of(context).colorScheme.error),
              },
              label: switch (_locationService.status) {
                LocationStatus.searching => const ChipLoadingIndicator(),
                _ when _addressService.status == AddressStatus.searching => const ChipLoadingIndicator(),
                _ when _currentPlace.value != null => Text(
                  "${_currentPlace.value?.locality}, ${_currentPlace.value?.isoCountryCode}",
                ),
                LocationStatus.idle || LocationStatus.success =>
                  _addressService.status == AddressStatus.error ? const Text("Address Error") : const Text("-"),
                LocationStatus.noService => const Text("No GPS Service"),
                LocationStatus.noPermission ||
                LocationStatus.permissionDeniedForever => const Text("No GPS Permission"),
                LocationStatus.timeout => const Text("GPS Timeout"),
                LocationStatus.error => const Text("Location Error"),
              },
            ),
            ActionChip(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
              backgroundColor:
                  widget.mode == FeedbackPageMode.edit &&
                      _currentWeather.value?.withoutCondition() != widget.feedback?.weather?.withoutCondition()
                  ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
                  : null,
              onPressed:
                  _locationService.status == LocationStatus.searching || _weatherService.status is WeatherSearching
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
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              avatar: Icon(
                _currentWeather.value?.condition?.iconData ?? Icons.edit_road,
                color: _currentWeather.value?.condition?.color,
              ),
              label: _weatherService.status is WeatherSearching
                  ? const ChipLoadingIndicator()
                  : Text(_currentWeather.value?.condition?.value ?? "-"),
              backgroundColor:
                  widget.mode == FeedbackPageMode.edit &&
                      _currentWeather.value?.condition != widget.feedback?.weather?.condition
                  ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
                  : null,
              onPressed:
                  _locationService.status == LocationStatus.searching || _weatherService.status is WeatherSearching
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

  /// The setup this ride rates: the one active at the chosen time, with the
  /// same header as its tile in the setup list.
  Widget _ratedSetupCard(Setup? rated) {
    final appSettings = context.read<AppSettings>();
    final appRepository = context.read<AppRepository>();
    final theme = Theme.of(context);
    final bike = appRepository.bikes[_bike];

    if (rated == null) {
      final errorColor = theme.colorScheme.error;
      return Card.outlined(
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minTileHeight: 0,
          titleAlignment: ListTileTitleAlignment.top,
          leading: Icon(Setup.iconData, color: errorColor),
          title: Text('No setup at this time', style: theme.textTheme.titleMedium?.copyWith(color: errorColor)),
          subtitle: Text(
            'Feedback rates the setup that was active when you rode. Pick a later date or add a setup first.',
            style: TextStyle(color: errorColor),
          ),
        ),
      );
    }

    final header = SetupTileHeader(
      setup: rated,
      dateTimeText:
          '${DateFormat(appSettings.dateFormat).format(rated.datetimeLocal)} • '
          '${DateFormat(appSettings.timeFormat).format(rated.datetimeLocal)}',
      metadata: SetupTileHeader.metadataOf(rated, appSettings),
      badge: appRepository.setupHistory.isCurrent(rated.id) ? const CurrentSetupBadge() : null,
      showSetupIcon: true,
      secondaryMetadata: TileMetaRow(icon: Bike.iconData, text: bike?.name ?? "BIKE NOT FOUND", isError: bike == null),
    );

    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: widget.heroTag == null
            ? header
            : HeroMode(
                enabled: !_isLeaving,
                child: Hero(
                  tag: widget.heroTag!,
                  flightShuttleBuilder: (flightContext, animation, direction, fromHeroContext, toHeroContext) =>
                      Material(
                        // The flight runs in the overlay, outside the card's Material.
                        type: MaterialType.transparency,
                        // In flight the header gets a size between the tile's and the card's, so
                        // its wrapped text may not fit exactly: keep its own height and clip.
                        child: ClipRect(
                          child: OverflowBox(alignment: Alignment.topLeft, maxHeight: double.infinity, child: header),
                        ),
                      ),
                  child: header,
                ),
              ),
      ),
    );
  }

  Widget? _driftWarning(Setup? rated) {
    final stored = _setupId;
    if (stored == null || rated == null || rated.id == stored) return null;

    final storedName = context.read<AppRepository>().setups[stored]?.displayName ?? "a deleted setup";
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(top: 8),
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
          "Originally '$storedName', now resolves to '${rated.displayName}'. Ranking follows the current resolution.",
          style: TextStyle(color: scheme.onErrorContainer.withValues(alpha: 0.9), fontSize: 12),
        ),
        trailing: TextButton(
          onPressed: () {
            setState(() => _setupId = rated.id);
            _changeListener();
          },
          style: TextButton.styleFrom(foregroundColor: scheme.onErrorContainer),
          child: const Text("Relink"),
        ),
      ),
    );
  }

  List<Widget> _comparisonSection(AppRepository appRepository, Setup? rated) {
    final candidates = _referenceCandidates(rated);
    final referenceId = _effectiveReferenceId(rated, candidates);
    if (rated == null || referenceId == null) return const [];

    final reference = appRepository.setups[referenceId];
    final followUps = _followUpIssues(referenceId);

    return [
      const SizedBox(height: 8),
      SectionTitle(
        title: "Compared to",
        trailing: reference == null
            ? null
            : TextButton.icon(
                onPressed: () => showCompareSetupsSheet(context, setupA: reference, setupB: rated),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.compare, size: 18),
                label: const Text("View comparison"),
              ),
      ),
      FeedbackComparisonField(
        rated: rated,
        referenceId: referenceId,
        candidates: candidates,
        outcome: _overallOutcome,
        onOutcomeChanged: (outcome) {
          setState(() => _overallOutcome = outcome);
          _changeListener();
        },
        onReferenceChanged: (id) {
          setState(() => _referenceId = id);
          _changeListener();
        },
      ),
      if (followUps.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text("Did its open issues change?", style: Theme.of(context).textTheme.titleSmall),
        ),
        for (final issue in followUps)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: FeedbackAspectRow(
              issue: issue,
              outcome: _aspectOutcomes[issue.aspect],
              onChanged: (outcome) {
                setState(() {
                  if (outcome == null) {
                    _aspectOutcomes.remove(issue.aspect);
                  } else {
                    _aspectOutcomes[issue.aspect] = outcome;
                  }
                });
                _changeListener();
              },
            ),
          ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final rated = _ratedSetup();

    return PopScope(
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: switch (widget.mode) {
            FeedbackPageMode.add => const Text('Add Feedback'),
            FeedbackPageMode.edit => const Text('Edit Feedback'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveFeedback),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ratedSetupCard(rated),
                        ?_driftWarning(rated),
                      ],
                    ),
                  ),
                  ..._comparisonSection(appRepository, rated),
                  const SizedBox(height: 8),
                  const SectionTitle(
                    title: "Anything stand out?",
                    infoText:
                        "Optional. Flagged problems show on the setup as open issues until a later ride says otherwise.",
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FeedbackIssueChips(
                      issues: _issues,
                      customIssues: _customIssues,
                      knownIssues: appRepository.customIssues,
                      nothingStoodOut: _nothingStoodOut,
                      onChanged: _setIssues,
                      onOpenCustomIssues: _openCustomIssues,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SectionTitle(title: "Details"),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _notesTextFormField(),
                        const SizedBox(height: 12),
                        _wrap(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
