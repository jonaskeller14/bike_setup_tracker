import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/adjustment/adjustment.dart';
import '../models/component.dart';
import '../models/rating.dart';
import '../models/strava/strava_activity.dart';
import '../models/task/task_rule.dart';
import 'converters/duration_converter.dart';
import 'converters/local_floating_datetime_converter.dart';
import 'converters/location_data_converter.dart';
import 'converters/placemark_converter.dart';
import 'converters/string_list_converter.dart';
import 'converters/utc_datetime_converter.dart';
import 'converters/weather_converter.dart';
import 'daos/bikes_dao.dart';
import 'daos/components_dao.dart';
import 'daos/persons_dao.dart';
import 'daos/rating_entries_dao.dart';
import 'daos/ratings_dao.dart';
import 'daos/setups_dao.dart';
import 'daos/strava_dao.dart';
import 'daos/task_dao.dart';
import 'tables/adjustments.dart';
import 'tables/bikes.dart';
import 'tables/components.dart';
import 'tables/installations.dart';
import 'tables/persons.dart';
import 'tables/rating_entries.dart';
import 'tables/rating_entry_values.dart';
import 'tables/rating_metrics.dart';
import 'tables/ratings.dart';
import 'tables/setup_adjustment_values.dart';
import 'tables/setups.dart';
import 'tables/strava/strava_activities.dart';
import 'tables/strava/strava_athletes.dart';
import 'tables/strava/strava_gears.dart';
import 'tables/task_entries.dart';
import 'tables/task_rules.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    TaskRules,
    TaskEntries,
    Bikes,
    Components,
    Adjustments,
    Installations,
    Setups,
    SetupAdjustmentValues,
    Persons,
    Ratings,
    RatingMetrics,
    RatingEntries,
    RatingEntryValues,
    StravaActivities,
    StravaAthletes,
    StravaGears,
  ],
  daos: [
    BikesDao,
    ComponentsDao,
    SetupsDao,
    PersonsDao,
    RatingsDao,
    RatingEntriesDao,
    TaskDao,
    StravaDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Fix legacy local timestamps that were stored as absolute UTC epochs 
          // instead of floating face-values.
          await migrateFloatingDates(this);
        }
        if (from < 3) {
          await m.addColumn(taskRules, taskRules.tags);
        }
        if (from < 4) {
          // Setup.name became nullable. Recreate the table to drop the NOT NULL
          // constraint, then clear out the legacy auto-generated placeholder so
          // those setups fall back to the (localizable) UI placeholder instead.
          await m.alterTable(TableMigration(setups));
          await customStatement("UPDATE setups SET name = NULL WHERE name = 'Unnamed Setup'");
        }
        if (from < 5) {
          // Rating redesign: metrics move to their own RatingMetrics table and
          // ratings are captured via RatingEntries (+ values). The unshipped
          // rating data is disposable.
          await m.createTable(ratingMetrics);
          await m.createTable(ratingEntries);
          await m.createTable(ratingEntryValues);
          // Drop the now-orphaned rating-metric adjustments (cascades to their
          // setup values), then recreate `adjustments` without the rating_id
          // column / CHECK arm.
          await customStatement('DELETE FROM adjustments WHERE rating_id IS NOT NULL');
          await m.alterTable(TableMigration(adjustments));
        }
        if (from < 6) {
          // RatingEntry.setupId became required (non-nullable). The unshipped rating
          // entry data is disposable, so recreate the table with the new schema.
          await m.deleteTable(ratingEntryValues.actualTableName);
          await m.deleteTable(ratingEntries.actualTableName);
          await m.createTable(ratingEntries);
          await m.createTable(ratingEntryValues);
        }
      },
    );
  }

  @visibleForTesting
  static Future<void> migrateFloatingDates(AppDatabase db) async {
    final Map<String, String> tableToColumn = {
      'setups': 'datetime_local',
      'installations': 'date_time_local',
      'task_entries': 'date_time_local',
      'strava_activities': 'start_date_local',
    };

    for (final entry in tableToColumn.entries) {
      final tableName = entry.key;
      final columnName = entry.value;

      final rows = await db.customSelect('SELECT id, $columnName FROM $tableName').get();
      for (final row in rows) {
        final Object id = (tableName == 'strava_activities') 
            ? row.read<int>('id') 
            : row.read<String>('id');
        final rawEpochSeconds = row.read<int?>(columnName);
        if (rawEpochSeconds == null) continue;

        // 1. Reconstruct EXACT historical local "wall clock" time.
        // fromMillisecondsSinceEpoch handles DST and historical timezone transitions 
        // correctly based on when that specific timestamp occurred in the past.
        final historicalLocal = DateTime.fromMillisecondsSinceEpoch(rawEpochSeconds * 1000);

        // 2. Convert it into our new strict "Face Value UTC" representation.
        final floatingUtc = const LocalFloatingDateTimeConverter().toSql(historicalLocal);
        final newEpochSeconds = floatingUtc.millisecondsSinceEpoch ~/ 1000;

        await db.customStatement(
          'UPDATE $tableName SET $columnName = ? WHERE id = ?',
          [newEpochSeconds, id],
        );
      }
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'bike_setup_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
