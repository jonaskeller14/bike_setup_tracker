import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/strava/strava_athletes.dart';
import '../tables/strava/strava_gears.dart';
import '../tables/strava/strava_activities.dart';
import '../tables/bikes.dart';
import '../tables/installations.dart';
import '../../models/component_stats.dart';

part 'strava_dao.g.dart';

@DriftAccessor(tables: [StravaAthletes, StravaGears, StravaActivities, Bikes, Installations])
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

  Stream<Map<String, ComponentStats>> watchComponentStats() {
    // This query sums up activities for each component based on its installation history.
    // It is optimized for large datasets and handles components moving between bikes.
    final query = customSelect(
      '''
      SELECT 
        c.id as component_id,
        c.initial_distance + COALESCE(s.distance, 0) as distance,
        c.initial_elevation_gain + COALESCE(s.elevation, 0) as elevation,
        c.initial_moving_time + COALESCE(s.moving_time, 0) as moving_time,
        c.initial_elapsed_time + COALESCE(s.elapsed_time, 0) as elapsed_time
      FROM components c
      LEFT JOIN (
        SELECT 
          i.component_id,
          SUM(a.distance) as distance,
          SUM(a.total_elevation_gain) as elevation,
          SUM(a.moving_time) as moving_time,
          SUM(a.elapsed_time) as elapsed_time
        FROM strava_activities a
        JOIN bikes b ON a.gear_id = b.strava_gear
        JOIN installations i ON b.id = i.parent
        WHERE a.start_date >= i.date_time_u_t_c
        AND (
          a.start_date < (
            SELECT MIN(next_i.date_time_u_t_c) 
            FROM installations next_i 
            WHERE next_i.component_id = i.component_id 
            AND next_i.date_time_u_t_c > i.date_time_u_t_c
          )
          OR NOT EXISTS (
            SELECT 1 
            FROM installations next_i 
            WHERE next_i.component_id = i.component_id 
            AND next_i.date_time_u_t_c > i.date_time_u_t_c
          )
        )
        GROUP BY i.component_id
      ) s ON s.component_id = c.id
      WHERE c.is_deleted = 0
      ''',
      readsFrom: {stravaActivities, db.bikes, db.installations, db.components},
    );

    return query.watch().map((rows) {
      final Map<String, ComponentStats> result = {};
      for (final row in rows) {
        result[row.read<String>('component_id')] = ComponentStats(
          distance: row.read<double>('distance'),
          elevationGain: row.read<double>('elevation'),
          movingTime: Duration(seconds: row.read<int>('moving_time')),
          elapsedTime: Duration(seconds: row.read<int>('elapsed_time')),
        );
      }
      return result;
    });
  }
}
