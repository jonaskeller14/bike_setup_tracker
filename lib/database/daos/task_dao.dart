import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/task_entries.dart';
import '../tables/task_rules.dart';
import 'soft_delete_dao_mixin.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [TaskRules, TaskEntries])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin, SoftDeletableDaoMixin<TaskRules, TaskRuleDb, TaskRulesCompanion> {
  TaskDao(super.db);

  @override TableInfo<TaskRules, TaskRuleDb> get softDeletableTable => taskRules;
  @override Expression<bool> get isDeletedColumn => taskRules.isDeleted;
  @override Expression<String> get idColumn => taskRules.id;
  @override TaskRulesCompanion createSoftDeleteCompanion() => TaskRulesCompanion(isDeleted: const Value(true), lastModified: Value(DateTime.now().toUtc()));

  Stream<List<TaskRuleDb>> watchAllRules() => watchAllActive();
  Stream<List<TaskRuleDb>> watchDeletedRules() => watchAllDeleted();

  Stream<List<TaskEntryDb>> watchEntriesForRule(String ruleId) {
    return (select(taskEntries)
          ..where((t) => t.taskRule.equals(ruleId))
          ..orderBy([(t) => OrderingTerm(expression: t.dateTimeUTC, mode: OrderingMode.desc)]))
        .watch();
  }

  Stream<List<TaskEntryDb>> watchAllEntries() => (select(taskEntries)..where((t) => t.isDeleted.equals(false))).watch();
  Stream<List<TaskEntryDb>> watchDeletedEntries() => (select(taskEntries)..where((t) => t.isDeleted.equals(true))).watch();

  Future<List<TaskRuleDb>> getAllRulesBypass() => select(taskRules).get();
  Future<List<TaskEntryDb>> getAllEntriesBypass() => select(taskEntries).get();

  /// Includes soft-deleted entries so their snapshots are correct on restore.
  Future<List<TaskEntryDb>> getEntriesForComponentIdsBypass(Iterable<String> componentIds) {
    final ids = componentIds.toSet();
    if (ids.isEmpty) {
      return Future.value(const []);
    }
    return (select(taskEntries)..where((t) => t.componentId.isIn(ids))).get();
  }

  Future<int> insertRule(TaskRulesCompanion entry) => into(taskRules).insert(entry);
  Future<bool> updateRule(TaskRulesCompanion entry) => update(taskRules).replace(entry);
  Future<int> upsertRule(TaskRulesCompanion entry) => into(taskRules).insertOnConflictUpdate(entry);
  Future<int> deleteRule(String id) => softDelete(id);
  
  Future<int> insertEntry(TaskEntriesCompanion entry) => into(taskEntries).insert(entry);
  Future<bool> updateEntry(TaskEntriesCompanion entry) => update(taskEntries).replace(entry);
  Future<int> upsertEntry(TaskEntriesCompanion entry) => into(taskEntries).insertOnConflictUpdate(entry);
  Future<int> deleteEntry(String id) => (update(taskEntries)..where((t) => t.id.equals(id))).write(TaskEntriesCompanion(isDeleted: const Value(true), lastModified: Value(DateTime.now().toUtc())));
}
