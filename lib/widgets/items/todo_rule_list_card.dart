import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../repositories/app_repository.dart';
import '../../utils/todo_actions.dart';

class TodoRuleListCard extends StatelessWidget {
  final String todoRuleId;

  const TodoRuleListCard({super.key, required this.todoRuleId});

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final todoRule = appRepository.todoRules[todoRuleId];
    if (todoRule == null) return const SizedBox.shrink();
    final component = appRepository.components[todoRule.componentId];
    final value = appRepository.todoEntries.values.any((te) => te.todoRule == todoRule.id);

    return Opacity(
      opacity: value ? 0.5 : 1,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        clipBehavior: Clip.antiAlias, // Borderradius for InkWell,
        child: ListTile(
          leading: Checkbox(
            value: value,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onChanged: value ? null : (bool? value) {
              HapticFeedback.lightImpact();
              TodoActions.addTodoEntry(context, todoRule: todoRule);
            },
          ),
          contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          minTileHeight: 0,
          title: Text(
            todoRule.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              decoration: value ? TextDecoration.lineThrough: null,
              decorationThickness: 2,
            ),
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
          trailing: PopupMenuButton<_TodoRuleOptions>(
            onSelected: (_TodoRuleOptions value) {
              switch (value) {
                case _TodoRuleOptions.edit:
                  TodoActions.editTodoRule(context, todoRule: todoRule);
                case _TodoRuleOptions.remove:
                  TodoActions.removeTodoRule(context, todoRule: todoRule);
                case _TodoRuleOptions.addEntry:
                  TodoActions.addTodoEntry(context, todoRule: todoRule);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<_TodoRuleOptions>>[
              const PopupMenuItem<_TodoRuleOptions>(
                value: _TodoRuleOptions.edit,
                child: Row(
                  spacing: 10,
                  children: [
                    Icon(Icons.edit, size: 20),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem<_TodoRuleOptions>(
                value: _TodoRuleOptions.remove,
                child: Row(
                  spacing: 10,
                  children: [
                    Icon(Icons.delete, size: 20),
                    Text('Remove'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                enabled: !value,
                value: _TodoRuleOptions.addEntry,
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
      ),
    ); 
  }
}

enum _TodoRuleOptions {
  edit,
  remove,
  addEntry,
}
