import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_save_directory/file_save_directory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/bike.dart';
import '../models/setup.dart';
import '../models/component.dart';


class FileExport {
  static Future<void> saveData({required Map<String, Bike> bikes, required List<Setup> setups, required List<Component> components}) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonData = jsonEncode({
      'bikes': bikes.values.map((b) => b.toJson()).toList(),
      'setups': setups.map((s) => s.toJson()).toList(),
      'components': components.map((c) => c.toJson()).toList(),
    });

    await prefs.setString('data', jsonData);
  }

  static Future<void> downloadJson({
    required BuildContext context,
    required Map<String, Bike> bikes,
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
    Map<String, Bike> bikes,
    List<Setup> setups,
    List<Component> components,
  ) async {
    try {
      final exportData = {
        'bikes': bikes.values.map((b) => b.toJson()).toList(),
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

  static Future<void> shareJson({
    required BuildContext context,
    required Map<String, Bike> bikes,
    required List<Setup> setups,
    required List<Component> components,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final String jsonString = jsonEncode({
        'bikes': bikes.values.map((b) => b.toJson()).toList(),
        'setups': setups.map((s) => s.toJson()).toList(),
        'components': components.map((c) => c.toJson()).toList(),
      });

      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/bike_setup_data.json';
      final File file = File(filePath);
      await file.writeAsString(jsonString);

      await SharePlus.instance.share(
        ShareParams(
          subject: 'Bike Setup Backup',
          text: 'Here is my bike setup data!',
          files: [XFile(filePath)],
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
          downloadFallbackEnabled: true,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error sharing file: $e')),
      );
    }
  }
}