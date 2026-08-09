import 'dart:convert';
import 'dart:io';
import 'package:file_save_directory/file_save_directory.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../database/app_database.dart';
import '../models/app_settings.dart';
import '../models/selected_data.dart';
import '../services/data_export_service.dart';
import '../services/image_storage_service.dart';
import '../services/share_service.dart';
import 'to_spreadsheet.dart';

class FileExport {
  static Future<void> downloadJson({
    required BuildContext context,
    required AppDatabase database,
    SelectedData? selectedData,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorContainerColor = Theme.of(context).colorScheme.errorContainer;
    final onErrorContainerColor = Theme.of(context).colorScheme.onErrorContainer;

    await _downloadJson(database: database, selectedData: selectedData)
        .then((result) {
      // On iOS, result might not contain a path even if successful
      final isSuccess = result != null && (Platform.isIOS || result.path != null);

      if (!isSuccess) {
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
            content: Text("Saved to: ${result.path ?? 'Unknown location'}")
          ),
        );
      }
    }).catchError((Object e, StackTrace st) {
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

  static Future<void> downloadImageBundle({
    required BuildContext context,
    required AppDatabase database,
    SelectedData? selectedData,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorContainerColor = Theme.of(context).colorScheme.errorContainer;
    final onErrorContainerColor = Theme.of(context).colorScheme.onErrorContainer;

    await _downloadImageBundle(database: database, selectedData: selectedData).then((result) {
      final isSuccess = result != null && (Platform.isIOS || result.path != null);
      if (!isSuccess) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            persist: false,
            showCloseIcon: true,
            closeIconColor: onErrorContainerColor,
            content: Text('Export failed', style: TextStyle(color: onErrorContainerColor)),
            backgroundColor: errorContainerColor,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            persist: false,
            showCloseIcon: true,
            content: Text('Saved to: ${result.path ?? 'Unknown location'}'),
          ),
        );
      }
    }).catchError((Object e, StackTrace st) {
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
      
  static Future<FileSaveResult?> _downloadImageBundle({
    required AppDatabase database,
    SelectedData? selectedData,
  }) async {
    try {
      final file = await ImageStorageService().exportBundle(database, selectedData: selectedData);
      final bytes = await file.readAsBytes();
      final result = await FileSaveDirectory.instance.saveFile(
        fileName: file.uri.pathSegments.last,
        fileBytes: bytes,
        location: SaveLocation.downloads,
        openAfterSave: false,
      );
      return result;
    } catch (e, st) {
      debugPrint('Error while exporting image bundle: $e\n$st');
      return null;
    }
  }
        
  static Future<void> exportLatestBackup(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorContainerColor = Theme.of(context).colorScheme.errorContainer;
    final onErrorContainerColor = Theme.of(context).colorScheme.onErrorContainer;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}/backup');

      if (!await backupDir.exists()) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            persist: false,
            showCloseIcon: true,
            closeIconColor: onErrorContainerColor,
            content: Text('No backup found yet.', style: TextStyle(color: onErrorContainerColor)),
            backgroundColor: errorContainerColor,
          ),
        );
        return;
      }

      final files = backupDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();

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
        return;
      }

      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      final latestBackup = files.first;

      final bytes = await latestBackup.readAsBytes();
      final originalFileName = latestBackup.uri.pathSegments.last;

      final result = await FileSaveDirectory.instance.saveFile(
        fileName: 'recovered_$originalFileName',
        fileBytes: bytes,
        location: SaveLocation.downloads,
        openAfterSave: false,
      );

      final isSuccess = Platform.isIOS || result.path != null;

      if (!isSuccess) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            persist: false,
            showCloseIcon: true,
            closeIconColor: onErrorContainerColor,
            content: Text('Export failed', style: TextStyle(color: onErrorContainerColor)), 
            backgroundColor: errorContainerColor,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            persist: false,
            showCloseIcon: true,
            content: Text('Saved to: ${result.path ?? "Unknown location"}'),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('Error exporting latest backup: $e\n$st');
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

  static Future<FileSaveResult?> _downloadJson({required AppDatabase database, SelectedData? selectedData}) async {
    try {
      final exportData = await DataExportService.backupDatabaseToJson(database, subset: selectedData);
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
