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
import '../models/app_data.dart';

class FileImport {
  static Future<List<LocalBackup>> getBackups(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    final errorContainerColor = Theme.of(context).colorScheme.errorContainer;
    final onErrorContainerColor = Theme.of(context).colorScheme.onErrorContainer;

    final List<LocalBackup> backups = [];
    try {
      final dir = await getApplicationDocumentsDirectory();  //catch MissingPlatformDirectoryException
      final backupDir = Directory('${dir.path}/backup');
      if (!await backupDir.exists()) return backups;
      
      await for (final entity in backupDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          backups.add(LocalBackup(createdAt: stat.modified, filepath: entity.path));
        }
      }
      return backups;
    } catch (e, st) {
      debugPrint("Getting local backups failed: $e\n$st");
      if (context.mounted) {
        scaffold.showSnackBar(SnackBar(
          persist: false,
          showCloseIcon: true,
          closeIconColor: onErrorContainerColor,
          content: Text("Getting local backups failed: $e", style: TextStyle(color: onErrorContainerColor)), 
          backgroundColor: errorContainerColor,
        ));
      }
      return backups;
    }
  }

  static Future<AppData?> readBackup({required BuildContext context, required String path}) async {
    final scaffold = ScaffoldMessenger.of(context);
    final errorContainerColor = Theme.of(context).colorScheme.errorContainer;
    final onErrorContainerColor = Theme.of(context).colorScheme.onErrorContainer;

    try {
      final file = File(path);
      if (!await file.exists()) throw Exception("File does not exist");

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      return AppData.addJson(data: AppData(), json: jsonData);
    } catch (e, st) {
      debugPrint("Reading backup failed: $e\n$st");
      if (context.mounted) {
        scaffold.showSnackBar(SnackBar(
          persist: false,
          showCloseIcon: true,
          closeIconColor: onErrorContainerColor,
          content: Text("Reading backup failed: $e", style: TextStyle(color: onErrorContainerColor)), 
          backgroundColor: errorContainerColor,
        ));
      }
      return null;
    }
  }

  static Future<AppData?> readJsonFileData(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    final errorContainerColor = Theme.of(context).colorScheme.errorContainer;
    final onErrorContainerColor = Theme.of(context).colorScheme.onErrorContainer;

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
        scaffold.showSnackBar(SnackBar(
          persist: false,
          showCloseIcon: true,
          closeIconColor: onErrorContainerColor,
          content: Text("Cannot read file!", style: TextStyle(color: onErrorContainerColor)), 
          backgroundColor: errorContainerColor,
        ));
        return null;
      }

      final jsonString = utf8.decode(fileBytes);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      scaffold.showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true,
        duration: Duration(seconds: 2),
        content: Text("Imported ${picked.files.single.name} successfully")
      ));
      return AppData.addJson(data: AppData(), json: jsonData);
    } catch (e, st) {
      debugPrint("Import failed: $e\n$st");
      scaffold.showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true,
        closeIconColor: onErrorContainerColor,
        content: Text("Import failed: $e", style: TextStyle(color: onErrorContainerColor)), 
        backgroundColor: errorContainerColor,
      ));
      return null;
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

  static void overwrite({required AppData remoteData, required AppData localData}) {
    localData.persons
      ..clear()
      ..addAll(remoteData.persons);
    localData.ratings
      ..clear()
      ..addAll(remoteData.ratings);
    localData.bikes
      ..clear()
      ..addAll(remoteData.bikes);
    localData.setups
      ..clear()
      ..addAll(remoteData.setups);
    final sortedSetupEntries = localData.setups.entries.toList();
    sortedSetupEntries.sort((a, b) => a.value.datetime.compareTo(b.value.datetime));
    localData.setups.clear();
    localData.setups.addEntries(sortedSetupEntries);
    localData.components
      ..clear()
      ..addAll(remoteData.components);
    
    cleanupIsDeleted(data: localData);
    localData.resolveData();
  }

  static void merge({
    required AppData remoteData,
    required AppData localData,
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

      // final bool remoteIsOlder = remoteComponent.lastModified.isBefore(localComponent.lastModified);
      // if (remoteIsOlder) continue;

      // remote = local
      // continue;
    }
    cleanupIsDeleted(data: localData);
    localData.resolveData();
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

  static void determinePreviousSetups({required Iterable<Setup> setups}) {
    // Assumes setups is sorted
    Map<String, Setup> previousBikeSetups = {};
    Map<String, Setup> previousPersonSetups = {};

    for (final setup in setups.where((s) => !s.isDeleted)) {
      final bike = setup.bike;
      final previousBikeSetup = previousBikeSetups[bike];
      setup.previousBikeSetup = previousBikeSetup == null ? setup.previousBikeSetup = null : setup.previousBikeSetup = previousBikeSetup;
      previousBikeSetups[bike] = setup;

      final person = setup.person;
      if (person == null) {
        setup.previousPersonSetup = null;
        continue;
      }
      final previousPersonSetup = previousPersonSetups[person];
      setup.previousPersonSetup = previousPersonSetup == null ? setup.previousPersonSetup = null : setup.previousPersonSetup = previousPersonSetup;
      previousPersonSetups[person] = setup;
    }
  }

  static void updateSetupsAfter({required List<Setup> setups, required Setup setup}) {
    // Call after sorting setups!
    // Handles case: New Component, New Setup with new component with date in the past
    // --> Solves Bug: component references current setup with missing values for new component
    if (setup.isCurrent) return;
    final index = setups.indexOf(setup);
    if (index == -1) return;
    if (index == setups.length -1) return; // ==isCurrent
    final afterSetups = setups.sublist(index + 1);

    final afterBikeSetups = afterSetups.where((s) => s.bike == setup.bike);
    for (final adjustmentValue in setup.bikeAdjustmentValues.entries) {
      final adjustment = adjustmentValue.key;
      final value = adjustmentValue.value;
      for (final afterBikeSetup in afterBikeSetups) {
        if (afterBikeSetup.bikeAdjustmentValues.containsKey(adjustment)) continue;
        afterBikeSetup.bikeAdjustmentValues[adjustment] = value;
      }
    }

    final afterPersonSetups = afterSetups.where((s) => s.person != null && s.person == setup.person);
    for (final adjustmentValue in setup.personAdjustmentValues.entries) {
      final adjustment = adjustmentValue.key;
      final value = adjustmentValue.value;
      for (final afterPersonSetup in afterPersonSetups) {
        if (afterPersonSetup.personAdjustmentValues.containsKey(adjustment)) continue;
        afterPersonSetup.personAdjustmentValues[adjustment] = value;
      }
    }
  }

  static void cleanupIsDeleted({required AppData data}) {
    final thirtyDays = const Duration(days: 30);
    final deleteDateTime = DateTime.now().subtract(thirtyDays);

    data.persons.removeWhere((_, p) => p.isDeleted && p.lastModified.isBefore(deleteDateTime));
    data.ratings.removeWhere((_, r) => r.isDeleted && r.lastModified.isBefore(deleteDateTime));
    data.bikes.removeWhere((_, b) => b.isDeleted && b.lastModified.isBefore(deleteDateTime));
    data.components.removeWhere((_, c) => c.isDeleted && c.lastModified.isBefore(deleteDateTime));
    data.setups.removeWhere((_, s) => s.isDeleted && s.lastModified.isBefore(deleteDateTime));
  }
}