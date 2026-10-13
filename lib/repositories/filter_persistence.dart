import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import 'filter_controller.dart';

/// Keeps the filter criteria on this device across app starts. They are view
/// state, so backups and sync leave them out.
class FilterPersistence {
  static Future<Map<String, Object?>?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppSettings.kFiltersKey);
      return raw == null ? null : jsonDecode(raw) as Map<String, Object?>;
    } catch (e) {
      debugPrint("ERROR loading filters: $e");
      return null;
    }
  }

  static Future<void> save(FilterController filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppSettings.kFiltersKey, jsonEncode(filters.toJson()));
    } catch (e) {
      debugPrint("ERROR saving filters: $e");
    }
  }
}
