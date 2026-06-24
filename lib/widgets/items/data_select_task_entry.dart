import 'package:flutter/material.dart';

import '../../models/task/task_entry.dart';
import '../../models/task/task_rule.dart';

class DataSelectTaskEntry extends StatelessWidget {
  final TaskEntry item;
  final Map<String, TaskRule> taskRules;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const DataSelectTaskEntry({
    super.key,
    required this.item,
    required this.taskRules,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: CheckboxListTile(
        secondary: const Icon(Icons.check_box_outlined),
        title: Text(
          item.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: item.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Icon(
              Icons.check_box_outlined,
              size: 13,
              color: taskRules.containsKey(item.taskRule)
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.error,
            ),
            Flexible(
              child: Text(
                taskRules[item.taskRule]?.name ?? "TASK NOT FOUND",
                style: TextStyle(
                  color: taskRules.containsKey(item.taskRule)
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                      : Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
        value: isSelected,
        onChanged: onChanged,
      ),
    );
  }
}
