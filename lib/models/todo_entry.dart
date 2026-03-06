export 'app_database.dart' show TodoEntry;

import 'app_database.dart';

extension TodoEntryJsonMapper on TodoEntry {
  Map<String, dynamic> toJson() => {
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'notes': notes,
    'dateTimeUTC': dateTimeUTC.toUtc().toIso8601String(),
    'dateTimeLocal': dateTimeLocal.toLocal().toIso8601String(),
    'todoRule': todoRule,
  };
}

TodoEntry todoEntryFromJson(Map<String, dynamic> json) {
  return TodoEntry(
      id: json['id'],
      isDeleted: json["isDeleted"],
      lastModified: DateTime.parse(json["lastModified"]).toUtc(),
      name: json['name'],
      notes: json['notes'] != null ? json['notes'] as String : null,
      dateTimeUTC: DateTime.parse(json['dateTimeUTC']).toUtc(),
      dateTimeLocal: DateTime.parse(json['dateTimeLocal'] ?? ''),
      todoRule: json['todoRule'],
  );
}
