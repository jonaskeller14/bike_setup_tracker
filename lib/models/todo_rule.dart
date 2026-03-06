import 'package:uuid/uuid.dart';

enum TodoPriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  critical('Critical');

  final String label;
  const TodoPriority(this.label);
}

class TodoRule {
  final String id;
  bool isDeleted;
  DateTime lastModified;
  final String name;
  final String? notes;
  final TodoPriority priority;

  TodoRule({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.name,
    this.notes,
    this.priority = TodoPriority.medium,
  })
    : id = id ?? const Uuid().v4(),
      isDeleted = isDeleted ?? false,
      lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc();
  
  Map<String, dynamic> toJson() => {
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'notes': notes,
    'priority': priority.toString(),
  };

  factory TodoRule.fromJson(Map<String, dynamic> json) {
    return TodoRule(
      id: json["id"] as String,
      isDeleted: json["isDeleted"] as bool,
      lastModified: DateTime.parse(json["lastModified"]),
      name: json["name"] as String,
      notes: json["notes"] as String?,
      priority: TodoPriority.values.firstWhere(
        (p) => p.toString() == json['priority'],
        orElse: () => TodoPriority.medium,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TodoRule &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        isDeleted == other.isDeleted &&
        lastModified == other.lastModified &&
        name == other.name &&
        notes == other.notes &&
        priority == other.priority;
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
    );
  }

  TodoRule copyWith({
    Object? id = const _Sentinel(),
    Object? isDeleted = const _Sentinel(),
    Object? lastModified = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? priority = const _Sentinel(),
  }) {
    return TodoRule(
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
          : (priority as TodoPriority),
    );
  }
}

class _Sentinel {
  const _Sentinel();
}
