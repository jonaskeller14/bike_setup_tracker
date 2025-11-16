import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'adjustment.dart';
import 'setting.dart';

class Component {
  final String id;
  final String name;
  final List<Adjustment> adjustments;
  Setting? currentSetting;

  Component({
    String? id,
    required this.name,
    this.currentSetting,
    List<Adjustment>? adjustments,
  }) : adjustments = adjustments ?? [],
       id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'adjustments': adjustments.map((a) => a.id).toList(),
    'currentSetting': currentSetting?.id,
  };

  factory Component.fromJson(
    Map<String, dynamic> json,
    List<Adjustment> allAdjustments,
    List<Setting> allSettings,
  ) {
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
      adjustments: adjustments,
      currentSetting: currentSetting,
    );
  }
}
