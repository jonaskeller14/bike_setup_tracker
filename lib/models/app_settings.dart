import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _dateFormat = 'yyyy-MM-dd';
  String _timeFormat = 'HH:mm';

  ThemeMode get themeMode => _themeMode;
  String get dateFormat => _dateFormat;
  String get timeFormat => _timeFormat;

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

  Future<void> loadAppSettings() async {
    String jsonString = "{}";
    try {
      final prefs = await SharedPreferences.getInstance();
      jsonString = prefs.getString("app_settings") ?? "{}";
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == json['themeMode'],
        orElse: () => _themeMode,
      );
      _dateFormat = json['dateFormat'] ?? _dateFormat;
      _timeFormat = json['timeFormat'] ?? _timeFormat;
    } catch (e, st) {
      debugPrint("ERROR loading App Settings: $e\n$st");
    }
  }

  Future<void> saveAppSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonData = jsonEncode({
      'themeMode': _themeMode.toString(),
      'dateFormat': _dateFormat,
      'timeFormat': _timeFormat,
    });
    await prefs.setString('app_settings', jsonData);
  }
}
