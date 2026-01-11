import 'dart:convert';
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
  bool _enableGoogleDrive = false;
  bool _enableTextAdjustment = false;

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

  void setShowOnboarding(bool newShowOnboarding) {
    if (_showOnboarding == newShowOnboarding) return;
    _showOnboarding = newShowOnboarding;
    notifyListeners();
    saveAppSettings();
  }

  void setThemeMode(ThemeMode newThemeMode) {
    if (_themeMode == newThemeMode) return; 
    _themeMode = newThemeMode;
    notifyListeners();
    saveAppSettings();
  }

  void setDateFormat(String newDateFormat) {
    if (newDateFormat == _dateFormat) return;
    _dateFormat = newDateFormat;
    notifyListeners();
    saveAppSettings();
  }

  void setTimeFormat(String newTimeFormat) {
    if (newTimeFormat == _timeFormat) return;
    _timeFormat = newTimeFormat;
    notifyListeners();
    saveAppSettings();
  }
  
  void setTemperatureUnit(String newUnit) {
    if (newUnit == _temperatureUnit) return;
    _temperatureUnit = newUnit;
    notifyListeners();
    saveAppSettings();
  }

  void setWindSpeedUnit(String newUnit) {
    if (newUnit == _windSpeedUnit) return;
    _windSpeedUnit = newUnit;
    notifyListeners();
    saveAppSettings();
  }

  void setAltitudeUnit(String newUnit) {
    if (newUnit == _altitudeUnit) return;
    _altitudeUnit = newUnit;
    notifyListeners();
    saveAppSettings();
  }

  void setPrecipitationUnit(String newUnit) {
    if (newUnit == _precipitationUnit) return;
    _precipitationUnit = newUnit;
    notifyListeners();
    saveAppSettings();
  }

  void setEnableGoogleDrive(bool newValue) {
    if (newValue == _enableGoogleDrive) return;
    _enableGoogleDrive = newValue;
    notifyListeners();
    saveAppSettings();
  }

  void setEnableTextAdjustment(bool newValue) {
    if (newValue == _enableTextAdjustment) return;
    _enableTextAdjustment = newValue;
    notifyListeners();
    saveAppSettings();
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
    });
    await prefs.setString('app_settings', jsonData);
  }
}
