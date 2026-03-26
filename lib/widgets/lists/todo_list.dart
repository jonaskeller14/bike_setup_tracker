import 'package:bike_setup_tracker/widgets/items/todo_rule_list_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/app_repository.dart';
import '../chips/todo_list_filter_widget.dart';

class TodoList extends StatelessWidget {
  const TodoList({super.key});

  Widget _emptyPlaceholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TodoListFilterWidget(),
          Expanded(
            child: Center(
              child: Text(
                'No todos yet',
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
    final todoRules = appRepository.filteredTodoRules.values.toList();
    
    if (todoRules.isEmpty) {
      return _emptyPlaceholder(context);
    }

    final openRules = todoRules.where((r) => !appRepository.todoEntries.values.any((te) => te.todoRule == r.id)).toList();
    final completedRules = todoRules.where((r) => appRepository.todoEntries.values.any((te) => te.todoRule == r.id)).toList();

    // Sort by lastModified descending to show newest/most recently changed first
    openRules.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    completedRules.sort((a, b) => b.lastModified.compareTo(a.lastModified));

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16 + 100),
      itemCount: openRules.length + (completedRules.isNotEmpty ? completedRules.length + 2 : 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return TodoListFilterWidget();
        }

        if (index <= openRules.length) {
          return TodoRuleListCard(todoRuleId: openRules[index - 1].id);
        }

        final completedIndex = index - openRules.length - 1;
        if (completedIndex == 0) {
          return const Divider(height: 32);
        }

        return TodoRuleListCard(todoRuleId: completedRules[completedIndex - 1].id);
      },
    );
  }
}
