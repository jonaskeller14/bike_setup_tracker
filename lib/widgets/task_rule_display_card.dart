import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/bike.dart';
import '../models/task_rule.dart';
import '../repositories/app_repository.dart';
import '../utils/task_actions.dart';

class TaskRuleDisplayCard extends StatelessWidget {
  final TaskRule taskRule;
  final bool showStatus;

  const TaskRuleDisplayCard({super.key, required this.taskRule, required this.showStatus});

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final status = appRepository.getTaskRuleStatus(taskRule);
    final isCompleted = status.type == TaskStatusType.completed;

    final component = taskRule.componentId != null ? appRepository.components[taskRule.componentId] : null;
    final bike = taskRule.bikeId != null ? appRepository.bikes[taskRule.bikeId] : (component?.bike != null ? appRepository.bikes[component!.bike] : null);

    final statusColor = switch (status.type) {
      TaskStatusType.upcoming => Colors.blue,
      TaskStatusType.due => Colors.orange,
      TaskStatusType.overdue => Colors.red,
      TaskStatusType.completed => Colors.green,
    };

    return Opacity(
      opacity: isCompleted ? 0.5 : 1,
      child: Card.outlined(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: showStatus
              ? Checkbox(
                  value: isCompleted,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: isCompleted ? null : (bool? value) async {
                    unawaited(HapticFeedback.lightImpact());
                    await TaskActions.addTaskEntry(context, taskRule: taskRule);
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minTileHeight: 0,
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
              Row(
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
              Row(
                mainAxisSize: MainAxisSize.min,
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
                          '${taskRule.repeat ? "Every " : "After "}${taskRule.interval!.toDisplayValue()}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  if (taskRule.delay != null && taskRule.delay!.isPositive)
                    Icon(Icons.history, size: 13, color: Colors.orange.withValues(alpha: 0.8)),
                ],
              ),
              if (taskRule.notes != null && taskRule.notes!.isNotEmpty)
                Row(
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
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              if (showStatus && !isCompleted && taskRule.interval != null) ...[
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
        ),
      ),
    );
  }
}
