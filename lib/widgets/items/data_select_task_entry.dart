import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/task/task_entry.dart';
import '../../models/task/task_rule.dart';
import '../../services/data_selection_dependencies.dart';
import 'data_select_missing_line.dart';

class DataSelectTaskEntry extends StatelessWidget {
  final TaskEntry item;
  final Map<String, TaskRule> taskRules;
  final bool isSelected;

  /// The referenced items that aren't selected, with their names.
  final Map<DataRef, String> missing;

  final ValueChanged<bool?> onChanged;

  const DataSelectTaskEntry({
    super.key,
    required this.item,
    required this.taskRules,
    required this.isSelected,
    this.missing = const {},
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
                    taskRules[item.taskRule]?.name ?? context.l10n.taskNotFound,
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
            for (final MapEntry(key: ref, value: name) in missing.entries)
              DataSelectMissingLine(kind: ref.kind, name: name),
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
