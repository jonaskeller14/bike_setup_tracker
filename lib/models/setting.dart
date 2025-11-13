import 'package:uuid/uuid.dart';
import "adjustment.dart";

class Setting {
  final String id;
  final String name;
  final DateTime datetime;
  final String? notes;
  Map<Adjustment, dynamic> adjustmentValues = {};

  Setting({
    String? id,
    required this.name,
    required this.datetime,
    this.notes,
    required this.adjustmentValues,
  }): id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'datetime': datetime.toIso8601String(),
    'notes': notes,
    'adjustmentValues': {
      for (var entry in adjustmentValues.entries)
        entry.key.id: entry.value,
    },
  };

  factory Setting.fromJson(Map<String, dynamic> json, List<Adjustment> allAdjustments) {
    final adjustmentIDValues = json['adjustmentValues'] as Map<String, dynamic>? ?? {};

    final Map<Adjustment, dynamic> adjustmentValues = {};
    for (var entry in adjustmentIDValues.entries) {
      final adjustment = allAdjustments.firstWhere(
        (a) => a.id == entry.key,
        orElse: () => throw Exception('Adjustment with id ${entry.key} not found'),
      );
      adjustmentValues[adjustment] = entry.value;
    }

    return Setting(
      id: json['id'],
      name: json['name'],
      datetime: DateTime.parse(json['datetime']),
      notes: json['notes'] != null ? json['notes'] as String : null,
      adjustmentValues: adjustmentValues,
    );
  }
}
