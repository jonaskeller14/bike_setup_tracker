// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ratings_dao.dart';

// ignore_for_file: type=lint
mixin _$RatingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $RatingsTable get ratings => attachedDatabase.ratings;
  $ComponentsTable get components => attachedDatabase.components;
  $PersonsTable get persons => attachedDatabase.persons;
  $AdjustmentsTable get adjustments => attachedDatabase.adjustments;
  RatingsDaoManager get managers => RatingsDaoManager(this);
}

class RatingsDaoManager {
  final _$RatingsDaoMixin _db;
  RatingsDaoManager(this._db);
  $$RatingsTableTableManager get ratings =>
      $$RatingsTableTableManager(_db.attachedDatabase, _db.ratings);
  $$ComponentsTableTableManager get components =>
      $$ComponentsTableTableManager(_db.attachedDatabase, _db.components);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db.attachedDatabase, _db.persons);
  $$AdjustmentsTableTableManager get adjustments =>
      $$AdjustmentsTableTableManager(_db.attachedDatabase, _db.adjustments);
}
