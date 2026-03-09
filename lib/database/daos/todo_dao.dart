import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/todo_rules.dart';
import '../tables/todo_entries.dart';

part 'todo_dao.g.dart';

@DriftAccessor(tables: [TodoRules, TodoEntries])
class TodoDao extends DatabaseAccessor<AppDatabase> with _$TodoDaoMixin {
  TodoDao(super.db);

  Stream<List<TodoRuleDb>> watchAllRules() => (select(todoRules)..where((t) => t.isDeleted.equals(false))).watch();

  Stream<List<TodoEntryDb>> watchEntriesForRule(String ruleId) {
    return (select(todoEntries)
          ..where((t) => t.todoRule.equals(ruleId))
          ..orderBy([(t) => OrderingTerm(expression: t.dateTimeUTC, mode: OrderingMode.desc)]))
        .watch();
  }

  Stream<List<TodoEntryDb>> watchAllEntries() => (select(todoEntries)..where((t) => t.isDeleted.equals(false))).watch();

  Future<int> insertRule(TodoRulesCompanion entry) => into(todoRules).insert(entry);
  Future updateRule(TodoRulesCompanion entry) => update(todoRules).replace(entry);
  Future deleteRule(String id) => (update(todoRules)..where((t) => t.id.equals(id))).write(TodoRulesCompanion(isDeleted: const Value(true), lastModified: Value(DateTime.now().toUtc())));
  
  Future<int> insertEntry(TodoEntriesCompanion entry) => into(todoEntries).insert(entry);
  Future updateEntry(TodoEntriesCompanion entry) => update(todoEntries).replace(entry);
  Future deleteEntry(String id) => (update(todoEntries)..where((t) => t.id.equals(id))).write(TodoEntriesCompanion(isDeleted: const Value(true), lastModified: Value(DateTime.now().toUtc())));
}
