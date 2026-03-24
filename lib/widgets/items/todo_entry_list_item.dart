import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../repositories/app_repository.dart';
import '../../utils/todo_actions.dart';

class TodoEntryListItem extends StatelessWidget {
  final String todoEntryId;

  const TodoEntryListItem({super.key, required this.todoEntryId});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final todoEntry = appRepository.todoEntries[todoEntryId];
    if (todoEntry == null) return const SizedBox.shrink();

    final todoRules = appRepository.todoRules;

    return ListTile(
      titleAlignment: ListTileTitleAlignment.top,
      title: Text(todoEntry.name),
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
                    DateFormat(appSettings.dateFormat).format(todoEntry.dateTimeLocal),
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
                      DateFormat(appSettings.timeFormat).format(todoEntry.dateTimeLocal),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
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
                    color: todoRules.containsKey(todoEntry.todoRule) 
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.error,
                  ),
                  Flexible(
                    child: Text(
                      todoRules[todoEntry.todoRule]?.name ?? "TODO NOT FOUND",
                      style: TextStyle(
                        color: todoRules.containsKey(todoEntry.todoRule)
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
            ],
          ),
          if (todoEntry.notes != null && todoEntry.notes!.isNotEmpty)
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
                    todoEntry.notes!,
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
      trailing: PopupMenuButton<_TodoEntryListCardPopupMenuButtonOptions>(
        onSelected: (_TodoEntryListCardPopupMenuButtonOptions value) {
          switch (value) {
            case _TodoEntryListCardPopupMenuButtonOptions.edit:
              TodoActions.editTodoEntry(context, todoEntry: todoEntry);
            case _TodoEntryListCardPopupMenuButtonOptions.remove:
              TodoActions.removeTodoEntry(context, todoEntry: todoEntry);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<_TodoEntryListCardPopupMenuButtonOptions>>[
          const PopupMenuItem<_TodoEntryListCardPopupMenuButtonOptions>(
            value: _TodoEntryListCardPopupMenuButtonOptions.edit,
            child: Row(
              spacing: 10,
              children: [
                Icon(Icons.edit, size: 20),
                Text('Edit'),
              ],
            )
          ),
          const PopupMenuItem<_TodoEntryListCardPopupMenuButtonOptions>(
            value: _TodoEntryListCardPopupMenuButtonOptions.remove,
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

enum _TodoEntryListCardPopupMenuButtonOptions {
  edit,
  remove,
}
