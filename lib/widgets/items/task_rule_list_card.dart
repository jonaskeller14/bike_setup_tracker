import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/installation.dart';
import '../../models/task/task_rule.dart';
import '../../models/task/task_threshold/task_threshold.dart';
import '../../pages/details/task_rule_details_page.dart';
import '../../repositories/app_repository.dart';
import '../../theme.dart';
import '../../utils/task_actions.dart';
import '../notes_text.dart';
import '../sheets/set_task_delay.dart';
import '../task_rule_progress_bar.dart';

class TaskRuleListCard extends StatelessWidget {
  final String taskRuleId;
  final bool selectionMode;
  final bool selected;
  final String? heroTag;
  final VoidCallback? onSelectionChanged;
  final VoidCallback? onSelectedTaskRulesCompleted;

  const TaskRuleListCard({
    super.key,
    required this.taskRuleId,
    this.selectionMode = false,
    this.selected = false,
    this.heroTag,
    this.onSelectionChanged,
    this.onSelectedTaskRulesCompleted,
  });

  static Widget filterWidget(BuildContext context, {required TaskRule taskRule, required Component? component, required Map<String, Bike> bikes}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 8,
      children: [
        if (taskRule.componentId != null) ...[
          Flexible(
            child: Row(
              spacing: 2,
              mainAxisSize: MainAxisSize.min,
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
          ),
          Flexible(
            child: Row(
              spacing: 2,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  switch (component?.latestInstallation) {
                    Archival() => Icons.inventory_2_outlined,
                    BikeInstallation() => Bike.iconData,
                    Uninstallation() || null => Icons.shelves,
                  },
                  size: 13,
                  color: switch (component?.latestInstallation) {
                    BikeInstallation(:final bikeId) when !bikes.containsKey(bikeId) => Theme.of(context).colorScheme.error,
                    _ => Theme.of(context).colorScheme.onSurfaceVariant,
                  },
                ),
                Flexible(
                  child: Text(
                    switch (component?.latestInstallation) {
                      Archival() => 'Archived',
                      BikeInstallation(:final bikeId) => bikes[bikeId]?.name ?? 'BIKE NOT FOUND',
                      Uninstallation() || null => 'Not installed',
                    },
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: switch (component?.latestInstallation) {
                        BikeInstallation(:final bikeId) when !bikes.containsKey(bikeId) => Theme.of(context).colorScheme.error,
                        _ => Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      },
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (taskRule.bikeId != null) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 2,
            children: [
              Icon(
                Bike.iconData, 
                size: 13,
                color: bikes.containsKey(taskRule.bikeId) ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.error,
              ),
              Flexible(
                child: Text(
                  bikes[taskRule.bikeId]?.name ?? "BIKE NOT FOUND",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: bikes.containsKey(taskRule.bikeId) ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8) : Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            spacing: 2,
            children: [
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
          ),
        ],
      ],
    );
  }

  static Widget priorityWidget(BuildContext context, {required TaskPriority priority}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 2,
      children: [
        Icon(Icons.traffic, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        Text(
          priority.label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  static Widget notesWidget(BuildContext context, {required String notes}) {
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
          child: NotesText(
            notes,
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  static Widget tagsWidget(BuildContext context, {required Set<String> tags}) {
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: tags.map((tag) {
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

  /// Background revealed while swiping the card to the left.
  Widget _delaySwipeBackground(BuildContext context, {required TaskRule taskRule}) {
    final color = Theme.of(context).extension<ValueHighlightColors>()!.changed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0), // matches the card margin
      child: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Icon(Icons.history, size: 20, color: color),
            Text(
              taskRule.delay == null ? 'Add Delay' : 'Edit Delay',
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
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

    final component = taskRule.componentId != null
        ? appRepository.components[taskRule.componentId]
        : null;
    final statusColor = status.type.getStatusColor(context);
    final defaultCardColor = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surfaceContainerLow;

    final canSetDelay = !isCompleted && canQuickEditTaskDelay(taskRule, appSettings);
    final resolvedHeroTag = heroTag ?? 'task-rule-card-${taskRule.id}';

    final card = Opacity(
      opacity: isCompleted && !selected ? 0.5 : 1,
      child: TweenAnimationBuilder<Color?>(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        tween: ColorTween(
          begin: defaultCardColor,
          end: selected ? Theme.of(context).colorScheme.primaryContainer : defaultCardColor,
        ),
        builder: (context, color, child) => Card(
        color: color,
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        clipBehavior: Clip.antiAlias, // Borderradius for InkWell,
        child: ListTile(
          leading: Checkbox(
            value: isCompleted,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onChanged: isCompleted || (selectionMode && (!selected || onSelectedTaskRulesCompleted == null))
                ? null
                : (bool? value) async {
                    unawaited(HapticFeedback.lightImpact());
                    if (selectionMode) {
                      onSelectedTaskRulesCompleted!();
                      return;
                    }
                    await TaskActions.addTaskEntry(
                      context,
                      taskRule: taskRule,
                      heroTag: resolvedHeroTag,
                    );
                  },
          ),
          contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          minTileHeight: 0,
          onTap: selectionMode
              ? onSelectionChanged
              : () async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TaskRuleDetailsPage(
                            taskRuleId: taskRuleId,
                            heroTag: resolvedHeroTag,
                          ),
                    ),
                  );
                },
          onLongPress: onSelectionChanged,
          titleAlignment: ListTileTitleAlignment.top,
          title: Text(
            taskRule.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              decorationThickness: 2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              filterWidget(
                context,
                taskRule: taskRule,
                component: component,
                bikes: appRepository.bikes,
              ),
              if (appSettings.enableTaskPriority)
                priorityWidget(context, priority: taskRule.priority),
              if (appSettings.enableTaskTags && taskRule.tags.isNotEmpty)
                tagsWidget(context, tags: taskRule.tags),
              if (taskRule.notes != null && taskRule.notes!.isNotEmpty)
                notesWidget(context, notes: taskRule.notes!),
              if (taskRule.interval != null)
                TaskIntervalText(
                  interval: taskRule.interval!,
                  delay: taskRule.delay,
                  repeat: taskRule.repeat,
                ),
              if (!isCompleted && taskRule.interval != null) ...[
                const SizedBox(height: 8),
                TaskRuleProgressBar(
                  interval: taskRule.interval!,
                  delay: taskRule.delay,
                  progress: status.progress,
                  statusColor: statusColor,
                ),
              ],
            ],
          ),
          trailing: selectionMode ? null : PopupMenuButton<_TaskRuleOptions>(
            onSelected: (_TaskRuleOptions value) async {
              switch (value) {
                case _TaskRuleOptions.edit:
                  await TaskActions.editTaskRule(context, taskRule: taskRule);
                case _TaskRuleOptions.remove:
                  await TaskActions.removeTaskRules(context, taskRuleIds: [taskRule.id]);
                case _TaskRuleOptions.duplicate:
                  await TaskActions.duplicateTaskRule(
                    context,
                    taskRule: taskRule,
                  );
                case _TaskRuleOptions.setDelay:
                  await TaskActions.setTaskDelay(context, taskRule: taskRule);
              }
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<_TaskRuleOptions>>[
                  const PopupMenuItem<_TaskRuleOptions>(
                    value: _TaskRuleOptions.edit,
                    child: Row(
                      spacing: 10,
                      children: [Icon(Icons.edit, size: 20), Text('Edit')],
                    ),
                  ),
                  if (canSetDelay)
                    PopupMenuItem<_TaskRuleOptions>(
                      value: _TaskRuleOptions.setDelay,
                      child: Row(
                        spacing: 10,
                        children: [
                          const Icon(Icons.history, size: 20),
                          Text(
                            taskRule.delay == null ? 'Add Delay' : 'Edit Delay',
                          ),
                        ],
                      ),
                    ),
                  const PopupMenuItem<_TaskRuleOptions>(
                    value: _TaskRuleOptions.duplicate,
                    child: Row(
                      spacing: 10,
                      children: [Icon(Icons.copy, size: 20), Text('Duplicate')],
                    ),
                  ),
                  const PopupMenuItem<_TaskRuleOptions>(
                    value: _TaskRuleOptions.remove,
                    child: Row(
                      spacing: 10,
                      children: [Icon(Icons.delete, size: 20), Text('Remove')],
                    ),
                  ),
                ],
          ),
        ),
      ),
      ),
    );

    // Wrap the outermost widget in the Hero so the whole thing — including the
    // orange swipe background — lifts out together during the flight. If the
    // Hero wrapped only the card, the flight would leave a gap that reveals the
    // orange background sitting behind it.
    Widget wrapInHero(Widget child) => Hero(tag: resolvedHeroTag, child: child);

    if (!canSetDelay || selectionMode) return wrapInHero(card);

    // The orange sits behind the card rather than in Dismissible's `background`,
    // which clips to the revealed strip and leaves a gap at the card's corners.
    return wrapInHero(
      Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: _delaySwipeBackground(context, taskRule: taskRule),
            ),
          ),
          Dismissible(
            key: ValueKey('task-rule-swipe-${taskRule.id}'),
            direction: DismissDirection.endToStart,
            dismissThresholds: const {DismissDirection.endToStart: 0.3},
            onUpdate: (DismissUpdateDetails details) {
              if (details.reached && !details.previousReached) {
                unawaited(HapticFeedback.lightImpact());
              }
            },
            // The card always springs back — the swipe is a shortcut to the sheet,
            // not a destructive action.
            confirmDismiss: (_) async {
              unawaited(TaskActions.setTaskDelay(context, taskRule: taskRule));
              return false;
            },
            child: card,
          ),
        ],
      ),
    );
  }
}

/// Whether the unit reads as plural for the value actually shown.
bool _isPlural(TaskThreshold threshold) => switch (threshold) {
  DurationThreshold(:final days) => days.inDays != 1,
  ActivityCountThreshold(:final count) => count != 1,
  _ => true,
};

/// The interval and its delay added up: the target this cycle really runs to,
/// and the one the progress bar measures against. Null when the two cannot be
/// added — a deadline, or a delay of another kind.
TaskThreshold? _combined(TaskThreshold interval, TaskThreshold delay) => switch ((interval, delay)) {
  (DistanceThreshold(:final meters), DistanceThreshold(meters: final extra)) =>
    DistanceThreshold(meters + extra),
  (ElevationThreshold(:final meters), ElevationThreshold(meters: final extra)) =>
    ElevationThreshold(meters + extra),
  (MovingTimeThreshold(:final hours), MovingTimeThreshold(hours: final extra)) =>
    MovingTimeThreshold(hours + extra),
  (ElapsedTimeThreshold(:final hours), ElapsedTimeThreshold(hours: final extra)) =>
    ElapsedTimeThreshold(hours + extra),
  (DurationThreshold(:final days), DurationThreshold(days: final extra)) =>
    DurationThreshold(days + extra),
  (ActivityCountThreshold(:final count), ActivityCountThreshold(count: final extra)) =>
    ActivityCountThreshold(count + extra),
  (KilojoulesThreshold(:final kilojoules), KilojoulesThreshold(kilojoules: final extra)) =>
    KilojoulesThreshold(kilojoules + extra),
  _ => null,
};

/// A threshold's display value split into its number and its unit, so an
/// interval and a delay of the same kind can share a single unit. Null for a
/// threshold whose value is not a plain number, i.e. a deadline.
({String number, String unit})? _thresholdParts(
  TaskThreshold threshold,
  AppSettings appSettings, {
  required bool plural,
}) {
  final fmt = NumberFormat.decimalPattern();
  return switch (threshold) {
    DistanceThreshold(:final meters) => (
      number: NumberFormat('#,##0.#')
          .format(AppSettings.convertDistanceFromMeters(meters, appSettings.distanceUnit)!),
      unit: appSettings.distanceUnit,
    ),
    ElevationThreshold(:final meters) => (
      number: fmt.format(AppSettings.convertElevationFromMeters(meters, appSettings.altitudeUnit)!.round()),
      unit: appSettings.altitudeUnit,
    ),
    MovingTimeThreshold(:final hours) ||
    ElapsedTimeThreshold(:final hours) => (number: fmt.format(hours.inHours), unit: 'h'),
    DurationThreshold(:final days) => (number: fmt.format(days.inDays), unit: plural ? 'days' : 'day'),
    ActivityCountThreshold(:final count) => (number: fmt.format(count), unit: plural ? 'rides' : 'ride'),
    KilojoulesThreshold(:final kilojoules) => (number: fmt.format(kilojoules.round()), unit: 'kJ'),
    DateTimeThreshold() => null,
  };
}

/// The interval a task rule runs on. A delay of the same kind supersedes it —
/// "Every 1̶0̶ 22 rides" — so the number that governs this cycle is the one that
/// stands out, and it is the very number the progress bar measures against.
/// The struck-through original stays readable, and matches the card title's own
/// line-through for a rule that no longer applies.
///
/// A delay that cannot be added to the interval — a deadline, or a delay of
/// another kind, both only reachable from legacy data — keeps a chip of its own.
class TaskIntervalText extends StatelessWidget {
  final TaskThreshold interval;
  final TaskThreshold? delay;
  final bool repeat;

  const TaskIntervalText({
    super.key,
    required this.interval,
    required this.delay,
    required this.repeat,
  });

  Widget _chip(BuildContext context, {required IconData icon, required Color iconColor, required Widget label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        Icon(icon, size: 13, color: iconColor),
        Flexible(child: label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
    final delayColor = Theme.of(context).extension<ValueHighlightColors>()!.changed;
    final prefix = repeat ? 'Every ' : 'After ';
    final activeDelay = delay != null && delay!.isPositive ? delay : null;

    final combined = activeDelay == null ? null : _combined(interval, activeDelay);
    final plural = _isPlural(combined ?? interval);
    final originalParts = combined == null ? null : _thresholdParts(interval, appSettings, plural: plural);
    final combinedParts = combined == null ? null : _thresholdParts(combined, appSettings, plural: plural);

    if (originalParts != null && combinedParts != null) {
      return _chip(
        context,
        icon: interval.iconData,
        iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
        label: Text.rich(
          TextSpan(
            text: prefix,
            children: [
              TextSpan(
                text: originalParts.number,
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  decorationColor: mutedColor,
                  decorationThickness: 1.5,
                ),
              ),
              TextSpan(text: ' ${combinedParts.number}', style: TextStyle(color: delayColor)),
              TextSpan(text: ' ${combinedParts.unit}'),
            ],
          ),
          style: TextStyle(color: mutedColor, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final intervalChip = _chip(
      context,
      icon: interval.iconData,
      iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
      label: Text(
        '$prefix${interval.toDisplayValue(distanceUnit: appSettings.distanceUnit, altitudeUnit: appSettings.altitudeUnit, dateFormat: appSettings.dateFormat)}',
        style: TextStyle(color: mutedColor, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    if (activeDelay == null) return intervalChip;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Flexible(child: intervalChip),
        Flexible(
          child: _chip(
            context,
            icon: Icons.history,
            iconColor: delayColor,
            label: Text(
              '+${activeDelay.toDisplayValue(distanceUnit: appSettings.distanceUnit, altitudeUnit: appSettings.altitudeUnit, dateFormat: appSettings.dateFormat)}',
              style: TextStyle(color: delayColor, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

enum _TaskRuleOptions { edit, duplicate, remove, setDelay }
