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

class TaskEntryListItem extends StatefulWidget {
  final String taskEntryId;
  final ComponentStats? previousSnapshot;
  final VoidCallback? onTap;

  const TaskEntryListItem({
    super.key,
    required this.taskEntryId,
    this.previousSnapshot,
    this.onTap,
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

    return ListTile(
      titleAlignment: ListTileTitleAlignment.top,
      title: Text(taskEntry.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 2,
                children: [
                  Icon(Icons.calendar_month, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  Text(
                    DateFormat(appSettings.dateFormat).format(taskEntry.dateTimeLocal),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 2,
                children: [
                  Icon(Icons.access_time, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  Flexible(
                    child: Text(
                      DateFormat(appSettings.timeFormat).format(taskEntry.dateTimeLocal),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 2,
            children: [
              Icon(
                Icons.check_box_outlined,
                size: 12, 
                color: taskRules.containsKey(taskEntry.taskRule) 
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.error,
              ),
              Flexible(
                child: Text(
                  taskRules[taskEntry.taskRule]?.name ?? "TASK NOT FOUND",
                  style: TextStyle(
                    color: taskRules.containsKey(taskEntry.taskRule)
                        ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                        : Theme.of(context).colorScheme.error, 
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          if (taskRules.containsKey(taskEntry.taskRule) && (taskEntry.componentId != taskRules[taskEntry.taskRule]!.componentId || taskEntry.bikeId != taskRules[taskEntry.taskRule]!.bikeId))
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 2,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 12, 
                  color: Theme.of(context).colorScheme.error,
                ),
                Flexible(
                  child: Text(
                    "Linked to $entryContextName",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error, 
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          if (taskEntry.notes != null && taskEntry.notes!.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3), // tweak to match font size
                  child: Icon(
                    Icons.notes,
                    size: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    taskEntry.notes!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          if (appSettings.enableStrava && subscriptionService.hasStravaEntitlement && taskEntry.snapshot != null && taskRules.containsKey(taskEntry.taskRule) && (taskEntry.componentId != null || taskEntry.bikeId != null)) ...[
            const SizedBox(height: 4),
            Builder(
              builder: (context) {
                final isInitial = widget.previousSnapshot == null;
                final effectivePrevious = widget.previousSnapshot ?? ComponentStats.zero();
                final delta = taskEntry.snapshot! - effectivePrevious;
                final stats = (!isInitial && !_showDelta) ? taskEntry.snapshot! : delta;
                final label = (!isInitial && !_showDelta) ? "Σ" : (isInitial ? "Σ" : "+");

                return GestureDetector(
                  onTap: isInitial ? null : () async {
                    setState(() => _showDelta = !_showDelta);
                    unawaited(HapticFeedback.selectionClick());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
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
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        _buildStatItem(context, Icons.route, '${NumberFormat.decimalPattern().format(AppSettings.convertDistanceFromMeters(stats.distance, appSettings.distanceUnit)!.round())} ${appSettings.distanceUnit}'),
                        _buildStatItem(context, Icons.terrain, '${NumberFormat.decimalPattern().format(AppSettings.convertElevationFromMeters(stats.elevationGain, appSettings.altitudeUnit)!.round())} ${appSettings.altitudeUnit}'),
                        _buildStatItem(context, Icons.timer, '${NumberFormat.decimalPattern().format(stats.movingTime.inHours)}h ${stats.movingTime.inMinutes.remainder(60)}m'),
                        _buildStatItem(context, Icons.repeat, NumberFormat.decimalPattern().format(stats.activityCount)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
      contentPadding: const EdgeInsets.only(left: 16, right: 16),
      trailing: PopupMenuButton<_TaskEntryListCardPopupMenuButtonOptions>(
        onSelected: (_TaskEntryListCardPopupMenuButtonOptions value) async {
          switch (value) {
            case _TaskEntryListCardPopupMenuButtonOptions.edit:
              await TaskActions.editTaskEntry(context, taskEntry: taskEntry);
            case _TaskEntryListCardPopupMenuButtonOptions.remove:
              await TaskActions.removeTaskEntry(context, taskEntry: taskEntry);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<_TaskEntryListCardPopupMenuButtonOptions>>[
          const PopupMenuItem<_TaskEntryListCardPopupMenuButtonOptions>(
            value: _TaskEntryListCardPopupMenuButtonOptions.edit,
            child: Row(
              spacing: 10,
              children: [
                Icon(Icons.edit, size: 20),
                Text('Edit'),
              ],
            )
          ),
          const PopupMenuItem<_TaskEntryListCardPopupMenuButtonOptions>(
            value: _TaskEntryListCardPopupMenuButtonOptions.remove,
            child: Row(
              spacing: 10,
              children: [
                Icon(Icons.delete, size: 20),
                Text('Remove'),
              ],
            )
          ),
        ],
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      onTap: widget.onTap,
    );
  }
}

enum _TaskEntryListCardPopupMenuButtonOptions {
  edit,
  remove,
}
