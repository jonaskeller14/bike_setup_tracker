// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bikes_dao.dart';

// ignore_for_file: type=lint
mixin _$BikesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BikesTable get bikes => attachedDatabase.bikes;
  $ComponentsTable get components => attachedDatabase.components;
  $PersonsTable get persons => attachedDatabase.persons;
  $SetupsTable get setups => attachedDatabase.setups;
  BikesDaoManager get managers => BikesDaoManager(this);
}

class BikesDaoManager {
  final _$BikesDaoMixin _db;
  BikesDaoManager(this._db);
  $$BikesTableTableManager get bikes =>
      $$BikesTableTableManager(_db.attachedDatabase, _db.bikes);
  $$ComponentsTableTableManager get components =>
      $$ComponentsTableTableManager(_db.attachedDatabase, _db.components);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db.attachedDatabase, _db.persons);
  $$SetupsTableTableManager get setups =>
      $$SetupsTableTableManager(_db.attachedDatabase, _db.setups);
}
