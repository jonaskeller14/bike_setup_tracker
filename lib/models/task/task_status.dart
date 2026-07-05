part of 'task_rule.dart';

enum TaskStatusType {
  upcoming,
  due,
  overdue,
  completed;

  Color getStatusColor(BuildContext context) {
    final colors = Theme.of(context).extension<TaskStatusColors>()!;
    return switch (this) {
      TaskStatusType.overdue => colors.overdue,
      TaskStatusType.due => colors.due,
      TaskStatusType.upcoming => colors.upcoming,
      TaskStatusType.completed => colors.completed,
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
