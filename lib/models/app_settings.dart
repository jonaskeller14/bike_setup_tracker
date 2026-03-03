import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  bool _showOnboarding = true;
  ThemeMode _themeMode = ThemeMode.system;
  String _dateFormat = 'yyyy-MM-dd';
  String _timeFormat = 'HH:mm';
  String _temperatureUnit = '°C';
  String _windSpeedUnit = 'km/h';
  String _altitudeUnit = 'm';
  String _precipitationUnit = 'mm';
  bool _enableGoogleDrive = Platform.isAndroid;
  bool _enableTextAdjustment = false;
  bool _enablePerson = false;
  bool _enableRating = false;
  bool _enableSetupTags = false;
  bool _enableStrava = false;
  static const bool _enableMap = true;
  bool _enableGarage = true;

  // Temporary Settings
  bool _setupListOnlyChanges = false;
  bool _setupListBikeAdjustmentValues = true;
  bool _setupListPersonAdjustmentValues = true;
  bool _setupListRatingAdjustmentValues = true;
  bool _setupListSortAscending = false;

  bool get showOnboarding => _showOnboarding;
  ThemeMode get themeMode => _themeMode;
  String get dateFormat => _dateFormat;
  String get timeFormat => _timeFormat;
  String get temperatureUnit => _temperatureUnit;
  String get windSpeedUnit => _windSpeedUnit;
  String get altitudeUnit => _altitudeUnit;
  String get precipitationUnit => _precipitationUnit;
  bool get enableGoogleDrive => _enableGoogleDrive;
  bool get enableTextAdjustment => _enableTextAdjustment;
  bool get enablePerson => _enablePerson;
  bool get enableRating => _enableRating;
  bool get enableSetupTags => _enableSetupTags;
  bool get enableStrava => _enableStrava;
  bool get enableMap => _enableMap;
  bool get enableGarage => _enableGarage;

  // Temporary Settings
  bool get setupListOnlyChanges => _setupListOnlyChanges;
  bool get setupListBikeAdjustmentValues => _setupListBikeAdjustmentValues;
  bool get setupListPersonAdjustmentValues => _setupListPersonAdjustmentValues;
  bool get setupListRatingAdjustmentValues => _setupListRatingAdjustmentValues;
  bool get setupListSortAscending => _setupListSortAscending;

  set showOnboarding(bool newShowOnboarding) {
    if (_showOnboarding == newShowOnboarding) return;
    _showOnboarding = newShowOnboarding;
    notifyListeners();
    saveAppSettings();
  }

  set themeMode(ThemeMode newThemeMode) {
    if (_themeMode == newThemeMode) return;
    _themeMode = newThemeMode;
    notifyListeners();
    saveAppSettings();
  }

  set dateFormat(String newDateFormat) {
    if (newDateFormat == _dateFormat) return;
    _dateFormat = newDateFormat;
    notifyListeners();
    saveAppSettings();
  }

  set timeFormat(String newTimeFormat) {
    if (newTimeFormat == _timeFormat) return;
    _timeFormat = newTimeFormat;
    notifyListeners();
    saveAppSettings();
  }

  set temperatureUnit(String newUnit) {
    if (newUnit == _temperatureUnit) return;
    _temperatureUnit = newUnit;
    notifyListeners();
    saveAppSettings();
  }

  set windSpeedUnit(String newUnit) {
    if (newUnit == _windSpeedUnit) return;
    _windSpeedUnit = newUnit;
    notifyListeners();
    saveAppSettings();
  }

  set altitudeUnit(String newUnit) {
    if (newUnit == _altitudeUnit) return;
    _altitudeUnit = newUnit;
    notifyListeners();
    saveAppSettings();
  }

  set precipitationUnit(String newUnit) {
    if (newUnit == _precipitationUnit) return;
    _precipitationUnit = newUnit;
    notifyListeners();
    saveAppSettings();
  }

  set enableGoogleDrive(bool newValue) {
    if (newValue == _enableGoogleDrive) return;
    _enableGoogleDrive = newValue;
    notifyListeners();
    saveAppSettings();
  }

  set enableTextAdjustment(bool newValue) {
    if (newValue == _enableTextAdjustment) return;
    _enableTextAdjustment = newValue;
    notifyListeners();
    saveAppSettings();
  }

  set enablePerson(bool newValue) {
    if (newValue == _enablePerson) return;
    _enablePerson = newValue;
    notifyListeners();
    saveAppSettings();
  }

  set enableRating(bool newValue) {
    if (newValue == _enableRating) return;
    _enableRating = newValue;
    notifyListeners();
    saveAppSettings();
  }

  set enableSetupTags(bool newValue) {
    if (newValue == _enableSetupTags) return;
    _enableSetupTags = newValue;
    notifyListeners();
    saveAppSettings();
  }

  set enableStrava(bool newValue) {
    if (newValue == _enableStrava) return;
    _enableStrava = newValue;
    notifyListeners();
    saveAppSettings();
  }

  set enableGarage(bool newValue) {
    if (newValue == _enableGarage) return;
    _enableGarage = newValue;
    notifyListeners();
    saveAppSettings();
  }

  set setupListOnlyChanges(bool newValue) {
    if (newValue == setupListOnlyChanges) return;
    _setupListOnlyChanges = newValue;
    notifyListeners();
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

  set setupListRatingAdjustmentValues(bool newValue) {
    if (newValue == _setupListRatingAdjustmentValues) return;
    _setupListRatingAdjustmentValues = newValue;
    notifyListeners();
  }

  set setupListSortAscending(bool newValue) {
    if (newValue == _setupListSortAscending) return;
    _setupListSortAscending = newValue;
    notifyListeners();
  }

  Future<void> loadAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString("app_settings") ?? "{}";
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _showOnboarding = json['showOnboarding'] ?? _showOnboarding;
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == json['themeMode'],
        orElse: () => _themeMode,
      );
      _dateFormat = json['dateFormat'] ?? _dateFormat;
      _timeFormat = json['timeFormat'] ?? _timeFormat;
      _temperatureUnit = json['temperatureUnit'] ?? _temperatureUnit;
      _windSpeedUnit = json['windSpeedUnit'] ?? _windSpeedUnit;
      _altitudeUnit = json['altitudeUnit'] ?? _altitudeUnit;
      _precipitationUnit = json['precipitationUnit'] ?? _precipitationUnit;
      _enableGoogleDrive = json['enableGoogleDrive'] ?? _enableGoogleDrive;
      _enableTextAdjustment = json['enableTextAdjustment'] ?? _enableTextAdjustment;
      _enablePerson = json['enablePerson'] ?? _enablePerson;
      _enableRating = json['enableRating'] ?? _enableRating;
      _enableSetupTags = json['enableSetupTags'] ?? _enableSetupTags;
      _enableStrava = json['enableStrava'] ?? _enableStrava;
      _enableGarage = json['enableGarage'] ?? _enableGarage;
    } catch (e, st) {
      debugPrint("ERROR loading App Settings: $e\n$st");
    }
  }

  Future<void> saveAppSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonData = jsonEncode({
      'showOnboarding': _showOnboarding,
      'themeMode': _themeMode.toString(),
      'dateFormat': _dateFormat,
      'timeFormat': _timeFormat,
      'temperatureUnit': _temperatureUnit,
      'windSpeedUnit': _windSpeedUnit,
      'altitudeUnit': _altitudeUnit,
      'precipitationUnit': _precipitationUnit,
      'enableGoogleDrive': _enableGoogleDrive,
      'enableTextAdjustment': _enableTextAdjustment,
      'enablePerson': _enablePerson,
      'enableRating': _enableRating,
      'enableSetupTags': _enableSetupTags,
      'enableStrava': _enableStrava,
      'enableGarage': _enableGarage,
    });
    await prefs.setString('app_settings', jsonData);
  }
}
