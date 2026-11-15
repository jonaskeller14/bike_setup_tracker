import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/daos/sync_dao.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/services/sync/sync_collection.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

const _epochSeconds = 1790000000;

/// The required columns of each root table. Rows are inserted with raw SQL
/// because the triggers fire on every write, typed or not.
const _seedColumns = <SyncCollection, String>{
  SyncCollection.persons: "(id, last_modified, name) VALUES (?, $_epochSeconds, 'Alex')",
  SyncCollection.bikes: "(id, last_modified, name) VALUES (?, $_epochSeconds, 'Bike')",
  SyncCollection.components: "(id, last_modified, name, component_type) VALUES (?, $_epochSeconds, 'Fork', 'fork')",
  SyncCollection.setups:
      '(id, bike_id, last_modified, datetime, datetime_local, tags) '
      "VALUES (?, 'b1', $_epochSeconds, $_epochSeconds, $_epochSeconds, '[]')",
  SyncCollection.taskRules: "(id, last_modified, name) VALUES (?, $_epochSeconds, 'Service fork')",
  SyncCollection.taskEntries:
      '(id, last_modified, name, date_time_u_t_c, date_time_local, task_rule) '
      "VALUES (?, $_epochSeconds, 'Fork serviced', $_epochSeconds, $_epochSeconds, 'tr1')",
  SyncCollection.feedbacks:
      '(id, bike_id, setup_id, last_modified, date_time_u_t_c, date_time_local) '
      "VALUES (?, 'b1', 's1', $_epochSeconds, $_epochSeconds, $_epochSeconds)",
  SyncCollection.testSessions:
      '(id, bike_id, last_modified, started_at_u_t_c, started_at_local) '
      "VALUES (?, 'b1', $_epochSeconds, $_epochSeconds, $_epochSeconds)",
};

Future<void> _settle() => Future.delayed(const Duration(milliseconds: 50));

