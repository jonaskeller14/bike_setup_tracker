import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task/task_entry.dart';
import '../models/task/task_rule.dart';
import '../pages/task_entry_page.dart';
import '../pages/task_rule_page.dart';
import '../repositories/app_repository.dart';
import '../widgets/app_snackbar.dart';
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
    final messenger = ScaffoldMessenger.of(context);

    final editedRule = await Navigator.push<TaskRule>(
      context,
      MaterialPageRoute(builder: (context) => TaskRulePage.edit(taskRule: taskRule)),
    );
    if (editedRule == null) return;

    await appRepository.editTaskRule(editedRule);

    if (editedRule.name == taskRule.name) return;

    final renamedEntries = [
      ...appRepository.taskEntries.values,
      ...appRepository.deletedTaskEntries,
    ].where((entry) => entry.taskRule == taskRule.id && entry.name.startsWith(taskRule.name)).toList();
    if (renamedEntries.isEmpty) return;

    await appRepository.editTaskEntry(
      renamedEntries.map(
        (entry) => entry.copyWith(
          name: '${editedRule.name}${entry.name.substring(taskRule.name.length)}',
        ),
      ),
    );

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.success(
        context,
        Intl.plural(
          renamedEntries.length,
          one: 'Renamed 1 corresponding Task Entry.',
          other: 'Renamed ${renamedEntries.length} corresponding Task Entries.',
        ),
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.editTaskEntry(renamedEntries),
        ),
      ),
    );
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

  static Future<void> removeTaskRules(BuildContext context, {required Iterable<String> taskRuleIds}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final taskRules = taskRuleIds.map((id) => appRepository.taskRules[id]).whereType<TaskRule>().toList();
    if (taskRules.isEmpty) return;

    final taskRuleIdsToRemove = taskRules.map((rule) => rule.id).toSet();
    final obsoleteTaskEntries = appRepository.taskEntries.values
        .where((entry) => taskRuleIdsToRemove.contains(entry.taskRule))
        .toList();

    await appRepository.removeTaskRules(taskRules);
    await appRepository.removeTaskEntries(obsoleteTaskEntries);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        Intl.plural(
          taskRules.length,
          one: "Task '${taskRules[0].name}' and corresponding entries moved to trash.",
          other: '${taskRules.length} Tasks and corresponding entries moved to trash.',
        ),
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await appRepository.restoreTaskRules(taskRules);
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

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        "Task '${taskRule.name}' restored from trash.",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await appRepository.removeTaskRules([taskRule]);
          },
        ),
      ),
    );
  }

  static Future<void> addTaskEntry(BuildContext context, {required TaskRule taskRule}) async {
    final appRepository = context.read<AppRepository>();

    final newEntry = await Navigator.push<TaskEntry>(
      context,
      MaterialPageRoute(builder: (context) => TaskEntryPage.add(taskRule: taskRule)),
    );
    if (newEntry == null) return;

    await appRepository.addTaskEntries([newEntry]);
  }

  static Future<void> addDefaultTaskEntries(BuildContext context, {required Iterable<String> taskRuleIds}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final taskRules = taskRuleIds
        .map((id) => appRepository.taskRules[id])
        .whereType<TaskRule>()
        .where((taskRule) => appRepository.getTaskRuleStatus(taskRule).type != TaskStatusType.completed)
        .toList();
    if (taskRules.isEmpty) return;

    final dateTimeLocal = DateTime.now();
    final dateTimeUTC = dateTimeLocal.toUtc();
    final taskEntries = await Future.wait(
      taskRules.map((taskRule) async {
        final snapshot = await appRepository.getStatsAt(
          componentId: taskRule.componentId,
          bikeId: taskRule.bikeId,
          date: dateTimeUTC,
        );
        return TaskEntry(
          name: taskRule.name,
          notes: null,
          dateTimeUTC: dateTimeUTC,
          dateTimeLocal: dateTimeLocal,
          taskRule: taskRule.id,
          componentId: taskRule.componentId,
          bikeId: taskRule.bikeId,
          snapshot: snapshot,
        );
      }),
    );

    await appRepository.addTaskEntries(taskEntries);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.success(
        context,
        Intl.plural(
          taskEntries.length,
          one: "Task '${taskRules[0].name}' completed.",
          other: '${taskEntries.length} Tasks completed.',
        ),
        duration: const Duration(seconds: 3),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.removeTaskEntries(taskEntries),
        ),
      ),
    );
  }

  static Future<void> editTaskEntry(BuildContext context, {required TaskEntry taskEntry}) async {
    final appRepository = context.read<AppRepository>();
    final taskRule = appRepository.taskRules[taskEntry.taskRule];
    if (taskRule == null) return;

    final editedEntry = await Navigator.push<TaskEntry>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskEntryPage.edit(taskEntry: taskEntry, taskRule: taskRule),
      ),
    );
    if (editedEntry == null) return;

    await appRepository.editTaskEntry([editedEntry]);
  }

  static Future<void> duplicateTaskEntry(BuildContext context, {required TaskEntry taskEntry}) async {
    final appRepository = context.read<AppRepository>();
    final taskRule = appRepository.taskRules[taskEntry.taskRule];
    if (taskRule == null) return;

    final newEntry = await Navigator.push<TaskEntry>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskEntryPage.duplicate(taskEntry: taskEntry, taskRule: taskRule),
      ),
    );
    if (newEntry == null) return;

    await appRepository.addTaskEntries([newEntry]);
  }

  static Future<void> removeTaskEntry(BuildContext context, {required TaskEntry taskEntry}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    await appRepository.removeTaskEntries([taskEntry]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        "Task Entry '${taskEntry.name}' moved to trash.",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.restoreTaskEntries([taskEntry]),
        ),
      ),
    );
  }

  static Future<void> removeTaskEntries(BuildContext context, {required Iterable<String> taskEntryIds}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final taskEntries = taskEntryIds.map((teId) => appRepository.taskEntries[teId]).whereType<TaskEntry>().toList();
    if (taskEntries.isEmpty) return;
    await appRepository.removeTaskEntries(taskEntries);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        Intl.plural(
          taskEntries.length,
          one: "Task Entry '${taskEntries[0].name}' moved to trash.",
          other: "${taskEntries.length} Task Entries moved to trash.",
        ),
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.restoreTaskEntries(taskEntries),
        ),
      ),
    );
  }

  static Future<void> restoreTaskEntry(BuildContext context, {required TaskEntry taskEntry}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    await appRepository.restoreTaskEntries([taskEntry]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        "Task Entry '${taskEntry.name}' restored from trash.",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.removeTaskEntries([taskEntry]),
        ),
      ),
    );
  }
}
