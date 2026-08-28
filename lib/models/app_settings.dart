import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:units_converter/units_converter.dart';

class AppSettings extends ChangeNotifier {
  static const String _kPrefix = 'app_settings.';
  static const String _kLegacyBlobKey = 'app_settings';

  bool _showOnboarding = true;
  ThemeMode _themeMode = ThemeMode.system;
  String _dateFormat = 'yyyy-MM-dd';
  String _timeFormat = 'HH:mm';
  String _temperatureUnit = '°C';
  String _windSpeedUnit = 'km/h';
  String _altitudeUnit = 'm';
  String _precipitationUnit = 'mm';
  String _distanceUnit = 'km';
  bool _enableGoogleDrive = false; // False is default, can only be activated on Android (see AppSettingsPage)
  bool _enableTextAdjustment = false;
  bool _enableMultiSelect = false;
  bool _enableCountedSelect = false;
  bool _enablePerson = false;
  bool _enableRating = false;
  bool _enableSetupTags = false;
  bool _enableTaskTags = false;
  final bool _enableStrava = true;
  bool _enableStravaNotifications = true;
  bool _enableTask = false;
  bool _enableTaskPriority = true;
  bool _enableTaskInterval = true;
  bool _enableTaskDelay = false;
  bool _enableGarageTaskIndicator = true;
  bool _enableInstallationTimeline = false;
  bool _useMapBoxTiles = false;
  bool _enableCalendar = false;
  bool _enableSetupImages = false;
  bool _enableSetupComparison = true;
  bool _enableComponentPresets = false;
  // Setup timeline grouping passes (debug-only, see FeaturesPage)
  bool _enableTimelineDayHeaders = true;
  bool _enableTimelineSetupGrouping = false;
  bool _enableTimelineReplacementDetection = true;
  bool _enableTimelineStravaContext = false;
  int _firstDayOfWeek = DateTime.monday; // 1 = Monday … 7 = Sunday

  // Temporary Settings (in-memory only, never persisted)
  bool _setupListBikeAdjustmentValues = true;
  bool _setupListPersonAdjustmentValues = true;
  bool _displayShowSetups = true;
  bool _displayShowActivities = true;
  bool _displayShowInstallations = true;
  bool _displayShowTasks = true;
  bool _displayShowRatingEntries = true;

  bool get showOnboarding => _showOnboarding;
  ThemeMode get themeMode => _themeMode;
  String get dateFormat => _dateFormat;
  String get timeFormat => _timeFormat;
  String get temperatureUnit => _temperatureUnit;
  String get windSpeedUnit => _windSpeedUnit;
  String get altitudeUnit => _altitudeUnit;
  String get precipitationUnit => _precipitationUnit;
  String get distanceUnit => _distanceUnit;
  bool get enableGoogleDrive => _enableGoogleDrive;
  bool get enableTextAdjustment => _enableTextAdjustment;
  bool get enableMultiSelect => _enableMultiSelect;
  bool get enableCountedSelect => _enableCountedSelect;
  bool get enablePerson => _enablePerson;
  bool get enableRating => _enableRating;
  bool get enableSetupTags => _enableSetupTags;
  bool get enableTaskTags => _enableTaskTags;
  bool get enableStrava => _enableStrava;
  bool get enableStravaNotifications => _enableStravaNotifications;
  bool get enableTask => _enableTask;
  bool get enableTaskPriority => _enableTaskPriority;
  bool get enableTaskInterval => _enableTaskInterval;
  bool get enableTaskDelay => _enableTaskDelay;
  bool get enableGarageTaskIndicator => _enableGarageTaskIndicator;
  bool get enableInstallationTimeline => _enableInstallationTimeline;
  bool get useMapBoxTiles => _useMapBoxTiles;
  bool get enableCalendar => _enableCalendar;
  bool get enableSetupImages => _enableSetupImages;
  bool get enableSetupComparison => _enableSetupComparison;
  bool get enableComponentPresets => _enableComponentPresets;
  bool get enableTimelineDayHeaders => _enableTimelineDayHeaders;
  bool get enableTimelineSetupGrouping => _enableTimelineSetupGrouping;
  bool get enableTimelineReplacementDetection => _enableTimelineReplacementDetection;
  bool get enableTimelineStravaContext => _enableTimelineStravaContext;
  int get firstDayOfWeek => _firstDayOfWeek;

