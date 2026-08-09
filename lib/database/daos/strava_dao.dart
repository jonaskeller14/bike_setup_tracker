import 'package:drift/drift.dart';
import '../../models/component_stats.dart';
import '../../utils/text_search.dart';
import '../app_database.dart';
import '../tables/bikes.dart';
import '../tables/installations.dart';
import '../tables/strava/strava_activities.dart';
import '../tables/strava/strava_athletes.dart';
import '../tables/strava/strava_gears.dart';

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
  /// Paginated activities, optionally filtered by gear so the filter is applied
  /// in SQL rather than after a global fetch.
  ///
  /// - [gearId] non-null: only activities for that gear (a linked bike).
  /// - [unassignedOnly]: only activities whose gear belongs to no bike — i.e.
  ///   a null gear or a gear not present in [assignedGears] (an unlinked bike).
  /// - neither: all activities.
  Future<List<StravaActivityDb>> getActivitiesPaginated({
    required int limit,
    required int offset,
    OrderingMode mode = OrderingMode.desc,
    String? gearId,
    bool unassignedOnly = false,
    List<String> assignedGears = const [],
  }) {
    final query = select(stravaActivities)
      ..orderBy([(t) => OrderingTerm(expression: t.startDate, mode: mode)]);

    if (gearId != null) {
      query.where((t) => t.gearId.equals(gearId));
    } else if (unassignedOnly && assignedGears.isNotEmpty) {
      // Null gear, or a gear that is not linked to any bike.
      query.where((t) => t.gearId.isNull() | t.gearId.isNotIn(assignedGears));
    }
    // unassignedOnly with no assigned gears => every activity qualifies (no filter).

    query.limit(limit, offset: offset);
    return query.get();
  }

  Stream<List<StravaActivityDb>> watchActivitiesWithPosition() {
    return (select(stravaActivities)
          ..where((t) => t.startLat.isNotNull() & t.startLon.isNotNull())
          ..orderBy([(t) => OrderingTerm(expression: t.startDate, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<List<StravaActivityDb>> searchActivitiesByName(String query) {
    final tokens = tokenizeSearchQuery(query);
    final statement = select(stravaActivities);
    if (tokens.isNotEmpty) {
      statement.where(
        (t) => tokens
            .map<Expression<bool>>((token) => t.name.lower().like('%$token%'))
            .reduce((left, right) => left & right),
      );
    }
    return statement.get();
  }

  Future<StravaActivityDb?> getActivityById(int id) {
    return (select(stravaActivities)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> upsertAthlete(StravaAthletesCompanion entry) => into(stravaAthletes).insertOnConflictUpdate(entry);
  Future<int> upsertGear(StravaGearsCompanion entry) => into(stravaGears).insertOnConflictUpdate(entry);

  /// Upserts all [gears] and deletes any gear whose ID is not in the incoming set,
  /// so the local table mirrors the Firestore source of truth.
  Future<void> syncGears(Iterable<StravaGearsCompanion> gears) async {
    final companions = gears.toList();
    final ids = companions.map((g) => g.id.value).toList();
    await transaction(() async {
      for (final gear in companions) {
        await into(stravaGears).insertOnConflictUpdate(gear);
      }
      if (ids.isEmpty) {
        await delete(stravaGears).go();
      } else {
        await (delete(stravaGears)..where((t) => t.id.isNotIn(ids))).go();
      }
    });
  }
  Future<int> upsertActivity(StravaActivitiesCompanion entry) => into(stravaActivities).insertOnConflictUpdate(entry);
  Future<int> deleteActivities(Iterable<int> ids) => (delete(stravaActivities)..where((t) => t.id.isIn(ids))).go();

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
        c.initial_elapsed_time + COALESCE(s.elapsed_time, 0) as elapsed_time,
        c.initial_activity_count + COALESCE(s.activity_count, 0) as activity_count
      FROM components c
      LEFT JOIN (
        SELECT 
          i.component_id,
          SUM(a.distance) as distance,
          SUM(a.total_elevation_gain) as elevation,
          SUM(a.moving_time) as moving_time,
          SUM(a.elapsed_time) as elapsed_time,
          COUNT(a.id) as activity_count
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
          activityCount: row.read<int>('activity_count'),
        );
      }
      return result;
    });
  }

  Stream<Map<String, ComponentStats>> watchBikeStats() {
    final query = customSelect(
      '''
      SELECT 
        b.id as bike_id,
        COALESCE(SUM(a.distance), 0) as distance,
        COALESCE(SUM(a.total_elevation_gain), 0) as elevation,
        COALESCE(SUM(a.moving_time), 0) as moving_time,
        COALESCE(SUM(a.elapsed_time), 0) as elapsed_time,
        COALESCE(COUNT(a.id), 0) as activity_count
      FROM bikes b
      LEFT JOIN strava_activities a ON b.strava_gear = a.gear_id
      WHERE b.is_deleted = 0
      GROUP BY b.id
      ''',
      readsFrom: {stravaActivities, db.bikes},
    );

    return query.watch().map((rows) {
      final Map<String, ComponentStats> result = {};
      for (final row in rows) {
        result[row.read<String>('bike_id')] = ComponentStats(
          distance: row.read<double>('distance'),
          elevationGain: row.read<double>('elevation'),
          movingTime: Duration(seconds: row.read<int>('moving_time')),
          elapsedTime: Duration(seconds: row.read<int>('elapsed_time')),
          activityCount: row.read<int>('activity_count'),
        );
      }
      return result;
    });
  }

  Future<ComponentStats> getComponentStatsAt(String componentId, DateTime date) async {
    final query = customSelect(
      '''
      SELECT 
        c.initial_distance + COALESCE(s.distance, 0) as distance,
        c.initial_elevation_gain + COALESCE(s.elevation, 0) as elevation,
        c.initial_moving_time + COALESCE(s.moving_time, 0) as moving_time,
        c.initial_elapsed_time + COALESCE(s.elapsed_time, 0) as elapsed_time,
        c.initial_activity_count + COALESCE(s.activity_count, 0) as activity_count
      FROM components c
      LEFT JOIN (
        SELECT 
          i.component_id,
          SUM(a.distance) as distance,
          SUM(a.total_elevation_gain) as elevation,
          SUM(a.moving_time) as moving_time,
          SUM(a.elapsed_time) as elapsed_time,
          COUNT(a.id) as activity_count
        FROM strava_activities a
        JOIN bikes b ON a.gear_id = b.strava_gear
        JOIN installations i ON b.id = i.parent
        WHERE a.start_date >= i.date_time_u_t_c
        AND a.start_date <= :selectedDate
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
      WHERE c.id = :componentId
      ''',
      readsFrom: {stravaActivities, db.bikes, db.installations, db.components},
      variables: [
        Variable<DateTime>(date),
        Variable<String>(componentId),
      ],
    );

    final row = await query.getSingleOrNull();
    if (row == null) return ComponentStats.zero();
    
    return ComponentStats(
      distance: row.read<double>('distance'),
      elevationGain: row.read<double>('elevation'),
      movingTime: Duration(seconds: row.read<int>('moving_time')),
      elapsedTime: Duration(seconds: row.read<int>('elapsed_time')),
      activityCount: row.read<int>('activity_count'),
    );
  }

  Future<ComponentStats> getBikeStatsAt(String bikeId, DateTime date) async {
    final query = customSelect(
      '''
      SELECT 
        COALESCE(SUM(a.distance), 0) as distance,
        COALESCE(SUM(a.total_elevation_gain), 0) as elevation,
        COALESCE(SUM(a.moving_time), 0) as moving_time,
        COALESCE(SUM(a.elapsed_time), 0) as elapsed_time,
        COALESCE(COUNT(a.id), 0) as activity_count
      FROM bikes b
      LEFT JOIN strava_activities a ON b.strava_gear = a.gear_id
      WHERE b.id = :bikeId
      AND a.start_date <= :selectedDate
      GROUP BY b.id
      ''',
      readsFrom: {stravaActivities, db.bikes},
      variables: [
        Variable<String>(bikeId),
        Variable<DateTime>(date),
      ],
    );

    final row = await query.getSingleOrNull();
    if (row == null) return ComponentStats.zero();

    return ComponentStats(
      distance: row.read<double>('distance'),
      elevationGain: row.read<double>('elevation'),
      movingTime: Duration(seconds: row.read<int>('moving_time')),
      elapsedTime: Duration(seconds: row.read<int>('elapsed_time')),
      activityCount: row.read<int>('activity_count'),
    );
  }
}
