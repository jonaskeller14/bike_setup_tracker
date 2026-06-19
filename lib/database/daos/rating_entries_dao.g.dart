// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rating_entries_dao.dart';

// ignore_for_file: type=lint
mixin _$RatingEntriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BikesTable get bikes => attachedDatabase.bikes;
  $PersonsTable get persons => attachedDatabase.persons;
  $SetupsTable get setups => attachedDatabase.setups;
  $RatingEntriesTable get ratingEntries => attachedDatabase.ratingEntries;
  $RatingsTable get ratings => attachedDatabase.ratings;
  $RatingMetricsTable get ratingMetrics => attachedDatabase.ratingMetrics;
  $RatingEntryValuesTable get ratingEntryValues =>
      attachedDatabase.ratingEntryValues;
  RatingEntriesDaoManager get managers => RatingEntriesDaoManager(this);
}

class RatingEntriesDaoManager {
  final _$RatingEntriesDaoMixin _db;
  RatingEntriesDaoManager(this._db);
  $$BikesTableTableManager get bikes =>
      $$BikesTableTableManager(_db.attachedDatabase, _db.bikes);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db.attachedDatabase, _db.persons);
  $$SetupsTableTableManager get setups =>
      $$SetupsTableTableManager(_db.attachedDatabase, _db.setups);
  $$RatingEntriesTableTableManager get ratingEntries =>
      $$RatingEntriesTableTableManager(_db.attachedDatabase, _db.ratingEntries);
  $$RatingsTableTableManager get ratings =>
      $$RatingsTableTableManager(_db.attachedDatabase, _db.ratings);
  $$RatingMetricsTableTableManager get ratingMetrics =>
      $$RatingMetricsTableTableManager(_db.attachedDatabase, _db.ratingMetrics);
  $$RatingEntryValuesTableTableManager get ratingEntryValues =>
      $$RatingEntryValuesTableTableManager(
        _db.attachedDatabase,
        _db.ratingEntryValues,
      );
}
