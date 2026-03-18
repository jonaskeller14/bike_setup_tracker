// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strava_dao.dart';

// ignore_for_file: type=lint
mixin _$StravaDaoMixin on DatabaseAccessor<AppDatabase> {
  $StravaAthletesTable get stravaAthletes => attachedDatabase.stravaAthletes;
  $StravaGearsTable get stravaGears => attachedDatabase.stravaGears;
  $StravaActivitiesTable get stravaActivities =>
      attachedDatabase.stravaActivities;
  $BikesTable get bikes => attachedDatabase.bikes;
  $ComponentsTable get components => attachedDatabase.components;
  $InstallationsTable get installations => attachedDatabase.installations;
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
  $$BikesTableTableManager get bikes =>
      $$BikesTableTableManager(_db.attachedDatabase, _db.bikes);
  $$ComponentsTableTableManager get components =>
      $$ComponentsTableTableManager(_db.attachedDatabase, _db.components);
  $$InstallationsTableTableManager get installations =>
      $$InstallationsTableTableManager(_db.attachedDatabase, _db.installations);
}
