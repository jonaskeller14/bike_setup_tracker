import 'dart:async';
import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/services/attachment_storage_service.dart';
import 'package:bike_setup_tracker/services/database_migration_service.dart';
import 'package:bike_setup_tracker/services/sync/attachment_remote.dart';
import 'package:bike_setup_tracker/services/sync/attachment_sync.dart';
import 'package:bike_setup_tracker/services/sync/sync_engine.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_attachment_remote.dart';

const _uid = 'account-1';
const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documents;
  late Directory temporary;
  late AppDatabase database;
  late FakeAttachmentRemote remote;
  late AttachmentStorageService storage;
  late DateTime now;
  late int changes;
  late AttachmentSync sync;

  AttachmentSync newSync({required int maxConcurrentDownloads, AttachmentRemote? over}) => AttachmentSync(
    database,
    remote: over ?? remote,
    storage: storage,
    onChanged: () => changes++,
    maxConcurrentDownloads: maxConcurrentDownloads,
    now: () => now,
    tempDir: () async => temporary,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({SyncEngine.syncedUidKey: _uid});
    documents = await Directory.systemTemp.createTemp('attachment_sync_docs_');
    temporary = await Directory.systemTemp.createTemp('attachment_sync_tmp_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      _pathProviderChannel,
      (call) async => switch (call.method) {
        'getApplicationDocumentsDirectory' => documents.path,
        'getTemporaryDirectory' => temporary.path,
        _ => null,
      },
    );
    database = AppDatabase.memory();
    remote = FakeAttachmentRemote();
    storage = AttachmentStorageService();
    now = DateTime.utc(2026, 11, 13, 12);
    changes = 0;
    sync = newSync(maxConcurrentDownloads: 3);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      _pathProviderChannel,
      null,
    );
    await database.close();
    await documents.delete(recursive: true);
    await temporary.delete(recursive: true);
  });

  Attachment jpg(String id) => Attachment(id: id, extension: '.jpg', name: '$id.jpg');

  Future<void> own(String bikeId, List<Attachment> attachments, {bool isDeleted = false}) =>
      DatabaseMigrationService(database).migrateFromSelectedData(
        SelectedData(
          bikes: {
            bikeId: Bike(id: bikeId, name: bikeId, person: null, attachments: attachments, isDeleted: isDeleted),
          },
        ),
      );

  Future<void> store(Attachment attachment, [List<int> bytes = const [1, 2, 3]]) async {
    await storage.ensureDir();
    await (await storage.resolve(attachment.filename)).writeAsBytes(bytes);
  }

  Future<void> run() => sync.run(_uid, ensureCurrent: () {});

  group('upload queue', () {
    test('uploads the referenced files the cloud lacks and leaves the ones it has', () async {
      final a = jpg('a'), b = jpg('b'), c = jpg('c');
      await own('bike', [a, b]);
      await own('bike2', [c]);
      for (final attachment in [a, b, c]) {
        await store(attachment);
      }
      remote.cloud[b.filename] = [9];

      await run();

      expect(remote.cloud.keys, unorderedEquals([a.filename, b.filename, c.filename]));
      expect(remote.cloud[b.filename], [9], reason: 'an existing file is never overwritten');
      expect(remote.uploads, 2);
      expect(sync.pendingUploads, 0);
    });

    test('files of trashed rows are uploaded too, until the row is purged', () async {
      final a = jpg('a');
      await own('bike', [a], isDeleted: true);
      await store(a);

      await run();

      expect(remote.cloud.keys, [a.filename]);
    });

    test('files nothing references are not uploaded', () async {
      await store(jpg('loose'));
      await own('bike', const []);

      await run();

      expect(remote.cloud, isEmpty);
      expect(remote.lists, 0, reason: 'nothing to compare, so the cloud is not asked');
    });

    test('a referenced file that is not on this device is skipped, not an error', () async {
      final here = jpg('here'), away = jpg('away');
      await own('bike', [here, away]);
      await store(here);

      await run();

      expect(remote.cloud.keys, [here.filename]);
      expect(sync.pendingUploads, 0, reason: 'a file this device never had is not its to upload');
    });

    test('a file that fails is retried after a back-off, and does not hold up the others', () async {
      final bad = jpg('bad'), good = jpg('good');
      await own('bike', [bad, good]);
      await store(bad);
      await store(good);
      remote.uploadErrors[bad.filename] = const FileSystemException('unreadable');

      await run();
      expect(remote.cloud.keys, [good.filename]);
      expect(sync.pendingUploads, 1);

      remote.uploadErrors.clear();
      await run();
      expect(remote.cloud.keys, [good.filename], reason: 'still backing off');

      now = now.add(const Duration(seconds: 31));
      await run();
      expect(remote.cloud.keys, unorderedEquals([good.filename, bad.filename]));
      expect(sync.pendingUploads, 0);
    });

    test('the back-off doubles with every failure', () async {
      final bad = jpg('bad');
      await own('bike', [bad]);
      await store(bad);
      remote.uploadErrors[bad.filename] = const FileSystemException('unreadable');

      Future<int> attemptsAfter(Duration wait) async {
        now = now.add(wait);
        remote.uploadAttempts = 0;
        await run();
        return remote.uploadAttempts;
      }

      expect(await attemptsAfter(Duration.zero), 1, reason: 'the first failure waits 30 s');
      expect(await attemptsAfter(const Duration(seconds: 29)), 0);
      expect(await attemptsAfter(const Duration(seconds: 2)), 1, reason: 'the second one waits 60 s');
      expect(await attemptsAfter(const Duration(seconds: 59)), 0);
      expect(await attemptsAfter(const Duration(seconds: 2)), 1);
    });

    test('being offline stops the run and keeps the pending count', () async {
      final a = jpg('a');
      await own('bike', [a]);
      await store(a);
      remote.failNext = TimeoutException('offline');

      await expectLater(run(), throwsA(isA<TimeoutException>()));

      expect(sync.pendingUploads, 1);
      expect(remote.cloud, isEmpty);
    });

    test('a file listed in the cloud since the last run counts as uploaded', () async {
      final a = jpg('a');
      await own('bike', [a]);
      await store(a);
      await run();
      expect(sync.pendingUploads, 0);

      remote.failNext = TimeoutException('offline');
      await expectLater(run(), throwsA(isA<TimeoutException>()));

      expect(sync.pendingUploads, 0, reason: 'it was in the cloud on the last successful run');
    });
  });

  group('quota and rejected uploads', () {
    test('a full quota is reported, not thrown, and clears once there is room', () async {
      final a = jpg('a');
      await own('bike', [a]);
      await store(a, List.filled(100, 7));
      remote.quota = 10;
      remote.reportedBytes = AttachmentSync.quotaBytes - 10;

      await run();

      expect(sync.quotaFull, isTrue);
      expect(sync.pendingUploads, 1);
      expect(remote.cloud, isEmpty);
      expect(changes, greaterThan(0));

      remote.quota = null;
      remote.reportedBytes = 0;
      now = now.add(const Duration(minutes: 1));
      await run();

      expect(sync.quotaFull, isFalse);
      expect(remote.cloud.keys, [a.filename]);
    });

    test('a rejected upload that is not about the quota is thrown for the session check', () async {
      final a = jpg('a');
      await own('bike', [a]);
      await store(a);
      remote.uploadErrors[a.filename] = FakeAttachmentRemote.denied();
      remote.reportedBytes = 0;

      await expectLater(run(), throwsA(predicate<Object>(AttachmentSync.isDenied)));

      expect(sync.quotaFull, isFalse);
    });

    test('an upload turned down because another device uploaded the file first counts as done', () async {
      final a = jpg('a');
      await own('bike', [a]);
      await store(a);
      remote.uploadErrors[a.filename] = FakeAttachmentRemote.denied();
      // The other device's copy lands between the listing and the upload.
      final racing = _RacingRemote(remote, a.filename);
      sync = newSync(maxConcurrentDownloads: 3, over: racing);

      await run();

      expect(sync.pendingUploads, 0);
      expect(sync.quotaFull, isFalse);
    });

    test('the quota flag follows the files still waiting', () async {
      final a = jpg('a');
      await own('bike', [a]);
      await store(a, List.filled(100, 7));
      remote.quota = 10;
      remote.reportedBytes = AttachmentSync.quotaBytes;
      await run();
      expect(sync.quotaFull, isTrue);

      // The user removes the file that could not go up.
      await own('bike', const []);
      await run();

      expect(sync.quotaFull, isFalse);
    });
  });

  group('deleting purged files from the cloud', () {
    test('queued files are deleted and leave the queue; a missing one is no problem', () async {
      remote.cloud['gone.jpg'] = [1];
      await AttachmentDeleteQueue.add(['gone.jpg', 'never-uploaded.jpg']);
      await own('bike', const []);

      await run();

      expect(remote.cloud, isEmpty);
      expect(remote.deleted, unorderedEquals(['gone.jpg', 'never-uploaded.jpg']));
      expect(await AttachmentDeleteQueue.read(), isEmpty);
    });

    test('a queued file that a record references again stays', () async {
      final a = jpg('a');
      remote.cloud[a.filename] = [1];
      await AttachmentDeleteQueue.add([a.filename]);
      await own('bike', [a]);

      await run();

      expect(remote.deleted, isEmpty);
      expect(remote.cloud.keys, [a.filename]);
      expect(await AttachmentDeleteQueue.read(), isEmpty);
    });

    test('a failed delete stays queued for the next run', () async {
      await AttachmentDeleteQueue.add(['a.jpg', 'b.jpg']);
      await own('bike', const []);
      remote.failNext = TimeoutException('offline');

      await expectLater(run(), throwsA(isA<TimeoutException>()));
      expect(await AttachmentDeleteQueue.read(), {'a.jpg', 'b.jpg'});

      await run();
      expect(await AttachmentDeleteQueue.read(), isEmpty);
    });

    test('a device that never synced queues nothing', () async {
      SharedPreferences.setMockInitialValues({});

      await AttachmentDeleteQueue.add(['a.jpg']);

      expect(await AttachmentDeleteQueue.read(), isEmpty);
    });
  });

  group('download on first view', () {
    final a = jpg('a');

    test('fetches a missing file into place, and a present one is left alone', () async {
      remote.cloud[a.filename] = [4, 5, 6];

      expect(await sync.download(_uid, a), AttachmentDownloadResult.downloaded);
      expect(await (await storage.resolve(a.filename)).readAsBytes(), [4, 5, 6]);
      expect(temporary.listSync(), isEmpty, reason: 'the temporary download is gone');

      expect(await sync.download(_uid, a), AttachmentDownloadResult.present);
      expect(remote.downloads, 1);
    });

    test('views of the same file share one download', () async {
      remote.cloud[a.filename] = [1];
      remote.downloadGate = Completer();

      final first = sync.download(_uid, a);
      final second = sync.download(_uid, a);
      remote.downloadGate!.complete();

      expect(await first, AttachmentDownloadResult.downloaded);
      expect(await second, AttachmentDownloadResult.downloaded);
      expect(remote.downloads, 1);
    });

    test('at most the allowed number of downloads run at once', () async {
      sync = newSync(maxConcurrentDownloads: 2);
      final files = [for (var i = 0; i < 5; i++) jpg('f$i')];
      for (final file in files) {
        remote.cloud[file.filename] = [1];
      }
      remote.downloadGate = Completer();

      final results = [for (final file in files) sync.download(_uid, file)];
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(remote.concurrentDownloads, 2);
      remote.downloadGate!.complete();

      expect(await Future.wait(results), everyElement(AttachmentDownloadResult.downloaded));
      expect(remote.maxConcurrentDownloads, 2);
    });

    test('a file the cloud lacks is reported, and asked for again only after a minute or on retry', () async {
      expect(await sync.download(_uid, a), AttachmentDownloadResult.notInCloud);
      expect(await sync.download(_uid, a), AttachmentDownloadResult.notInCloud);
      expect(remote.downloads, 1);

      remote.cloud[a.filename] = [1];
      expect(await sync.download(_uid, a), AttachmentDownloadResult.notInCloud, reason: 'remembered');
      expect(await sync.download(_uid, a, force: true), AttachmentDownloadResult.downloaded);
    });

    test('a failure is forgotten after a minute', () async {
      expect(await sync.download(_uid, a), AttachmentDownloadResult.notInCloud);
      remote.cloud[a.filename] = [1];
      now = now.add(const Duration(seconds: 61));

      expect(await sync.download(_uid, a), AttachmentDownloadResult.downloaded);
    });

    test('offline, denied and broken downloads map to results and leave no file behind', () async {
      remote.failNext = TimeoutException('offline');
      expect(await sync.download(_uid, a, force: true), AttachmentDownloadResult.offline);

      remote.failNext = FakeAttachmentRemote.denied();
      expect(await sync.download(_uid, a, force: true), AttachmentDownloadResult.failed);

      remote.failNext = const FileSystemException('disk full');
      expect(await sync.download(_uid, a, force: true), AttachmentDownloadResult.failed);

      expect(await (await storage.resolve(a.filename)).exists(), isFalse);
      expect(temporary.listSync(), isEmpty);
    });

    test('an interrupted download never leaves a partial file under the real name', () async {
      remote.cloud[a.filename] = [1, 2, 3];
      remote.failNext = null;
      sync = newSync(maxConcurrentDownloads: 3, over: _InterruptedRemote(remote));

      expect(await sync.download(_uid, a), AttachmentDownloadResult.failed);

      expect(await (await storage.resolve(a.filename)).exists(), isFalse);
      expect(temporary.listSync(), isEmpty);
    });
  });

  test('reset forgets the quota state of the previous account', () async {
    final a = jpg('a');
    await own('bike', [a]);
    await store(a, List.filled(100, 7));
    remote.quota = 10;
    remote.reportedBytes = AttachmentSync.quotaBytes;
    await run();
    expect(sync.quotaFull, isTrue);

    sync.reset();

    expect(sync.quotaFull, isFalse);
    expect(sync.pendingUploads, 0);
  });
}

/// The cloud gains [filename] right after the first listing, as when another
/// device uploads the same file at the same time.
class _RacingRemote extends FakeAttachmentRemote {
  final FakeAttachmentRemote inner;
  final String filename;
  var _listed = false;

  _RacingRemote(this.inner, this.filename);

  @override
  Future<Set<String>> list(String uid) async {
    final names = await inner.list(uid);
    if (_listed) return {...names, filename};
    _listed = true;
    return names;
  }

  @override
  Future<void> upload(String uid, String filename, File file) => inner.upload(uid, filename, file);

  @override
  Future<int> storageBytes(String uid) => inner.storageBytes(uid);
}

/// Writes half of the file, then fails.
class _InterruptedRemote extends FakeAttachmentRemote {
  final FakeAttachmentRemote inner;

  _InterruptedRemote(this.inner);

  @override
  Future<bool> download(String uid, String filename, File destination) async {
    await destination.writeAsBytes([1]);
    throw FirebaseException(plugin: 'firebase_storage', code: 'canceled');
  }
}