  // Temporary Settings
  bool get setupListBikeAdjustmentValues => _setupListBikeAdjustmentValues;
  bool get setupListPersonAdjustmentValues => _setupListPersonAdjustmentValues;
  bool get displayShowSetups => _displayShowSetups;
  bool get displayShowActivities => _displayShowActivities;
  bool get displayShowInstallations => _displayShowInstallations;
  bool get displayShowTasks => _displayShowTasks;
  bool get displayShowRatingEntries => _displayShowRatingEntries;

  set showOnboarding(bool newShowOnboarding) {
    if (_showOnboarding == newShowOnboarding) return;
    _showOnboarding = newShowOnboarding;
    notifyListeners();
    _persistBool('showOnboarding', newShowOnboarding);
  }

  set themeMode(ThemeMode newThemeMode) {
    if (_themeMode == newThemeMode) return;
    _themeMode = newThemeMode;
    notifyListeners();
    _persistString('themeMode', newThemeMode.toString());
  }

  set dateFormat(String newDateFormat) {
    if (newDateFormat == _dateFormat) return;
    _dateFormat = newDateFormat;
    notifyListeners();
    _persistString('dateFormat', newDateFormat);
  }

  set timeFormat(String newTimeFormat) {
    if (newTimeFormat == _timeFormat) return;
    _timeFormat = newTimeFormat;
    notifyListeners();
    _persistString('timeFormat', newTimeFormat);
  }

  set temperatureUnit(String newUnit) {
    if (newUnit == _temperatureUnit) return;
    _temperatureUnit = newUnit;
    notifyListeners();
    _persistString('temperatureUnit', newUnit);
  }

  set windSpeedUnit(String newUnit) {
    if (newUnit == _windSpeedUnit) return;
    _windSpeedUnit = newUnit;
    notifyListeners();
    _persistString('windSpeedUnit', newUnit);
  }

  set altitudeUnit(String newUnit) {
    if (newUnit == _altitudeUnit) return;
    _altitudeUnit = newUnit;
    notifyListeners();
    _persistString('altitudeUnit', newUnit);
  }

  set precipitationUnit(String newUnit) {
    if (newUnit == _precipitationUnit) return;
    _precipitationUnit = newUnit;
    notifyListeners();
    _persistString('precipitationUnit', newUnit);
  }

  set distanceUnit(String newUnit) {
    if (newUnit == _distanceUnit) return;
    _distanceUnit = newUnit;
    notifyListeners();
    _persistString('distanceUnit', newUnit);
  }

  set enableGoogleDrive(bool newValue) {
    if (newValue == _enableGoogleDrive) return;
    _enableGoogleDrive = newValue;
    notifyListeners();
    _persistBool('enableGoogleDrive', newValue);
  }

  set enableTextAdjustment(bool newValue) {
    if (newValue == _enableTextAdjustment) return;
    _enableTextAdjustment = newValue;
    notifyListeners();
    _persistBool('enableTextAdjustment', newValue);
  }

  set enableMultiSelect(bool newValue) {
    if (newValue == _enableMultiSelect) return;
    _enableMultiSelect = newValue;
    notifyListeners();
    _persistBool('enableMultiSelect', newValue);
  }

  set enableCountedSelect(bool newValue) {
    if (newValue == _enableCountedSelect) return;
    _enableCountedSelect = newValue;
    notifyListeners();
    _persistBool('enableCountedSelect', newValue);
  }

  set enablePerson(bool newValue) {
    if (newValue == _enablePerson) return;
    _enablePerson = newValue;
    notifyListeners();
    _persistBool('enablePerson', newValue);
  }

  set enableRating(bool newValue) {
    if (newValue == _enableRating) return;
    _enableRating = newValue;
    notifyListeners();
    _persistBool('enableRating', newValue);
  }

  set enableSetupTags(bool newValue) {
    if (newValue == _enableSetupTags) return;
    _enableSetupTags = newValue;
    notifyListeners();
    _persistBool('enableSetupTags', newValue);
  }

  set enableTaskTags(bool newValue) {
    if (newValue == _enableTaskTags) return;
    _enableTaskTags = newValue;
    notifyListeners();
    _persistBool('enableTaskTags', newValue);
  }

  set enableStravaNotifications(bool newValue) {
    if (newValue == _enableStravaNotifications) return;
    _enableStravaNotifications = newValue;
    notifyListeners();
    _persistBool('enableStravaNotifications', newValue);
  }

