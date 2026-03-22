import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/app_repository.dart';
import '../utils/todo_actions.dart';

class TodoRuleListCard extends StatelessWidget {
  final String todoRuleId;

  const TodoRuleListCard({super.key, required this.todoRuleId});

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final todoRule = appRepository.todoRules[todoRuleId];
    if (todoRule == null) return const SizedBox.shrink();
    final component = appRepository.components[todoRule.componentId];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      clipBehavior: Clip.antiAlias, // Borderradius for InkWell,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        minTileHeight: 0,
        titleAlignment: ListTileTitleAlignment.top,
        title: Text(
          todoRule.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 2,
              children: [
                Icon(
                  component?.componentType.getIconData() ?? Icons.grid_view_sharp, 
                  size: 13, 
                  color: component != null ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.error,
                ),
                Flexible(
                  child: Text(
                    component?.name ?? "COMPONENT NOT FOUND",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: component != null ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8) : Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 2,
              children: [
                Icon(Icons.traffic, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                Text(
                  'Priority: ${todoRule.priority.label}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (todoRule.notes != null && todoRule.notes!.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3), // tweak to match font size
                    child: Icon(
                      Icons.notes,
                      size: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      todoRule.notes!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),            
          ],
        ),
        trailing: PopupMenuButton<_TodoRuleListCardPopupMenuButtonOptions>(
          onSelected: (_TodoRuleListCardPopupMenuButtonOptions value) {
            switch (value) {
              case _TodoRuleListCardPopupMenuButtonOptions.edit:
                TodoActions.editTodoRule(context, todoRule: todoRule);
              case _TodoRuleListCardPopupMenuButtonOptions.remove:
                TodoActions.removeTodoRule(context, todoRule: todoRule);
              case _TodoRuleListCardPopupMenuButtonOptions.addEntry:
                TodoActions.addTodoEntry(context, todoRule: todoRule);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<_TodoRuleListCardPopupMenuButtonOptions>>[
            const PopupMenuItem<_TodoRuleListCardPopupMenuButtonOptions>(
              value: _TodoRuleListCardPopupMenuButtonOptions.edit,
              child: Row(
                spacing: 10,
                children: [
                  Icon(Icons.edit, size: 20),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem<_TodoRuleListCardPopupMenuButtonOptions>(
              value: _TodoRuleListCardPopupMenuButtonOptions.remove,
              child: Row(
                spacing: 10,
                children: [
                  Icon(Icons.delete, size: 20),
                  Text('Remove'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: _TodoRuleListCardPopupMenuButtonOptions.addEntry,
              child: Row(
                spacing: 10,
                children: [
                  Icon(Icons.check, size: 20),
                  Text('Add Todo Entry'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TodoRuleListCardPopupMenuButtonOptions {
  edit,
  remove,
  addEntry,
}
