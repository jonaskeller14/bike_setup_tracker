import 'dart:io';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/component/installation.dart';
import '../models/strava/strava_activity.dart';
import '../models/task/task_rule.dart';
import 'converters/attachment_list_converter.dart';
import 'converters/component_preset_converter.dart';
import 'converters/context_position_converter.dart';
import 'converters/duration_converter.dart';
import 'converters/local_floating_datetime_converter.dart';
import 'converters/placemark_converter.dart';
import 'converters/string_list_converter.dart';
import 'converters/utc_datetime_converter.dart';
import 'converters/weather_converter.dart';
import 'daos/bikes_dao.dart';
import 'daos/components_dao.dart';
import 'daos/feedback_dao.dart';
import 'daos/persons_dao.dart';
import 'daos/setups_dao.dart';
import 'daos/strava_dao.dart';
import 'daos/task_dao.dart';
import 'tables/adjustments.dart';
import 'tables/bikes.dart';
import 'tables/components.dart';
import 'tables/feedback_comparisons.dart';
import 'tables/feedback_observations.dart';
import 'tables/feedbacks.dart';
import 'tables/installations.dart';
import 'tables/persons.dart';
import 'tables/setup_adjustment_values.dart';
import 'tables/setups.dart';
import 'tables/strava/strava_activities.dart';
import 'tables/strava/strava_athletes.dart';
import 'tables/strava/strava_gears.dart';
import 'tables/task_entries.dart';
import 'tables/task_rules.dart';
import 'tables/test_sessions.dart';

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
    StravaActivities,
    StravaAthletes,
    StravaGears,
    Feedbacks,
    FeedbackObservations,
    FeedbackComparisons,
    TestSessions,
  ],
  daos: [
    BikesDao,
    ComponentsDao,
    SetupsDao,
    PersonsDao,
    TaskDao,
    StravaDao,
    FeedbackDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.memory() : super(NativeDatabase.memory());

  /// Opens the database over an arbitrary [executor]. Used by migration tests
  /// that need to seed a database at an older schema version (on a file they
  /// control) and then re-open it to exercise the real upgrade path.
  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 26;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      // Drift stamps the new version only after this returns, so a partial run
      // would replay steps on the next launch that aren't idempotent (v2 shifts
      // dates again, unguarded addColumn/createTable fail). All or nothing.
      onUpgrade: (Migrator m, int from, int to) => transaction(() async {
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
          //
          // This recreation rebuilds setups from the *current* schema, which
          // now includes `attachments` (v20, `images` from v8), `isBookmarked` (v13)
          // and `testSessionId` (v26).
          // Pre-v4 rows have no such columns, so flag them as new columns —
          // Drift fills them from their defaults instead of trying to copy
          // them out of the old table.
          await m.alterTable(
            TableMigration(setups, newColumns: [setups.attachments, setups.isBookmarked, setups.testSessionId]),
          );
          await customStatement("UPDATE setups SET name = NULL WHERE name = 'Unnamed Setup'");
        }
        if (from < 5) {
          // Drop the now-orphaned rating-metric adjustments (cascades to their
          // setup values), then recreate `adjustments` without the rating_id
          // column / CHECK arm. The rating tables this step once created are
          // gone from the schema; v25 drops them where they exist.
          await customStatement('DELETE FROM adjustments WHERE rating_id IS NOT NULL');
          await m.alterTable(TableMigration(adjustments));
        }
        if (from < 7) {
          // AdjustmentCategory removed — drop the category column from
          // adjustments via schema recreation.
          await m.alterTable(TableMigration(adjustments));
        }
        if (from < 8) {
          // v8 added `images`, which v20 replaces with `attachments`; add the
          // latter directly. Upgrades that crossed the v4 boundary already
          // gained it when the setups table was recreated above; only add it
          // when missing so we don't hit a duplicate-column error.
          if (!await _columnExists('setups', 'attachments')) {
            await m.addColumn(setups, setups.attachments);
          }
        }
        if (from < 9) {
          // Component archiving: installations gain a `parentType` discriminator
          // ('bike' | 'none' | 'archived'). Existing rows default to 'bike'; a
          // null `parent` always meant uninstalled, so backfill those to 'none'.
          // No rows are archived yet.
          await m.addColumn(installations, installations.parentType);
          await customStatement(
            "UPDATE installations SET parent_type = 'none' WHERE parent IS NULL",
          );
        }
        if (from < 10) {
          // Strava activities gain `workoutType` (Strava's sub-classification,
          // e.g. Race/Workout for rides). Existing rows have no such data.
          await m.addColumn(stravaActivities, stravaActivities.workoutType);
        }
        if (from < 11) {
          // The single value column moves to a uniformly JSON-encoded format for
          // every type. Reparse each existing row with the legacy decoder and
          // re-encode with the new codec (data-only, no schema change).
          await migrateAdjustmentValuesToJson(this);
        }
        if (from < 12) {
          // Adjustment units move from free-spelled strings
          // ("psi", "KPH", ...) to a structured `AdjustmentUnit` encoding
          // ("pressure:psi"). Normalize every existing unit string via the
          // alias table once; unmatched spellings become a `CustomUnit`
          // (data-only, no schema change).
          await migrateAdjustmentUnits(this);
        }
        if (from < 13) {
          // Setups gain `isBookmarked` so a good setup can be marked and found
          // again among the many recorded ones. Existing rows default to false.
          // Upgrades that crossed the v4 boundary already gained the column
          // when the setups table was recreated above.
          if (!await _columnExists('setups', 'is_bookmarked')) {
            await m.addColumn(setups, setups.isBookmarked);
          }
        }
        if (from < 14) {
          // Strava activities gain `averageWatts`
          if (!await _columnExists('strava_activities', 'average_watts')) {
            await m.addColumn(stravaActivities, stravaActivities.averageWatts);
          }
        }
        if (from < 15) {
          // Components gain `initialKilojoules`
          if (!await _columnExists('components', 'initial_kilojoules')) {
            await m.addColumn(components, components.initialKilojoules);
          }
        }
        if (from < 16) {
          // Installation instants became minute-resolution (the UI only ever
          // edited minutes; "Now" and drag-and-drop wrote seconds). Round the
          // stored rows down so they match what is displayed and editable.
          await migrateInstallationMinutes(this);
        }
        if (from < 17) {
          // Component nesting resolves placement by walking installations up the
          // parent chain; index both lookup directions so the traversal stays
          // cheap as timelines grow.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS installations_component_date_idx '
            'ON installations (component_id, date_time_u_t_c)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS installations_parent_lookup_idx '
            'ON installations (parent_type, parent, date_time_u_t_c)',
          );
        }
        if (from < 18) {
          // Bikes gain initial stats (usage before tracking), mirroring components.
          final columns = <String, GeneratedColumn>{
            'initial_distance': bikes.initialDistance,
            'initial_elevation_gain': bikes.initialElevationGain,
            'initial_moving_time': bikes.initialMovingTime,
            'initial_elapsed_time': bikes.initialElapsedTime,
            'initial_activity_count': bikes.initialActivityCount,
            'initial_kilojoules': bikes.initialKilojoules,
          };
          for (final MapEntry(key: name, value: column) in columns.entries) {
            if (!await _columnExists('bikes', name)) {
              await m.addColumn(bikes, column);
            }
          }
        }
        // v19 added `preset_key` and `preset_damper_key` to components, which
        // v22 replaces with `preset`; upgrades from below v19 gain the latter
        // in that step.
        if (from < 20) {
          // Setup images generalise to attachments on setups, bikes and
          // components. The image feature never shipped, so `images` is
          // dropped rather than converted. Only databases that ran the old v8
          // step still have it; every other path gained `attachments` above.
          if (await _columnExists('setups', 'images')) {
            await m.alterTable(TableMigration(setups, newColumns: [setups.attachments, setups.testSessionId]));
          }
          if (!await _columnExists('bikes', 'attachments')) {
            await m.addColumn(bikes, bikes.attachments);
          }
          if (!await _columnExists('components', 'attachments')) {
            await m.addColumn(components, components.attachments);
          }
        }
        if (from < 21) {
          // Task rules (reference files) and task entries (record of one
          // completion) gain attachments.
          if (!await _columnExists('task_rules', 'attachments')) {
            await m.addColumn(taskRules, taskRules.attachments);
          }
          if (!await _columnExists('task_entries', 'attachments')) {
            await m.addColumn(taskEntries, taskEntries.attachments);
          }
        }
        if (from < 22) {
          // The preset key pair becomes one `preset` map of the catalog path and
          // chosen options. The preset UI was debug-only, so the old columns
          // are dropped rather than converted: recreating the table from the
          // current schema removes both `preset_key` and `preset_damper_key`.
          // Only databases that ran the v19 step have them; it added both.
          if (await _columnExists('components', 'preset_key')) {
            await m.alterTable(TableMigration(components, newColumns: [components.preset]));
          } else if (!await _columnExists('components', 'preset')) {
            await m.addColumn(components, components.preset);
          }
        }
        if (from < 23) {
          // Task rules remember the task preset they were created from.
          if (!await _columnExists('task_rules', 'preset_key')) {
            await m.addColumn(taskRules, taskRules.presetKey);
          }
        }
        if (from < 24) {
          await customStatement(
            'CREATE INDEX IF NOT EXISTS strava_activities_gear_date_idx '
            'ON strava_activities (gear_id, start_date)',
          );
        }
        if (from < 25) {
          // Rating v2 (templates, metrics, entries) never shipped and is
          // replaced by Feedback, so its data is dropped. Children first.
          for (final table in const [
            'rating_entry_values',
            'rating_entries',
            'rating_metrics',
            'ratings',
          ]) {
            await customStatement('DROP TABLE IF EXISTS $table');
          }
        }
        if (from < 26) {
          // Feedback (rating v3): ride feedback with its answers and setup
          // comparisons, and test sessions whose runs are setups. Upgrades that crossed the v4 boundary, or the v20
          // recreation, already gained `test_session_id`.
          await m.createTable(feedbacks);
          await m.createTable(feedbackObservations);
          await m.createTable(feedbackComparisons);
          await m.createTable(testSessions);
          if (!await _columnExists('setups', 'test_session_id')) {
            await m.addColumn(setups, setups.testSessionId);
          }
        }
      }),
    );
  }

  /// Ordered children first so deletes never trip a foreign key.
  List<TableInfo<Table, dynamic>> get _userDataTables => [
    feedbackObservations,
    feedbackComparisons,
    feedbacks,
    testSessions,
    setupAdjustmentValues,
    setups,
    adjustments,
    installations,
    taskEntries,
    components,
    taskRules,
    bikes,
    persons,
  ];

  /// Emits whether any table cleared by [deleteAllUserData] holds a row,
  /// including soft-deleted ones.
  Stream<bool> watchHasUserData() {
    final tables = _userDataTables;
    final query = tables.map((table) => 'SELECT 1 FROM ${table.actualTableName}').join(' UNION ALL ');
    return customSelect('SELECT EXISTS($query) AS has_data', readsFrom: tables.toSet())
        .watchSingle()
        .map((row) => row.read<bool>('has_data'));
  }

  /// Hard-deletes all user data. Synced Strava tables are left untouched.
  Future<void> deleteAllUserData() {
    return transaction(() async {
      for (final table in _userDataTables) {
        await delete(table).go();
      }
    });
  }

  /// Hard-deletes every trashed row last modified before [cutoff], together
  /// with the rows nested under it. Foreign keys are not enforced, so those
  /// children are deleted explicitly.
  Future<void> purgeTrash(DateTime cutoff) {
    return transaction(() async {
      Future<List<String>> expiredIds(
        TableInfo<Table, dynamic> table,
        GeneratedColumn<String> id,
        GeneratedColumn<bool> isDeleted,
        GeneratedColumnWithTypeConverter<DateTime, DateTime> lastModified,
      ) async {
        final trashed = selectOnly(table)
          ..addColumns([id, lastModified])
          ..where(isDeleted.equals(true));
        return [
          for (final row in await trashed.get())
            if (row.readWithConverter(lastModified)!.isBefore(cutoff)) row.read(id)!,
        ];
      }

      final feedbackIds = await expiredIds(feedbacks, feedbacks.id, feedbacks.isDeleted, feedbacks.lastModified);
      await (delete(feedbackObservations)..where((t) => t.feedbackId.isIn(feedbackIds))).go();
      await (delete(feedbackComparisons)..where((t) => t.feedbackId.isIn(feedbackIds))).go();
      await (delete(feedbacks)..where((t) => t.id.isIn(feedbackIds))).go();

      final testSessionIds = await expiredIds(
        testSessions,
        testSessions.id,
        testSessions.isDeleted,
        testSessions.lastModified,
      );
      await (delete(testSessions)..where((t) => t.id.isIn(testSessionIds))).go();

      final setupIds = await expiredIds(setups, setups.id, setups.isDeleted, setups.lastModified);
      await (delete(setupAdjustmentValues)..where((t) => t.setupId.isIn(setupIds))).go();
      await (delete(setups)..where((t) => t.id.isIn(setupIds))).go();

      final taskEntryIds = await expiredIds(
        taskEntries,
        taskEntries.id,
        taskEntries.isDeleted,
        taskEntries.lastModified,
      );
      await (delete(taskEntries)..where((t) => t.id.isIn(taskEntryIds))).go();

      final componentIds = await expiredIds(components, components.id, components.isDeleted, components.lastModified);
      await (delete(adjustments)..where((t) => t.componentId.isIn(componentIds))).go();
      await (delete(installations)..where((t) => t.componentId.isIn(componentIds))).go();
      await (delete(components)..where((t) => t.id.isIn(componentIds))).go();

      final taskRuleIds = await expiredIds(taskRules, taskRules.id, taskRules.isDeleted, taskRules.lastModified);
      await (delete(taskRules)..where((t) => t.id.isIn(taskRuleIds))).go();

      final bikeIds = await expiredIds(bikes, bikes.id, bikes.isDeleted, bikes.lastModified);
      await (delete(bikes)..where((t) => t.id.isIn(bikeIds))).go();

      final personIds = await expiredIds(persons, persons.id, persons.isDeleted, persons.lastModified);
      await (delete(adjustments)..where((t) => t.personId.isIn(personIds))).go();
      await (delete(persons)..where((t) => t.id.isIn(personIds))).go();
    });
  }

  /// Filenames of the attachments any row still references, trashed rows included.
  Future<Set<String>> referencedAttachmentFilenames() async {
    Future<Iterable<Attachment>> attachmentsOf(
      TableInfo<Table, dynamic> table,
      GeneratedColumnWithTypeConverter<List<Attachment>, String> column,
    ) async {
      final rows = await (selectOnly(table)..addColumns([column])).get();
      return rows.expand((row) => row.readWithConverter(column)!);
    }

    return {
      ...await attachmentsOf(setups, setups.attachments),
      ...await attachmentsOf(bikes, bikes.attachments),
      ...await attachmentsOf(components, components.attachments),
      ...await attachmentsOf(taskRules, taskRules.attachments),
      ...await attachmentsOf(taskEntries, taskEntries.attachments),
    }.map((a) => a.filename).toSet();
  }

  /// Rounds every installation instant down to the whole minute.
  ///
  /// Rounding can collapse two events onto the same minute, and equal instants
  /// sort arbitrarily — which for a single component decides what it is
  /// currently installed on. Collisions within a component are therefore spread
  /// forward a minute at a time, preserving the order the rows were recorded in.
  /// The epoch-0 "from beginning" sentinel is left untouched.
  @visibleForTesting
  static Future<void> migrateInstallationMinutes(AppDatabase db) async {
    final rows = await db.customSelect(
      'SELECT id, component_id, date_time_u_t_c, date_time_local FROM installations '
      'ORDER BY component_id, date_time_u_t_c',
    ).get();

    final Map<String, int> lastMinuteByComponent = {};
    for (final row in rows) {
      final utc = row.read<int>('date_time_u_t_c');
      if (utc == 0) continue;

      final local = row.read<int>('date_time_local');
      final componentId = row.read<String>('component_id');

      final roundedUtc = utc - (utc % 60);
      final lastMinute = lastMinuteByComponent[componentId];
      final newUtc = (lastMinute != null && roundedUtc <= lastMinute)
          ? lastMinute + 60
          : roundedUtc;
      lastMinuteByComponent[componentId] = newUtc;

      // `date_time_local` stores a floating face value, so the same shift in
      // seconds moves the wall clock by the same number of minutes.
      final newLocal = local - (local % 60) + (newUtc - roundedUtc);
      if (newUtc == utc && newLocal == local) continue;

      await db.customStatement(
        'UPDATE installations SET date_time_u_t_c = ?, date_time_local = ? WHERE id = ?',
        [newUtc, newLocal, row.read<String>('id')],
      );
    }
  }

  @visibleForTesting
  static Future<void> migrateAdjustmentUnits(AppDatabase db) async {
    await db._reencodeUnitColumn('adjustments');
  }

  Future<void> _reencodeUnitColumn(String table) async {
    final rows = await customSelect('SELECT id, unit FROM $table').get();
    for (final row in rows) {
      final raw = row.read<String?>('unit');
      if (raw == null) continue;
      final newRaw = AdjustmentUnit.fromLegacy(raw)?.encode();
      if (newRaw == raw) continue;
      await customStatement(
        'UPDATE $table SET unit = ? WHERE id = ?',
        [newRaw, row.read<String>('id')],
      );
    }
  }

  @visibleForTesting
  static Future<void> migrateAdjustmentValuesToJson(AppDatabase db) async {
    await db._reencodeValueColumn(
      valueTable: 'setup_adjustment_values',
      keyColumns: ('setup_id', 'adjustment_id'),
      defTable: 'adjustments',
      defForeignKey: 'adjustment_id',
    );
  }
 
  /// Reencoding: Rows already in JSON form (bool/num/step) are left untouched;
  /// only reshaped rows (text, categorical, duration) are rewritten.
  Future<void> _reencodeValueColumn({
    required String valueTable,
    required (String, String) keyColumns,
    required String defTable,
    required String defForeignKey,
  }) async {
    final (keyA, keyB) = keyColumns;
    final rows = await customSelect(
      'SELECT v.$keyA AS key_a, v.$keyB AS key_b, v.value AS value, d.type AS type '
      'FROM $valueTable v JOIN $defTable d ON d.id = v.$defForeignKey',
    ).get();

    for (final row in rows) {
      final raw = row.read<String>('value');
      final typeName = row.read<String>('type');
      final type = AdjustmentType.values.firstWhereOrNull((e) => e.name == typeName);
      if (type == null) continue; // unknown type — leave the row untouched.

      final newRaw = AdjustmentValue.decodeLegacy(raw, type)?.encode() ?? 'null';
      if (newRaw == raw) continue; // already JSON-shaped.

      await customStatement(
        'UPDATE $valueTable SET value = ? WHERE $keyA = ? AND $keyB = ?',
        [newRaw, row.read<String>('key_a'), row.read<String>('key_b')],
      );
    }
  }

  Future<bool> _columnExists(String table, String column) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return rows.any((r) => r.read<String>('name') == column);
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
