import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'adjustment.dart';
import 'setting.dart';
import 'bike.dart';

enum ComponentType {
  frame,
  fork,
  shock,
  brake,
  wheel,
  tire,
  drivetrain,
  stem,
  handlebar,
  saddle,
  pedal,
  motor,
  other,
}

class Component {
  final String id;
  final String name;
  final ComponentType componentType; 
  final List<Adjustment> adjustments;
  final Bike bike;
  Setting? currentSetting;

  Component({
    String? id,
    required this.name,
    required this.bike,
    required this.componentType,
    this.currentSetting,
    List<Adjustment>? adjustments,
  }) : adjustments = adjustments ?? [],
       id = id ?? const Uuid().v4();
    
  Component deepCopy() {
    return Component(
      name: name,
      bike: bike,
      componentType: componentType,
      currentSetting: currentSetting,
      adjustments: adjustments.map((a) => a.deepCopy()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'componentType': componentType.toString(),
    'bike': bike.id,
    'adjustments': adjustments.map((a) => a.id).toList(),
    'currentSetting': currentSetting?.id,
  };

  factory Component.fromJson({
    required Map<String, dynamic> json,
    required List<Bike> bikes,
    required List<Adjustment> allAdjustments,
    required List<Setting> allSettings,
  }) {
    final bike = bikes.firstWhere(
      (b) => b.id == json["bike"]
    );

    final adjustmentIDs = (json["adjustments"] as List<dynamic>?)
      ?.map((e) => e.toString())
      .toList() ?? [];

    final List<Adjustment> adjustments = [];
    for (var adjustmentID in adjustmentIDs) {
      final adjustment = allAdjustments.firstWhere(
        (a) => a.id == adjustmentID,
        orElse: () => throw Exception('Adjustment with id $adjustmentID not found'),
      );
      adjustments.add(adjustment);
    }

    final settingID = json["currentSetting"];
    Setting? currentSetting;

    if (settingID != null) {
      currentSetting = allSettings.where((s) => s.id == settingID).firstOrNull;

      if (currentSetting == null) {
        debugPrint('⚠️ Warning: Setting with id $settingID not found.');
      }
    }

    return Component(
      id: json["id"],
      name: json['name'],
      componentType: ComponentType.values.firstWhere(
        (e) => e.toString() == json['componentType'],
        orElse: () => ComponentType.other,
      ),
      bike: bike,
      adjustments: adjustments,
      currentSetting: currentSetting,
    );
  }
}
