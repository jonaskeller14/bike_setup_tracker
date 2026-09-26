import 'package:uuid/uuid.dart';

import '../component_stats.dart';
import 'task_association.dart';

class TaskEntry {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String name;
  final String? notes;
  final DateTime dateTimeUTC;
  final DateTime dateTimeLocal;
  final String taskRule;
  final TaskAssociation association;
  final ComponentStats? snapshot;

  TaskEntry({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.name,
    this.notes,
    required DateTime dateTimeUTC,
    required this.dateTimeLocal,
    required this.taskRule,
    this.association = const GeneralTaskAssociation(),
    this.snapshot,
  })
    : id = id ?? const Uuid().v4(),
      isDeleted = isDeleted ?? false,
      lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc(),
      dateTimeUTC = dateTimeUTC.toUtc();
  
  Map<String, dynamic> toJson() => {
    'version': 2,
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'notes': notes,
    'dateTimeUTC': dateTimeUTC.toUtc().toIso8601String(),
    'dateTimeLocal': dateTimeLocal.toIso8601String(),
    'taskRule': taskRule,
    'association': association.toJson(),
    'snapshot': snapshot?.toJson(),
  };

  factory TaskEntry.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"] as int?;
    final TaskAssociation association = switch (version) {
      null || 1 => TaskAssociation.fromIds(
          componentId: json['componentId'] as String?,
          bikeId: json['bikeId'] as String?,
        ),
      2 => TaskAssociation.fromJson(json['association'] as Map<String, dynamic>),
      _ => throw Exception("Json Version $version of TaskEntry incompatible."),
    };
    return TaskEntry(
        id: json['id'] as String?,
        isDeleted: json["isDeleted"] as bool?,
        lastModified: DateTime.parse(json["lastModified"] as String),
        name: json['name'] as String,
        notes: json['notes'] != null ? json['notes'] as String : null,
        dateTimeUTC: DateTime.parse(json['dateTimeUTC'] as String).toUtc(),
        dateTimeLocal: DateTime.parse(json['dateTimeLocal'] as String? ?? '').copyWith(isUtc: false),
        taskRule: json['taskRule'] as String,
        association: association,
        snapshot: json['snapshot'] != null 
            ? ComponentStats.fromJson(json['snapshot'] as Map<String, dynamic>) 
            : null,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskEntry &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        isDeleted == other.isDeleted &&
        lastModified == other.lastModified &&
        name == other.name &&
        notes == other.notes &&
        dateTimeUTC == other.dateTimeUTC &&
        dateTimeLocal == other.dateTimeLocal && 
        taskRule == other.taskRule &&
        association == other.association &&
        snapshot == other.snapshot;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      isDeleted,
      lastModified,
      name,
      notes,
      dateTimeUTC,
      dateTimeLocal,
      taskRule,
      association,
      snapshot,
    ]);
  }

  TaskEntry copyWith({
    Object? id = const _Sentinel(),
    Object? isDeleted= const _Sentinel(),
    Object? lastModified = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? dateTimeUTC = const _Sentinel(),
    Object? dateTimeLocal = const _Sentinel(),
    Object? taskRule = const _Sentinel(),
    Object? association = const _Sentinel(),
    Object? snapshot = const _Sentinel(),
  }) {
    return TaskEntry(
      id: id is _Sentinel
          ? this.id
          : (id as String),
      isDeleted: isDeleted is _Sentinel
          ? this.isDeleted
          : (isDeleted as bool),
      lastModified: lastModified is _Sentinel
          ? this.lastModified
          : (lastModified as DateTime),
      name: name is _Sentinel
          ? this.name
          : (name as String), 
      notes: notes is _Sentinel
          ? this.notes
          : (notes as String?),
      dateTimeUTC: dateTimeUTC is _Sentinel
          ? this.dateTimeUTC
          : (dateTimeUTC as DateTime), 
      dateTimeLocal: dateTimeLocal is _Sentinel
          ? this.dateTimeLocal
          : (dateTimeLocal as DateTime),
      taskRule: taskRule is _Sentinel
          ? this.taskRule
          : (taskRule as String), 
      association: association is _Sentinel
          ? this.association
          : (association as TaskAssociation),
      snapshot: snapshot is _Sentinel
          ? this.snapshot
          : (snapshot as ComponentStats?),
    );
  }
}

class _Sentinel {
  const _Sentinel();
}
