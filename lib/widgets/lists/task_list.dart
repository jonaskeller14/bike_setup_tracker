import 'package:bike_setup_tracker/widgets/items/task_rule_list_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/app_repository.dart';
import '../chips/task_list_filter_widget.dart';

class TaskList extends StatelessWidget {
  const TaskList({super.key});

  Widget _emptyPlaceholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TaskListFilterWidget(),
          Expanded(
            child: Center(
              child: Text(
                'No tasks yet',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final taskRules = appRepository.filteredTaskRules.values.toList();
    
    if (taskRules.isEmpty) {
      return _emptyPlaceholder(context);
    }

    final openRules = taskRules.where((r) => !appRepository.taskEntries.values.any((te) => te.taskRule == r.id)).toList();
    final completedRules = taskRules.where((r) => appRepository.taskEntries.values.any((te) => te.taskRule == r.id)).toList();

    // Sort by lastModified descending to show newest/most recently changed first
    openRules.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    completedRules.sort((a, b) => b.lastModified.compareTo(a.lastModified));

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16 + 100),
      itemCount: (openRules.isEmpty ? 1 : openRules.length) + (completedRules.isNotEmpty ? completedRules.length + 2 : 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return TaskListFilterWidget();
        }

        if (index <= (openRules.isEmpty ? 1 : openRules.length)) {
          if (openRules.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Text(
                  'No open tasks',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                ),
              ),
            );
          }
          return TaskRuleListCard(taskRuleId: openRules[index - 1].id);
        }

        final completedIndex = index - (openRules.isEmpty ? 1 : openRules.length) - 1;
        if (completedIndex == 0) {
          return const Divider(height: 32);
        }

        return TaskRuleListCard(taskRuleId: completedRules[completedIndex - 1].id);
      },
    );
  }
}
