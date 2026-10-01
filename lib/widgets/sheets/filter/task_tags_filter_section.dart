import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../repositories/app_repository.dart';
import '../../text/sheet_section_title.dart';
import '../sheet.dart';
import 'isolatable_chips.dart';

class TaskTagsFilterSection extends StatelessWidget {
  const TaskTagsFilterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final filters = appRepository.filters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetSectionTitle(title: "Task Tags"),
        appRepository.taskRuleTags.isEmpty
            ? const SheetFilterEmptyHint(
                icon: Icons.tag,
                title: "No task tags yet",
                hint: "Add/Edit a Task Rule to add tags.",
              )
            : Wrap(
                spacing: 6,
                children: appRepository.taskRuleTags.map((tag) {
                  void select(bool selected) => filters.taskRule = filters.taskRule.copyWith(
                    tags: toggled(filters.taskRule.tags, tag, selected: selected),
                  );
                  return FilterChip(
                    avatar: const Icon(Icons.tag),
                    label: Text(tag),
                    selected: filters.taskRule.tags.contains(tag),
                    showCheckmark: false,
                    onSelected: select,
                    onDeleted: filters.taskRule.tags.contains(tag) ? () => select(false) : null,
                  );
                }).toList(),
              ),
      ],
    );
  }
}
