import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_rule.dart';
import '../repositories/app_repository.dart';

class TaskRuleDisplayCard extends StatelessWidget {
  final TaskRule taskRule;

  const TaskRuleDisplayCard({super.key, required this.taskRule});

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final component = appRepository.components[taskRule.componentId];
    
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          taskRule.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
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
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: component != null 
                          ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                          : Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
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
            if (taskRule.notes != null && taskRule.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
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
            ],
          ],
        ),
      ),
    );
  }
}