  set enableTask(bool newValue) {
    if (newValue == _enableTask) return;
    _enableTask = newValue;
    notifyListeners();
    _persistBool('enableTask', newValue);
  }

  set enableInstallationTimeline(bool newValue) {
    if (newValue == _enableInstallationTimeline) return;
    _enableInstallationTimeline = newValue;
    notifyListeners();
    _persistBool('enableInstallationTimeline', newValue);
  }

  set enableTaskPriority(bool newValue) {
    if (newValue == _enableTaskPriority) return;
    _enableTaskPriority = newValue;
    notifyListeners();
    _persistBool('enableTaskPriority', newValue);
  }

  set enableTaskInterval(bool newValue) {
    if (newValue == _enableTaskInterval) return;
    _enableTaskInterval = newValue;
    notifyListeners();
    _persistBool('enableTaskInterval', newValue);
  }

  set enableTaskDelay(bool newValue) {
    if (newValue == _enableTaskDelay) return;
    _enableTaskDelay = newValue;
    notifyListeners();
    _persistBool('enableTaskDelay', newValue);
  }

  set enableGarageTaskIndicator(bool newValue) {
    if (newValue == _enableGarageTaskIndicator) return;
    _enableGarageTaskIndicator = newValue;
    notifyListeners();
    _persistBool('enableGarageTaskIndicator', newValue);
  }

  set useMapBoxTiles(bool newValue) {
    if (newValue == _useMapBoxTiles) return;
    _useMapBoxTiles = newValue;
    notifyListeners();
    _persistBool('useMapBoxTiles', newValue);
  }

  set enableCalendar(bool newValue) {
    if (newValue == _enableCalendar) return;
    _enableCalendar = newValue;
    notifyListeners();
    _persistBool('enableCalendar', newValue);
  }

  set enableSetupImages(bool newValue) {
    if (newValue == _enableSetupImages) return;
    _enableSetupImages = newValue;
    notifyListeners();
    _persistBool('enableSetupImages', newValue);
  }

  set enableSetupComparison(bool newValue) {
    if (newValue == _enableSetupComparison) return;
    _enableSetupComparison = newValue;
    notifyListeners();
    _persistBool('enableSetupComparison', newValue);
  }

  set enableComponentPresets(bool newValue) {
    if (newValue == _enableComponentPresets) return;
    _enableComponentPresets = newValue;
    notifyListeners();
    _persistBool('enableComponentPresets', newValue);
  }

  set enableTimelineDayHeaders(bool newValue) {
    if (newValue == _enableTimelineDayHeaders) return;
    _enableTimelineDayHeaders = newValue;
    notifyListeners();
    _persistBool('enableTimelineDayHeaders', newValue);
  }

  set enableTimelineSetupGrouping(bool newValue) {
    if (newValue == _enableTimelineSetupGrouping) return;
    _enableTimelineSetupGrouping = newValue;
    notifyListeners();
    _persistBool('enableTimelineSetupGrouping', newValue);
  }

  set enableTimelineReplacementDetection(bool newValue) {
    if (newValue == _enableTimelineReplacementDetection) return;
    _enableTimelineReplacementDetection = newValue;
    notifyListeners();
    _persistBool('enableTimelineReplacementDetection', newValue);
  }

  set enableTimelineStravaContext(bool newValue) {
    if (newValue == _enableTimelineStravaContext) return;
    _enableTimelineStravaContext = newValue;
    notifyListeners();
    _persistBool('enableTimelineStravaContext', newValue);
  }

  set firstDayOfWeek(int newValue) {
    if (newValue == _firstDayOfWeek) return;
    _firstDayOfWeek = newValue;
    notifyListeners();
    _persistInt('firstDayOfWeek', newValue);
  }

  set setupListBikeAdjustmentValues(bool newValue) {
    if (newValue == _setupListBikeAdjustmentValues) return;
    _setupListBikeAdjustmentValues = newValue;
    notifyListeners();
  }

  set setupListPersonAdjustmentValues(bool newValue) {
    if (newValue == _setupListPersonAdjustmentValues) return;
    _setupListPersonAdjustmentValues = newValue;
    notifyListeners();
  }

  set displayShowSetups(bool newValue) {
    if (newValue == _displayShowSetups) return;
    _displayShowSetups = newValue;
    notifyListeners();
  }

  set displayShowActivities(bool newValue) {
    if (newValue == _displayShowActivities) return;
    _displayShowActivities = newValue;
    notifyListeners();
  }

