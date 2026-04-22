// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_dao.dart';

// ignore_for_file: type=lint
mixin _$TaskDaoMixin on DatabaseAccessor<AppDatabase> {
  $ComponentsTable get components => attachedDatabase.components;
  $BikesTable get bikes => attachedDatabase.bikes;
  $TaskRulesTable get taskRules => attachedDatabase.taskRules;
  $TaskEntriesTable get taskEntries => attachedDatabase.taskEntries;
  TaskDaoManager get managers => TaskDaoManager(this);
}

class TaskDaoManager {
  final _$TaskDaoMixin _db;
  TaskDaoManager(this._db);
  $$ComponentsTableTableManager get components =>
      $$ComponentsTableTableManager(_db.attachedDatabase, _db.components);
  $$BikesTableTableManager get bikes =>
      $$BikesTableTableManager(_db.attachedDatabase, _db.bikes);
  $$TaskRulesTableTableManager get taskRules =>
      $$TaskRulesTableTableManager(_db.attachedDatabase, _db.taskRules);
  $$TaskEntriesTableTableManager get taskEntries =>
      $$TaskEntriesTableTableManager(_db.attachedDatabase, _db.taskEntries);
}
