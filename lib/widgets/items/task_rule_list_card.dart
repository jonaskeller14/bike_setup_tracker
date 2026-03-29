import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/task_rule.dart';
import '../../repositories/app_repository.dart';
import '../../utils/task_actions.dart';
import '../../pages/details/task_rule_details_page.dart';

class TaskRuleListCard extends StatelessWidget {
  final String taskRuleId;

  const TaskRuleListCard({super.key, required this.taskRuleId});

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final taskRule = appRepository.taskRules[taskRuleId];
    if (taskRule == null) return const SizedBox.shrink();
    final component = appRepository.components[taskRule.componentId];
    final value = appRepository.taskEntries.values.any((te) => te.taskRule == taskRule.id);

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
              TaskActions.addTaskEntry(context, taskRule: taskRule);
            },
          ),
          contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          minTileHeight: 0,
          onTap: () async {
            await Navigator.push<TaskRule>(
              context,
              MaterialPageRoute(
                builder: (context) => TaskRuleDetailsPage(taskRule: taskRule),
              ),
            );
          },
          title: Text(
            taskRule.name,
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
                    'Priority: ${taskRule.priority.label}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (taskRule.notes != null && taskRule.notes!.isNotEmpty)
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
                        taskRule.notes!,
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
          trailing: PopupMenuButton<_TaskRuleOptions>(
            onSelected: (_TaskRuleOptions value) {
              switch (value) {
                case _TaskRuleOptions.edit:
                  TaskActions.editTaskRule(context, taskRule: taskRule);
                case _TaskRuleOptions.remove:
                  TaskActions.removeTaskRule(context, taskRule: taskRule);
                case _TaskRuleOptions.duplicate:
                  TaskActions.duplicateTaskRule(context, taskRule: taskRule);
                case _TaskRuleOptions.addEntry:
                  TaskActions.addTaskEntry(context, taskRule: taskRule);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<_TaskRuleOptions>>[
              const PopupMenuItem<_TaskRuleOptions>(
                value: _TaskRuleOptions.edit,
                child: Row(
                  spacing: 10,
                  children: [
                    Icon(Icons.edit, size: 20),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem<_TaskRuleOptions>(
                value: _TaskRuleOptions.duplicate,
                child: Row(
                  spacing: 10,
                  children: [
                    Icon(Icons.copy, size: 20),
                    Text('Duplicate'),
                  ],
                ),
              ),
              const PopupMenuItem<_TaskRuleOptions>(
                value: _TaskRuleOptions.remove,
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
                value: _TaskRuleOptions.addEntry,
                child: Row(
                  spacing: 10,
                  children: [
                    Icon(Icons.check, size: 20),
                    Text('Add Task Entry'),
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

enum _TaskRuleOptions {
  edit,
  duplicate,
  remove,
  addEntry,
}
