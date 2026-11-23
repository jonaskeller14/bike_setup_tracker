import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/import_preview.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/services/data_selection_dependencies.dart';
import 'package:bike_setup_tracker/services/database_migration_service.dart';
import 'package:bike_setup_tracker/utils/file_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.now().toUtc().copyWith(millisecond: 0, microsecond: 0);
  final older = now.subtract(const Duration(hours: 1));
  final newer = now.add(const Duration(hours: 1));

  Person person(String id, {DateTime? lastModified, bool? isDeleted}) =>
      Person(id: id, name: id, lastModified: lastModified ?? now, isDeleted: isDeleted);

  Bike bike(String id, {String? name, String? person, DateTime? lastModified, bool? isDeleted}) =>
      Bike(id: id, name: name ?? id, person: person, lastModified: lastModified ?? now, isDeleted: isDeleted);

  Component component(String id, {DateTime? lastModified, bool? isDeleted}) => Component(
    id: id,
    name: id,
    componentType: ComponentType.other,
    installations: const [],
    lastModified: lastModified ?? now,
    isDeleted: isDeleted,
  );

  Setup setup(String id, {String? notes, DateTime? lastModified, bool? isDeleted}) => Setup(
    id: id,
    notes: notes,
    lastModified: lastModified ?? now,
    isDeleted: isDeleted,
    datetime: DateTime.utc(2026, 5, 1, 13),
    datetimeLocal: DateTime(2026, 5, 1, 15),
    tags: const <String>{},
    bike: 'b1',
    person: null,
    bikeAdjustmentValues: const {},
    personAdjustmentValues: const {},
  );

  TaskRule taskRule(String id, {DateTime? lastModified}) =>
      TaskRule(id: id, name: id, tags: const {}, lastModified: lastModified ?? now);

  ImportPreview preview(SelectedData remote, SelectedData local, ImportMethod method) =>
      FileImport.preview(remoteData: remote, localData: local, method: method);

  Map<String, ImportOutcome> outcomes(ImportPreview preview, DataKind kind) => {
    for (final entry in preview.entriesOf(kind)) entry.id: entry.outcome,
  };

  group('preview', () {
    group('overwrite', () {
      test('adds, updates, keeps unchanged items and restores trashed ones', () {
        final local = SelectedData(
          bikes: {
            'edited': bike('edited', name: 'Local'),
            'same': bike('same'),
            'trashed': bike('trashed', isDeleted: true),
          },
        );
        final remote = SelectedData(
          bikes: {
            'edited': bike('edited', name: 'Remote', lastModified: older),
            'same': bike('same', lastModified: older),
            'trashed': bike('trashed', lastModified: older),
            'new': bike('new'),
          },
        );

        expect(outcomes(preview(remote, local, ImportMethod.overwrite), DataKind.bike), {
          'edited': ImportOutcome.updated,
          'same': ImportOutcome.unchanged,
          'trashed': ImportOutcome.added,
          'new': ImportOutcome.added,
        });
      });

      test('keeps the local items the file does not contain out of the preview', () {
        final local = SelectedData(bikes: {'local': bike('local')}, persons: {'p1': person('p1')});
        final remote = SelectedData(bikes: {'new': bike('new')});

        final result = preview(remote, local, ImportMethod.overwrite);

        expect(outcomes(result, DataKind.bike), {'new': ImportOutcome.added});
        expect(result.entriesOf(DataKind.person), isEmpty);
      });

      test('a deleted file item trashes the live local one; absent locally it is not listed', () {
        final local = SelectedData(bikes: {'live': bike('live')});
        final remote = SelectedData(
          bikes: {
            'live': bike('live', isDeleted: true),
            'absent': bike('absent', isDeleted: true),
          },
        );

        expect(outcomes(preview(remote, local, ImportMethod.overwrite), DataKind.bike), {
          'live': ImportOutcome.trashed,
        });
      });

      test('the entries carry the file item and the item before the import', () {
        final localBike = bike('b1', name: 'Local');
        final remoteBike = bike('b1', name: 'Remote');

        final entry = preview(
          SelectedData(bikes: {'b1': remoteBike}),
          SelectedData(bikes: {'b1': localBike}),
          ImportMethod.overwrite,
        ).entriesOf(DataKind.bike).single;

        expect(entry.kind, DataKind.bike);
        expect(entry.remote, same(remoteBike));
        expect(entry.local, same(localBike));
      });
    });

    group('merge', () {
      test('a newer local item stays unchanged, a newer file item updates it', () {
        final local = SelectedData(
          bikes: {
            'localNewer': bike('localNewer', name: 'Local', lastModified: newer),
            'remoteNewer': bike('remoteNewer', name: 'Local', lastModified: older),
            'equal': bike('equal', name: 'Local'),
          },
        );
        final remote = SelectedData(
          bikes: {
            'localNewer': bike('localNewer', name: 'Remote', lastModified: now),
            'remoteNewer': bike('remoteNewer', name: 'Remote', lastModified: now),
            'equal': bike('equal', name: 'Remote'),
            'new': bike('new'),
          },
        );

        expect(outcomes(preview(remote, local, ImportMethod.merge), DataKind.bike), {
          'localNewer': ImportOutcome.unchanged,
          'remoteNewer': ImportOutcome.updated,
          'equal': ImportOutcome.unchanged,
          'new': ImportOutcome.added,
        });
      });

      test('a newer deleted file item trashes the local one; an older one does not', () {
        final local = SelectedData(
          bikes: {
            'older': bike('older', lastModified: older),
            'newer': bike('newer', lastModified: newer),
          },
        );
        final remote = SelectedData(
          bikes: {
            'older': bike('older', isDeleted: true),
            'newer': bike('newer', isDeleted: true),
            'absent': bike('absent', isDeleted: true),
          },
        );

        expect(outcomes(preview(remote, local, ImportMethod.merge), DataKind.bike), {
          'older': ImportOutcome.trashed,
          'newer': ImportOutcome.unchanged,
        });
      });
    });

    group('replace', () {
      test('trashes the live local items the file does not contain', () {
        final local = SelectedData(
          persons: {'p1': person('p1')},
          bikes: {'kept': bike('kept'), 'other': bike('other'), 'inTrash': bike('inTrash', isDeleted: true)},
        );
        final remote = SelectedData(
          bikes: {
            'kept': bike('kept', lastModified: older),
            'new': bike('new'),
          },
        );

        final result = preview(remote, local, ImportMethod.replace);

        expect(outcomes(result, DataKind.bike), {
          'kept': ImportOutcome.unchanged,
          'new': ImportOutcome.added,
          'other': ImportOutcome.trashed,
        });
        expect(outcomes(result, DataKind.person), {'p1': ImportOutcome.trashed});
        expect(result.entriesOf(DataKind.bike).last.remote, isNull);
      });
    });

    test('does not change the local data it previews against', () {
      final local = SelectedData(
        bikes: {
          'b1': bike('b1', name: 'Local'),
          'b2': bike('b2'),
        },
      );

      preview(
        SelectedData(
          bikes: {
            'b1': bike('b1', name: 'Remote'),
            'b3': bike('b3'),
          },
        ),
        local,
        ImportMethod.replace,
      );

      expect(local.bikes.keys, ['b1', 'b2']);
      expect(local.bikes['b1']!.name, 'Local');
      expect(local.bikes['b2']!.isDeleted, isFalse);
    });

    test('count and isEmpty', () {
      final local = SelectedData(bikes: {'b1': bike('b1'), 'b2': bike('b2')});
      final remote = SelectedData(bikes: {'b1': bike('b1'), 'b3': bike('b3'), 'b4': bike('b4')});

      final result = preview(remote, local, ImportMethod.replace);

      expect(result.count(DataKind.bike, ImportOutcome.added), 2);
      expect(result.count(DataKind.bike, ImportOutcome.unchanged), 1);
      expect(result.count(DataKind.bike, ImportOutcome.trashed), 1);
      expect(result.count(DataKind.bike, ImportOutcome.updated), 0);
      expect(result.isEmpty, isFalse);
      expect(preview(SelectedData(), SelectedData(), ImportMethod.replace).isEmpty, isTrue);
      expect(preview(SelectedData(), local, ImportMethod.merge).isEmpty, isTrue);
    });
  });

  group('preview matches the database after the import', () {
    late AppDatabase database;

    setUp(() => database = AppDatabase.memory());
    tearDown(() => database.close());

    Future<void> expectPreviewMatchesImport(ImportMethod method) async {
      await DatabaseMigrationService(database).migrateFromSelectedData(
        SelectedData(
          persons: {'p1': person('p1')},
          bikes: {
            'b1': bike('b1', name: 'Enduro', person: 'p1'),
            'b2': bike('b2', name: 'Trail'),
            'b3': bike('b3', name: 'Old', isDeleted: true),
          },
          components: {'c1': component('c1'), 'c2': component('c2')},
          setups: {'s1': setup('s1', notes: 'Local', lastModified: newer)},
          taskRules: {'tr1': taskRule('tr1')},
        ),
      );
      final before = await FileImport.loadLocalData(database);

      // A file is an export, so the unchanged items are the device's own.
      final remote = SelectedData(
        bikes: {
          'b1': before.bikes['b1']!.copyWith(name: 'Enduro v2', lastModified: newer),
          'b2': before.bikes['b2']!.copyWith(lastModified: older),
          'b3': before.bikes['b3']!.copyWith(name: 'Old restored', isDeleted: false, lastModified: newer),
          'b4': bike('b4', name: 'New'),
          'b5': bike('b5', name: 'Deleted', isDeleted: true),
        },
        components: {'c1': before.components['c1']!.copyWith(isDeleted: true, lastModified: newer)},
        setups: {
          's1': before.setups['s1']!.copyWith(notes: 'Remote', lastModified: now),
          's2': setup('s2', notes: 'New'),
        },
      );

      final expected = FileImport.preview(remoteData: remote, localData: before, method: method);
      switch (method) {
        case ImportMethod.overwrite:
          await FileImport.overwrite(remoteData: remote, database: database);
        case ImportMethod.merge:
          await FileImport.merge(remoteData: remote, database: database);
        case ImportMethod.replace:
          await FileImport.replace(remoteData: remote, database: database);
      }
      final actual = ImportPreview.diff(
        remote: remote,
        before: before,
        after: await FileImport.loadLocalData(database),
      );

      for (final kind in DataKind.values) {
        expect(outcomes(expected, kind), outcomes(actual, kind), reason: kind.name);
      }
      expect(expected.count(DataKind.bike, ImportOutcome.added), 2, reason: 'b3 restored, b4 new');
      expect(expected.count(DataKind.component, ImportOutcome.trashed), method == ImportMethod.replace ? 2 : 1);
    }

    test('overwrite', () => expectPreviewMatchesImport(ImportMethod.overwrite));
    test('merge', () => expectPreviewMatchesImport(ImportMethod.merge));
    test('replace', () => expectPreviewMatchesImport(ImportMethod.replace));
  });
}
