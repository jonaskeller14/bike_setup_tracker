// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_dao.dart';

// ignore_for_file: type=lint
mixin _$TodoDaoMixin on DatabaseAccessor<AppDatabase> {
  $ComponentsTable get components => attachedDatabase.components;
  $TodoRulesTable get todoRules => attachedDatabase.todoRules;
  $TodoEntriesTable get todoEntries => attachedDatabase.todoEntries;
  TodoDaoManager get managers => TodoDaoManager(this);
}

class TodoDaoManager {
  final _$TodoDaoMixin _db;
  TodoDaoManager(this._db);
  $$ComponentsTableTableManager get components =>
      $$ComponentsTableTableManager(_db.attachedDatabase, _db.components);
  $$TodoRulesTableTableManager get todoRules =>
      $$TodoRulesTableTableManager(_db.attachedDatabase, _db.todoRules);
  $$TodoEntriesTableTableManager get todoEntries =>
      $$TodoEntriesTableTableManager(_db.attachedDatabase, _db.todoEntries);
}
