import 'package:uuid/uuid.dart';

enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  critical('Critical');

  final String label;
  const TaskPriority(this.label);
}

class TaskRule {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String name;
  final String? notes;
  final TaskPriority priority;
  final String componentId;

  TaskRule({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.name,
    this.notes,
    this.priority = TaskPriority.medium,
    required this.componentId,
  }) : id = id ?? const Uuid().v4(),
      isDeleted = isDeleted ?? false,
      lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc();
  
  Map<String, dynamic> toJson() => {
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'notes': notes,
    'priority': priority.toString(),
    'componentId': componentId,
  };

  factory TaskRule.fromJson(Map<String, dynamic> json) {
    return TaskRule(
      id: json["id"] as String,
      isDeleted: json["isDeleted"] as bool,
      lastModified: DateTime.parse(json["lastModified"]),
      name: json["name"] as String,
      notes: json["notes"] as String?,
      priority: TaskPriority.values.firstWhere(
        (p) => p.toString() == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      componentId: json["componentId"] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskRule &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        isDeleted == other.isDeleted &&
        lastModified == other.lastModified &&
        name == other.name &&
        notes == other.notes &&
        priority == other.priority &&
        componentId == other.componentId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      isDeleted,
      lastModified,
      name,
      notes,
      priority,
      componentId,
    );
  }

  TaskRule copyWith({
    Object? id = const _Sentinel(),
    Object? isDeleted = const _Sentinel(),
    Object? lastModified = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? priority = const _Sentinel(),
    Object? componentId = const _Sentinel(),
  }) {
    return TaskRule(
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
      priority: priority is _Sentinel 
          ? this.priority 
          : (priority as TaskPriority),
      componentId: componentId is _Sentinel
          ? this.componentId
          : (componentId as String),
    );
  }
}

class _Sentinel {
  const _Sentinel();
}
