import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/services/data_export_service.dart';
import 'package:bike_setup_tracker/services/database_migration_service.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

/// General guard against import/export serialization asymmetries, across every
/// model in a backup (persons, bikes, components, setups, ratings, rating
/// entries, task rules, task entries).
///
/// Adjustment values cross a codec boundary twice: they are written to the DB
/// on import ([DatabaseMigrationService.migrateFromSelectedData]) and read back
/// on export ([DataExportService.backupDatabaseToJson]). If the two sides use
/// different encodings, values silently corrupt on every round-trip.
///
/// This is exactly what happened with multi-select categoricals: the import
/// path stored `["open"]` via `List.toString()` (`[open]`) instead of the JSON
/// codec, so a re-export produced `["[open]"]` — a phantom bracket that grows
/// on each cycle. The same encoded-value path is shared by setup
/// `bikeAdjustmentValues`/`personAdjustmentValues` and rating-entry
/// `metricValues`, so both are exercised here.
void main() {
  // Each round-trip opens a fresh in-memory DB; several may briefly coexist.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);

  /// Imports [json] into a fresh DB and exports it straight back out — the
  /// real import→export path a user triggers.
  Future<Map<String, dynamic>> importThenExport(Map<String, dynamic> json) async {
    final db = AppDatabase.memory();
    try {
      await DatabaseMigrationService(db)
          .migrateFromSelectedData(SelectedData.fromJson(json));
      return await DataExportService.backupDatabaseToJson(db, includeStrava: true);
    } finally {
      await db.close();
    }
  }

  Map<String, dynamic> findById(Map<String, dynamic> export, String key, String id) {
    return (export[key] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((e) => e['id'] == id);
  }

  // A full backup covering every model. Adjustment values include the shapes
  // that broke: a single-element, a multi-element, and an empty categorical
  // list — both on a setup and on a rating entry.
  Map<String, dynamic> sampleData() => {
        'persons': [
          {
            'id': 'p1',
            'name': 'Alex',
            'isDeleted': false,
            'lastModified': '2026-01-01T00:00:00Z',
            'adjustments': [
              {'type': 'numerical', 'id': 'pnum', 'name': 'Weight', 'unit': 'kg', 'min': 0.0, 'max': 150.0, 'category': 'AdjustmentCategory.body'},
            ],
          },
        ],
        'bikes': [
          {'id': 'b1', 'name': 'Hightower', 'person': 'p1', 'isDeleted': false, 'lastModified': '2026-01-01T00:00:00Z'},
        ],
        'components': [
          {
            'version': 4,
            'id': 'c1',
            'name': 'Fork',
            'componentType': 'ComponentType.fork',
            'isDeleted': false,
            'lastModified': '2026-01-01T00:00:00Z',
            'installations': <dynamic>[],
            'adjustments': [
              {'type': 'categorical', 'id': 'cat_single', 'name': 'Mode', 'category': 'AdjustmentCategory.component', 'options': ['Open', 'Firm', 'Locked'], 'multiSelect': false},
              {'type': 'categorical', 'id': 'cat_multi', 'name': 'Tokens', 'category': 'AdjustmentCategory.component', 'options': ['Front', 'Rear', 'Both'], 'multiSelect': true},
              {'type': 'categorical', 'id': 'cat_empty', 'name': 'Tags', 'category': 'AdjustmentCategory.component', 'options': ['A', 'B'], 'multiSelect': true},
              {'type': 'text', 'id': 'txt', 'name': 'Note', 'category': 'AdjustmentCategory.component'},
              {'type': 'numerical', 'id': 'num', 'name': 'Pressure', 'unit': 'psi', 'category': 'AdjustmentCategory.component', 'min': 0.0, 'max': 200.0},
              {'type': 'step', 'id': 'stp', 'name': 'Rebound', 'category': 'AdjustmentCategory.component', 'min': 0.0, 'max': 10.0, 'step': 1.0, 'visualization': 'slider'},
              {'type': 'boolean', 'id': 'bln', 'name': 'Lockout', 'category': 'AdjustmentCategory.component'},
              {'type': 'duration', 'id': 'dur', 'name': 'Service', 'category': 'AdjustmentCategory.component'},
            ],
          },
        ],
        'setups': [
          {
            'id': 's1',
            'name': 'Trail day',
            'datetime': '2026-05-01T12:00:00Z',
            'datetimeLocal': '2026-05-01T14:00:00',
            'bike': 'b1',
            'person': 'p1',
            'tags': ['Trail'],
            'isDeleted': false,
            'lastModified': '2026-05-01T12:00:00Z',
            'bikeAdjustmentValues': {
              'cat_single': ['Open'],
              'cat_multi': ['Front', 'Rear'],
              'cat_empty': <String>[],
              'txt': 'Trail notes',
              'num': 85.5,
              'stp': 5,
              'bln': true,
              'dur': '01:30:00',
            },
            'personAdjustmentValues': {
              'pnum': 75.0,
            },
          },
        ],
        'ratings': [
          {
            'version': 3,
            'id': 'rating1',
            'name': 'Suspension feel',
            'notes': null,
            'filter': 'c1',
            'filterType': 'FilterType.component',
            'orderIndex': 0,
            'isDeleted': false,
            'lastModified': '2026-01-01T00:00:00Z',
            'metrics': [
              {'version': 1, 'weight': 1.0, 'adjustment': {'type': 'numerical', 'id': 'm_grip', 'name': 'Grip', 'unit': null, 'min': 1.0, 'max': 10.0, 'category': 'AdjustmentCategory.rating'}},
              {'version': 1, 'weight': 2.0, 'adjustment': {'type': 'categorical', 'id': 'm_feel', 'name': 'Feel', 'category': 'AdjustmentCategory.rating', 'options': ['Harsh', 'Balanced', 'Plush'], 'multiSelect': false}},
            ],
          },
        ],
        'ratingEntries': [
          {
            'version': 1,
            'id': 're1',
            'name': 'Post-ride',
            'bike': 'b1',
            'setupId': 's1',
            'dateTimeUTC': '2026-05-01T13:00:00Z',
            'dateTimeLocal': '2026-05-01T15:00:00',
            'notes': null,
            'isDeleted': false,
            'lastModified': '2026-05-01T13:00:00Z',
            'metricValues': {
              'm_grip': 8.0,
              'm_feel': ['Balanced'], // categorical value shares the codec path
            },
          },
        ],
        'taskRules': [
          {
            'version': 1,
            'id': 'tr1',
            'name': 'Service fork',
            'notes': 'Lowers service',
            'priority': 'TaskPriority.high',
            'tags': ['suspension'],
            'componentId': 'c1',
            'bikeId': null,
            'interval': {'type': 'duration', 'microseconds': const Duration(days: 45).inMicroseconds},
            'delay': {'type': 'distance', 'meters': 500.0},
            'repeat': true,
            'isDeleted': false,
            'lastModified': '2026-01-01T00:00:00Z',
          },
        ],
        'taskEntries': [
          {
            'id': 'te1',
            'name': 'Fork serviced',
            'notes': null,
            'dateTimeUTC': '2026-05-02T10:00:00Z',
            'dateTimeLocal': '2026-05-02T12:00:00',
            'taskRule': 'tr1',
            'componentId': 'c1',
            'bikeId': null,
            'snapshot': {
              'distance': 12000.0,
              'elevationGain': 400.0,
              'movingTime': const Duration(hours: 10).inMicroseconds,
              'elapsedTime': const Duration(hours: 12).inMicroseconds,
              'activityCount': 5,
            },
            'isDeleted': false,
            'lastModified': '2026-05-02T10:00:00Z',
          },
        ],
      };

  group('Import/Export round-trip', () {
    test('preserves adjustment values of every type (no phantom brackets)', () async {
      final export = await importThenExport(sampleData());

      // Setup values: a categorical list must survive verbatim, never become
      // ["[Open]"] or collapse ["Front","Rear"] into a single mangled string.
      final setup = findById(export, 'setups', 's1');
      final bikeValues = (setup['bikeAdjustmentValues'] as Map).cast<String, dynamic>();
      expect(bikeValues['cat_single'], ['Open']);
      expect(bikeValues['cat_multi'], ['Front', 'Rear']);
      expect(bikeValues['cat_empty'], isEmpty);
      expect(bikeValues['txt'], 'Trail notes');
      expect(bikeValues['num'], 85.5);
      expect(bikeValues['stp'], 5);
      expect(bikeValues['bln'], true);
      expect(bikeValues['dur'], '1:30:00.000000');
      expect((setup['personAdjustmentValues'] as Map)['pnum'], 75.0);

      // Rating-entry metric values go through the same codec path.
      final entry = findById(export, 'ratingEntries', 're1');
      final metricValues = (entry['metricValues'] as Map).cast<String, dynamic>();
      expect(metricValues['m_grip'], 8.0);
      expect(metricValues['m_feel'], ['Balanced']);
    });

    test('is idempotent across all models: a second import→export equals the first', () async {
      // After one round-trip the data is in canonical form, so re-importing and
      // re-exporting must be a fixed point. Any encode/decode asymmetry (a value
      // that mutates each cycle) breaks this, in any model or field.
      final exportA = await importThenExport(sampleData());
      final exportB = await importThenExport(exportA);

      // Every top-level collection must be present and stable.
      for (final key in const [
        'persons', 'bikes', 'components', 'setups',
        'ratings', 'ratingEntries', 'taskRules', 'taskEntries',
      ]) {
        expect(exportA[key], isNotEmpty, reason: '$key should be populated');
      }

      expect(exportB, equals(exportA));
    });
  });
}
