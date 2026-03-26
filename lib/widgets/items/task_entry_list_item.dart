import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../repositories/app_repository.dart';
import '../../utils/task_actions.dart';

class TaskEntryListItem extends StatelessWidget {
  final String taskEntryId;

  const TaskEntryListItem({super.key, required this.taskEntryId});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final taskEntry = appRepository.taskEntries[taskEntryId];
    if (taskEntry == null) return const SizedBox.shrink();

    final taskRules = appRepository.taskRules;

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
        ],
      ),
      contentPadding: const EdgeInsets.only(left: 16, right: 16),
      trailing: PopupMenuButton<_TaskEntryListCardPopupMenuButtonOptions>(
        onSelected: (_TaskEntryListCardPopupMenuButtonOptions value) {
          switch (value) {
            case _TaskEntryListCardPopupMenuButtonOptions.edit:
              TaskActions.editTaskEntry(context, taskEntry: taskEntry);
            case _TaskEntryListCardPopupMenuButtonOptions.remove:
              TaskActions.removeTaskEntry(context, taskEntry: taskEntry);
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
    );
  }
}

enum _TaskEntryListCardPopupMenuButtonOptions {
  edit,
  remove,
}
