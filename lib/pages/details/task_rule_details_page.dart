import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/app_repository.dart';
import '../../utils/task_actions.dart';
import '../../widgets/items/task_entry_list_item.dart';
import '../../widgets/section_title.dart';
import '../../widgets/task_rule_display_card.dart';

class TaskRuleDetailsPage extends StatelessWidget {
  final String taskRuleId;
  final String? highlightTaskEntryId;

  const TaskRuleDetailsPage({super.key, required this.taskRuleId, this.highlightTaskEntryId});

  Widget _noTaskEntriesPlaceholder(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'No entries yet',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();

    final taskRule = appRepository.taskRules[taskRuleId];
    if (taskRule == null) return const SizedBox.shrink();

    final taskEntries = appRepository.taskEntries.values.where((te) => te.taskRule == taskRule.id).sortedBy((te) => te.dateTimeUTC);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task"),
        actions: [
          IconButton(
            onPressed: () => TaskActions.editTaskRule(context, taskRule: taskRule),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TaskRuleDisplayCard(taskRule: taskRule, showStatus: true),
              ),

              const SectionTitle(title: "Entries"),

              if (taskEntries.isEmpty)
                _noTaskEntriesPlaceholder(context)
              else
                ...taskEntries.reversed.mapIndexed((index, te) {
                  // previousSnapshot is the snapshot of the entry that occurred BEFORE this one in time.
                  // Since taskEntries is sorted ASC, the previous entry is at [index - 1] in taskEntries if we weren't reversing.
                  // But we are reversed for display (latest first).
                  // So for taskEntries.reversed[index], the 'previous' in time is actually taskEntries.reversed[index + 1].
                  final reversedList = taskEntries.reversed.toList();
                  final previousEntry = (index + 1 < reversedList.length) ? reversedList[index + 1] : null;
                  
                  return TaskEntryListItem(
                    taskEntryId: te.id,
                    previousSnapshot: previousEntry?.snapshot,
                    enabled: highlightTaskEntryId == null || te.id == highlightTaskEntryId,
                    onTap: null, // disable infinite tap
                  );
                }),
            ],
          ),
        )
      ),
    );
  }
}