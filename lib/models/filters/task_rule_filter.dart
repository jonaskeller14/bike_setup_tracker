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

  TaskRuleFilter copyWith({Set<TaskPriority>? priorities, Set<String>? tags}) =>
      TaskRuleFilter(priorities: priorities ?? this.priorities, tags: tags ?? this.tags);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskRuleFilter && setEquals(priorities, other.priorities) && setEquals(tags, other.tags);

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(priorities), Object.hashAllUnordered(tags));
}