void main() {
  late AppDatabase db;
  late SyncDao dao;

  setUp(() {
    db = AppDatabase.memory();
    dao = db.syncDao;
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertRow(SyncCollection collection, String id) =>
      db.customStatement('INSERT INTO ${collection.collectionName} ${_seedColumns[collection]}', [id]);

  Future<void> touchRow(SyncCollection collection, String id) => db.customStatement(
    'UPDATE ${collection.collectionName} SET last_modified = last_modified + 1 WHERE id = ?',
    [id],
  );

  Future<void> trashRow(SyncCollection collection, String id) =>
      db.customStatement('UPDATE ${collection.collectionName} SET is_deleted = 1 WHERE id = ?', [id]);

  Future<List<SyncOutboxDb>> pending() => dao.pendingBatch(1000);

  Future<List<(String, String)>> pendingKeys() async => [for (final e in await pending()) (e.collection, e.rowId)];

  Future<void> clearOutbox() async => dao.markPushed([for (final e in await pending()) e.id]);

  group('triggers', () {
    for (final collection in SyncCollection.values) {
      test('${collection.collectionName}: insert, update and soft delete each re-enqueue the row', () async {
        await insertRow(collection, 'r1');
        final inserted = (await pending()).single;
        expect((inserted.collection, inserted.rowId), (collection.collectionName, 'r1'));

        await touchRow(collection, 'r1');
        final updated = (await pending()).single;
        expect(updated.rowId, 'r1');
        expect(updated.id, greaterThan(inserted.id));

        await trashRow(collection, 'r1');
        final trashed = (await pending()).single;
        expect(trashed.rowId, 'r1');
        expect(trashed.id, greaterThan(updated.id));
      });
    }

    test('exist on the root tables only', () async {
      final rows = await db.customSelect("SELECT tbl_name FROM sqlite_master WHERE type = 'trigger'").get();
      expect(
        rows.map((r) => r.read<String>('tbl_name')).toSet(),
        {for (final collection in SyncCollection.values) collection.collectionName},
      );
    });

    test('fire for typed inserts, upserts, replaces and soft deletes', () async {
      final bike = Bike(name: 'Bike', person: null);
      final before = DateTime.now().toUtc().subtract(const Duration(seconds: 1));

      await db.bikesDao.insertBike(bike.toCompanion());
      final inserted = (await pending()).single;
      expect(inserted.rowId, bike.id);
      expect(inserted.enqueuedAt.isBefore(before), isFalse);

      await db.into(db.bikes).insertOnConflictUpdate(bike.toCompanion());
      final upserted = (await pending()).single;
      expect(upserted.id, greaterThan(inserted.id));

      // The outer OR REPLACE would override a conflict clause in the trigger.
      await db.into(db.bikes).insert(bike.toCompanion(), mode: InsertMode.insertOrReplace);
      final replaced = (await pending()).single;
      expect(replaced.id, greaterThan(upserted.id));

      await db.bikesDao.deleteBike(bike.id);
      final trashed = (await pending()).single;
      expect(trashed.id, greaterThan(replaced.id));
    });

    test('the trash purge adds nothing', () async {
      for (final collection in SyncCollection.values) {
        await insertRow(collection, 'r1');
        await trashRow(collection, 'r1');
      }
      await clearOutbox();

      await db.purgeTrash(DateTime.now().toUtc());

      for (final collection in SyncCollection.values) {
        final rows = await db.customSelect('SELECT id FROM ${collection.collectionName}').get();
        expect(rows, isEmpty, reason: '${collection.collectionName} not purged');
      }
      expect(await pending(), isEmpty);
    });
  });

  group('runApplyingRemote', () {
    test('adds no entries and drops the entries of the rows it writes', () async {
      await insertRow(SyncCollection.bikes, 'b1');
      await insertRow(SyncCollection.bikes, 'b2');
      await insertRow(SyncCollection.persons, 'p1');

      await dao.runApplyingRemote(() async {
        await touchRow(SyncCollection.bikes, 'b1');
        await insertRow(SyncCollection.bikes, 'b3');
      });

      expect(await pendingKeys(), [('bikes', 'b2'), ('persons', 'p1')]);
    });

    test('returns the result, and local writes enqueue again afterwards', () async {
      expect(await dao.runApplyingRemote(() async => 42), 42);

      await insertRow(SyncCollection.bikes, 'b1');

      expect(await pendingKeys(), [('bikes', 'b1')]);
    });

    test('a failing action rolls back its writes and leaves triggers enqueuing', () async {
      await insertRow(SyncCollection.bikes, 'b1');
      final entry = (await pending()).single;

      await expectLater(
        dao.runApplyingRemote(() async {
          await touchRow(SyncCollection.bikes, 'b1');
          throw StateError('boom');
        }),
        throwsStateError,
      );

      expect((await pending()).single.id, entry.id);
      await insertRow(SyncCollection.bikes, 'b2');
      expect(await pendingKeys(), [('bikes', 'b1'), ('bikes', 'b2')]);
    });
  });

  group('outbox', () {
    test('pendingBatch returns the oldest entries first, up to the limit', () async {
      await insertRow(SyncCollection.bikes, 'b1');
      await insertRow(SyncCollection.persons, 'p1');
      await insertRow(SyncCollection.bikes, 'b2');
      await touchRow(SyncCollection.bikes, 'b1');

      final batch = await dao.pendingBatch(2);

      expect([for (final e in batch) e.rowId], ['p1', 'b2']);
    });

    test('markPushed keeps entries re-enqueued after the batch was read and stamps the push', () async {
      expect(await dao.lastPushAt(), isNull);
      await insertRow(SyncCollection.bikes, 'b1');
      await insertRow(SyncCollection.bikes, 'b2');
      final batch = await dao.pendingBatch(10);
      await touchRow(SyncCollection.bikes, 'b1');
      final before = DateTime.now().toUtc().subtract(const Duration(seconds: 1));

      await dao.markPushed([for (final e in batch) e.id]);

      expect(await pendingKeys(), [('bikes', 'b1')]);
      expect((await dao.lastPushAt())!.isBefore(before), isFalse);
    });

    test('enqueueAll adds every root row, trashed ones included, and keeps existing entries', () async {
      await insertRow(SyncCollection.bikes, 'pending');
      final existing = (await pending()).single;
      await dao.runApplyingRemote(() async {
        for (final collection in SyncCollection.values) {
          await insertRow(collection, 'r1');
        }
        await trashRow(SyncCollection.setups, 'r1');
      });

      await dao.enqueueAll();

      expect((await pendingKeys()).toSet(), {
        ('bikes', 'pending'),
        for (final collection in SyncCollection.values) (collection.collectionName, 'r1'),
      });
      expect((await pending()).firstWhere((e) => e.rowId == 'pending').id, existing.id);
    });

    test('watchPendingCount follows typed writes the triggers enqueue', () async {
      final counts = <int>[];
      final subscription = dao.watchPendingCount().listen(counts.add);
      addTearDown(subscription.cancel);
      await _settle();

      await db.bikesDao.insertBike(Bike(name: 'Bike', person: null).toCompanion());
      await _settle();
      await clearOutbox();
      await _settle();

      expect(counts, [0, 1, 0]);
    });
  });

  group('cursors', () {
    test('are null until set, kept per collection and overwritten', () async {
      expect(await dao.getCursor(SyncCollection.setups), isNull);

      final first = (serverUpdatedAt: DateTime.utc(2026, 11, 11, 10, 0, 0, 123, 456), docId: 'a');
      final second = (serverUpdatedAt: DateTime.utc(2026, 11, 11, 10, 0, 1), docId: 'b');
      await dao.setCursor(SyncCollection.setups, first);
      await dao.setCursor(SyncCollection.bikes, second);

      expect(await dao.getCursor(SyncCollection.setups), first);
      expect(await dao.getCursor(SyncCollection.bikes), second);
      expect(await dao.getCursor(SyncCollection.persons), isNull);

      await dao.setCursor(SyncCollection.setups, second);
      expect(await dao.getCursor(SyncCollection.setups), second);
    });
  });
}
