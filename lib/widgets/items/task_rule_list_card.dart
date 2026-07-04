import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/task/task_rule.dart';
import '../../pages/details/task_rule_details_page.dart';
import '../../repositories/app_repository.dart';
import '../../theme.dart';
import '../../utils/task_actions.dart';

class TaskRuleListCard extends StatelessWidget {
  final String taskRuleId;

  const TaskRuleListCard({super.key, required this.taskRuleId});

  Widget _filterWidget(BuildContext context, {required TaskRule taskRule, required Component? component, required Bike? bike}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 2,
      children: [
        if (taskRule.componentId != null) ...[
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
        ] else if (taskRule.bikeId != null) ...[
          Icon(
            Bike.iconData, 
            size: 13,
            color: bike != null ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.error,
          ),
          Flexible(
            child: Text(
              bike?.name ?? "BIKE NOT FOUND",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: bike != null ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8) : Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
          ),
        ] else ...[
          Icon(
            Icons.circle_outlined, 
            size: 13, 
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          Flexible(
            child: Text(
              "General Task",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _priorityWidget(BuildContext context, {required TaskRule taskRule}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 2,
      children: [
        Icon(Icons.traffic, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        Text(
          taskRule.priority.label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _notesWidget(BuildContext context, {required TaskRule taskRule}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3), // tweak to match font size
          child: Icon(
            Icons.notes,
            size: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            taskRule.notes!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tagsWidget(BuildContext context, {required TaskRule taskRule}) {
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: taskRule.tags.map((tag) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 2,
          children: [
            Icon(Icons.tag, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            Flexible(
              child: Text(
                tag,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final appSettings = context.watch<AppSettings>();
    final taskRule = appRepository.taskRules[taskRuleId];
    if (taskRule == null) return const SizedBox.shrink();

    final status = appRepository.getTaskRuleStatus(taskRule);
    final isCompleted = status.type == TaskStatusType.completed;

    final component = taskRule.componentId != null ? appRepository.components[taskRule.componentId] : null;
    final bike = taskRule.bikeId != null ? appRepository.bikes[taskRule.bikeId] : (component?.bike != null ? appRepository.bikes[component!.bike] : null);

    final statusColor = status.type.getStatusColor();

    return Opacity(
      opacity: isCompleted ? 0.5 : 1,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        clipBehavior: Clip.antiAlias, // Borderradius for InkWell,
        child: ListTile(
          leading: Checkbox(
            value: isCompleted,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onChanged: isCompleted ? null : (bool? value) async {
              unawaited(HapticFeedback.lightImpact());
              await TaskActions.addTaskEntry(context, taskRule: taskRule);
            },
          ),
          contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          minTileHeight: 0,
          onTap: () async {
            await Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (context) => TaskRuleDetailsPage(taskRuleId: taskRuleId),
              ),
            );
          },
          titleAlignment: ListTileTitleAlignment.top,
          title: Text(
            taskRule.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              decoration: isCompleted ? TextDecoration.lineThrough: null,
              decorationThickness: 2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _filterWidget(context, taskRule: taskRule, component: component, bike: bike),
              if (appSettings.enableTaskPriority)
                _priorityWidget(context, taskRule: taskRule),
              if (appSettings.enableTaskTags && taskRule.tags.isNotEmpty)
                _tagsWidget(context, taskRule: taskRule),
              if (taskRule.notes != null && taskRule.notes!.isNotEmpty)
                _notesWidget(context, taskRule: taskRule),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 8,
                children: [
                  if (taskRule.interval != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 2,
                      children: [
                        Icon(taskRule.interval!.iconData, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        Text(
                          '${taskRule.repeat ? "Every " : "After "}${taskRule.interval!.toDisplayValue(distanceUnit: appSettings.distanceUnit, altitudeUnit: appSettings.altitudeUnit, dateFormat: appSettings.dateFormat)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  if (taskRule.delay != null && taskRule.delay!.isPositive)
                    Flexible(
                      child: Row(
                        spacing: 2,
                        children: [
                          Icon(Icons.history, size: 13, color: Theme.of(context).extension<ValueHighlightColors>()!.changed),
                          Expanded(
                            child: Text(
                              '+${taskRule.delay!.toDisplayValue(distanceUnit: appSettings.distanceUnit, altitudeUnit: appSettings.altitudeUnit, dateFormat: appSettings.dateFormat)}',
                              style: TextStyle(color: Theme.of(context).extension<ValueHighlightColors>()!.changed, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (!isCompleted && taskRule.interval != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: status.progress.clamp(0.0, 1.0),
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  color: statusColor,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ],
          ),
          trailing: PopupMenuButton<_TaskRuleOptions>(
            onSelected: (_TaskRuleOptions value) async {
              switch (value) {
                case _TaskRuleOptions.edit:
                  await TaskActions.editTaskRule(context, taskRule: taskRule);
                case _TaskRuleOptions.remove:
                  await TaskActions.removeTaskRule(context, taskRule: taskRule);
                case _TaskRuleOptions.duplicate:
                  await TaskActions.duplicateTaskRule(context, taskRule: taskRule);
                case _TaskRuleOptions.addEntry:
                  await TaskActions.addTaskEntry(context, taskRule: taskRule);
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
                enabled: !isCompleted,
                value: _TaskRuleOptions.addEntry,
                child: const Row(
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
