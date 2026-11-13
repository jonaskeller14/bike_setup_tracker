import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/daos/sync_dao.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/service_error.dart';
import 'package:bike_setup_tracker/models/syncable.dart';
import 'package:bike_setup_tracker/services/account_service.dart';
import 'package:bike_setup_tracker/services/attachment_storage_service.dart';
import 'package:bike_setup_tracker/services/cloud_sync_service.dart';
import 'package:bike_setup_tracker/services/database_migration_service.dart';
import 'package:bike_setup_tracker/services/sync/attachment_sync.dart';
import 'package:bike_setup_tracker/services/sync/sync_codec.dart';
import 'package:bike_setup_tracker/services/sync/sync_collection.dart';
import 'package:bike_setup_tracker/services/sync/sync_engine.dart';
import 'package:bike_setup_tracker/services/sync/sync_local_store.dart';
import 'package:bike_setup_tracker/services/sync/sync_remote.dart';
import 'package:bike_setup_tracker/utils/backup.dart';
import 'package:bike_setup_tracker/utils/file_import.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sync/fake_attachment_remote.dart';
import 'sync/fake_backup_remote.dart';
import 'sync/sync_fixture.dart';

const _uid = 'account-1';

DateTime _t(int seconds) => DateTime.utc(2026, 6, 1).add(Duration(seconds: seconds));

Bike _bike(String id, {String name = 'Bike', int at = 0, bool isDeleted = false}) =>
    Bike(id: id, name: name, person: null, lastModified: _t(at), isDeleted: isDeleted);

/// The cloud with the record rules of `firestore.rules`: a write older than
/// the stored version is rejected, and the whole batch with it.
class _RulesRemote implements SyncRemote {
  final FakeFirebaseFirestore firestore;
  final FirestoreSyncRemote _inner;
  int pushes = 0;
  int rejected = 0;
  int pulls = 0;

  /// Runs once, right before the next push is checked.
  Future<void> Function()? beforePush;
  Exception? failWith;

  _RulesRemote(this.firestore) : _inner = FirestoreSyncRemote(firestore: firestore, tieBreaker: 'id');

  DocumentReference<Map<String, dynamic>> doc(SyncCollection collection, String id) =>
      firestore.doc('users/$_uid/data/${collection.collectionName}/records/$id');

  @override
  Future<List<SyncRemoteDoc>> pull(String uid, SyncCollection collection, {SyncCursor? after, required int limit}) {
    pulls++;
    if (failWith case final error?) throw error;
    return _inner.pull(uid, collection, after: after, limit: limit);
  }

  @override
  Future<List<SyncRemoteDoc>> fetch(String uid, SyncCollection collection, Iterable<String> ids) =>
      _inner.fetch(uid, collection, ids);

  @override
  Future<void> push(String uid, List<(SyncCollection, Syncable)> records) async {
    if (beforePush case final hook?) {
      beforePush = null;
      await hook();
    }
    for (final (collection, record) in records) {
      final stored = (await doc(collection, record.id).get()).data()?['lastModified'] as Timestamp?;
      if (stored != null && stored.toDate().isAfter(record.lastModified)) {
        rejected++;
        throw FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
      }
    }
    pushes++;
    await _inner.push(uid, records);
  }

  Future<int> count(SyncCollection collection) async =>
      (await firestore.collection('users/$_uid/data/${collection.collectionName}/records').get()).size;
}

class _Device {
  final SyncEngine engine;

  _Device(String name, SyncRemote remote, {int pageSize = 500})
    : engine = SyncEngine(AppDatabase.memory(), remote: remote, prefsPrefix: 'test.$name', pageSize: pageSize);

  AppDatabase get database => engine.db;
  SyncLocalStore get _store => SyncLocalStore(database);

  Future<void> sync({String uid = _uid}) => engine.run(uid);

  Future<SelectedData> data() => _store.snapshot();

