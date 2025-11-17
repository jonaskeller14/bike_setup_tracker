import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_save_directory/file_save_directory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adjustment.dart';
import '../models/setting.dart';
import '../models/component.dart';


class FileExport {
  static Future<void> saveData({required List<Adjustment> adjustments, required List<Setting> settings, required List<Component> components}) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonData = jsonEncode({
      'adjustments': adjustments.map((a) => a.toJson()).toList(),
      'settings': settings.map((s) => s.toJson()).toList(),
      'components': components.map((c) => c.toJson()).toList(),
    });

    await prefs.setString('data', jsonData);
  }

  static Future<void> downloadJson({
    required BuildContext context,
    required List<Adjustment> adjustments,
    required List<Setting> settings,
    required List<Component> components,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    _downloadJson(adjustments, settings, components).then((result) {
        if (result == null || result.path == null) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text("Export failed")),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text("Saved to: ${result.path}")),
          );
        }
      }).catchError((e, st) {
        debugPrint('Export failed: $e\n$st');
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
      });
    }

  static Future<FileSaveResult?> _downloadJson(
    List<Adjustment> adjustments,
    List<Setting> settings,
    List<Component> components,
  ) async {
    try {
      final exportData = {
        'adjustments': adjustments.map((a) => a.toJson()).toList(),
        'settings': settings.map((s) => s.toJson()).toList(),
        'components': components.map((c) => c.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final bytes = utf8.encode(jsonString);

      final now = DateTime.now();
      final timestamp =
          '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

      final result = await FileSaveDirectory.instance.saveFile(
        fileName: '${timestamp}_export.json',
        fileBytes: bytes,
        location: SaveLocation.downloads,
        openAfterSave: false,
      );
      return result;
    } catch (e, st) {
      debugPrint('Error while exporting JSON: $e\n$st');
      return null;
    }
  }
}