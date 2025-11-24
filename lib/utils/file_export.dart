import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_save_directory/file_save_directory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bike.dart';
import '../models/setup.dart';
import '../models/component.dart';


class FileExport {
  static Future<void> saveData({required List<Bike> bikes, required List<Setup> setups, required List<Component> components}) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonData = jsonEncode({
      'bikes': bikes.map((b) => b.toJson()).toList(),
      'setups': setups.map((s) => s.toJson()).toList(),
      'components': components.map((c) => c.toJson()).toList(),
    });

    await prefs.setString('data', jsonData);
  }

  static Future<void> downloadJson({
    required BuildContext context,
    required List<Bike> bikes,
    required List<Setup> setups,
    required List<Component> components,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    _downloadJson(bikes, setups, components).then((result) {
        if (result == null || result.path == null) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text("Export failed"), backgroundColor: errorColor),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text("Saved to: ${result.path}")),
          );
        }
      }).catchError((e, st) {
        debugPrint('Export failed: $e\n$st');
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: errorColor,));
      });
    }

  static Future<FileSaveResult?> _downloadJson(
    List<Bike> bikes,
    List<Setup> setups,
    List<Component> components,
  ) async {
    try {
      final exportData = {
        'bikes': bikes.map((b) => b.toJson()).toList(),
        'setups': setups.map((s) => s.toJson()).toList(),
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