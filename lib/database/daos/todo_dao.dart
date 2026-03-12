import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/todo_rules.dart';
import '../tables/todo_entries.dart';
import 'soft_delete_dao_mixin.dart';

part 'todo_dao.g.dart';

@DriftAccessor(tables: [TodoRules, TodoEntries])
class TodoDao extends DatabaseAccessor<AppDatabase> with _$TodoDaoMixin, SoftDeletableDaoMixin<TodoRules, TodoRuleDb, TodoRulesCompanion> {
  TodoDao(super.db);

  @override TableInfo<TodoRules, TodoRuleDb> get softDeletableTable => todoRules;
  @override Expression<bool> get isDeletedColumn => todoRules.isDeleted;
  @override Expression<String> get idColumn => todoRules.id;
  @override TodoRulesCompanion createSoftDeleteCompanion() => TodoRulesCompanion(isDeleted: const Value(true), lastModified: Value(DateTime.now().toUtc()));

  Stream<List<TodoRuleDb>> watchAllRules() => watchAllActive();

  Stream<List<TodoEntryDb>> watchEntriesForRule(String ruleId) {
    return (select(todoEntries)
          ..where((t) => t.todoRule.equals(ruleId))
          ..orderBy([(t) => OrderingTerm(expression: t.dateTimeUTC, mode: OrderingMode.desc)]))
        .watch();
  }

  Stream<List<TodoEntryDb>> watchAllEntries() => (select(todoEntries)..where((t) => t.isDeleted.equals(false))).watch();

  Future<List<TodoRuleDb>> getAllRulesBypass() => select(todoRules).get();
  Future<List<TodoEntryDb>> getAllEntriesBypass() => select(todoEntries).get();

  Future<int> insertRule(TodoRulesCompanion entry) => into(todoRules).insert(entry);
  Future updateRule(TodoRulesCompanion entry) => update(todoRules).replace(entry);
  Future<int> deleteRule(String id) => softDelete(id);
  
  Future<int> insertEntry(TodoEntriesCompanion entry) => into(todoEntries).insert(entry);
  Future updateEntry(TodoEntriesCompanion entry) => update(todoEntries).replace(entry);
  Future deleteEntry(String id) => (update(todoEntries)..where((t) => t.id.equals(id))).write(TodoEntriesCompanion(isDeleted: const Value(true), lastModified: Value(DateTime.now().toUtc())));
}
