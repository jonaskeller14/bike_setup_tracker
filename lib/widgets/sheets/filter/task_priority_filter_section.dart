import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/task/task_rule.dart';
import '../../../repositories/app_repository.dart';
import '../../text/sheet_section_title.dart';
import 'isolatable_chips.dart';

class TaskPriorityFilterSection extends StatelessWidget {
  const TaskPriorityFilterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final filters = context.watch<AppRepository>().filters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetSectionTitle(title: "Task Priority"),
        IsolatableChips(
          options: TaskPriority.values.map((tp) {
            return IsolatableChipOption(
              icon: null,
              label: tp.label,
              selected: filters.taskRule.priorities.contains(tp),
              onChanged: (selected) => filters.taskRule = filters.taskRule.copyWith(
                priorities: toggled(filters.taskRule.priorities, tp, selected: selected),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
