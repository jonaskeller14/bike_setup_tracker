part of 'task_rule.dart';

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
