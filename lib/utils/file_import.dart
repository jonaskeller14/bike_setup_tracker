import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../l10n/l10n.dart';
import '../models/import_preview.dart';
import '../models/selected_data.dart';
import '../models/service_error.dart';
import '../models/syncable.dart';
import '../services/attachment_storage_service.dart';
import '../services/component_hierarchy_resolver.dart';
import '../services/data_export_service.dart';
import '../services/database_migration_service.dart';
import '../services/trash_cleanup_service.dart';
import '../widgets/app_snackbar.dart';
import 'backup.dart';

class FileImport {
  static Future<DataResult<List<LocalBackup>>> getBackups() async {
    final List<LocalBackup> backups = [];
    try {
      final dir = await getApplicationDocumentsDirectory();  //catch MissingPlatformDirectoryException
      final backupDir = Directory('${dir.path}/backup');
      if (!await backupDir.exists()) return DataSuccess(backups);
      
      await for (final entity in backupDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          backups.add(LocalBackup(createdAt: stat.modified, filepath: entity.path));
        }
      }
      return DataSuccess(backups);
    } catch (e) {
      return DataFailure(DataError(DataErrorKind.getLocalBackups, e.toString()));
    }
  }

  static Future<DataResult<SelectedData>> readBackup({required String path, required AppDatabase appDatabase}) async {
    try {
      final file = File(path);
      if (!await file.exists()) throw Exception("File does not exist");

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      return DataSuccess(SelectedData.fromJson(jsonData));
    } catch (e, st) {
      debugPrint("Reading backup failed: $e\n$st");
      return DataFailure(DataError(DataErrorKind.readLocalBackup, e.toString()));
    }
  }

  static Future<DataResult<SelectedData>> pickAndReadJsonFile({required AppDatabase appDatabase, VoidCallback? onPicked}) async {
    try {
      // Step 1 — pick a file
      final pickedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (pickedFile == null) return const DataFailure(DataError(DataErrorKind.noFileSelected));
      onPicked?.call();

      final fileBytes = await pickedFile.readAsBytes();

      final jsonString = utf8.decode(fileBytes);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      return DataSuccess(SelectedData.fromJson(jsonData));
    } catch (e) {
      debugPrint("Import failed: $e");
      return DataFailure(DataError(DataErrorKind.importFile, e.toString()));
    }
  }

  static Future<void> saveErrorJson({required BuildContext context, required String jsonString}) async {
    final filename = '${DateFormat('yyyyMMdd_HHmm', 'en_US').format(DateTime.now())}_bike_setup_tracker_error.json'; 
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      
      await file.writeAsString(jsonString);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showAppSnackBar(
        AppSnackBar.success(context, context.l10n.debugFileSaved(file.path)),
      );
      debugPrint("Saved error file: ${file.path}");
    } catch (saveError) {
      debugPrint("Could not save debug file: $saveError");
    }
  }

  /// The data on this device, in the in-memory form the import works on.
  static Future<SelectedData> loadLocalData(AppDatabase database) async =>
      SelectedData.fromJson(await DataExportService.backupDatabaseToJson(database));

  /// What importing [remoteData] with [method] would change in [localData]. Writes nothing.
  static ImportPreview preview({
    required SelectedData remoteData,
    required SelectedData localData,
    required ImportMethod method,
  }) {
    final after = _shallowCopy(localData);
    _apply(remoteData: remoteData, localData: after, method: method);
    return ImportPreview.diff(remote: remoteData, before: localData, after: after);
  }

  /// Overwrites by id and moves every other local item to the trash: as
  /// tombstones, the removals reach the other devices through cloud sync.
  static Future<void> replace({required SelectedData remoteData, required AppDatabase database}) =>
      _import(remoteData: remoteData, database: database, method: ImportMethod.replace);

  static Future<void> overwrite({required SelectedData remoteData, required AppDatabase database}) =>
      _import(remoteData: remoteData, database: database, method: ImportMethod.overwrite);

  static Future<void> merge({required SelectedData remoteData, required AppDatabase database}) =>
      _import(remoteData: remoteData, database: database, method: ImportMethod.merge);

  static Future<void> _import({
    required SelectedData remoteData,
    required AppDatabase database,
    required ImportMethod method,
  }) async {
    final localData = await loadLocalData(database);
    final purgedAttachments = _apply(remoteData: remoteData, localData: localData, method: method);
    await _importDataToDb(database, localData);

    // Delete attachments of purged setups, bikes, components and tasks (after the DB write succeeds).
    await AttachmentStorageService().deleteFiles(purgedAttachments);
  }

  /// Applies the import to [localData] in memory, then purges its old trash.
  /// Returns the attachment files of the purged items.
  static List<String> _apply({
    required SelectedData remoteData,
    required SelectedData localData,
    required ImportMethod method,
  }) {
    switch (method) {
      case ImportMethod.merge:
        _mergeInternal(remoteData: remoteData, localData: localData);
      case ImportMethod.overwrite:
        _overwriteInternal(remoteData: remoteData, localData: localData);
      case ImportMethod.replace:
        _overwriteInternal(remoteData: remoteData, localData: localData, trashRest: true);
    }
    return cleanupIsDeleted(data: localData);
  }

  /// New maps, same items: [_apply] only replaces map entries, and the items are immutable.
  static SelectedData _shallowCopy(SelectedData data) => SelectedData(
        persons: {...data.persons},
        bikes: {...data.bikes},
        components: {...data.components},
        setups: {...data.setups},
        taskRules: {...data.taskRules},
        taskEntries: {...data.taskEntries},
        feedbacks: {...data.feedbacks},
        testSessions: {...data.testSessions},
      );

  static Future<void> _importDataToDb(AppDatabase database, SelectedData dataToImport) async {
    // Reject an unusable component hierarchy before touching the database.
    // Merged data is checked, not just the incoming file — two individually
    // sound datasets can still merge into a cycle.
    ComponentHierarchyResolver(dataToImport.components).validate();

    // One transaction, so a failing insert rolls the wipe back instead of
    // leaving the database empty.
    await database.transaction(() async {
      await database.deleteAllUserData();

      final migrationService = DatabaseMigrationService(database);
      await migrationService.migrateFromSelectedData(dataToImport);
    });
  }

  static void _mergeInternal({
    required SelectedData remoteData,
    required SelectedData localData,
  }) {
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

    for (final remoteBike in remoteData.bikes.values) {
      final localBike = localData.bikes[remoteBike.id];
      
      if (localBike == null) {
        if (!remoteBike.isDeleted) localData.bikes[remoteBike.id] = remoteBike;
        continue;
      }
      
      final bool remoteIsNewer = remoteBike.lastModified.isAfter(localBike.lastModified);
      if (remoteIsNewer) {
        localData.bikes[remoteBike.id] = remoteBike;
        continue;
      }
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

    for (final remoteFeedback in remoteData.feedbacks.values) {
      final localFeedback = localData.feedbacks[remoteFeedback.id];
      if (localFeedback == null) {
        if (!remoteFeedback.isDeleted) localData.feedbacks[remoteFeedback.id] = remoteFeedback;
        continue;
      }
      if (remoteFeedback.lastModified.isAfter(localFeedback.lastModified)) {
        localData.feedbacks[remoteFeedback.id] = remoteFeedback;
        continue;
      }
    }

    for (final remoteSession in remoteData.testSessions.values) {
      final localSession = localData.testSessions[remoteSession.id];
      if (localSession == null) {
        if (!remoteSession.isDeleted) localData.testSessions[remoteSession.id] = remoteSession;
        continue;
      }
      if (remoteSession.lastModified.isAfter(localSession.lastModified)) {
        localData.testSessions[remoteSession.id] = remoteSession;
        continue;
      }
    }
  }

  /// Every item written gets the current time as its lastModified, so a
  /// restored older version counts as the newest edit. Otherwise last-writer-wins
  /// sync would bring back the newer version the cloud still has. Items whose
  /// content is unchanged are left as they are.
  static void _overwriteInternal({
    required SelectedData remoteData,
    required SelectedData localData,
    bool trashRest = false,
  }) {
    final now = DateTime.now().toUtc();
    _overwriteRecords(localData.persons, remoteData.persons, trashRest,
        (p, isDeleted) => p.copyWith(isDeleted: isDeleted, lastModified: now));
    _overwriteRecords(localData.bikes, remoteData.bikes, trashRest,
        (b, isDeleted) => b.copyWith(isDeleted: isDeleted, lastModified: now));
    _overwriteRecords(localData.components, remoteData.components, trashRest,
        (c, isDeleted) => c.copyWith(isDeleted: isDeleted, lastModified: now));
    _overwriteRecords(localData.setups, remoteData.setups, trashRest,
        (s, isDeleted) => s.copyWith(isDeleted: isDeleted, lastModified: now));
    _overwriteRecords(localData.taskRules, remoteData.taskRules, trashRest,
        (tr, isDeleted) => tr.copyWith(isDeleted: isDeleted, lastModified: now));
    _overwriteRecords(localData.taskEntries, remoteData.taskEntries, trashRest,
        (te, isDeleted) => te.copyWith(isDeleted: isDeleted, lastModified: now));
    _overwriteRecords(localData.feedbacks, remoteData.feedbacks, trashRest,
        (f, isDeleted) => f.copyWith(isDeleted: isDeleted, lastModified: now));
    _overwriteRecords(localData.testSessions, remoteData.testSessions, trashRest,
        (ts, isDeleted) => ts.copyWith(isDeleted: isDeleted, lastModified: now));
  }

  static void _overwriteRecords<T extends Syncable>(
    Map<String, T> local,
    Map<String, T> imported,
    bool trashRest,
    T Function(T record, bool isDeleted) stamp,
  ) {
    if (trashRest) {
      for (final record in local.values.toList()) {
        if (!record.isDeleted && !imported.containsKey(record.id)) local[record.id] = stamp(record, true);
      }
    }
    for (final record in imported.values) {
      final current = local[record.id];
      if (current != null && current.hasSameContent(record)) continue;
      local[record.id] = stamp(record, record.isDeleted);
    }
  }

  static List<String> cleanupIsDeleted({required SelectedData data}) {
    final deleteDateTime = DateTime.now().toUtc().subtract(TrashCleanupService.retention);

    data.persons.removeWhere((_, p) => p.isDeleted && p.lastModified.isBefore(deleteDateTime));

    final purgedAttachments = <String>[];
    data.bikes.removeWhere((_, b) {
      final purge = b.isDeleted && b.lastModified.isBefore(deleteDateTime);
      if (purge) purgedAttachments.addAll(b.attachments.map((a) => a.filename));
      return purge;
    });
    data.components.removeWhere((_, c) {
      final purge = c.isDeleted && c.lastModified.isBefore(deleteDateTime);
      if (purge) purgedAttachments.addAll(c.attachments.map((a) => a.filename));
      return purge;
    });
    data.setups.removeWhere((_, s) {
      final purge = s.isDeleted && s.lastModified.isBefore(deleteDateTime);
      if (purge) purgedAttachments.addAll(s.attachments.map((a) => a.filename));
      return purge;
    });

    data.taskRules.removeWhere((_, tr) {
      final purge = tr.isDeleted && tr.lastModified.isBefore(deleteDateTime);
      if (purge) purgedAttachments.addAll(tr.attachments.map((a) => a.filename));
      return purge;
    });
    // An entry outlives its purged rule until its own 30 days are up: the import
    // does not enforce foreign keys, so the entry and its files stay.
    data.taskEntries.removeWhere((_, te) {
      final purge = te.isDeleted && te.lastModified.isBefore(deleteDateTime);
      if (purge) purgedAttachments.addAll(te.attachments.map((a) => a.filename));
      return purge;
    });

    data.feedbacks.removeWhere((_, f) => f.isDeleted && f.lastModified.isBefore(deleteDateTime));
    data.testSessions.removeWhere((_, ts) => ts.isDeleted && ts.lastModified.isBefore(deleteDateTime));

    // Never delete a file a surviving setup, bike, component or task still references.
    final stillReferenced = {
      ...data.setups.values.expand((s) => s.attachments),
      ...data.bikes.values.expand((b) => b.attachments),
      ...data.components.values.expand((c) => c.attachments),
      ...data.taskRules.values.expand((tr) => tr.attachments),
      ...data.taskEntries.values.expand((te) => te.attachments),
    }.map((a) => a.filename).toSet();
    return purgedAttachments.where((f) => !stillReferenced.contains(f)).toList();
  }
}
