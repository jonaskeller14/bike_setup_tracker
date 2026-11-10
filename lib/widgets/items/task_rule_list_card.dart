import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../l10n/task_threshold_text.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../models/component/component_ancestor.dart';
import '../../models/task/task_association.dart';
import '../../models/task/task_rule.dart';
import '../../models/task/task_threshold/task_threshold.dart';
import '../../pages/details/task_rule_details_page.dart';
import '../../repositories/app_repository.dart';
import '../../services/component_hierarchy_resolver.dart';
import '../../theme.dart';
import '../../utils/automation_ids.dart';
import '../../utils/task_actions.dart';
import '../component_ancestor_display.dart';
import '../notes_text.dart';
import '../sheets/set_task_delay.dart';
import '../task_priority_badge.dart';
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

  static Widget filterWidget(BuildContext context, {
    required TaskRule taskRule,
    required Component? component,
    required Map<String, Bike> bikes,
    required ComponentHierarchyResolver hierarchy,
  }) {
    final root = component == null ? const UninstalledAncestor() : hierarchy.currentRoot(component.id);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 8,
      children: [
        if (taskRule.association is ComponentTaskAssociation) ...[
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
                    component?.name ?? context.l10n.componentNotFound,
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
                  root.iconData,
                  size: 13,
                  color: root.isMissing(bikes) ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                Flexible(
                  child: Text(
                    root.label(bikes, context.l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: root.isMissing(bikes) ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (taskRule.association case BikeTaskAssociation(id: final bikeId)) ...[
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 2,
              children: [
                Icon(
                  Bike.iconData, 
                  size: 13,
                  color: bikes.containsKey(bikeId) ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.error,
                ),
                Flexible(
                  child: Text(
                    bikes[bikeId]?.name ?? context.l10n.bikeNotFound,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: bikes.containsKey(bikeId) ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8) : Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 2,
              children: [
                Icon(
                  Icons.circle_outlined, 
                  size: 13, 
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                Flexible(
                  child: Text(
                    context.l10n.taskGeneral,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static Widget notesWidget(BuildContext context, {required String notes}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
        Flexible(
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

  static Widget attachmentsWidget(BuildContext context, {required int count}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 2,
      children: [
        Icon(Icons.attach_file, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        Flexible(
          child: Text(
            '$count',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
          ),
        ),
      ],
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
            Flexible(
              child: Text(
                taskRule.delay == null ? context.l10n.taskDelayAdd : context.l10n.taskDelayEdit,
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
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

    final component = appRepository.components[taskRule.association.componentId];
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
          leading: Semantics(
            container: true,
            identifier: AutomationIds.taskRuleComplete(taskRuleId),
            child: Checkbox(
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
          title: Row(
            spacing: 6,
            children: [
              Flexible(
                child: Semantics(
                  identifier: AutomationIds.taskRuleTitle(taskRuleId),
                  child: Text(
                    taskRule.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      decorationThickness: 2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (appSettings.enableTaskPriority)
                TaskPriorityBadge(priority: taskRule.priority),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              filterWidget(
                context,
                taskRule: taskRule,
                component: component,
                bikes: appRepository.bikes,
                hierarchy: appRepository.componentHierarchy,
              ),
              if (appSettings.enableTaskTags && taskRule.tags.isNotEmpty)
                tagsWidget(context, tags: taskRule.tags),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  if (taskRule.notes != null && taskRule.notes!.isNotEmpty)
                    Flexible(child: notesWidget(context, notes: taskRule.notes!)),
                  if (appSettings.enableAttachments && taskRule.attachments.isNotEmpty)
                    attachmentsWidget(context, count: taskRule.attachments.length),
                ]
              ),
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
          trailing: PopupMenuButton<_TaskRuleOptions>(
            enabled: !selectionMode,
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
                  PopupMenuItem<_TaskRuleOptions>(
                    value: _TaskRuleOptions.edit,
                    child: Row(
                      spacing: 10,
                      children: [const Icon(Icons.edit, size: 20), Flexible(child: Text(context.l10n.edit))],
                    ),
                  ),
                  if (canSetDelay)
                    PopupMenuItem<_TaskRuleOptions>(
                      value: _TaskRuleOptions.setDelay,
                      child: Row(
                        spacing: 10,
                        children: [
                          const Icon(Icons.history, size: 20),
                          Flexible(
                            child: Text(
                              taskRule.delay == null ? context.l10n.taskDelayAdd : context.l10n.taskDelayEdit,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuItem<_TaskRuleOptions>(
                    value: _TaskRuleOptions.duplicate,
                    child: Row(
                      spacing: 10,
                      children: [const Icon(Icons.copy, size: 20), Flexible(child: Text(context.l10n.duplicate))],
                    ),
                  ),
                  PopupMenuItem<_TaskRuleOptions>(
                    value: _TaskRuleOptions.remove,
                    child: Row(
                      spacing: 10,
                      children: [const Icon(Icons.delete, size: 20), Flexible(child: Text(context.l10n.remove))],
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
  AppSettings appSettings,
  AppLocalizations l10n,
) {
  final fmt = NumberFormat.decimalPattern(l10n.localeName);
  return switch (threshold) {
    DistanceThreshold(:final meters) => (
      number: NumberFormat('#,##0.#', l10n.localeName)
          .format(AppSettings.convertDistanceFromMeters(meters, appSettings.distanceUnit)!),
      unit: appSettings.distanceUnit,
    ),
    ElevationThreshold(:final meters) => (
      number: fmt.format(AppSettings.convertElevationFromMeters(meters, appSettings.altitudeUnit)!.round()),
      unit: appSettings.altitudeUnit,
    ),
    MovingTimeThreshold(:final hours) ||
    ElapsedTimeThreshold(:final hours) => (number: fmt.format(hours.inHours), unit: 'h'),
    DurationThreshold(:final days) => (number: fmt.format(days.inDays), unit: l10n.taskUnitDays(days.inDays)),
    ActivityCountThreshold(:final count) => (number: fmt.format(count), unit: l10n.taskUnitRides(count)),
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

  /// A prefix and "1 day" read wrong in German (`Alle 1 Tag`), so a single unit has its own text.
  String? _everyOne(AppLocalizations l10n) => switch (interval) {
    DurationThreshold(:final days) when days.inDays == 1 => l10n.taskIntervalCardEveryDay,
    ActivityCountThreshold(count: 1) => l10n.taskIntervalCardEveryRide,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
    final delayColor = Theme.of(context).extension<ValueHighlightColors>()!.changed;
    final l10n = context.l10n;
    final prefix = repeat ? l10n.taskIntervalPrefixEvery : l10n.taskIntervalPrefixAfter;
    final activeDelay = switch (delay) {
      AccumulatingThreshold(:final isPullForward) when isPullForward => delay,
      final delay? when delay.isPositive => delay,
      _ => null,
    };

    final combined = activeDelay == null ? null : _combined(interval, activeDelay);
    // The unit follows the number that governs this cycle, so both numbers share it.
    final originalParts = combined == null ? null : _thresholdParts(interval, appSettings, l10n);
    final combinedParts = combined == null ? null : _thresholdParts(combined, appSettings, l10n);

    if (originalParts != null && combinedParts != null) {
      return _chip(
        context,
        icon: interval.iconData,
        iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
        label: Text.rich(
          TextSpan(
            text: '$prefix ',
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
        (repeat ? _everyOne(l10n) : null) ??
            '$prefix ${interval.toDisplayValue(l10n, distanceUnit: appSettings.distanceUnit, altitudeUnit: appSettings.altitudeUnit, dateFormat: appSettings.dateFormat)}',
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
              '+${activeDelay.toDisplayValue(l10n, distanceUnit: appSettings.distanceUnit, altitudeUnit: appSettings.altitudeUnit, dateFormat: appSettings.dateFormat)}',
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
