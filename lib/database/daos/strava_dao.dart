import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/strava/strava_athletes.dart';
import '../tables/strava/strava_gears.dart';
import '../tables/strava/strava_activities.dart';

part 'strava_dao.g.dart';

@DriftAccessor(tables: [StravaAthletes, StravaGears, StravaActivities])
class StravaDao extends DatabaseAccessor<AppDatabase> with _$StravaDaoMixin {
  StravaDao(super.db);

  Stream<List<StravaAthleteDb>> watchAllAthletes() => select(stravaAthletes).watch();
  Stream<List<StravaGearDb>> watchAllGears() => select(stravaGears).watch();
  
  Stream<List<StravaActivityDb>> watchActivitiesForAthlete(int athleteId) {
    return (select(stravaActivities)
          ..where((t) => t.athlete.equals(athleteId))
          ..orderBy([(t) => OrderingTerm(expression: t.startDate, mode: OrderingMode.desc)]))
        .watch();
  }

  Stream<List<StravaActivityDb>> watchAllActivities() {
    return select(stravaActivities).watch();
  }

  Future<List<StravaAthleteDb>> getAllAthletesBypass() => select(stravaAthletes).get();
  Future<List<StravaGearDb>> getAllGearsBypass() => select(stravaGears).get();
  Future<List<StravaActivityDb>> getAllActivitiesBypass() => select(stravaActivities).get();

  Future upsertAthlete(StravaAthletesCompanion entry) => into(stravaAthletes).insertOnConflictUpdate(entry);
  Future upsertGear(StravaGearsCompanion entry) => into(stravaGears).insertOnConflictUpdate(entry);
  Future upsertActivity(StravaActivitiesCompanion entry) => into(stravaActivities).insertOnConflictUpdate(entry);
}
