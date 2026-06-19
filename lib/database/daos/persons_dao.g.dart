// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'persons_dao.dart';

// ignore_for_file: type=lint
mixin _$PersonsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PersonsTable get persons => attachedDatabase.persons;
  $ComponentsTable get components => attachedDatabase.components;
  $AdjustmentsTable get adjustments => attachedDatabase.adjustments;
  PersonsDaoManager get managers => PersonsDaoManager(this);
}

class PersonsDaoManager {
  final _$PersonsDaoMixin _db;
  PersonsDaoManager(this._db);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db.attachedDatabase, _db.persons);
  $$ComponentsTableTableManager get components =>
      $$ComponentsTableTableManager(_db.attachedDatabase, _db.components);
  $$AdjustmentsTableTableManager get adjustments =>
      $$AdjustmentsTableTableManager(_db.attachedDatabase, _db.adjustments);
}
