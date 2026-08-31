import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/component_stats.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../utils/task_actions.dart';
import '../notes_text.dart';

class TaskEntryListItem extends StatefulWidget {
  final String taskEntryId;
  final ComponentStats? previousSnapshot;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final bool selected;
  final bool showDate;
  final bool showTaskRule;
  final bool showStats;
  final String? heroTag;

  const TaskEntryListItem({
    super.key,
    required this.taskEntryId,
    this.previousSnapshot,
    this.onTap,
    this.onLongPress,
    this.selectionMode = false,
    this.selected = false,
    this.showDate = true,
    this.showTaskRule = true,
    this.showStats = false,
    this.heroTag,
  });

  @override
  State<TaskEntryListItem> createState() => _TaskEntryListItemState();
}

class _TaskEntryListItemState extends State<TaskEntryListItem> {
  bool _showDelta = true;

  Widget _buildStatItem(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        Icon(icon, size: 10, color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7)),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();
    final taskEntry = appRepository.taskEntries[widget.taskEntryId];
    if (taskEntry == null) return const SizedBox.shrink();

    final taskRules = appRepository.taskRules;

    final String entryContextName;
    if (taskEntry.componentId != null) {
      entryContextName = appRepository.components[taskEntry.componentId]?.name ?? "COMPONENT NOT FOUND";
    } else if (taskEntry.bikeId != null) {
      entryContextName = appRepository.bikes[taskEntry.bikeId]?.name ?? "BIKE NOT FOUND";
    } else {
      entryContextName = "General Task";
    }

    final taskRule = taskRules[taskEntry.taskRule];

    final dateText = DateFormat(appSettings.dateFormat).format(taskEntry.dateTimeLocal);
    final timeText = DateFormat(appSettings.timeFormat).format(taskEntry.dateTimeLocal);

    final showLinkWarning =
        taskRules.containsKey(taskEntry.taskRule) &&
        (taskEntry.componentId != taskRules[taskEntry.taskRule]!.componentId ||
            taskEntry.bikeId != taskRules[taskEntry.taskRule]!.bikeId);
    final hasNotes = taskEntry.notes != null && taskEntry.notes!.isNotEmpty;
    final resolvedShowStats =
        widget.showStats &&
        appSettings.enableStrava &&
        subscriptionService.hasStravaEntitlement &&
        taskEntry.snapshot != null &&
        taskRules.containsKey(taskEntry.taskRule) &&
        (taskEntry.componentId != null || taskEntry.bikeId != null);
    final hasBottomBlock = showLinkWarning || hasNotes || resolvedShowStats;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: widget.selected ? colorScheme.primaryContainer.withValues(alpha: 0.55) : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                selected: widget.selected,
                dense: true,
                visualDensity: VisualDensity.compact,
                titleAlignment: ListTileTitleAlignment.top,
                minLeadingWidth: 0,
                horizontalTitleGap: 8,
                minTileHeight: 0,
                minVerticalPadding: 0,
                contentPadding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: hasBottomBlock ? 4 : 8),
                leading: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    widget.selected ? Icons.check_box : Icons.check_box_outlined,
                    color: widget.selected ? colorScheme.primary : null,
                  ),
                ),
                title: Text(taskEntry.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          widget.showDate ? "$dateText • $timeText" : timeText,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        if (widget.showTaskRule)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 2,
                            children: [
                              Icon(
                                Icons.check_box_outline_blank,
                                size: 12,
                                color: taskRules.containsKey(taskEntry.taskRule)
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.error,
                              ),
                              Flexible(
                                child: Text(
                                  taskRule?.name ?? "TASK NOT FOUND",
                                  style: TextStyle(
                                    color: taskRules.containsKey(taskEntry.taskRule)
                                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                                        : colorScheme.error,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
                trailing: widget.selectionMode
                    ? null
                    : PopupMenuButton<_TaskEntryListCardPopupMenuButtonOptions>(
                        onSelected: (_TaskEntryListCardPopupMenuButtonOptions value) async {
                          switch (value) {
                            case _TaskEntryListCardPopupMenuButtonOptions.edit:
                              await TaskActions.editTaskEntry(
                                context,
                                taskEntry: taskEntry,
                                heroTag: widget.heroTag,
                              );
                            case _TaskEntryListCardPopupMenuButtonOptions.dupliate:
                              await TaskActions.duplicateTaskEntry(context, taskEntry: taskEntry);
                            case _TaskEntryListCardPopupMenuButtonOptions.remove:
                              await TaskActions.removeTaskEntry(context, taskEntry: taskEntry);
                          }
                        },
                        itemBuilder: (BuildContext context) => _TaskEntryListCardPopupMenuButtonOptions.values
                            .where(
                              (option) =>
                                  option != _TaskEntryListCardPopupMenuButtonOptions.dupliate ||
                                  (taskRule != null && (taskRule.interval != null && taskRule.repeat)),
                            )
                            .map(
                              (option) => PopupMenuItem<_TaskEntryListCardPopupMenuButtonOptions>(
                                value: option,
                                child: Row(
                                  spacing: 10,
                                  children: [
                                    Icon(option.iconData, size: 20),
                                    Text(option.label),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              if (hasBottomBlock)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showLinkWarning)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 2,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 12,
                              color: colorScheme.error,
                            ),
                            Flexible(
                              child: Text(
                                "Linked to $entryContextName",
                                style: TextStyle(
                                  color: colorScheme.error,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      if (hasNotes)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3), // tweak to match font size
                              child: Icon(
                                Icons.notes,
                                size: 12,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: NotesText(
                                taskEntry.notes!,
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      if (resolvedShowStats) ...[
                        const SizedBox(height: 4),
                        Builder(
                          builder: (context) {
                            final isInitial = widget.previousSnapshot == null;
                            final effectivePrevious = widget.previousSnapshot ?? ComponentStats.zero();
                            final delta = taskEntry.snapshot! - effectivePrevious;
                            final stats = (!isInitial && !_showDelta) ? taskEntry.snapshot! : delta;
                            final label = (!isInitial && !_showDelta) ? "Σ" : (isInitial ? "Σ" : "+");

                            return GestureDetector(
                              onTap: isInitial || widget.selectionMode
                                  ? null
                                  : () async {
                                      setState(() => _showDelta = !_showDelta);
                                      unawaited(HapticFeedback.selectionClick());
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 2,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    _buildStatItem(
                                      context,
                                      Icons.route,
                                      '${NumberFormat.decimalPattern().format(AppSettings.convertDistanceFromMeters(stats.distance, appSettings.distanceUnit)!.round())} ${appSettings.distanceUnit}',
                                    ),
                                    _buildStatItem(
                                      context,
                                      Icons.terrain,
                                      '${NumberFormat.decimalPattern().format(AppSettings.convertElevationFromMeters(stats.elevationGain, appSettings.altitudeUnit)!.round())} ${appSettings.altitudeUnit}',
                                    ),
                                    _buildStatItem(
                                      context,
                                      Icons.timer,
                                      '${NumberFormat.decimalPattern().format(stats.movingTime.inHours)}h ${stats.movingTime.inMinutes.remainder(60)}m',
                                    ),
                                    _buildStatItem(
                                      context,
                                      Icons.repeat,
                                      NumberFormat.decimalPattern().format(stats.activityCount),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
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

enum _TaskEntryListCardPopupMenuButtonOptions {
  edit("Edit", Icons.edit),
  dupliate("Duplicate", Icons.copy),
  remove("Remove", Icons.delete);

  final String label;
  final IconData iconData;
  const _TaskEntryListCardPopupMenuButtonOptions(this.label, this.iconData);
}
