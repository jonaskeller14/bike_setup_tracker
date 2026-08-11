import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../models/app_settings.dart';
import '../models/selected_data.dart';
import '../services/data_export_service.dart';
import '../services/file_save_service.dart';
import '../services/image_storage_service.dart';
import '../services/share_service.dart';
import 'to_spreadsheet.dart';

class FileExport {
  static Future<void> saveJson({
    required BuildContext context,
    required AppDatabase database,
    SelectedData? selectedData,
    FileSaveService? fileSaveService,
  }) async {
    await _runSave(
      context: context,
      save: () => _saveJson(
        database: database,
        selectedData: selectedData,
        fileSaveService: fileSaveService ?? FileSaveService(),
      ),
    );
  }

  static Future<void> saveImageBundle({
    required BuildContext context,
    required AppDatabase database,
    SelectedData? selectedData,
    FileSaveService? fileSaveService,
  }) async {
    await _runSave(
      context: context,
      save: () => _saveImageBundle(
        database: database,
        selectedData: selectedData,
        fileSaveService: fileSaveService ?? FileSaveService(),
      ),
    );
  }
      
  static Future<FileSaveOutcome> _saveImageBundle({
    required AppDatabase database,
    SelectedData? selectedData,
    required FileSaveService fileSaveService,
  }) async {
    final file = await ImageStorageService().exportBundle(database, selectedData: selectedData);
    final bytes = await file.readAsBytes();
    return fileSaveService.saveFile(
      fileName: file.uri.pathSegments.last,
      bytes: bytes,
      extension: 'zip',
    );
  }
        
  static Future<void> exportLatestBackup(
    BuildContext context, {
    FileSaveService? fileSaveService,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorContainerColor = Theme.of(context).colorScheme.errorContainer;
    final onErrorContainerColor = Theme.of(context).colorScheme.onErrorContainer;

    await _runSave(
      context: context,
      save: () async {
        final dir = await getApplicationDocumentsDirectory();
        final backupDir = Directory('${dir.path}/backup');
        final files = await backupDir.exists()
            ? backupDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
            : <File>[];

        if (files.isEmpty) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              persist: false,
              showCloseIcon: true,
              closeIconColor: onErrorContainerColor,
              content: Text('No backup found yet.', style: TextStyle(color: onErrorContainerColor)),
              backgroundColor: errorContainerColor,
            ),
          );
          return FileSaveOutcome.cancelled;
        }

        files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        final latestBackup = files.first;
        final bytes = await latestBackup.readAsBytes();

        return (fileSaveService ?? FileSaveService()).saveFile(
          fileName: 'recovered_${latestBackup.uri.pathSegments.last}',
          bytes: bytes,
          extension: 'json',
        );
      },
    );
  }

  static Future<FileSaveOutcome> _saveJson({
    required AppDatabase database,
    SelectedData? selectedData,
    required FileSaveService fileSaveService,
  }) async {
    final exportData = await DataExportService.backupDatabaseToJson(database, subset: selectedData);
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    final bytes = utf8.encode(jsonString);

    final now = DateTime.now();
    final timestamp =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

    return fileSaveService.saveFile(
      fileName: '${timestamp}_export.json',
      bytes: bytes,
      extension: 'json',
    );
  }

  static Future<void> _runSave({
    required BuildContext context,
    required Future<FileSaveOutcome> Function() save,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorContainerColor = Theme.of(context).colorScheme.errorContainer;
    final onErrorContainerColor = Theme.of(context).colorScheme.onErrorContainer;

    try {
      final result = await save();
      if (result == FileSaveOutcome.saved) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            persist: false,
            showCloseIcon: true,
            content: Text('File saved'),
          ),
        );
      }
    } catch (e, st) {
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
    }
  }

  static Future<void> shareJson({
    required BuildContext context,
    required AppDatabase database,
    SelectedData? selectedData,
  }) async {
    try {
      final exportData = await DataExportService.backupDatabaseToJson(database, subset: selectedData);
      final String jsonString = jsonEncode(exportData);

      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/bike_setup_tracker.json';
      final File file = File(filePath);
      await file.writeAsString(jsonString);

      if (!context.mounted) return;
      await ShareService.shareFile(
        context: context,
        filePath: filePath,
        text: 'Here is my bike setup data!',
        errorMessage: 'Error sharing file',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: false,
          showCloseIcon: true,
          closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
          content: Text('Error preparing JSON: $e', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
          backgroundColor: Theme.of(context).colorScheme.errorContainer
        ),
      );
    }
  }

  static Future<void> shareXlsx({
    required BuildContext context,
    required SelectedData data,
  }) async {
    final settings = context.read<AppSettings>();

    try {
      final bytes = SpreadsheetExport.toExcel(data, settings);
      if (bytes == null) throw Exception("Failed to encode Excel file");

      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/bike_setup_tracker.xlsx';
      final File file = File(filePath);
      await file.writeAsBytes(bytes);

      if (!context.mounted) return;
      await ShareService.shareFile(
        context: context,
        filePath: filePath,
        text: 'Here is my bike setup data in Excel format!',
        errorMessage: 'Error sharing Excel file',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: false,
          showCloseIcon: true,
          closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
          content: Text('Error preparing Excel: $e', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
          backgroundColor: Theme.of(context).colorScheme.errorContainer
        ),
      );
    }
  }

  static Future<void> shareCsv({
    required BuildContext context,
    required SelectedData data,
  }) async {
    final settings = context.read<AppSettings>();

    try {
      final csvString = SpreadsheetExport.toCsv(data, settings);

      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/bike_setup_tracker.csv';
      final File file = File(filePath);
      await file.writeAsString(csvString);

      if (!context.mounted) return;
      await ShareService.shareFile(
        context: context,
        filePath: filePath,
        text: 'Here is my bike setup data in CSV format!',
        errorMessage: 'Error sharing CSV file',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: false,
          showCloseIcon: true,
          closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
          content: Text('Error preparing CSV: $e', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
          backgroundColor: Theme.of(context).colorScheme.errorContainer
        ),
      );
    }
  }

  static Future<void> shareText({required BuildContext context, required String content}) async {
    await ShareService.shareText(
      context: context,
      text: content,
      errorMessage: 'Error sharing text',
    );
  }
}
