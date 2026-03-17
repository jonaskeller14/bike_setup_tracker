import 'package:bike_setup_tracker/widgets/todo_rule_list_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/app_repository.dart';
import 'chips/todo_list_filter_widget.dart';

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
    
    return todoRules.isEmpty
        ? _emptyPlaceholder(context)
        : ListView.builder(
          padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16+100),
            itemCount: todoRules.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return TodoListFilterWidget();
              }

              final rule = todoRules[index-1];
              return TodoRuleListCard(todoRuleId: rule.id);
            },
          );
  }
}
