import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'component_stats.dart';
import 'task_entry.dart';
import 'task_threshold.dart';

enum TaskStatusType {
  upcoming,
  due,
  overdue,
  completed;

  Color getStatusColor() {
    return switch (this) {
      TaskStatusType.overdue => Colors.red,
      TaskStatusType.due => Colors.orange,
      TaskStatusType.upcoming => Colors.blue,
      TaskStatusType.completed => Colors.green,
    };
  }
}

class TaskStatus {
  final TaskStatusType type;
  final double progress;

  const TaskStatus({
    required this.type,
    required this.progress,
  });

  bool get isDue => type == TaskStatusType.due || type == TaskStatusType.overdue;
  bool get isOverdue => type == TaskStatusType.overdue;
}

class TaskRuleWithStatus {
  final TaskRule rule;
  final TaskStatus status;

  const TaskRuleWithStatus({
    required this.rule,
    required this.status,
  });
}

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
  final Set<String> tags;
  final String? componentId;
  final String? bikeId;
  final TaskThreshold? interval;
  final TaskThreshold? delay;
  final bool repeat;

  TaskRule({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.name,
    this.notes,
    this.priority = TaskPriority.medium,
    required this.tags,
    this.componentId,
    this.bikeId,
    this.interval,
    this.delay,
    this.repeat = true,
  }) : id = id ?? const Uuid().v4(),
      isDeleted = isDeleted ?? false,
      lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc() {
    // Distance/MovingTime thresholds require a component or bike.
    if (interval is DistanceThreshold || interval is MovingTimeThreshold || interval is ActivityCountThreshold) {
      assert(componentId != null || bikeId != null, 
        'Distance/MovingTime/ActivityCount thresholds require at least a componentId or a bikeId');
    }
    assert(componentId == null || bikeId == null, 'Cannot link to both a component and a bike');
  }

  TaskStatus calculateStatus({
    required ComponentStats currentStats,
    required DateTime now,
    TaskEntry? lastEntry,
    DateTime? componentInstallationDate,
  }) {
    if (!repeat && lastEntry != null) {
      return const TaskStatus(type: TaskStatusType.completed, progress: 1.0);
    }

    if (interval == null) {
      // Simple todo with no threshold
      if (lastEntry != null) {
        return const TaskStatus(type: TaskStatusType.completed, progress: 1.0);
      }
      return const TaskStatus(type: TaskStatusType.due, progress: 0.0);
    }

    final baselineStats = lastEntry?.snapshot ?? ComponentStats.zero();
    final baselineDate = lastEntry?.dateTimeUTC ?? componentInstallationDate ?? DateTime.fromMillisecondsSinceEpoch(0);

    final progress = interval!.getProgress(
      currentStats,
      baselineStats,
      now,
      baselineDate,
      delay: delay,
    );

    TaskStatusType type;
    if (progress >= 1.1) {
      type = TaskStatusType.overdue;
    } else if (progress >= 1.0) {
      type = TaskStatusType.due;
    } else {
      type = TaskStatusType.upcoming;
    }

    return TaskStatus(type: type, progress: progress);
  }
  
  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'notes': notes,
    'priority': priority.toString(),
    'tags': tags.toList(),
    'componentId': componentId,
    'bikeId': bikeId,
    'interval': interval?.toJson(),
    'delay': delay?.toJson(),
    'repeat': repeat,
  };

  factory TaskRule.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null || 1:
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
          tags: (json['tags'] as List?)?.map((item) => item as String).toSet() ?? <String>{},
          componentId: json["componentId"] as String?,
          bikeId: json["bikeId"] as String?,
          interval: json["interval"] != null 
              ? TaskThreshold.fromJson(json["interval"] as Map<String, dynamic>) 
              : null,
          delay: json["delay"] != null 
              ? TaskThreshold.fromJson(json["delay"] as Map<String, dynamic>) 
              : null,
          repeat: json["repeat"] as bool? ?? true,
        );
      default: throw Exception("Json Version $version of TaskRule incompatible.");
    }
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
        setEquals(tags, other.tags) &&
        componentId == other.componentId &&
        bikeId == other.bikeId &&
        interval == other.interval &&
        delay == other.delay &&
        repeat == other.repeat;
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
      tags,
      componentId,
      bikeId,
      interval,
      delay,
      repeat,
    );
  }

  TaskRule deepCopy() {
    return TaskRule(
      name: name, 
      notes: notes,
      priority: priority,
      tags: tags,
      componentId: componentId,
      bikeId: bikeId,
      interval: interval,
      delay: delay,
      repeat: repeat,
    );
  }

  TaskRule copyWith({
    Object? id = const _Sentinel(),
    Object? isDeleted = const _Sentinel(),
    Object? lastModified = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? priority = const _Sentinel(),
    Object? tags = const _Sentinel(),
    Object? componentId = const _Sentinel(),
    Object? bikeId = const _Sentinel(),
    Object? interval = const _Sentinel(),
    Object? delay = const _Sentinel(),
    Object? repeat = const _Sentinel(),
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
      tags: tags is _Sentinel
          ? this.tags
          : (tags as Set<String>),
      componentId: componentId is _Sentinel
          ? this.componentId
          : (componentId as String?),
      bikeId: bikeId is _Sentinel
          ? this.bikeId
          : (bikeId as String?),
      interval: interval is _Sentinel
          ? this.interval
          : (interval as TaskThreshold?),
      delay: delay is _Sentinel
          ? this.delay
          : (delay as TaskThreshold?),
      repeat: repeat is _Sentinel
          ? this.repeat
          : (repeat as bool),
    );
  }
}

class _Sentinel {
  const _Sentinel();
}
