import 'package:flutter/material.dart';

import '../../models/task/task_rule.dart';
import '../task_priority_badge.dart';
import 'radio_group.dart';

Future<void> showSetTaskPrioritySheet({
  required BuildContext context,
  required TaskPriority currentPriority,
  required ValueChanged<TaskPriority> onSelected,
}) {
  return radioGroupSheet<TaskPriority>(
    context: context,
    leadingIcon: const Icon(TaskPriority.iconData),
    title: "Task Priority",
    value: currentPriority,
    optionWidgets: Map.fromEntries(
      TaskPriority.values.map((priority) {
        return MapEntry(
          priority,
          // ListTile gives its title a tight width, which would stretch the badge.
          Align(
            alignment: AlignmentDirectional.centerStart,
            heightFactor: 1,
            child: TaskPriorityBadge(priority: priority, large: true),
          ),
        );
      }),
    ),
    onChanged: (TaskPriority? newValue) {
      if (newValue == null) return;
      Navigator.pop(context);
      onSelected(newValue);
    },
  );
}
