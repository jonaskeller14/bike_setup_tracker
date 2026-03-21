import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo_entry.dart';
import '../pages/todo_entry_page.dart';
import '../repositories/app_repository.dart';
import '../models/todo_rule.dart';
import '../pages/todo_rule_page.dart';

class TodoActions {
  static Future<void> addTodoRule(BuildContext context) async {
    final appRepository = context.read<AppRepository>();

    final newRule = await Navigator.push<TodoRule>(
      context,
      MaterialPageRoute(builder: (context) => TodoRulePage.add()),
    );
    if (newRule == null) return;

    await appRepository.addTodoRule(newRule);
  }

  static Future<void> editTodoRule(BuildContext context, {required TodoRule todoRule}) async {
    final appRepository = context.read<AppRepository>();

    final editedRule = await Navigator.push<TodoRule>(
      context,
      MaterialPageRoute(builder: (context) => TodoRulePage.edit(todoRule: todoRule)),
    );
    if (editedRule == null) return;

    await appRepository.editTodoRule(editedRule);
  }

  static Future<void> removeTodoRule(BuildContext context, {required TodoRule todoRule}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    
    final obsoleteTodoEntries = appRepository.todoEntries.values.where((te) => te.todoRule == todoRule.id).toList();

    await appRepository.removeTodoRules([todoRule]);
    await appRepository.removeTodoEntries(obsoleteTodoEntries);

    messenger.showSnackBar(SnackBar(
      content: Text("Todo '${todoRule.name}' and corresponding entries moved to trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async {
          await appRepository.restoreTodoRules([todoRule]);
          await appRepository.restoreTodoEntries(obsoleteTodoEntries);
        },
      ),
    ));
  }

  static Future<void> addTodoEntry(BuildContext context, {required TodoRule todoRule}) async {
    final appRepository = context.read<AppRepository>();

    final newEntry = await Navigator.push<TodoEntry>(
      context,
      MaterialPageRoute(builder: (context) => TodoEntryPage.add(todoRule: todoRule)),
    );
    if (newEntry == null) return;

    await appRepository.addTodoEntry(newEntry);
  }

  static Future<void> editTodoEntry(BuildContext context, {required TodoEntry todoEntry}) async {
    final appRepository = context.read<AppRepository>();
    final todoRule = appRepository.todoRules[todoEntry.todoRule];
    if (todoRule == null) return;

    final editedTodoEntry = await Navigator.push<TodoEntry>(
      context,
      MaterialPageRoute(builder: (context) => TodoEntryPage.edit(todoEntry: todoEntry, todoRule: todoRule)),
    );
    if (editedTodoEntry == null) return;

    await appRepository.editTodoEntry(editedTodoEntry);
  }

  static Future<void> removeTodoEntry(BuildContext context, {required TodoEntry todoEntry}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    await appRepository.removeTodoEntries([todoEntry]);

    messenger.showSnackBar(SnackBar(
      content: Text("Todo Entry '${todoEntry.name}' moved to trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async => await appRepository.restoreTodoEntries([todoEntry]),
      ),
    ));
  }
}
