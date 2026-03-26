import 'package:uuid/uuid.dart';

class TaskEntry {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String name;
  final String? notes;
  final DateTime dateTimeUTC;
  final DateTime dateTimeLocal;
  final String taskRule;

  TaskEntry({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.name,
    this.notes,
    required DateTime dateTimeUTC,
    required this.dateTimeLocal,
    required this.taskRule,
  })
    : id = id ?? const Uuid().v4(),
      isDeleted = isDeleted ?? false,
      lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc(),
      dateTimeUTC = dateTimeUTC.toUtc();
  
  Map<String, dynamic> toJson() => {
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'notes': notes,
    'dateTimeUTC': dateTimeUTC.toUtc().toIso8601String(),
    'dateTimeLocal': dateTimeLocal.toLocal().toIso8601String(),
    'taskRule': taskRule,
  };

  factory TaskEntry.fromJson(Map<String, dynamic> json) {
    return TaskEntry(
        id: json['id'],
        isDeleted: json["isDeleted"],
        lastModified: DateTime.parse(json["lastModified"]),
        name: json['name'],
        notes: json['notes'] != null ? json['notes'] as String : null,
        dateTimeUTC: DateTime.parse(json['dateTimeUTC']).toUtc(),
        dateTimeLocal: DateTime.parse(json['dateTimeLocal'] ?? ''),
        taskRule: json['taskRule'],
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
        taskRule == other.taskRule;     
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
    );
  }
}

class _Sentinel {
  const _Sentinel();
}
