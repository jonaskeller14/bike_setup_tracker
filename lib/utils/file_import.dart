import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/bike.dart';
import '../models/setup.dart';
import '../utils/backup.dart';
import '../models/selected_data.dart';
import '../database/app_database.dart';
import '../services/data_export_service.dart';
import '../services/database_migration_service.dart';

class FileImport {
  static Future<GetLocalBackupsResult> getBackups() async {
    final List<LocalBackup> backups = [];
    try {
      final dir = await getApplicationDocumentsDirectory();  //catch MissingPlatformDirectoryException
      final backupDir = Directory('${dir.path}/backup');
      if (!await backupDir.exists()) return GetLocalBackupsResult.success(backups);
      
      await for (final entity in backupDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          backups.add(LocalBackup(createdAt: stat.modified, filepath: entity.path));
        }
      }
      return GetLocalBackupsResult.success(backups);
    } catch (e) {
      return GetLocalBackupsResult.failure("Getting local backups failed: $e");
    }
  }

  static Future<ReadLocalBackupResult> readBackup({required String path, required AppDatabase appDatabase}) async {
    try {
      final file = File(path);
      if (!await file.exists()) throw Exception("File does not exist");

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      return ReadLocalBackupResult.success(SelectedData.fromJson(jsonData));
    } catch (e, st) {
      debugPrint("Reading backup failed: $e\n$st");
      return ReadLocalBackupResult.failure("Reading backup failed: $e");
    }
  }

  static Future<ReadJsonFileResult> pickAndReadJsonFile({required AppDatabase appDatabase}) async {
    try {
      // Step 1 — pick a file
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (picked == null || picked.files.isEmpty) return ReadJsonFileResult.failure("No file was selected.");  // no error message

      Uint8List fileBytes;

      if (picked.files.single.bytes != null) {
        // Works in Web / Desktop
        fileBytes = picked.files.single.bytes!;
      } else if (picked.files.single.path != null) {
        // Works in Android / iOS
        fileBytes = await File(picked.files.single.path!).readAsBytes();
      } else {
        return ReadJsonFileResult.failure("Cannot open and read file!");
      }

      final jsonString = utf8.decode(fileBytes);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      return ReadJsonFileResult.success(SelectedData.fromJson(jsonData));
    } catch (e) {
      debugPrint("Import failed: $e");
      return ReadJsonFileResult.failure("Import failed: $e");
    }
  }

  static Future<void> saveErrorJson({required BuildContext context, required String jsonString}) async {
    final filename = '${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}_bike_setup_tracker_error.json'; 
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      
      await file.writeAsString(jsonString);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: false,
          showCloseIcon: true,
          content: Text("Debug file saved to: ${file.path}"),
          duration: const Duration(seconds: 5),
        ),
      );
      debugPrint("Saved error file: ${file.path}");
    } catch (saveError) {
      debugPrint("Could not save debug file: $saveError");
    }
  }

  static Future<void> overwrite({required SelectedData remoteData, required AppDatabase database}) async {
    cleanupIsDeleted(data: remoteData);
    await _importDataToDb(database, remoteData);
  }

  static Future<void> merge({
    required SelectedData remoteData,
    required AppDatabase database,
  }) async {
    // 1. Fetch current DB state into memory
    final localJson = await DataExportService.backupDatabaseToJson(database, includeStrava: true);
    final localData = SelectedData.fromJson(localJson);

    // 2. Perform merge in memory
    _mergeInternal(remoteData: remoteData, localData: localData);
    cleanupIsDeleted(data: localData);

    // 3. Write merged state back to DB
    await _importDataToDb(database, localData);
  }

  static Future<void> _importDataToDb(AppDatabase database, SelectedData dataToImport) async {
    await database.transaction(() async {
      await database.delete(database.setupAdjustmentValues).go();
      await database.delete(database.setups).go();
      await database.delete(database.stravaActivities).go();
      await database.delete(database.adjustments).go();
      await database.delete(database.installations).go();
      await database.delete(database.taskEntries).go();
      await database.delete(database.components).go();
      await database.delete(database.stravaGears).go();
      await database.delete(database.stravaAthletes).go();
      await database.delete(database.taskRules).go();
      await database.delete(database.ratings).go();
      await database.delete(database.bikes).go();
      await database.delete(database.persons).go();
    });

    final migrationService = DatabaseMigrationService(database);
    await migrationService.migrateFromSelectedData(dataToImport);
  }

  static void _mergeInternal({
    required SelectedData remoteData,
    required SelectedData localData,
  }) {
    //FIXME: Preserve Order (except setups?)
    // Last Write Wins (LWW) strategy
    for (final remotePerson in remoteData.persons.values) {
      final localPerson = localData.persons[remotePerson.id];
      
      // Prio 1: Person does not exist --> add newPerson if it was not deleted on remote device yet
      if (localPerson == null) {
        if (!remotePerson.isDeleted) localData.persons[remotePerson.id] = remotePerson;
        continue;
      }
      
      // Prio 2: LastModified (remote edit, remote delete, remote restauration)
      final bool remoteIsNewer = remotePerson.lastModified.isAfter(localPerson.lastModified);
      if (remoteIsNewer) {
        localData.persons[remotePerson.id] = remotePerson;
        continue;
      }

      // final bool remoteIsOlder = remotePerson.lastModified.isBefore(localPerson.lastModified);
      // if (remoteIsOlder) continue; // local wins

      // remote = local
      // continue;
    }

    for (final remoteRating in remoteData.ratings.values) {
      final localRating = localData.ratings[remoteRating.id];
      
      // Prio 1: Rating does not exist --> add newPerson if it was not deleted on remote device yet
      if (localRating == null) {
        if (!remoteRating.isDeleted) localData.ratings[remoteRating.id] = remoteRating;
        continue;
      }
      
      // Prio 2: LastModified (remote edit, remote delete, remote restauration)
      final bool remoteIsNewer = remoteRating.lastModified.isAfter(localRating.lastModified);
      if (remoteIsNewer) {
        localData.ratings[remoteRating.id] = remoteRating;
        continue;
      }

      // final bool remoteIsOlder = remoteRating.lastModified.isBefore(localRating.lastModified);
      // if (remoteIsOlder) continue; // local wins

      // remote = local
      // continue;
    }

    for (final remoteBike in remoteData.bikes.values) {
      final localBike = localData.bikes[remoteBike.id];
      
      // Prio 1: Bike does not exist --> add newBike if it was not deleted on remote device yet
      if (localBike == null) {
        if (!remoteBike.isDeleted) localData.bikes[remoteBike.id] = remoteBike;
        continue;
      }
      
      // Prio 2: LastModified (remote edit, remote delete, remote restauration)
      final bool remoteIsNewer = remoteBike.lastModified.isAfter(localBike.lastModified);
      if (remoteIsNewer) {
        localData.bikes[remoteBike.id] = remoteBike;
        continue;
      }

      // final bool remoteIsOlder = remoteBike.lastModified.isBefore(localBike.lastModified);
      // if (remoteIsOlder) continue; // local wins

      // remote = local
      // continue;
    }

    for (final remoteSetup in remoteData.setups.values) {
      final localSetup = localData.setups[remoteSetup.id];

      if (localSetup == null) {
        if (!remoteSetup.isDeleted) localData.setups[remoteSetup.id] = remoteSetup;
        continue;
      }

      final bool remoteIsNewer = remoteSetup.lastModified.isAfter(localSetup.lastModified);
      if (remoteIsNewer) {
        localData.setups[remoteSetup.id] = remoteSetup;
        continue;
      }

      // final bool remoteIsOlder = remoteSetup.lastModified.isBefore(localSetup.lastModified);
      // if (remoteIsOlder) continue;

      // remote = local
      // continue;
    }

    for (final remoteComponent in remoteData.components.values) {
      final localComponent = localData.components[remoteComponent.id];

      if (localComponent == null) {
        if (!remoteComponent.isDeleted) localData.components[remoteComponent.id] = remoteComponent;
        continue;
      }

      final bool remoteIsNewer = remoteComponent.lastModified.isAfter(localComponent.lastModified);
      if (remoteIsNewer) {
        localData.components[remoteComponent.id] = remoteComponent;
        continue;
      }
    }

    for (final remoteTaskRule in remoteData.taskRules.values) {
      final localTaskRule = localData.taskRules[remoteTaskRule.id];
      if (localTaskRule == null) {
        if (!remoteTaskRule.isDeleted) localData.taskRules[remoteTaskRule.id] = remoteTaskRule;
        continue;
      }
      if (remoteTaskRule.lastModified.isAfter(localTaskRule.lastModified)) {
        localData.taskRules[remoteTaskRule.id] = remoteTaskRule;
        continue;
      }
    }

    for (final remoteTaskEntry in remoteData.taskEntries.values) {
      final localTaskEntry = localData.taskEntries[remoteTaskEntry.id];
      if (localTaskEntry == null) {
        if (!remoteTaskEntry.isDeleted) localData.taskEntries[remoteTaskEntry.id] = remoteTaskEntry;
        continue;
      }
      if (remoteTaskEntry.lastModified.isAfter(localTaskEntry.lastModified)) {
        localData.taskEntries[remoteTaskEntry.id] = remoteTaskEntry;
        continue;
      }
    }
  }

  static void determineCurrentSetups({required List<Setup> setups, required Map<String, Bike> bikes}) {
    // Assumes setups is sorted
    for (final setup in setups) {
      setup.isCurrent = false;
    }
    final Set<String> remainingBikes = Set.of(bikes.values.where((b) => !b.isDeleted).map((b) => b.id));
    for (final setup in setups.reversed.where((s) => !s.isDeleted)) {
      final bike = setup.bike;
      if (remainingBikes.contains(bike)) {
        setup.isCurrent = true;
        remainingBikes.remove(bike);
        if (remainingBikes.isEmpty) break;
      }
    }
  }

  static void cleanupIsDeleted({required SelectedData data}) {
    final thirtyDays = const Duration(days: 30);
    final deleteDateTime = DateTime.now().toUtc().subtract(thirtyDays);

    data.persons.removeWhere((_, p) => p.isDeleted && p.lastModified.isBefore(deleteDateTime));
    data.ratings.removeWhere((_, r) => r.isDeleted && r.lastModified.isBefore(deleteDateTime));
    data.bikes.removeWhere((_, b) => b.isDeleted && b.lastModified.isBefore(deleteDateTime));
    data.components.removeWhere((_, c) => c.isDeleted && c.lastModified.isBefore(deleteDateTime));
    data.setups.removeWhere((_, s) => s.isDeleted && s.lastModified.isBefore(deleteDateTime));
    data.taskRules.removeWhere((_, tr) => tr.isDeleted && tr.lastModified.isBefore(deleteDateTime));
    data.taskEntries.removeWhere((_, te) => te.isDeleted && te.lastModified.isBefore(deleteDateTime));
  }
}

class GetLocalBackupsResult {
  final List<LocalBackup> backups;
  final String? errorMessage;
  final bool isError;

  GetLocalBackupsResult.success(this.backups) : errorMessage = null, isError = false;
  GetLocalBackupsResult.failure(this.errorMessage) : backups = [], isError = true;
}

class ReadLocalBackupResult {
  final SelectedData? appData;
  final String? errorMessage;
  final bool isError;

  ReadLocalBackupResult.success(this.appData) : errorMessage = null, isError = false;
  ReadLocalBackupResult.failure(this.errorMessage) : appData = null, isError = true;
}

class ReadJsonFileResult {
  final SelectedData? appData;
  final String? errorMessage;
  final bool isError;

  ReadJsonFileResult.success(this.appData) : errorMessage = null, isError = false;
  ReadJsonFileResult.failure(this.errorMessage) : appData = null, isError = true;
}