  /// A local edit: the triggers enqueue it.
  Future<void> save(Syncable record) async => _store.write(record, adjustmentTypes: (await data()).adjustmentTypes);

  Future<void> import(SelectedData data) => DatabaseMigrationService(database).migrateFromSelectedData(data);

  Future<int> pending() => database.syncDao.watchPendingCount().first;

  Future<Bike?> bike(String id) async => (await data()).bikes[id];

  Future<void> close() => database.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Each simulated device has its own in-memory database.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late FakeFirebaseFirestore firestore;
  late _RulesRemote remote;
  final devices = <_Device>[];

  _Device device(String name, {int pageSize = 500}) {
    final device = _Device(name, remote, pageSize: pageSize);
    devices.add(device);
    return device;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    firestore = FakeFirebaseFirestore();
    remote = _RulesRemote(firestore);
  });

  tearDown(() async {
    for (final device in devices) {
      await device.close();
    }
    devices.clear();
  });

  group('SyncEngine', () {
    test('records of all 8 collections reach the other device with their children', () async {
      final a = device('a');
      final b = device('b');
      final fixture = SelectedData.fromJson(syncFixtureJson());
      await a.import(fixture);

      await a.sync();
      await b.sync();

      final expected = await a.data();
      final actual = await b.data();
      for (final collection in SyncCollection.values) {
        expect(
          {for (final r in actual.recordsOf(collection).values) r.id: r.toJson()},
          {for (final r in expected.recordsOf(collection).values) r.id: r.toJson()},
          reason: collection.collectionName,
        );
        expect(await remote.count(collection), 1, reason: collection.collectionName);
      }
      expect(await b.pending(), 0, reason: 'pulled records are not pushed back');
    });

    test('data that existed before the first sync is pushed and merged with the cloud data', () async {
      final a = device('a');
      final b = device('b');
      await a.save(_bike('b1'));
      await b.save(_bike('b2'));
      // Rows written before the outbox existed have no entry.
      await a.database.syncDao.reset();

      await a.sync();
      await b.sync();
      await a.sync();

      expect((await a.data()).bikes.keys, unorderedEquals(['b1', 'b2']));
      expect((await b.data()).bikes.keys, unorderedEquals(['b1', 'b2']));
    });

    test('offline edits on both devices: each record keeps its newest version', () async {
      final a = device('a');
      final b = device('b');
      await a.save(_bike('b1', name: 'Original'));
      await a.save(_bike('b2', name: 'Original'));
      await a.sync();
      await b.sync();

      await a.save(_bike('b1', name: 'Edited on A', at: 30));
      await b.save(_bike('b1', name: 'Edited on B', at: 20));
      await b.save(_bike('b2', name: 'Edited on B', at: 20));
      await a.sync();
      await b.sync();
      await a.sync();

      for (final d in [a, b]) {
        expect((await d.bike('b1'))!.name, 'Edited on A');
        expect((await d.bike('b2'))!.name, 'Edited on B');
      }
    });

    test('a newer delete wins over an older edit, and a newer edit over an older delete', () async {
      final a = device('a');
      final b = device('b');
      await a.save(_bike('b1'));
      await a.save(_bike('b2'));
      await a.sync();
      await b.sync();

      await a.save(_bike('b1', at: 30, isDeleted: true));
      await b.save(_bike('b1', name: 'Edited', at: 20));
      await a.save(_bike('b2', at: 20, isDeleted: true));
      await b.save(_bike('b2', name: 'Edited', at: 30));
      await b.sync();
      await a.sync();
      await b.sync();

      for (final d in [a, b]) {
        expect((await d.bike('b1'))!.isDeleted, isTrue);
        expect((await d.bike('b2'))!.isDeleted, isFalse);
        expect((await d.bike('b2'))!.name, 'Edited');
      }
    });

    test('a record purged from the local trash is not brought back by its cloud tombstone', () async {
      final a = device('a');
      await a.save(_bike('b1'));
      await a.sync();
      await a.save(_bike('b1', at: 10, isDeleted: true));
      await a.sync();

      await a.database.purgeTrash(DateTime.now().toUtc());
      await a.database.syncDao.resetCursors();
      await a.sync();
      expect(await a.bike('b1'), isNull);

      final fresh = device('fresh');
      await fresh.sync();
      expect(await fresh.bike('b1'), isNull);
      expect(await fresh.pending(), 0);
    });

    test('a push rejected as stale pulls the newer version and retries with the rest', () async {
      final a = device('a');
      final b = device('b');
      await a.save(_bike('b1', name: 'Original'));
      await a.sync();
      await b.sync();

      await a.save(_bike('b1', name: 'Edited on A', at: 10));
      await a.save(_bike('b2', name: 'New on A', at: 10));
      // B pushes a newer b1 between A's pull and A's push.
      remote.beforePush = () async {
        await b.save(_bike('b1', name: 'Edited on B', at: 20));
        await b.sync();
      };
      await a.sync();
      await b.sync();

      expect(remote.rejected, 1);
      expect(await a.pending(), 0);
      for (final d in [a, b]) {
        expect((await d.bike('b1'))!.name, 'Edited on B');
        expect((await d.bike('b2'))!.name, 'New on A');
      }
    });

    test('pulls page by page, also through documents that share a server timestamp', () async {
      final a = device('a');
      for (var i = 0; i < 5; i++) {
        await a.save(_bike('b$i'));
      }
      await a.sync();
      // Three more written in one batch: the same serverUpdatedAt.
      final shared = Timestamp.fromDate(DateTime.utc(2030));
      for (final id in ['x1', 'x2', 'x3']) {
        await remote.doc(SyncCollection.bikes, id).set({...SyncCodec.encode(_bike(id)), 'serverUpdatedAt': shared});
      }

      final b = device('b', pageSize: 2);
      await b.sync();
      expect((await b.data()).bikes.keys, unorderedEquals(['b0', 'b1', 'b2', 'b3', 'b4', 'x1', 'x2', 'x3']));
      final cursor = await b.database.syncDao.getCursor(SyncCollection.bikes);
      expect(cursor?.docId, 'x3');
    });

    test('more than 500 changes go up in several batches', () async {
      final a = device('a');
      await a.import(SelectedData(bikes: {for (var i = 0; i < 501; i++) 'b$i': _bike('b$i')}));

      await a.sync();

      expect(remote.pushes, 2);
      expect(await remote.count(SyncCollection.bikes), 501);
      expect(await a.pending(), 0);
    });

    test('a removed setup value disappears on the other device', () async {
      final a = device('a');
      final b = device('b');
      await a.import(SelectedData.fromJson(syncFixtureJson()));
      await a.sync();
      await b.sync();

      final setup = (await a.data()).setups['s1']!;
      final values = Map.of(setup.bikeAdjustmentValues)..remove('cat');
      await a.save(
        setup.copyWith(bikeAdjustmentValues: values, lastModified: setup.lastModified.add(const Duration(seconds: 5))),
      );
      await a.sync();
      await b.sync();

      final pulled = (await b.data()).setups['s1']!;
      expect(pulled.bikeAdjustmentValues.keys, isNot(contains('cat')));
      expect(pulled.bikeAdjustmentValues.keys, contains('num'));
    });

    test('a document of a newer model version is skipped, retried, and then blocks no push', () async {
      final a = device('a');
      await a.save(_bike('b1', name: 'Local', at: 10));
      await a.save(_bike('b2', name: 'Other', at: 10));
      await a.database.syncDao.reset();
      await a.database.syncDao.enqueue(SyncCollection.bikes, 'b2');
      await SharedPreferences.getInstance().then((prefs) => prefs.setString('test.a.uid', _uid));
      final old = Timestamp.fromDate(DateTime.utc(2026));
      // A bike document a future app wrote: unreadable here, and newer.
      await remote.doc(SyncCollection.bikes, 'b1').set({
        ...SyncCodec.encode(_bike('b1', name: 'Future', at: 20)),
        'name': 42,
        'serverUpdatedAt': old,
      });
      await a.database.syncDao.enqueue(SyncCollection.bikes, 'b1');

      await a.sync();
      expect((await a.bike('b1'))!.name, 'Local');
      expect(await a.pending(), 0, reason: 'the local b1 lost and must not block b2');
      expect(await remote.count(SyncCollection.bikes), 2);

      // The "app update": the same document becomes readable, behind the cursor.
      await remote.doc(SyncCollection.bikes, 'b1').update({'name': 'Future'});
      await a.sync();
      expect((await a.bike('b1'))!.name, 'Future');
    });

    test('a tie on lastModified converges on both devices', () async {
      final a = device('a');
      final b = device('b');
      await a.save(_bike('b1', name: 'Alpha', at: 10));
      await b.save(_bike('b1', name: 'Zulu', at: 10));
      await a.sync();
      await b.sync();
      await a.sync();

      expect((await a.bike('b1'))!.name, (await b.bike('b1'))!.name);
      expect((await remote.doc(SyncCollection.bikes, 'b1').get()).data()?['name'], (await a.bike('b1'))!.name);
    });

    test('a new uid (a move into an account) pulls everything and merges the local data in', () async {
      final a = device('a');
      final b = device('b');
      await b.save(_bike('cloud'));
      await b.sync();

      await a.save(_bike('local'));
      await a.sync(uid: 'anonymous-a');
      await a.sync();

      expect((await a.data()).bikes.keys, unorderedEquals(['cloud', 'local']));
      expect(await remote.count(SyncCollection.bikes), 2);
    });

    test('after a wipe, the next run pulls everything again', () async {
      final a = device('a');
      await a.save(_bike('b1'));
      await a.sync();

      await a.database.deleteAllUserData();
      await a.database.syncDao.reset();
      await a.sync();

      expect(await a.bike('b1'), isNotNull);
    });

    test('a backup restored with overwrite wins over the newer cloud versions on every device', () async {
      final a = device('a');
      final b = device('b');
      await a.save(_bike('b1', name: 'Original'));
      await a.save(_bike('b2', name: 'Kept'));
      await a.sync();
      final backup = await a.data();
      await b.sync();
      await b.save(_bike('b1', name: 'Broken', at: 10));
      await b.save(_bike('b2', name: 'Kept', at: 10, isDeleted: true));
      await b.sync();
      await a.sync();

      await FileImport.overwrite(remoteData: backup, database: a.database);
      await a.sync();
      await b.sync();

      for (final d in [a, b]) {
        expect((await d.bike('b1'))!.name, 'Original');
        expect((await d.bike('b2'))!.isDeleted, isFalse);
      }
    });

    test('a backup restored with replace sends the newer records to the trash on every device', () async {
      final a = device('a');
      final b = device('b');
      await a.save(_bike('b1'));
      await a.sync();
      final backup = await a.data();
      await a.save(_bike('b2', at: 10));
      await a.sync();
      await b.sync();

      await FileImport.replace(remoteData: backup, database: a.database);
      await a.sync();
      await b.sync();

      for (final d in [a, b]) {
        expect((await d.bike('b1'))!.isDeleted, isFalse);
        expect((await d.bike('b2'))!.isDeleted, isTrue);
      }
    });
  });

  group('CloudSyncService', () {
    late AppDatabase db;
    late AccountService account;
    late FakeBackupRemote backups;
    late CloudSyncService service;

    setUp(() async {
      db = AppDatabase.memory();
      account = AccountService(
        auth: _FakeAuth(_FakeUser(_uid, deviceIdClaim: 'device-1')),
        api: _FakeAccountApi(),
        describeDevice: () async => (platform: 'android', name: null),
        clearLocalData: ({required removeData}) async {},
      );
      await account.initialize(enableAccounts: true, enableCloudSync: true);
      backups = FakeBackupRemote();
      service = CloudSyncService(
        db,
        remote: remote,
        backupRemote: backups,
        debounce: const Duration(milliseconds: 20),
      );
    });

    tearDown(() async {
      service.dispose();
      account.dispose();
      await db.close();
    });

    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 100));

    test('does nothing without cloud sync, premium or an account session', () async {
      service.update(enabled: false, premium: true, account: account);
      await settle();
      service.update(enabled: true, premium: false, account: account);
      await settle();
      expect(remote.pulls, 0);
      expect(service.isActive, isFalse);

      service.update(enabled: true, premium: true, account: account);
      await settle();
      expect(service.isActive, isTrue);
      expect(remote.pulls, greaterThan(0));
      expect(service.status, CloudSyncStatus.idle);
      expect(service.lastSyncAt, isNotNull);
    });

    test('a local edit is pushed after the debounce', () async {
      service.update(enabled: true, premium: true, account: account);
      await settle();

      await SyncLocalStore(db).write(_bike('b1'), adjustmentTypes: const {});
      await settle();

      expect(await remote.count(SyncCollection.bikes), 1);
      expect(service.pendingCount, 0);
    });

    test('before a sign-out the outbox is pushed; offline the pending count comes back', () async {
      service.update(enabled: true, premium: true, account: account);
      await settle();

      await SyncLocalStore(db).write(_bike('b1'), adjustmentTypes: const {});
      expect(await service.pushBeforeSignOut(), 0);

      remote.failWith = FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
      await SyncLocalStore(db).write(_bike('b2'), adjustmentTypes: const {});
      expect(await service.pushBeforeSignOut(), 1);
      expect(service.status, CloudSyncStatus.offline);
    });

    test('a failed run shows the error status', () async {
      remote.failWith = Exception('broken');
      service.update(enabled: true, premium: true, account: account);
      await settle();

      expect(service.status, CloudSyncStatus.error);
    });

    group('backups', () {
      test('a run saves the daily backup, which the restore list shows and reads', () async {
        service.update(enabled: true, premium: true, account: account);
        await settle();
        await SyncLocalStore(db).write(_bike('b1', name: 'Trail bike'), adjustmentTypes: const {});
        await settle();

        final listed = switch (await service.listBackups()) {
          DataSuccess(:final value) => value,
          DataFailure(:final error) => fail('$error'),
        };
        final read = switch (await service.readBackup(listed.single)) {
          DataSuccess(:final value) => value,
          DataFailure(:final error) => fail('$error'),
        };
        expect(read.bikes['b1']?.name, 'Trail bike');
      });

      test('a failed backup does not fail the sync', () async {
        backups.quotaFull = true;
        service.update(enabled: true, premium: true, account: account);
        await SyncLocalStore(db).write(_bike('b1'), adjustmentTypes: const {});
        await settle();

        expect(service.status, CloudSyncStatus.idle);
        expect(await remote.count(SyncCollection.bikes), 1);
      });

      test('without an active sync there is nothing to list', () async {
        backups.cloud['20261113_090000_backup.json'] = utf8.encode('{}');

        expect(
          await service.listBackups(),
          isA<DataSuccess<List<CloudBackup>>>().having((result) => result.value, 'value', isEmpty),
        );
        expect(backups.lists, 0);
      });
    });

    group('attachments', () {
      const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
      late Directory documents;
      late Directory temporary;
      late FakeAttachmentRemote files;
      late CloudSyncService withFiles;

      final photo = Attachment(id: 'photo', extension: '.jpg', name: 'photo.jpg');

      setUp(() async {
        documents = await Directory.systemTemp.createTemp('cloud_sync_docs_');
        temporary = await Directory.systemTemp.createTemp('cloud_sync_tmp_');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          pathProviderChannel,
          (call) async => switch (call.method) {
            'getApplicationDocumentsDirectory' => documents.path,
            'getTemporaryDirectory' => temporary.path,
            _ => null,
          },
        );
        files = FakeAttachmentRemote();
        withFiles = CloudSyncService(
          db,
          remote: remote,
          attachmentRemote: files,
          debounce: const Duration(milliseconds: 20),
        );
      });

      tearDown(() async {
        withFiles.dispose();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          pathProviderChannel,
          null,
        );
        await documents.delete(recursive: true);
        await temporary.delete(recursive: true);
      });

      Future<void> addPhotoToBike() async {
        await AttachmentStorageService().ensureDir();
        await (await AttachmentStorageService().resolve(photo.filename)).writeAsBytes([1, 2, 3]);
        await DatabaseMigrationService(db).migrateFromSelectedData(
          SelectedData(bikes: {'b1': Bike(id: 'b1', name: 'Bike', person: null, attachments: [photo])}),
        );
      }

      test('the files go up after the records', () async {
        withFiles.update(enabled: true, premium: true, account: account);
        await settle();

        await addPhotoToBike();
        await settle();

        expect(await remote.count(SyncCollection.bikes), 1);
        expect(files.cloud.keys, [photo.filename]);
        expect(withFiles.pendingAttachmentUploads, 0);
        expect(withFiles.status, CloudSyncStatus.idle);
      });

      test('a file that is not uploaded yet counts as unsynced before a sign-out', () async {
        withFiles.update(enabled: true, premium: true, account: account);
        await settle();
        files.offline = true;
        await addPhotoToBike();
        await settle();

        expect(await withFiles.pushBeforeSignOut(), 1, reason: 'the record is in the cloud, the photo is not');
        expect(files.cloud, isEmpty);

        files.offline = false;
        expect(await withFiles.pushBeforeSignOut(), 0);
        expect(files.cloud.keys, [photo.filename]);
      });

      test('a full quota is flagged for the status line without failing the sync', () async {
        withFiles.update(enabled: true, premium: true, account: account);
        await settle();
        files.quota = 1;
        files.reportedBytes = AttachmentSync.quotaBytes;
        await addPhotoToBike();
        await settle();

        expect(withFiles.attachmentQuotaFull, isTrue);
        expect(withFiles.status, CloudSyncStatus.idle);
      });

      test('being offline while uploading shows the offline status, not an error', () async {
        withFiles.update(enabled: true, premium: true, account: account);
        await settle();
        files.failNext = TimeoutException('offline');
        await addPhotoToBike();
        await settle();

        expect(withFiles.status, CloudSyncStatus.offline);
        expect(withFiles.pendingAttachmentUploads, 1);
      });

      test('a missing file is downloaded while sync is active, and reported otherwise', () async {
        files.cloud[photo.filename] = [7, 8];
        expect(await withFiles.downloadAttachment(photo), AttachmentDownloadResult.notSyncing);

        withFiles.update(enabled: true, premium: true, account: account);
        await settle();

        expect(await withFiles.downloadAttachment(photo), AttachmentDownloadResult.downloaded);
        expect(await (await AttachmentStorageService().resolve(photo.filename)).readAsBytes(), [7, 8]);
      });
    });
  });
}

class _FakeIdTokenResult extends Fake implements IdTokenResult {
  @override
  final Map<String, dynamic>? claims;

  _FakeIdTokenResult(this.claims);
}

class _FakeUser extends Fake implements User {
  @override
  final String uid;
  final String? deviceIdClaim;

  _FakeUser(this.uid, {this.deviceIdClaim});

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async =>
      _FakeIdTokenResult({'deviceId': ?deviceIdClaim});
}

/// Signed in to the account from the start.
class _FakeAuth extends Fake implements FirebaseAuth {
  final User _user;

  _FakeAuth(this._user);

  @override
  User? get currentUser => _user;

  @override
  Stream<User?> authStateChanges() => Stream.value(_user);
}

class _FakeAccountApi extends Fake implements AccountApi {
  @override
  Future<AccountSessionResult?> startSession({
    required String deviceId,
    required String platform,
    String? deviceName,
  }) async => (uid: _uid, token: null);
}
