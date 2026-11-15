import 'dart:convert';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/services/database_migration_service.dart';
import 'package:bike_setup_tracker/services/sync/cloud_backups.dart';
import 'package:bike_setup_tracker/services/sync/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backup_remote.dart';

const _uid = 'account-1';

void main() {
  late AppDatabase db;
  late FakeBackupRemote remote;
  late DateTime now;
  late CloudBackups backups;

  void ensureCurrent() {}

  Future<void> addBike(String id, String name) =>
      DatabaseMigrationService(
        db,
      ).migrateFromSelectedData(
        SelectedData(
          bikes: {id: Bike(id: id, name: name, person: null)},
        ),
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.memory();
    remote = FakeBackupRemote();
    now = DateTime.utc(2026, 11, 13, 9, 5, 7);
    backups = CloudBackups(db, remote: remote, now: () => now);
  });

  tearDown(() => db.close());

  group('filenames', () {
    test('carry the UTC time and the suffix the lifecycle rule matches', () {
      expect(CloudBackups.filenameFor(DateTime.utc(2026, 1, 2, 3, 4, 5)), '20260102_030405_backup.json');
      expect(
        CloudBackups.filenameFor(DateTime.utc(2026, 1, 2, 3, 4, 5).toLocal()),
        '20260102_030405_backup.json',
        reason: 'a local time is written in UTC',
      );
    });

    test('are read back; other files in the folder are not backups', () {
      expect(CloudBackups.createdAtOf('20260102_030405_backup.json'), DateTime.utc(2026, 1, 2, 3, 4, 5));
      expect(CloudBackups.createdAtOf('20260102_030405.json'), isNull);
      expect(CloudBackups.createdAtOf('backup.json'), isNull);
      expect(CloudBackups.createdAtOf('20260102_030405_backup.json.tmp'), isNull);
    });

    test('list returns only backups with their time', () async {
      remote.cloud['20261110_080000_backup.json'] = utf8.encode('{}');
      remote.cloud['notes.txt'] = utf8.encode('');

      final list = await backups.list(_uid);

      expect(list.single.filename, '20261110_080000_backup.json');
      expect(list.single.createdAt, DateTime.utc(2026, 11, 10, 8));
    });
  });

  group('saveIfDue', () {
    test('uploads a snapshot that reads back as the local data', () async {
      await addBike('b1', 'Trail bike');

      await backups.saveIfDue(_uid, ensureCurrent: ensureCurrent);

      expect(remote.cloud.keys, ['20261113_090507_backup.json']);
      final restored = await backups.read(_uid, (await backups.list(_uid)).single);
      expect(restored.bikes['b1']?.name, 'Trail bike');
    });

    test('at most once a day', () async {
      await addBike('b1', 'Bike');
      await backups.saveIfDue(_uid, ensureCurrent: ensureCurrent);

      now = now.add(const Duration(hours: 23));
      await backups.saveIfDue(_uid, ensureCurrent: ensureCurrent);
      expect(remote.uploads, 1);
      expect(remote.lists, 1, reason: 'the stored time answers without asking the cloud');

      now = now.add(const Duration(hours: 1));
      await backups.saveIfDue(_uid, ensureCurrent: ensureCurrent);
      expect(remote.uploads, 2);
    });

    test("another device's backup from the last day counts", () async {
      await addBike('b1', 'Bike');
      remote.cloud['20261113_020000_backup.json'] = utf8.encode('{}');

      await backups.saveIfDue(_uid, ensureCurrent: ensureCurrent);
      expect(remote.uploads, 0);

      // The next check is a day after that backup, not after this run.
      now = DateTime.utc(2026, 11, 14, 1, 59);
      await backups.saveIfDue(_uid, ensureCurrent: ensureCurrent);
      expect(remote.lists, 1);
      now = DateTime.utc(2026, 11, 14, 2);
      await backups.saveIfDue(_uid, ensureCurrent: ensureCurrent);
      expect(remote.uploads, 1);
    });

    test('the daily guard is per account', () async {
      await addBike('b1', 'Bike');
      await backups.saveIfDue(_uid, ensureCurrent: ensureCurrent);
      remote.cloud.clear();

      await backups.saveIfDue('account-2', ensureCurrent: ensureCurrent);

      expect(remote.uploads, 2);
    });

    test('an empty database is not backed up', () async {
      await backups.saveIfDue(_uid, ensureCurrent: ensureCurrent);

      expect(remote.lists, 0);
      expect(remote.uploads, 0);
    });

    test('offline it fails quietly and tries again on the next run', () async {
      await addBike('b1', 'Bike');
      remote.offline = true;
      await backups.saveIfDue(_uid, ensureCurrent: ensureCurrent);

      remote.offline = false;
      await backups.saveIfDue(_uid, ensureCurrent: ensureCurrent);
      expect(remote.uploads, 1);
    });

    test('a denied upload (full quota) fails quietly and waits an hour', () async {
      await addBike('b1', 'Bike');
      remote.quotaFull = true;
      await backups.saveIfDue(_uid, ensureCurrent: ensureCurrent);

      remote.quotaFull = false;
      now = now.add(const Duration(minutes: 59));
      await backups.saveIfDue(_uid, ensureCurrent: ensureCurrent);
      expect(remote.uploads, 0);

      now = now.add(const Duration(minutes: 1));
      await backups.saveIfDue(_uid, ensureCurrent: ensureCurrent);
      expect(remote.uploads, 1);
    });

    test('a run cancelled by an account switch stops before the upload', () async {
      await addBike('b1', 'Bike');

      await expectLater(
        backups.saveIfDue(_uid, ensureCurrent: () => throw const SyncCancelled()),
        throwsA(isA<SyncCancelled>()),
      );
      expect(remote.uploads, 0);
    });
  });
}
