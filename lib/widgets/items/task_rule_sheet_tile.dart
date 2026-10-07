import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/task/task_rule.dart';
import '../../models/task/task_threshold/task_threshold.dart';
import '../task_priority_badge.dart';
import 'task_rule_list_card.dart';

/// One selectable row: what the created rule will be, without the source's
/// progress (a copy starts at 0 %) or its component (the same on every row).
class TaskRuleSheetTile extends StatelessWidget {
  final String name;
  final TaskPriority priority;
  final TaskThreshold? interval;
  final TaskThreshold? delay;
  final bool repeat;
  final Set<String> tags;

  /// Where a recommended interval comes from; `null` for copied rules.
  final String? origin;
  final bool isDone;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const TaskRuleSheetTile({
    super.key,
    required this.name,
    required this.priority,
    required this.interval,
    required this.delay,
    required this.repeat,
    required this.tags,
    this.origin,
    required this.isDone,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final showTags = appSettings.enableTaskTags && tags.isNotEmpty;
    final hasSubtitle = interval != null || showTags || origin != null;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Opacity(
      opacity: isDone && !isSelected ? 0.5 : 1,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: CheckboxListTile(
          title: Row(
            spacing: 6,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationThickness: 2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (appSettings.enableTaskPriority) TaskPriorityBadge(priority: priority),
            ],
          ),
          subtitle: !hasSubtitle
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (interval != null) TaskIntervalText(interval: interval!, delay: delay, repeat: repeat),
                    if (showTags) TaskRuleListCard.tagsWidget(context, tags: tags),
                    if (origin != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          spacing: 6,
                          children: [
                            Icon(Icons.auto_awesome, size: 14, color: mutedColor),
                            Expanded(
                              child: Text(
                                origin!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: mutedColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          dense: true,
          value: isSelected,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
