import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/app_repository.dart';
import '../../utils/task_actions.dart';
import '../../widgets/task_rule_display_card.dart';
import '../../widgets/items/task_entry_list_item.dart';

class TaskRuleDetailsPage extends StatelessWidget {
  final String taskRuleId;

  const TaskRuleDetailsPage({super.key, required this.taskRuleId});

  Widget _noTaskEntriesPlaceholder(BuildContext context) {
    return SizedBox(
      height: 100,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TaskRuleDisplayCard(taskRule: taskRule),

              const SizedBox(height: 16),
              Text("Entries".toUpperCase(), style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, 
                letterSpacing: 1.2, 
                color: Theme.of(context).colorScheme.primary
              )),
              const SizedBox(height: 8),

              if (taskEntries.isEmpty)
                _noTaskEntriesPlaceholder(context)
              else
                ...taskEntries.map((te) => TaskEntryListItem(
                  taskEntryId: te.id,
                  contentPadding: EdgeInsets.zero,
                )),
            ],
          ),
        )
      ),
    );
  }
}