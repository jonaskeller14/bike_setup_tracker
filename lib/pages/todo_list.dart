import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/app_repository.dart';
import '../models/todo_rule.dart';
import '../models/todo_entry.dart';
import 'todo_page.dart';
import 'package:uuid/uuid.dart';

class TodoList extends StatelessWidget {
  const TodoList({super.key});

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final todoRules = appRepository.filteredTodoRules.values.toList();
    final todoEntries = appRepository.filteredTodoEntries.values.toList();


    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos (Debug)'),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Todo Rules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: todoRules.length,
                    itemBuilder: (context, index) {
                      final rule = todoRules[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          title: Text(rule.name),
                          subtitle: Text('Priority: ${rule.priority.label}${rule.notes != null ? '\n${rule.notes}' : ''}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check),
                                tooltip: 'Complete Todo',
                                onPressed: () {
                                  // Add an entry for this rule
                                  appRepository.addTodoEntry(TodoEntry(
                                    id: const Uuid().v4(),
                                    isDeleted: false,
                                    lastModified: DateTime.now().toUtc(),
                                    name: rule.name,
                                    notes: rule.notes,
                                    dateTimeUTC: DateTime.now().toUtc(),
                                    dateTimeLocal: DateTime.now(),
                                    todoRule: rule.id,
                                  ));
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Edit Rule',
                                onPressed: () async {
                                  final edited = await Navigator.push<TodoRule>(
                                    context,
                                    MaterialPageRoute(builder: (context) => TodoPage.edit(todoRule: rule)),
                                  );
                                  if (edited != null) appRepository.editTodoRule(edited);
                                }
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Delete Rule',
                                onPressed: () {
                                  appRepository.removeTodoRules([rule]);
                                }
                              ),
                            ],
                          )
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Todo Entries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: todoEntries.length,
                    itemBuilder: (context, index) {
                      final entry = todoEntries[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          title: Text(entry.name),
                          subtitle: Text(entry.dateTimeLocal.toString()),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: 'Delete Entry',
                            onPressed: () {
                              appRepository.removeTodoEntries([entry]);
                            }
                          )
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newRule = await Navigator.push<TodoRule>(
            context,
            MaterialPageRoute(builder: (context) => TodoPage.add()),
          );
          if (newRule != null) {
            appRepository.addTodoRule(newRule);
          }
        },
        tooltip: 'Add Todo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
