import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bike.dart';
import '../models/adjustment.dart';
import '../models/setting.dart';
import '../models/component.dart';
import 'data.dart';

class FileImport {
  static Future<Data?> readData(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString("data") ?? "{}";
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      final Data data = await parseJson(jsonData: jsonData);
      scaffold.showSnackBar(SnackBar(content: Text("Loading data successfully")));
      return data;
    } catch (e, st) {
      debugPrint("Loading data failed: $e\n$st");
      scaffold.showSnackBar(SnackBar(content: Text("Loading data failed: $e"), backgroundColor: errorColor,));
      return null;
    }
  }

  static Future<Data> parseJson({required Map<String, dynamic> jsonData}) async {
    //parse bikes
    final loadedBikes = (jsonData['bikes'] as List)
        .map((a) => Bike.fromJson(a))
        .toList();
    
    // parse adjustments
    final loadedAdjustments = (jsonData['adjustments'] as List)
        .map((a) => Adjustment.fromJson(a))
        .toList();

    // parse settings (first pass)
    final loadedSettings = (jsonData['settings'] as List)
        .map((s) => Setting.fromJson(s, loadedAdjustments, loadedBikes))
        .toList();

    // fix previousSetting links (second pass)
    final settingsJsonList = jsonData['settings'] as List;
    for (int i = 0; i < loadedSettings.length; i++) {
      loadedSettings[i].previousSettingFromJson(
        settingsJsonList[i],
        loadedSettings,
      );
    }

    // parse components
    final loadedComponents = (jsonData['components'] as List)
        .map((c) => Component.fromJson(json: c, allAdjustments: loadedAdjustments, allSettings: loadedSettings, bikes: loadedBikes))
        .toList();
    
    return Data(
      bikes: loadedBikes,
      adjustments: loadedAdjustments,
      settings: loadedSettings,
      components: loadedComponents,
    );
  }

  static Future<Data?> readJsonFileData(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    try {
      // Step 1 — pick a file
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (picked == null || picked.files.isEmpty) return null;  // no error message

      Uint8List fileBytes;

      if (picked.files.single.bytes != null) {
        // Works in Web / Desktop
        fileBytes = picked.files.single.bytes!;
      } else if (picked.files.single.path != null) {
        // Works in Android / iOS
        fileBytes = await File(picked.files.single.path!).readAsBytes();
      } else {
        scaffold.showSnackBar(SnackBar(content: Text("Cannot read file!"), backgroundColor: errorColor));
        return null;
      }

      // Step 2 — decode JSON
      final jsonString = utf8.decode(fileBytes);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Step 3 — validate structure
      if (!jsonData.containsKey('bikes') ||
          !jsonData.containsKey('adjustments') ||
          !jsonData.containsKey('settings') ||
          !jsonData.containsKey('components')) {
        scaffold.showSnackBar(
          const SnackBar(content: Text("Invalid JSON format")),
        );
        return null;
      }

      final Data data = await parseJson(jsonData: jsonData);
      scaffold.showSnackBar(SnackBar(content: Text("Imported ${picked.files.single.name} successfully")));
      return data;
    } catch (e, st) {
      debugPrint("Import failed: $e\n$st");
      scaffold.showSnackBar(SnackBar(content: Text("Import failed: $e"), backgroundColor: errorColor,));
      return null;
    }
  }

  static Future<String?> showImportChoiceDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import JSON'),
          content: const Text(
            'Do you want to overwrite existing data or append (merge) the imported data?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'merge'),
              child: const Text('Merge'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'overwrite'),
              child: const Text('Overwrite'),
            ),
          ],
        );
      },
    );
  }
}