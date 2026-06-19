// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ratings_dao.dart';

// ignore_for_file: type=lint
mixin _$RatingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $RatingsTable get ratings => attachedDatabase.ratings;
  $RatingMetricsTable get ratingMetrics => attachedDatabase.ratingMetrics;
  RatingsDaoManager get managers => RatingsDaoManager(this);
}

class RatingsDaoManager {
  final _$RatingsDaoMixin _db;
  RatingsDaoManager(this._db);
  $$RatingsTableTableManager get ratings =>
      $$RatingsTableTableManager(_db.attachedDatabase, _db.ratings);
  $$RatingMetricsTableTableManager get ratingMetrics =>
      $$RatingMetricsTableTableManager(_db.attachedDatabase, _db.ratingMetrics);
}
