import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/rating/rating_entry.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/services/attachment_storage_service.dart';
import 'package:bike_setup_tracker/services/database_migration_service.dart';
import 'package:bike_setup_tracker/services/trash_cleanup_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  final expired = DateTime.now().toUtc().subtract(const Duration(days: 31));
  final recent = DateTime.now().toUtc().subtract(const Duration(days: 1));
  final cutoff = DateTime.now().toUtc().subtract(TrashCleanupService.retention);

  setUp(() {
    database = AppDatabase.memory();
  });

  tearDown(() async {
    await database.close();
  });

  Attachment jpg(String id) => Attachment(id: id, extension: '.jpg', name: '$id.jpg');

  Bike bike(String id, {DateTime? lastModified, bool isDeleted = false, List<Attachment> attachments = const []}) =>
      Bike(id: id, name: id, person: null, lastModified: lastModified, isDeleted: isDeleted, attachments: attachments);

  Component component(
    String id, {
    DateTime? lastModified,
    bool isDeleted = false,
    List<Attachment> attachments = const [],
  }) => Component(
    id: id,
    name: id,
    lastModified: lastModified,
    isDeleted: isDeleted,
    componentType: ComponentType.other,
    installations: [Installation.sinceBeginning(parent: 'bike')],
    adjustments: [BooleanAdjustment(name: 'Lockout', notes: null, unit: null)],
    attachments: attachments,
  );

  Setup setup(String id, {DateTime? lastModified, bool isDeleted = false, List<Attachment> attachments = const []}) {
    final now = DateTime.now();
    return Setup(
      id: id,
      lastModified: lastModified,
      isDeleted: isDeleted,
      datetime: now,
      datetimeLocal: now,
      tags: const <String>{},
      bike: 'bike',
      person: null,
      bikeAdjustmentValues: const {},
      personAdjustmentValues: const {},
      attachments: attachments,
    );
  }

  TaskRule taskRule(
    String id, {
    DateTime? lastModified,
    bool isDeleted = false,
    List<Attachment> attachments = const [],
  }) => TaskRule(
    id: id,
    name: id,
    tags: const {},
    lastModified: lastModified,
    isDeleted: isDeleted,
    attachments: attachments,
  );

  TaskEntry taskEntry(
    String id, {
    DateTime? lastModified,
    bool isDeleted = false,
    List<Attachment> attachments = const [],
  }) {
    final now = DateTime.now();
    return TaskEntry(
      id: id,
      name: id,
      dateTimeUTC: now.toUtc(),
      dateTimeLocal: now,
      taskRule: 'rule',
      lastModified: lastModified,
      isDeleted: isDeleted,
      attachments: attachments,
    );
  }

  RatingEntry ratingEntry(String id, {DateTime? lastModified, bool isDeleted = false}) {
    final now = DateTime.now();
    return RatingEntry(
      id: id,
      lastModified: lastModified,
      isDeleted: isDeleted,
      bike: 'bike',
      setupId: 'setup',
      dateTimeUTC: now.toUtc(),
      dateTimeLocal: now,
    );
  }

  Future<void> insert(SelectedData data) => DatabaseMigrationService(database).migrateFromSelectedData(data);

  Future<void> insertSetupValue(String setupId) => database
      .into(database.setupAdjustmentValues)
      .insert(SetupAdjustmentValuesCompanion.insert(setupId: setupId, adjustmentId: 'adjustment', value: 'true'));

  Future<void> insertRatingEntryValue(String ratingEntryId) => database
      .into(database.ratingEntryValues)
      .insert(RatingEntryValuesCompanion.insert(ratingEntryId: ratingEntryId, ratingMetricId: 'metric', value: '1'));

  group('AppDatabase.purgeTrash', () {
    test('removes trashed rows older than the cutoff and keeps the rest', () async {
      await insert(
        SelectedData(
          bikes: {
            'old': bike('old', lastModified: expired, isDeleted: true),
            'recent': bike('recent', lastModified: recent, isDeleted: true),
            'live': bike('live', lastModified: expired),
          },
          setups: {
            'old': setup('old', lastModified: expired, isDeleted: true),
            'recent': setup('recent', lastModified: recent, isDeleted: true),
            'live': setup('live', lastModified: expired),
          },
          taskRules: {
            'old': taskRule('old', lastModified: expired, isDeleted: true),
            'live': taskRule('live', lastModified: expired),
          },
          taskEntries: {
            'old': taskEntry('old', lastModified: expired, isDeleted: true),
            'live': taskEntry('live', lastModified: expired),
          },
          persons: {
            'old': Person(id: 'old', name: 'old', lastModified: expired, isDeleted: true),
            'live': Person(id: 'live', name: 'live', lastModified: expired),
          },
        ),
      );

      await database.purgeTrash(cutoff);

      expect((await database.select(database.bikes).get()).map((b) => b.id), unorderedEquals(['recent', 'live']));
      expect((await database.select(database.setups).get()).map((s) => s.id), unorderedEquals(['recent', 'live']));
      expect((await database.select(database.taskRules).get()).map((r) => r.id), ['live']);
      expect((await database.select(database.taskEntries).get()).map((e) => e.id), ['live']);
      expect((await database.select(database.persons).get()).map((p) => p.id), ['live']);
    });

    test('removes the rows nested under a purged row only', () async {
      await insert(
        SelectedData(
          components: {
            'old': component('old', lastModified: expired, isDeleted: true),
            'live': component('live'),
          },
          persons: {
            'old': Person(
              id: 'old',
              name: 'old',
              lastModified: expired,
              isDeleted: true,
              adjustments: [BooleanAdjustment(name: 'Gloves', notes: null, unit: null)],
            ),
          },
          setups: {
            'old': setup('old', lastModified: expired, isDeleted: true),
            'live': setup('live'),
          },
          ratingEntries: {
            'old': ratingEntry('old', lastModified: expired, isDeleted: true),
            'live': ratingEntry('live'),
          },
        ),
      );
      await insertSetupValue('old');
      await insertSetupValue('live');
      await insertRatingEntryValue('old');
      await insertRatingEntryValue('live');

      await database.purgeTrash(cutoff);

      expect((await database.select(database.components).get()).map((c) => c.id), ['live']);
      expect((await database.select(database.adjustments).get()).map((a) => a.componentId), ['live']);
      expect((await database.select(database.installations).get()).map((i) => i.componentId), ['live']);
      expect((await database.select(database.setupAdjustmentValues).get()).map((v) => v.setupId), ['live']);
      expect((await database.select(database.ratingEntryValues).get()).map((v) => v.ratingEntryId), ['live']);
    });

    test('does nothing on an empty database', () async {
      await database.purgeTrash(cutoff);

      expect(await database.watchHasUserData().first, isFalse);
    });
  });

  test('referencedAttachmentFilenames covers every owner type, trashed rows included', () async {
    await insert(
      SelectedData(
        bikes: {
          'bike': bike('bike', attachments: [jpg('bike')]),
        },
        components: {
          'component': component('component', attachments: [jpg('component')]),
        },
        setups: {
          'setup': setup('setup', isDeleted: true, attachments: [jpg('setup')]),
        },
        taskRules: {
          'rule': taskRule('rule', attachments: [jpg('rule')]),
        },
        taskEntries: {
          'entry': taskEntry('entry', isDeleted: true, attachments: [jpg('entry')]),
        },
      ),
    );

    expect(
      await database.referencedAttachmentFilenames(),
      {'bike.jpg', 'component.jpg', 'setup.jpg', 'rule.jpg', 'entry.jpg'},
    );
  });

  group('TrashCleanupService.run', () {
    const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
    late Directory documentsDirectory;
    late AttachmentStorageService storage;

    setUp(() async {
      documentsDirectory = await Directory.systemTemp.createTemp('trash_cleanup_docs_');
      storage = AttachmentStorageService();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pathProviderChannel, (
        call,
      ) async {
        if (call.method == 'getApplicationDocumentsDirectory') return documentsDirectory.path;
        return null;
      });
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        pathProviderChannel,
        null,
      );
      await documentsDirectory.delete(recursive: true);
    });

    Future<void> storeFiles(Iterable<String> ids) async {
      await storage.ensureDir();
      for (final id in ids) {
        await (await storage.resolve(jpg(id).filename)).writeAsBytes([1]);
      }
    }

    Future<Set<String>> storedFiles() async {
      final dir = Directory(await storage.getAttachmentsPath());
      return {for (final file in dir.listSync().whereType<File>()) file.uri.pathSegments.last};
    }

    test('deletes the files of purged rows and keeps those of live and recently trashed rows', () async {
      await insert(
        SelectedData(
          bikes: {
            'old': bike('old', lastModified: expired, isDeleted: true, attachments: [jpg('old')]),
            'recent': bike('recent', lastModified: recent, isDeleted: true, attachments: [jpg('recent')]),
            'live': bike('live', attachments: [jpg('live')]),
          },
        ),
      );
      await storeFiles(['old', 'recent', 'live']);

      await TrashCleanupService.run(database);

      expect(await storedFiles(), {'recent.jpg', 'live.jpg'});
      expect((await database.select(database.bikes).get()).map((b) => b.id), unorderedEquals(['recent', 'live']));
    });

    test('keeps a file of a purged row that a surviving row still references', () async {
      await insert(
        SelectedData(
          bikes: {
            'old': bike('old', lastModified: expired, isDeleted: true, attachments: [jpg('shared')]),
          },
          setups: {
            'live': setup('live', attachments: [jpg('shared')]),
          },
        ),
      );
      await storeFiles(['shared']);

      await TrashCleanupService.run(database);

      expect(await storedFiles(), {'shared.jpg'});
    });

    test('deletes files no row references', () async {
      await insert(
        SelectedData(
          bikes: {
            'live': bike('live', attachments: [jpg('live')]),
          },
        ),
      );
      await storeFiles(['live', 'unlinked']);

      await TrashCleanupService.run(database);

      expect(await storedFiles(), {'live.jpg'});
    });

    test('keeps every file while the database holds no user data', () async {
      await storeFiles(['unlinked']);

      await TrashCleanupService.run(database);

      expect(await storedFiles(), {'unlinked.jpg'});
    });

    test('does not fail when the attachments folder is missing', () async {
      await insert(SelectedData(bikes: {'old': bike('old', lastModified: expired, isDeleted: true)}));

      await TrashCleanupService.run(database);

      expect(await database.select(database.bikes).get(), isEmpty);
    });
  });
}
