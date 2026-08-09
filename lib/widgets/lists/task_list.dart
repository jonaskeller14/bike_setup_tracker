import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/app_repository.dart';
import '../../utils/task_actions.dart';
import '../chips/task_list_filter_widget.dart';
import '../empty_state_placeholder.dart';
import '../items/task_rule_list_card.dart';

class TaskList extends StatefulWidget {
  const TaskList({super.key});

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  bool _showAllCompleted = false;

  Widget _emptyPlaceholder(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(child: TaskListFilterWidget()),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: EmptyStatePlaceholder(
              icon: Icons.checklist,
              title: 'No tasks yet',
              subtitle: 'Add a task to track service intervals or other bike related todos.',
              actionLabel: 'Add a task',
              onAction: () => TaskActions.addTaskRule(context),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final openTaskRules = appRepository.openTaskRules;
    final completedTaskRules = appRepository.completedTaskRules;

    if (openTaskRules.isEmpty && completedTaskRules.isEmpty) {
      return _emptyPlaceholder(context);
    }

    final int numOpen = openTaskRules.isEmpty ? 1 : openTaskRules.length;
    final bool hasCompleted = completedTaskRules.isNotEmpty;
    final int numCompleted = completedTaskRules.length;
    final bool showToggle = numCompleted > 3;
    final int visibleCompleted = _showAllCompleted ? numCompleted : (numCompleted > 3 ? 3 : numCompleted);

    int totalItems = 1 + numOpen;
    if (hasCompleted) {
      totalItems += 1; // Divider
      totalItems += visibleCompleted;
      if (showToggle) {
        totalItems += 1; // Button
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16 + 100),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const TaskListFilterWidget();
        }

        // Open tasks section
        if (index <= numOpen) {
          if (openTaskRules.isEmpty) {
            return EmptyStatePlaceholder(
              icon: Icons.task_alt,
              title: 'All caught up',
              subtitle: 'No open tasks right now.',
              actionLabel: 'Add a task',
              onAction: () => TaskActions.addTaskRule(context),
            );
          }
          return TaskRuleListCard(taskRuleId: openTaskRules[index - 1].rule.id);
        }

        // Divider
        final completedSectionStart = numOpen + 1;
        if (index == completedSectionStart) {
          return const Divider(height: 32);
        }

        // Completed tasks
        final completedItemIndex = index - completedSectionStart - 1;
        if (completedItemIndex < visibleCompleted) {
          return TaskRuleListCard(taskRuleId: completedTaskRules[completedItemIndex].rule.id);
        }

        // Show more/less button
        return Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton.icon(
              onPressed: () => setState(() => _showAllCompleted = !_showAllCompleted),
              icon: Icon(_showAllCompleted ? Icons.expand_less : Icons.expand_more),
              label: Text(_showAllCompleted ? 'Show less' : 'Show ${numCompleted - 3} more'),
            ),
          ),
        );
      },
    );
  }
}
