import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/app_repository.dart';
import '../../utils/task_actions.dart';
import '../chips/task_list_filter_widget.dart';
import '../empty_state_placeholder.dart';
import '../items/task_rule_list_card.dart';
import 'task_list_controller.dart';

class TaskList extends StatefulWidget {
  final TaskListController? controller;
  final Set<String> selectedTaskRules;
  final ValueChanged<String>? onTaskRuleSelectionChanged;
  final VoidCallback? onSelectedTaskRulesCompleted;

  const TaskList({
    super.key,
    this.controller,
    this.selectedTaskRules = const {},
    this.onTaskRuleSelectionChanged,
    this.onSelectedTaskRulesCompleted,
  });

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  bool _showAllCompleted = false;

  Widget _emptyPlaceholder(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
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

    return CustomScrollView(
      controller: widget.controller?.scrollController,
      slivers: [
        SliverPersistentHeader(
          floating: true,
          delegate: _TaskFilterHeaderDelegate(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16 + 100),
          sliver: SliverList.builder(
            itemCount: totalItems - 1,
            itemBuilder: (context, itemIndex) {
              final index = itemIndex + 1;

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
                final taskRuleId = openTaskRules[index - 1].rule.id;
                return TaskRuleListCard(
                  taskRuleId: taskRuleId,
                  selectionMode: widget.selectedTaskRules.isNotEmpty,
                  selected: widget.selectedTaskRules.contains(taskRuleId),
                  onSelectionChanged: widget.onTaskRuleSelectionChanged == null
                      ? null
                      : () => widget.onTaskRuleSelectionChanged!(taskRuleId),
                  onSelectedTaskRulesCompleted: widget.onSelectedTaskRulesCompleted,
                );
              }

              // Divider
              final completedSectionStart = numOpen + 1;
              if (index == completedSectionStart) {
                return const Divider(height: 32);
              }

              // Completed tasks
              final completedItemIndex = index - completedSectionStart - 1;
              if (completedItemIndex < visibleCompleted) {
                final taskRuleId = completedTaskRules[completedItemIndex].rule.id;
                return TaskRuleListCard(
                  taskRuleId: taskRuleId,
                  selectionMode: widget.selectedTaskRules.isNotEmpty,
                  selected: widget.selectedTaskRules.contains(taskRuleId),
                  onSelectionChanged: widget.onTaskRuleSelectionChanged == null
                      ? null
                      : () => widget.onTaskRuleSelectionChanged!(taskRuleId),
                  onSelectedTaskRulesCompleted: widget.onSelectedTaskRulesCompleted,
                );
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
          ),
        ),
      ],
    );
  }
}

class _TaskFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  static const double _height = 64;

  final Color backgroundColor;

  const _TaskFilterHeaderDelegate({required this.backgroundColor});

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: backgroundColor,
      elevation: overlapsContent ? 2 : 0,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: TaskListFilterWidget(),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TaskFilterHeaderDelegate oldDelegate) {
    return backgroundColor != oldDelegate.backgroundColor;
  }
}