  set displayShowInstallations(bool newValue) {
    if (newValue == _displayShowInstallations) return;
    _displayShowInstallations = newValue;
    notifyListeners();
  }

  set displayShowTasks(bool newValue) {
    if (newValue == _displayShowTasks) return;
    _displayShowTasks = newValue;
    notifyListeners();
  }

  set displayShowRatingEntries(bool newValue) {
    if (newValue == _displayShowRatingEntries) return;
    _displayShowRatingEntries = newValue;
    notifyListeners();
  }

  void _persistBool(String name, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kPrefix$name', value);
  }

  void _persistString(String name, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kPrefix$name', value);
  }

  void _persistInt(String name, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_kPrefix$name', value);
  }

  Future<void> loadAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await _migrateLegacyBlob(prefs);
      await _removeDeprecatedPreferences(prefs);

      _showOnboarding = prefs.getBool('${_kPrefix}showOnboarding') ?? _showOnboarding;
      final storedThemeMode = prefs.getString('${_kPrefix}themeMode');
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == storedThemeMode,
        orElse: () => _themeMode,
      );
      _dateFormat = prefs.getString('${_kPrefix}dateFormat') ?? _dateFormat;
      _timeFormat = prefs.getString('${_kPrefix}timeFormat') ?? _timeFormat;
      _temperatureUnit = prefs.getString('${_kPrefix}temperatureUnit') ?? _temperatureUnit;
      _windSpeedUnit = prefs.getString('${_kPrefix}windSpeedUnit') ?? _windSpeedUnit;
      _altitudeUnit = prefs.getString('${_kPrefix}altitudeUnit') ?? _altitudeUnit;
      _precipitationUnit = prefs.getString('${_kPrefix}precipitationUnit') ?? _precipitationUnit;
      _distanceUnit = prefs.getString('${_kPrefix}distanceUnit') ?? _distanceUnit;
      _enableGoogleDrive = prefs.getBool('${_kPrefix}enableGoogleDrive') ?? _enableGoogleDrive;
      _enableTextAdjustment = prefs.getBool('${_kPrefix}enableTextAdjustment') ?? _enableTextAdjustment;
      _enableMultiSelect = prefs.getBool('${_kPrefix}enableMultiSelect') ?? _enableMultiSelect;
      _enableCountedSelect = prefs.getBool('${_kPrefix}enableCountedSelect') ?? _enableCountedSelect;
      _enablePerson = prefs.getBool('${_kPrefix}enablePerson') ?? _enablePerson;
      _enableRating = prefs.getBool('${_kPrefix}enableRating') ?? _enableRating;
      _enableSetupTags = prefs.getBool('${_kPrefix}enableSetupTags') ?? _enableSetupTags;
      _enableTaskTags = prefs.getBool('${_kPrefix}enableTaskTags') ?? _enableTaskTags;
      // enableStrava should always be true; ignored persisted value
      _enableStravaNotifications = prefs.getBool('${_kPrefix}enableStravaNotifications') ?? _enableStravaNotifications;
      _enableTask = prefs.getBool('${_kPrefix}enableTask') ?? _enableTask;
      _enableTaskPriority = prefs.getBool('${_kPrefix}enableTaskPriority') ?? _enableTaskPriority;
      _enableTaskInterval = prefs.getBool('${_kPrefix}enableTaskInterval') ?? _enableTaskInterval;
      _enableTaskDelay = prefs.getBool('${_kPrefix}enableTaskDelay') ?? _enableTaskDelay;
      _enableGarageTaskIndicator = prefs.getBool('${_kPrefix}enableGarageTaskIndicator') ?? _enableGarageTaskIndicator;
      _enableInstallationTimeline =
          prefs.getBool('${_kPrefix}enableInstallationTimeline') ?? _enableInstallationTimeline;
      _useMapBoxTiles = prefs.getBool('${_kPrefix}useMapBoxTiles') ?? _useMapBoxTiles;
      _enableCalendar = prefs.getBool('${_kPrefix}enableCalendar') ?? _enableCalendar;
      _enableSetupImages = prefs.getBool('${_kPrefix}enableSetupImages') ?? _enableSetupImages;
      _enableSetupComparison = prefs.getBool('${_kPrefix}enableSetupComparison') ?? _enableSetupComparison;
      _enableComponentPresets = prefs.getBool('${_kPrefix}enableComponentPresets') ?? _enableComponentPresets;
      _enableTimelineDayHeaders = prefs.getBool('${_kPrefix}enableTimelineDayHeaders') ?? _enableTimelineDayHeaders;
      _enableTimelineSetupGrouping =
          prefs.getBool('${_kPrefix}enableTimelineSetupGrouping') ?? _enableTimelineSetupGrouping;
      _enableTimelineReplacementDetection =
          prefs.getBool('${_kPrefix}enableTimelineReplacementDetection') ?? _enableTimelineReplacementDetection;
      _enableTimelineStravaContext =
          prefs.getBool('${_kPrefix}enableTimelineStravaContext') ?? _enableTimelineStravaContext;
      _firstDayOfWeek = prefs.getInt('${_kPrefix}firstDayOfWeek') ?? _firstDayOfWeek;
    } catch (e, st) {
      debugPrint("ERROR loading App Settings: $e\n$st");
    }
  }

  /// Migrates the pre-existing monolithic `app_settings` JSON blob to per-key
  /// storage, then removes it. Runs at most once (the blob is gone afterwards).
  /// Only values that *differ* from the original default are migrated: settings
  /// the user never explicitly changed are left unset, so they continue to
  /// track the live code default — matching new-install behaviour.
  Future<void> _migrateLegacyBlob(SharedPreferences prefs) async {
    final raw = prefs.getString(_kLegacyBlobKey);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in json.entries) {
        final value = entry.value;
        if (!_legacyDefaults.containsKey(entry.key)) continue;
        // Skip untouched defaults so they keep following future code defaults.
        if (_legacyDefaults[entry.key] == value) continue;
        final key = '$_kPrefix${entry.key}';
        if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is String) {
          await prefs.setString(key, value);
        }
      }
    } catch (e, st) {
      debugPrint("ERROR migrating legacy App Settings: $e\n$st");
    }
    await prefs.remove(_kLegacyBlobKey);
  }

  static const _deprecatedPreferenceKeys = ['enableGarage'];

  Future<void> _removeDeprecatedPreferences(SharedPreferences prefs) async {
    for (final key in _deprecatedPreferenceKeys) {
      await prefs.remove('$_kPrefix$key');
    }
  }

  /// Default values as written into the old monolithic blob. Used solely by
  /// [_migrateLegacyBlob] to tell an explicit user choice from a frozen default.
  /// These are the defaults at the time the blob format was retired; do not
  /// change them when you bump the live defaults above.
  static const Map<String, Object> _legacyDefaults = {
    'showOnboarding': true,
    'themeMode': 'ThemeMode.system',
    'dateFormat': 'yyyy-MM-dd',
    'timeFormat': 'HH:mm',
    'temperatureUnit': '°C',
    'windSpeedUnit': 'km/h',
    'altitudeUnit': 'm',
    'precipitationUnit': 'mm',
    'distanceUnit': 'km',
    'enableGoogleDrive': false,
    'enableTextAdjustment': false,
    'enableSetupTags': false,
    'enableTaskTags': false,
    'enableStravaNotifications': true,
    'enableTask': false,
    'enableTaskPriority': true,
    'enableInstallationTimeline': false,
    'enableCalendar': false,
  };

  static LENGTH _distanceLengthUnit(String unit) => switch (unit) {
    'km' => LENGTH.kilometers,
    'mi' => LENGTH.miles,
    _ => LENGTH.kilometers,
  };

  static LENGTH _elevationLengthUnit(String unit) => switch (unit) {
    'm' => LENGTH.meters,
    'ft' => LENGTH.feet,
    _ => LENGTH.meters,
  };

  static double? convertDistanceFromMeters(double? meters, String targetUnit) {
    if (meters == null) return null;
    return meters.convertFromTo(LENGTH.meters, _distanceLengthUnit(targetUnit));
  }

  static double? convertDistanceToMeters(double? distance, String currentUnit) {
    if (distance == null) return null;
    return distance.convertFromTo(_distanceLengthUnit(currentUnit), LENGTH.meters);
  }

  static double? convertElevationFromMeters(double? meters, String targetUnit) {
    if (meters == null) return null;
    return meters.convertFromTo(LENGTH.meters, _elevationLengthUnit(targetUnit));
  }

  static String speedUnitForDistance(String distanceUnit) => distanceUnit == 'mi' ? 'mph' : 'km/h';
}
