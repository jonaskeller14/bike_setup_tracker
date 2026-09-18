import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../theme.dart';
import 'task_association.dart';
import 'task_threshold/task_threshold.dart';

part 'task_priority.dart';
part 'task_status.dart';

class TaskRule {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String name;
  final String? notes;
  final TaskPriority priority;
  final Set<String> tags;
  final TaskAssociation association;
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
    this.association = const GeneralTaskAssociation(),
    this.interval,
    this.delay,
    this.repeat = true,
  }) : id = id ?? const Uuid().v4(),
      isDeleted = isDeleted ?? false,
      lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc() {
    assert(interval?.requiresActivityData != true || association is! GeneralTaskAssociation,
      'Ride-based intervals require a component or a bike to measure against');
  }

  Map<String, dynamic> toJson() => {
    'version': 2,
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'notes': notes,
    'priority': priority.toString(),
    'tags': tags.toList(),
    'association': association.toJson(),
    'interval': interval?.toJson(),
    'delay': delay?.toJson(),
    'repeat': repeat,
  };

  factory TaskRule.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"] as int?;
    switch (version) {
      case null || 1:
        return TaskRule(
          id: json["id"] as String,
          isDeleted: json["isDeleted"] as bool,
          lastModified: DateTime.parse(json["lastModified"] as String),
          name: json["name"] as String,
          notes: json["notes"] as String?,
          priority: TaskPriority.values.firstWhere(
            (p) => p.toString() == (json['priority'] as String?),
            orElse: () => TaskPriority.medium,
          ),
          tags: (json['tags'] as List?)?.map((item) => item as String).toSet() ?? <String>{},
          association: TaskAssociation.fromIds(
            componentId: json["componentId"] as String?,
            bikeId: json["bikeId"] as String?,
          ),
          interval: json["interval"] != null 
              ? TaskThreshold.fromJson(json["interval"] as Map<String, dynamic>) 
              : null,
          delay: json["delay"] != null 
              ? TaskThreshold.fromJson(json["delay"] as Map<String, dynamic>) 
              : null,
          repeat: json["repeat"] as bool? ?? true,
        );
      case 2:
        return TaskRule(
          id: json["id"] as String,
          isDeleted: json["isDeleted"] as bool,
          lastModified: DateTime.parse(json["lastModified"] as String),
          name: json["name"] as String,
          notes: json["notes"] as String?,
          priority: TaskPriority.values.firstWhere(
            (p) => p.toString() == (json['priority'] as String?),
            orElse: () => TaskPriority.medium,
          ),
          tags: (json['tags'] as List?)?.map((item) => item as String).toSet() ?? <String>{},
          association: TaskAssociation.fromJson(json["association"] as Map<String, dynamic>),
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
        association == other.association &&
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
      association,
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
      association: association,
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
    Object? association = const _Sentinel(),
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
      association: association is _Sentinel
          ? this.association
          : (association as TaskAssociation),
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
