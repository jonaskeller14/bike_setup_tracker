part of 'task_rule.dart';

enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  critical('Critical');

  final String label;
  const TaskPriority(this.label);
}
