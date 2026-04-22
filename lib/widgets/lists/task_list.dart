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
    final openTaskRules = appRepository.toDoTaskRules;
    final completedTaskRules = appRepository.completedTaskRules;

    if (openTaskRules.isEmpty && completedTaskRules.isEmpty) {
      return _emptyPlaceholder(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16 + 100),
      itemCount: (openTaskRules.isEmpty ? 1 : openTaskRules.length) + (completedTaskRules.isNotEmpty ? completedTaskRules.length + 2 : 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return TaskListFilterWidget();
        }

        if (index <= (openTaskRules.isEmpty ? 1 : openTaskRules.length)) {
          if (openTaskRules.isEmpty) {
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
          return TaskRuleListCard(taskRuleId: openTaskRules[index - 1].rule.id);
        }

        final completedIndex = index - (openTaskRules.isEmpty ? 1 : openTaskRules.length) - 1;
        if (completedIndex == 0) {
          return const Divider(height: 32);
        }

        return TaskRuleListCard(taskRuleId: completedTaskRules[completedIndex - 1].rule.id);
      },
    );
  }
}
