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
    'adjustment': adjustments.map((a) => a.id).toList(),
    'currentSetting': currentSetting?.id,
  };

  factory Component.fromJson(
    Map<String, dynamic> json,
    List<Adjustment> allAdjustments,
    List<Setting> allSettings,
  ) {
    final adjustmentIDs = json["adjustments"] as List<String>? ?? [];

    final List<Adjustment> adjustments = [];
    for (var adjustmentID in adjustmentIDs) {
      final adjustment = allAdjustments.firstWhere(
        (a) => a.id == adjustmentID,
        orElse: () => throw Exception('Adjustment with id $adjustmentID not found'),
      );
      adjustments.add(adjustment);
    }

    final settingID = json["currentSetting"];
    final Setting? currentSetting;
    if (settingID != null) {
      currentSetting = allSettings.firstWhere(
        (s) => s.id == settingID,
        orElse: () => throw Exception('Setting with id $settingID not found'),
      );
    } else {
      currentSetting = null;
    }

    return Component(
      id: json["id"],
      name: json['name'],
      adjustments: adjustments,
      currentSetting: currentSetting,
    );
  }
}
