// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'components_dao.dart';

// ignore_for_file: type=lint
mixin _$ComponentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ComponentsTable get components => attachedDatabase.components;
  $PersonsTable get persons => attachedDatabase.persons;
  $AdjustmentsTable get adjustments => attachedDatabase.adjustments;
  $InstallationsTable get installations => attachedDatabase.installations;
  ComponentsDaoManager get managers => ComponentsDaoManager(this);
}

class ComponentsDaoManager {
  final _$ComponentsDaoMixin _db;
  ComponentsDaoManager(this._db);
  $$ComponentsTableTableManager get components =>
      $$ComponentsTableTableManager(_db.attachedDatabase, _db.components);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db.attachedDatabase, _db.persons);
  $$AdjustmentsTableTableManager get adjustments =>
      $$AdjustmentsTableTableManager(_db.attachedDatabase, _db.adjustments);
  $$InstallationsTableTableManager get installations =>
      $$InstallationsTableTableManager(_db.attachedDatabase, _db.installations);
}
