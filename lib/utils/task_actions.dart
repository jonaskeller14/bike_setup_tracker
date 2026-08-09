import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task/task_entry.dart';
import '../models/task/task_rule.dart';
import '../pages/task_entry_page.dart';
import '../pages/task_rule_page.dart';
import '../repositories/app_repository.dart';
import '../widgets/sheets/set_task_delay.dart';

class TaskActions {
  static Future<void> addTaskRule(BuildContext context) async {
    final appRepository = context.read<AppRepository>();

    final newRule = await Navigator.push<TaskRule>(
      context,
      MaterialPageRoute(builder: (context) => TaskRulePage.add()),
    );
    if (newRule == null) return;

    await appRepository.addTaskRule(newRule);
  }

  static Future<void> editTaskRule(BuildContext context, {required TaskRule taskRule}) async {
    final appRepository = context.read<AppRepository>();

    final editedRule = await Navigator.push<TaskRule>(
      context,
      MaterialPageRoute(builder: (context) => TaskRulePage.edit(taskRule: taskRule)),
    );
    if (editedRule == null) return;

    await appRepository.editTaskRule(editedRule);
  }

  static Future<void> setTaskDelay(BuildContext context, {required TaskRule taskRule}) async {
    final appRepository = context.read<AppRepository>();

    final updatedRule = await showSetTaskDelaySheet(context: context, taskRule: taskRule);
    if (updatedRule == null) return;

    await appRepository.editTaskRule(updatedRule);
  }

  static Future<void> duplicateTaskRule(BuildContext context, {required TaskRule taskRule}) async {
    final appRepository = context.read<AppRepository>();

    final newRule = await Navigator.push<TaskRule>(
      context,
      MaterialPageRoute(builder: (context) => TaskRulePage.duplicate(taskRule: taskRule.deepCopy())),
    );
    if (newRule == null) return;

    await appRepository.addTaskRule(newRule);
  }

  static Future<void> removeTaskRule(BuildContext context, {required TaskRule taskRule}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final obsoleteTaskEntries = appRepository.taskEntries.values.where((te) => te.taskRule == taskRule.id).toList();

    await appRepository.removeTaskRules([taskRule]);
    await appRepository.removeTaskEntries(obsoleteTaskEntries);

    messenger.showSnackBar(
      SnackBar(
        content: Text("Task '${taskRule.name}' and corresponding entries moved to trash."),
        duration: const Duration(seconds: 5),
        persist: false,
        showCloseIcon: true,
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await appRepository.restoreTaskRules([taskRule]);
            await appRepository.restoreTaskEntries(obsoleteTaskEntries);
          },
        ),
      ),
    );
  }

  static Future<void> restoreTaskRule(BuildContext context, {required TaskRule taskRule}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    
    await appRepository.restoreTaskRules([taskRule]);

    messenger.showSnackBar(SnackBar(
      content: Text("Task '${taskRule.name}' restored from trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async {
          await appRepository.removeTaskRules([taskRule]);
        },
      ),
    ));
  }

  static Future<void> addTaskEntry(BuildContext context, {required TaskRule taskRule}) async {
    final appRepository = context.read<AppRepository>();

    final newEntry = await Navigator.push<TaskEntry>(
      context,
      MaterialPageRoute(builder: (context) => TaskEntryPage.add(taskRule: taskRule)),
    );
    if (newEntry == null) return;

    await appRepository.addTaskEntry(newEntry);
  }

  static Future<void> editTaskEntry(BuildContext context, {required TaskEntry taskEntry}) async {
    final appRepository = context.read<AppRepository>();
    final taskRule = appRepository.taskRules[taskEntry.taskRule];
    if (taskRule == null) return;

    final editedEntry = await Navigator.push<TaskEntry>(
      context,
      MaterialPageRoute(builder: (context) => TaskEntryPage.edit(taskEntry: taskEntry, taskRule: taskRule)),
    );
    if (editedEntry == null) return;

    await appRepository.editTaskEntry(editedEntry);
  }

  static Future<void> duplicateTaskEntry(BuildContext context, {required TaskEntry taskEntry}) async {
    final appRepository = context.read<AppRepository>();
    final taskRule = appRepository.taskRules[taskEntry.taskRule];
    if (taskRule == null) return;

    final newEntry = await Navigator.push<TaskEntry>(
      context,
      MaterialPageRoute(builder: (context) => TaskEntryPage.duplicate(taskEntry: taskEntry, taskRule: taskRule)),
    );
    if (newEntry == null) return;

    await appRepository.addTaskEntry(newEntry);
  }

  static Future<void> removeTaskEntry(BuildContext context, {required TaskEntry taskEntry}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    await appRepository.removeTaskEntries([taskEntry]);

    messenger.showSnackBar(SnackBar(
      content: Text("Task Entry '${taskEntry.name}' moved to trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async => appRepository.restoreTaskEntries([taskEntry]),
      ),
    ));
  }

  static Future<void> removeTaskEntries(BuildContext context, {required Iterable<String> taskEntryIds}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final taskEntries = taskEntryIds
      .map((teId) => appRepository.taskEntries[teId])
      .whereType<TaskEntry>()
      .toList();
    if (taskEntries.isEmpty) return;
    await appRepository.removeTaskEntries(taskEntries);

    messenger.showSnackBar(SnackBar(
      content: Text(
        Intl.plural(
          taskEntries.length,
          one: "Task Entry '${taskEntries[0].name}' moved to trash.",
          other: "${taskEntries.length} Task Entries moved to trash.",
        ),
      ),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async => appRepository.restoreTaskEntries(taskEntries),
      ),
    ));
  }

  static Future<void> restoreTaskEntry(BuildContext context, {required TaskEntry taskEntry}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    await appRepository.restoreTaskEntries([taskEntry]);

    messenger.showSnackBar(SnackBar(
      content: Text("Task Entry '${taskEntry.name}' restored from trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async => appRepository.removeTaskEntries([taskEntry]),
      ),
    ));
  }
}
