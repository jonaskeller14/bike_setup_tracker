// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setups_dao.dart';

// ignore_for_file: type=lint
mixin _$SetupsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BikesTable get bikes => attachedDatabase.bikes;
  $PersonsTable get persons => attachedDatabase.persons;
  $SetupsTable get setups => attachedDatabase.setups;
  $ComponentsTable get components => attachedDatabase.components;
  $AdjustmentsTable get adjustments => attachedDatabase.adjustments;
  $SetupAdjustmentValuesTable get setupAdjustmentValues =>
      attachedDatabase.setupAdjustmentValues;
  SetupsDaoManager get managers => SetupsDaoManager(this);
}

class SetupsDaoManager {
  final _$SetupsDaoMixin _db;
  SetupsDaoManager(this._db);
  $$BikesTableTableManager get bikes =>
      $$BikesTableTableManager(_db.attachedDatabase, _db.bikes);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db.attachedDatabase, _db.persons);
  $$SetupsTableTableManager get setups =>
      $$SetupsTableTableManager(_db.attachedDatabase, _db.setups);
  $$ComponentsTableTableManager get components =>
      $$ComponentsTableTableManager(_db.attachedDatabase, _db.components);
  $$AdjustmentsTableTableManager get adjustments =>
      $$AdjustmentsTableTableManager(_db.attachedDatabase, _db.adjustments);
  $$SetupAdjustmentValuesTableTableManager get setupAdjustmentValues =>
      $$SetupAdjustmentValuesTableTableManager(
        _db.attachedDatabase,
        _db.setupAdjustmentValues,
      );
}
