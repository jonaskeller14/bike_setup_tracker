import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/component_stats.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/task_entry.dart';
import 'package:bike_setup_tracker/models/task_rule.dart';
import 'package:bike_setup_tracker/models/task_threshold.dart';
import 'package:bike_setup_tracker/services/data_export_service.dart';
import 'package:bike_setup_tracker/services/database_migration_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.memory();
  });

  tearDown(() async {
    await database.close();
  });

  test('migrateFromSelectedData completely preserves all TaskRule and TaskEntry fields', () async {
    final now = DateTime.now().toUtc().copyWith(microsecond: 0, millisecond: 0);
    
    final rule = TaskRule(
      id: "rule_1",
      isDeleted: false,
      lastModified: now,
      name: "Complex Task Rule",
      priority: TaskPriority.high,
      notes: "Some notes about the rule",
      componentId: "comp_1",
      interval: const DurationThreshold(Duration(days: 45)),
      delay: const DistanceThreshold(500),
      repeat: true,
      tags: const {},
    );

    final entry = TaskEntry(
      id: "entry_1",
      isDeleted: false,
      lastModified: now,
      name: "Complex Task Rule",
      notes: "Some notes about the entry",
      dateTimeUTC: now,
      dateTimeLocal: now.toLocal(),
      taskRule: "rule_1",
      componentId: "comp_1",
      snapshot: const ComponentStats(
        distance: 12000,
        elevationGain: 400,
        movingTime: Duration(hours: 10),
        elapsedTime: Duration(hours: 12),
        activityCount: 5,
      ),
    );

    final data = SelectedData(
      taskRules: {rule.id: rule},
      taskEntries: {entry.id: entry},
    );

    final migrationService = DatabaseMigrationService(database);
    await migrationService.migrateFromSelectedData(data);

    final exportJson = await DataExportService.backupDatabaseToJson(database);
    
    // Check TaskRules
    final expectedRules = data.taskRules.values.map((tr) => tr.toJson()).toList();
    expect(exportJson['taskRules'], equals(expectedRules));

    // Check TaskEntries
    final expectedEntries = data.taskEntries.values.map((te) => te.toJson()).toList();
    expect(exportJson['taskEntries'], equals(expectedEntries));
  });
}
