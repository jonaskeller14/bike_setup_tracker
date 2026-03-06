export 'app_database.dart' show TodoRule;
export 'database/tables/todo_rule.dart' show TodoPriority;

import 'app_database.dart';
import 'database/tables/todo_rule.dart';

extension TodoRuleJsonMapper on TodoRule {
  Map<String, dynamic> toJson() => {
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'notes': notes,
    'priority': priority.toString(),
  };
}

TodoRule todoRuleFromJson(Map<String, dynamic> json) {
  return TodoRule(
    id: json["id"] as String,
    isDeleted: json["isDeleted"] as bool,
    lastModified: DateTime.parse(json["lastModified"]).toUtc(),
    name: json["name"] as String,
    notes: json["notes"] as String?,
    priority: TodoPriority.values.firstWhere(
      (p) => p.toString() == json['priority'],
      orElse: () => TodoPriority.medium,
    ),
  );
}
