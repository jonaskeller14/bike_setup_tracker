import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/app_repository.dart';
import '../../utils/task_actions.dart';
import '../../widgets/flash_highlight.dart';
import '../../widgets/items/task_entry_list_item.dart';
import '../../widgets/sheets/sheet.dart';
import '../../widgets/task_rule_display_card.dart';
import '../../widgets/text/section_title.dart';

class TaskRuleDetailsPage extends StatelessWidget {
  final String taskRuleId;
  final String? highlightTaskEntryId;

  const TaskRuleDetailsPage({super.key, required this.taskRuleId, this.highlightTaskEntryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task"),
        actions: [
          IconButton(
            onPressed: () async {
              final appRepository = context.read<AppRepository>();
              final taskRule = appRepository.taskRules[taskRuleId];
              if (taskRule == null) return;
              await TaskActions.editTaskRule(context, taskRule: taskRule);
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: TaskRuleDetailsPageContent(taskRuleId: taskRuleId, highlightTaskEntryId: highlightTaskEntryId),
        ),
      ),
    );
  }
}

class TaskRuleDetailsPageContent extends StatelessWidget {
  final String taskRuleId;
  final String? highlightTaskEntryId;
  final bool showEditButton;
  final bool showCloseButton;

  const TaskRuleDetailsPageContent({super.key, required this.taskRuleId, this.highlightTaskEntryId, this.showEditButton = false, this.showCloseButton = false});

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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Expanded(
                  child: TaskRuleDisplayCard(taskRule: taskRule, showStatus: true),
                ),
                if (showCloseButton || showEditButton)
                  Column(
                    children: [
                      if (showCloseButton)
                        sheetCloseButton(context),
                      if (showEditButton)
                        sheetEditButton(context, onPressed: () => TaskActions.editTaskRule(context, taskRule: taskRule)),
                    ],
                  )
              ],
            ),
          ),
          const SizedBox(height: 16),

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
              
              return FlashHighlight(
                highlighted: highlightTaskEntryId != null && te.id == highlightTaskEntryId,
                child: TaskEntryListItem(
                  taskEntryId: te.id,
                  previousSnapshot: previousEntry?.snapshot,
                  onTap: null, // disable infinite tap
                ),
              );
            }),
        ],
      ),
    );
  }
}