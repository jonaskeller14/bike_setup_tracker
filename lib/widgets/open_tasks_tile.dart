import 'package:flutter/material.dart';
import '../models/task_rule.dart';
import '../repositories/app_repository.dart';
import 'items/task_rule_list_card.dart';

class OpenTasksTile extends StatelessWidget {
  final List<TaskRuleWithStatus> openTasks;
  final AppRepository repository;

  const OpenTasksTile({
    super.key,
    required this.openTasks,
    required this.repository,
  });

  static TaskStatusType _getAggregatedStatus(List<TaskRule> rules, AppRepository repository) {
    if (rules.isEmpty) return TaskStatusType.completed;

    bool hasOverdue = false;
    bool hasDue = false;
    bool hasUpcoming = false;

    for (final rule in rules) {
      final status = repository.getTaskRuleStatus(rule);
      if (status.type == TaskStatusType.overdue) hasOverdue = true;
      if (status.type == TaskStatusType.due) hasDue = true;
      if (status.type == TaskStatusType.upcoming) hasUpcoming = true;
    }

    if (hasOverdue) return TaskStatusType.overdue;
    if (hasDue) return TaskStatusType.due;
    if (hasUpcoming) return TaskStatusType.upcoming;
    return TaskStatusType.completed;
  }

  @override
  Widget build(BuildContext context) {
    final count = openTasks.length;
    final aggregatedStatus = _getAggregatedStatus(
      openTasks.map((t) => t.rule).toList(),
      repository,
    );
    final isEnabled = count > 0;

    return ExpansionTile(
      enabled: isEnabled,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: Badge.count(
        count: count,
        isLabelVisible: count > 0,
        backgroundColor: aggregatedStatus.getStatusColor(),
        child: const Icon(Icons.checklist),
      ),
      title: Text(
        "Open Tasks",
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: isEnabled ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
        ),
      ),
      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      children: openTasks.map((t) => TaskRuleListCard(taskRuleId: t.rule.id)).toList(),
    );
  }
}
