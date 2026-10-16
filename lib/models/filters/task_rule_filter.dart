import 'package:flutter/foundation.dart';

import '../task/task_rule.dart';

/// The task rule criteria besides the bike scope, which is held separately.
@immutable
class TaskRuleFilter {
  final Set<TaskPriority> priorities;
  final Set<String> tags;

  TaskRuleFilter({Set<TaskPriority>? priorities, this.tags = const {}})
    : priorities = priorities ?? TaskPriority.values.toSet();

  bool get hasActivePriorities => !priorities.containsAll(TaskPriority.values);

  bool get isActive => hasActivePriorities || tags.isNotEmpty;

  bool matches(TaskRule rule) => priorities.contains(rule.priority) && rule.tags.containsAll(tags);

  Map<String, Object?> toJson() => {
    'priorities': [for (final priority in priorities) priority.name],
    'tags': tags.toList(),
  };

  /// Skips priority names this version does not know. Without stored
  /// priorities every priority is shown.
  factory TaskRuleFilter.fromJson(Map<String, Object?> json) {
    final names = (json['priorities'] as List<Object?>?)?.toSet();
    return TaskRuleFilter(
      priorities: names == null ? null : TaskPriority.values.where((p) => names.contains(p.name)).toSet(),
      tags: (json['tags'] as List<Object?>? ?? const []).whereType<String>().toSet(),
    );
  }

  TaskRuleFilter copyWith({Set<TaskPriority>? priorities, Set<String>? tags}) =>
      TaskRuleFilter(priorities: priorities ?? this.priorities, tags: tags ?? this.tags);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskRuleFilter && setEquals(priorities, other.priorities) && setEquals(tags, other.tags);

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(priorities), Object.hashAllUnordered(tags));
}
