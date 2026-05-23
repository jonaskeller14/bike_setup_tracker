import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/task_rule.dart';
import '../models/task_threshold.dart';
import '../repositories/app_repository.dart';
import '../utils/task_actions.dart';

class TaskRuleDisplayCard extends StatelessWidget {
  final TaskRule taskRule;
  final bool showStatus;

  const TaskRuleDisplayCard({super.key, required this.taskRule, required this.showStatus});

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final appSettings = context.watch<AppSettings>();
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
              if (appSettings.enableTaskPriority)
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
              if (appSettings.enableTaskTags && taskRule.tags.isNotEmpty)
                Wrap(
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      if (taskRule.interval != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 2,
                          children: [
                            Icon(taskRule.interval!.iconData, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            Text(
                              '${taskRule.repeat ? "Every " : "After "}${taskRule.interval!.toDisplayValue(distanceUnit: appSettings.distanceUnit, altitudeUnit: appSettings.altitudeUnit)}',
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
                  if (!isCompleted && taskRule.interval != null)
                    Flexible(
                      child: _buildThresholdDetailRow(context, taskRule.interval!, taskRule.delay, status, statusColor, appSettings.distanceUnit, appSettings.altitudeUnit),
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

  Widget _buildThresholdDetailRow(BuildContext context, TaskThreshold interval, TaskThreshold? delay, TaskStatus status, Color statusColor, String distanceUnit, String altitudeUnit) {
    final detail = _thresholdDetail(interval, delay, status.progress, distanceUnit, altitudeUnit);
    if (detail == null) return const SizedBox.shrink();
    final isExceeded = status.isDue;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 2,
      children: [
        Icon(isExceeded ? Icons.warning_amber_rounded : Icons.arrow_forward, size: 13, color: statusColor),
        Flexible(
          child: Text(
            detail,
            style: TextStyle(color: statusColor, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String? _thresholdDetail(TaskThreshold interval, TaskThreshold? delay, double progress, String distanceUnit, String altitudeUnit) {
    switch (interval) {
      case DistanceThreshold(:final meters):
        final totalM = meters + (delay is DistanceThreshold ? delay.meters : 0.0);
        if (totalM <= 0) return null;
        final diffM = (totalM - progress * totalM).abs();
        final converted = AppSettings.convertDistanceFromMeters(diffM, distanceUnit)!;
        final fmt = NumberFormat.decimalPattern();
        return progress < 1.0
            ? '${fmt.format(converted.round())} $distanceUnit remaining'
            : '${fmt.format(converted.round())} $distanceUnit exceeded';

      case ElevationThreshold(:final meters):
        final totalM = meters + (delay is ElevationThreshold ? delay.meters : 0.0);
        if (totalM <= 0) return null;
        final accumulatedM = progress * totalM;
        final diffM = (totalM - accumulatedM).abs();
        final converted = AppSettings.convertElevationFromMeters(diffM, altitudeUnit)!;
        final fmt = NumberFormat.decimalPattern();
        return progress < 1.0
            ? '${fmt.format(converted.round())} $altitudeUnit remaining'
            : '${fmt.format(converted.round())} $altitudeUnit exceeded';

      case MovingTimeThreshold(:final hours):
        final totalMicros = hours.inMicroseconds + (delay is MovingTimeThreshold ? delay.hours.inMicroseconds : 0);
        if (totalMicros <= 0) return null;
        final diff = Duration(microseconds: ((progress < 1.0 ? 1.0 - progress : progress - 1.0) * totalMicros).round());
        final label = progress < 1.0 ? 'remaining' : 'exceeded';
        final h = diff.inHours;
        final m = diff.inMinutes.remainder(60);
        return h > 0 ? '${h}h ${m}min $label' : '${m}min $label';

      case DurationThreshold(:final days):
        final totalMicros = days.inMicroseconds + (delay is DurationThreshold ? delay.days.inMicroseconds : 0);
        if (totalMicros <= 0) return null;
        final diff = Duration(microseconds: ((progress < 1.0 ? 1.0 - progress : progress - 1.0) * totalMicros).round());
        return '${diff.inDays} d ${progress < 1.0 ? 'remaining' : 'exceeded'}';

      case ActivityCountThreshold(:final count):
        final total = count + (delay is ActivityCountThreshold ? delay.count : 0);
        if (total <= 0) return null;
        final accumulated = (progress * total).round();
        return progress < 1.0
            ? '${total - accumulated} rides remaining'
            : '${accumulated - total} rides exceeded';

      case DateTimeThreshold(:final deadline):
        final effectiveDeadline = deadline.add(delay is DurationThreshold ? delay.days : Duration.zero);
        final now = DateTime.now().toUtc();
        final diff = now.isBefore(effectiveDeadline) ? effectiveDeadline.difference(now) : now.difference(effectiveDeadline);
        return '${diff.inDays} d ${now.isBefore(effectiveDeadline) ? 'remaining' : 'exceeded'}';
    }
  }
}
