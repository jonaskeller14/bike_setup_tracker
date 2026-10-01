import 'package:flutter/material.dart';

import '../models/task/task_rule.dart';
import '../theme.dart';

/// Priority as a compact pill that gains weight with each level: outlined for
/// Low, light grey for Medium, solid grey for High. Only Critical takes a
/// color — the overdue red, so a card never carries two different reds.
class TaskPriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  final bool large;

  const TaskPriorityBadge({super.key, required this.priority, this.large = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final (background, foreground, border) = switch (priority) {
      TaskPriority.critical => (theme.extension<TaskStatusColors>()!.overdue, scheme.surface, null),
      TaskPriority.high => (scheme.outline, scheme.surface, null),
      TaskPriority.medium => (muted.withValues(alpha: 0.12), muted, null),
      TaskPriority.low => (null, muted.withValues(alpha: 0.8), scheme.outlineVariant),
    };
    return Container(
      // Caps growth under large text scaling so the title keeps most of its row.
      constraints: large ? null : const BoxConstraints(maxWidth: 96),
      padding: EdgeInsets.symmetric(horizontal: large ? 8 : 4, vertical: large ? 2 : 0),
      decoration: BoxDecoration(
        color: background,
        // Always present so the filled levels match the outlined Low in size.
        border: Border.all(color: border ?? Colors.transparent),
        borderRadius: BorderRadius.circular(large ? 6 : 4),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          priority.label.toUpperCase(),
          semanticsLabel: '${priority.label} priority',
          style: theme.textTheme.labelSmall?.copyWith(
            color: foreground,
            fontSize: large ? 14 : 10,
            fontWeight: priority.index >= TaskPriority.high.index ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
