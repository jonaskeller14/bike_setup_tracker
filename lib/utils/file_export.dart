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
  static const Duration _backupStoreDuration = Duration(days: 30);
  static const Duration _backupFrequency = Duration(days: 1);
  static const String _backupSharedPreferencesInstance = "backup/lastBackup";
  
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
    final errorContainerColor = Theme.of(context).colorScheme.errorContainer;
    final onErrorContainerColor = Theme.of(context).colorScheme.onErrorContainer;

    _downloadJson(bikes, setups, components).then((result) {
        if (result == null || result.path == null) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              persist: false,
              showCloseIcon: true,
              closeIconColor: onErrorContainerColor,
              content: Text("Export failed", style: TextStyle(color: onErrorContainerColor)), 
              backgroundColor: errorContainerColor,
            ),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              persist: false,
              showCloseIcon: true,
              content: Text("Saved to: ${result.path}")
            ),
          );
        }
      }).catchError((e, st) {
        debugPrint('Export failed: $e\n$st');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            persist: false,
            showCloseIcon: true,
            closeIconColor: onErrorContainerColor,
            content: Text('Export failed: $e', style: TextStyle(color: onErrorContainerColor)), 
            backgroundColor: errorContainerColor,
          ),
        );
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

  static Future<File?> saveBackup({
    BuildContext? context,
    required Map<String, Bike> bikes,
    required List<Setup> setups,
    required List<Component> components,
    bool force = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? lastBackupStr = prefs.getString(_backupSharedPreferencesInstance);
      final DateTime? lastBackup = DateTime.tryParse(lastBackupStr ?? "");

      final now = DateTime.now();

      if (!force && lastBackup != null && lastBackup.add(_backupFrequency).isAfter(now)) {
        // debugPrint('Backup already exists.');
        return null;
      }

      final exportData = {
        'bikes': bikes.values.map((b) => b.toJson()).toList(),
        'setups': setups.map((s) => s.toJson()).toList(),
        'components': components.map((c) => c.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final dir = await getApplicationDocumentsDirectory();  //catch MissingPlatformDirectoryException
      final backupDir = Directory('${dir.path}/backup');
      if (!await backupDir.exists()) await backupDir.create(recursive: true);

      final timestamp =
          '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

      final file = File('${backupDir.path}/${timestamp}_backup.json');

      await file.writeAsString(jsonString);
      await prefs.setString(_backupSharedPreferencesInstance, now.toIso8601String());

      if (context != null && context.mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            persist: false,
            showCloseIcon: true,
            content: Text('Saved backup at ${file.path}')
          ),
        );
      }
      // debugPrint('Saved backup at ${file.path}');
      return file;
    } catch (e, st) {
      if (context != null && context.mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final errorContainerColor = Theme.of(context).colorScheme.errorContainer;
        final onErrorContainerColor = Theme.of(context).colorScheme.onErrorContainer;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            persist: false,
            showCloseIcon: true,
            closeIconColor: onErrorContainerColor,
            content: Text('Error saving backup: $e', style: TextStyle(color: onErrorContainerColor)), 
            backgroundColor: errorContainerColor,
          ),
        );
      }
      debugPrint('Error saving backup: $e\n$st');
      return null;
    }
  }

  static Future<void> deleteOldBackups() async {
    try {
      final dir = await getApplicationDocumentsDirectory();  //catch MissingPlatformDirectoryException
      final backupDir = Directory('${dir.path}/backup');
      if (!await backupDir.exists()) return;

      final cutoffDateTime = DateTime.now().subtract(_backupStoreDuration);
      await for (final fileEntity in backupDir.list()) {
        if (fileEntity is File) {
          try {
            final stat = await fileEntity.stat();
            if (stat.modified.isBefore(cutoffDateTime)) { //TODO read date from filename
              await fileEntity.delete();
            }
          } catch (e) {
            debugPrint('Failed to delete backup file ${fileEntity.path}: $e');
          }
        }
      }
      // debugPrint('Successfully deleting backups');
    } catch (e, st) {
      debugPrint('Error deleting backups: $e\n$st');
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
    final errorContainerColor = Theme.of(context).colorScheme.errorContainer;
    final onErrorContainerColor = Theme.of(context).colorScheme.onErrorContainer;

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
        SnackBar(
          persist: false,
          showCloseIcon: true,
          closeIconColor: onErrorContainerColor,
          content: Text('Error sharing file: $e'),
          backgroundColor: errorContainerColor,
        ),
      );
    }
  }
}