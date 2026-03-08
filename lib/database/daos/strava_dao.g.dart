// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strava_dao.dart';

// ignore_for_file: type=lint
mixin _$StravaDaoMixin on DatabaseAccessor<AppDatabase> {
  $StravaAthletesTable get stravaAthletes => attachedDatabase.stravaAthletes;
  $StravaGearsTable get stravaGears => attachedDatabase.stravaGears;
  $StravaActivitiesTable get stravaActivities =>
      attachedDatabase.stravaActivities;
  StravaDaoManager get managers => StravaDaoManager(this);
}

class StravaDaoManager {
  final _$StravaDaoMixin _db;
  StravaDaoManager(this._db);
  $$StravaAthletesTableTableManager get stravaAthletes =>
      $$StravaAthletesTableTableManager(
        _db.attachedDatabase,
        _db.stravaAthletes,
      );
  $$StravaGearsTableTableManager get stravaGears =>
      $$StravaGearsTableTableManager(_db.attachedDatabase, _db.stravaGears);
  $$StravaActivitiesTableTableManager get stravaActivities =>
      $$StravaActivitiesTableTableManager(
        _db.attachedDatabase,
        _db.stravaActivities,
      );
}
