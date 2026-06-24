import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../services/data_export_service.dart';

class BackupService {
  Timer? _debounce;
  static const Duration _backupStoreDuration = Duration(days: 30);
  static const Duration _backupFrequency = Duration(days: 1);
  static const String _backupSharedPreferencesInstance = "backup/lastBackup";

  void update(AppDatabase database) {
    // If a new change comes in, cancel the previous pending save
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Only save if no changes have happened for 1 second
    _debounce = Timer(const Duration(seconds: 1), () async {
      await saveBackup(database: database);
    });
  }

  static Future<File?> saveBackup({
    BuildContext? context,
    required AppDatabase database,
    bool force = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? lastBackupStr = prefs.getString(_backupSharedPreferencesInstance);
      final DateTime? lastBackup = DateTime.tryParse(lastBackupStr ?? "");

      final now = DateTime.now().toUtc();

      if (!force && lastBackup != null && lastBackup.add(_backupFrequency).isAfter(now)) {
        // debugPrint('Backup already exists.');
        return null;
      }
      
      final exportData = await DataExportService.backupDatabaseToJson(database);
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
            content: Text('Saved backup at ${file.path}'),
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

      final cutoffDateTime = DateTime.now().toUtc().subtract(_backupStoreDuration);
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
}
