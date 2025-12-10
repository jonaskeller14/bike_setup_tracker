import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/bike.dart';
import '../models/adjustment.dart';
import '../models/setup.dart';
import '../models/component.dart';
import 'data.dart';

class FileImport {
  static Future<Data?> readData(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    final errorContainerColor = Theme.of(context).colorScheme.errorContainer;
    final onErrorContainerColor = Theme.of(context).colorScheme.onErrorContainer;

    String jsonString = "{}";
    try {
      final prefs = await SharedPreferences.getInstance();
      jsonString = prefs.getString("data") ?? "{}";
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      final Data data = await parseJson(jsonData: jsonData);
      scaffold.showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true,
        content: Text("Loading data successfully")
      ));
      return data;
    } catch (e, st) {
      debugPrint("Loading data failed: $e\n$st");
      scaffold.showSnackBar(SnackBar(             
        persist: false,
        showCloseIcon: true,
        closeIconColor: onErrorContainerColor,
        content: Text("Loading data failed: $e", style: TextStyle(color: onErrorContainerColor)), 
        backgroundColor: errorContainerColor,
      ));

      if (!context.mounted) return null;
      await _saveErrorJson(context: context, jsonString: jsonString);
      
      return null;
    }
  }

  static Future<Data> parseJson({required Map<String, dynamic> jsonData}) async {
    final loadedBikes = (jsonData['bikes'] as List<dynamic>? ?? [])
        .map((a) => Bike.fromJson(a))
        .toList();

    final loadedComponents = (jsonData['components'] as List<dynamic>? ?? [])
        .map((c) => Component.fromJson(json: c))
        .toList();

    final List<Adjustment> loadedAllAdjustments = [];
    for (final component in loadedComponents) {
      loadedAllAdjustments.addAll(component.adjustments);
    }
    final loadedSetups = (jsonData['setups'] as List<dynamic>? ?? [])
        .map((s) => Setup.fromJson(json: s, allAdjustments: loadedAllAdjustments))
        .toList();
    
    return Data(
      bikes: <String, Bike>{for (var item in loadedBikes) item.id: item},
      setups: loadedSetups,
      components: loadedComponents,
    );
  }

  static Future<Data?> readJsonFileData(BuildContext context) async {
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

      // Step 2 — decode JSON
      final jsonString = utf8.decode(fileBytes);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Step 3 — validate structure
      if (!jsonData.containsKey('bikes') ||
          !jsonData.containsKey('setups') ||
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

  static Future<void> _saveErrorJson({required BuildContext context, required String jsonString}) async {
    final filename = '${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}_bike_setup_tracker_error.json'; 
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      
      await file.writeAsString(jsonString);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Debug file saved to: ${file.path}"),
          duration: const Duration(seconds: 5),
        ),
      );
      debugPrint("Saved error file: ${file.path}");
    } catch (saveError) {
      debugPrint("Could not save debug file: $saveError");
    }
  }

  static void overwrite({required Data remoteData, required Map<String, Bike> localBikes, required List<Setup> localSetups, required List<Component> localComponents}) {
    localBikes
      ..clear()
      ..addAll(remoteData.bikes);
    localSetups
      ..clear()
      ..addAll(remoteData.setups)
      ..sort((a, b) => a.datetime.compareTo(b.datetime));
    localComponents
      ..clear()
      ..addAll(remoteData.components);
    
    localSetups.sort((a, b) => a.datetime.compareTo(b.datetime));
    determineCurrentSetups(setups: localSetups, bikes: localBikes);
    determinePreviousSetups(setups: localSetups);
  }

  static void merge({required Data remoteData, required Map<String, Bike> localBikes, required List<Setup> localSetups, required List<Component> localComponents}) {
    // Last Write Wins (LWW) strategy
    for (final remoteBike in remoteData.bikes.values) {
      final localBike = localBikes[remoteBike.id];
      
      // Prio 1: Bike does not exist --> add newBike if it was not deleted on remote device yet
      if (localBike == null) {
        if (!remoteBike.isDeleted) localBikes[remoteBike.id] = remoteBike;
        continue;
      }
      
      // Prio 2: LastModified (remote edit, remote delete, remote restauration)
      final bool remoteIsNewer = remoteBike.lastModified.isAfter(localBike.lastModified);
      if (remoteIsNewer) {
        localBikes[remoteBike.id] = remoteBike;
        continue;
      }

      // final bool remoteIsOlder = remoteBike.lastModified.isBefore(localBike.lastModified);
      // if (remoteIsOlder) continue; // local wins

      // remote = local
      // continue;
    }

    for (final remoteSetup in remoteData.setups) {
      final localSetup = localSetups.firstWhereOrNull((setup) => setup.id == remoteSetup.id);

      if (localSetup == null) {
        if (!remoteSetup.isDeleted) localSetups.add(remoteSetup);
        continue;
      }

      final bool remoteIsNewer = remoteSetup.lastModified.isAfter(localSetup.lastModified);
      if (remoteIsNewer) {
        final int index = localSetups.indexOf(localSetup);
        localSetups[index] = remoteSetup;
        continue;
      }

      // final bool remoteIsOlder = remoteSetup.lastModified.isBefore(localSetup.lastModified);
      // if (remoteIsOlder) continue;

      // remote = local
      // continue;
    }

    for (final remoteComponent in remoteData.components) {
      final localComponent = localComponents.firstWhereOrNull((component) => component.id == remoteComponent.id);

      if (localComponent == null) {
        if (!remoteComponent.isDeleted) localComponents.add(remoteComponent);
        continue;
      }

      final bool remoteIsNewer = remoteComponent.lastModified.isAfter(localComponent.lastModified);
      if (remoteIsNewer) {
        final int index = localComponents.indexOf(localComponent);
        localComponents[index] = remoteComponent;
        continue;
      }

      // final bool remoteIsOlder = remoteComponent.lastModified.isBefore(localComponent.lastModified);
      // if (remoteIsOlder) continue;

      // remote = local
      // continue;
    }
    cleanupIsDeleted(bikes: localBikes, components: localComponents, setups: localSetups);
    localSetups.sort((a, b) => a.datetime.compareTo(b.datetime));
    determineCurrentSetups(setups: localSetups, bikes: localBikes);
    determinePreviousSetups(setups: localSetups);
    for (final remoteSetup in remoteData.setups) {
      FileImport.updateSetupsAfter(setups: localSetups, setup: remoteSetup);
    }
  }

  static void determineCurrentSetups({required List<Setup> setups, required Map<String, Bike> bikes}) {
    // Assumes setups is sorted
    for (final setup in setups) {
      setup.isCurrent = false;
    }
    final remainingBikes = Set.of(bikes.values.where((b) => !b.isDeleted).map((b) => b.id));
    for (final setup in setups.reversed.where((s) => !s.isDeleted)) {
      final bike = setup.bike;
      if (remainingBikes.contains(bike)) {
        setup.isCurrent = true;
        remainingBikes.remove(bike);
        if (remainingBikes.isEmpty) break;
      }
    }
  }

  static void determinePreviousSetups({required List<Setup> setups}) {
    // Assumes setups is sorted
    Map<String, Setup> previousSetups = {}; 
    for (final setup in setups.where((s) => !s.isDeleted)) {
      final bike = setup.bike;
      final previousSetup = previousSetups[bike];
      if (previousSetup == null) {
        setup.previousSetup = null;
      } else {
        setup.previousSetup = previousSetup;
      }
      previousSetups[bike] = setup;
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
    for (final adjustmentValue in setup.adjustmentValues.entries) {
      final adjustment = adjustmentValue.key;
      final value = adjustmentValue.value;
      for (final afterBikeSetup in afterBikeSetups) {
        if (afterBikeSetup.adjustmentValues.containsKey(adjustment)) continue;
        afterBikeSetup.adjustmentValues[adjustment] = value;
      }
    }
  }

  static void cleanupIsDeleted({required Map<String, Bike> bikes, required List<Component> components, required List<Setup> setups}) {
    final thirtyDays = const Duration(days: 30); 
    final deleteDateTime = DateTime.now().subtract(thirtyDays);
    
    for (final bike in List.from(bikes.values)) {
      if (bike.isDeleted && bike.lastModified.isBefore(deleteDateTime)) bikes.remove(bike.id);
    }

    for (final component in List.from(components)) {
      if ((component.isDeleted && component.lastModified.isBefore(deleteDateTime)) || !bikes.containsKey(component.bike)) components.remove(component);
    }

    for (final setup in List.from(setups)) {
      if ((setup.isDeleted && setup.lastModified.isBefore(deleteDateTime)) || !bikes.containsKey(setup.bike)) setups.remove(setup);
    }
  }
}