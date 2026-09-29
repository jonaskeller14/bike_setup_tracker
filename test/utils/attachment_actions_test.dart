import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/attachment_storage_service.dart';
import 'package:bike_setup_tracker/utils/attachment_actions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Allow Drift streams to propagate through subscriptions.
Future<void> pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Attachment pdf(String id, {String? name}) => Attachment(id: id, extension: '.pdf', name: name ?? '$id.pdf');

  group('removedAttachments', () {
    test('returns the originals missing from the edited list, matched by id', () {
      final a = pdf('a');
      final b = pdf('b');
      final c = pdf('c');

      final removed = AttachmentActions.removedAttachments([a, b, c], [c, a]);

      expect(removed, [b]);
    });

    test('a renamed attachment is not removed', () {
      final a = pdf('a', name: 'Manual');

      final removed = AttachmentActions.removedAttachments([a], [a.copyWith(name: 'Fox 38 Manual')]);

      expect(removed, isEmpty);
    });

    test('attachments added in the edited list are ignored', () {
      final removed = AttachmentActions.removedAttachments([pdf('a')], [pdf('a'), pdf('b')]);

      expect(removed, isEmpty);
    });
  });

  group('attachment files', () {
    const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
    late Directory documentsDirectory;
    late AttachmentStorageService service;

    setUp(() async {
      documentsDirectory = await Directory.systemTemp.createTemp('attachment_actions_docs_');
      service = AttachmentStorageService();
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

    Future<void> storeFile(Attachment attachment, List<int> bytes) async {
      await service.ensureDir();
      await (await service.resolve(attachment.filename)).writeAsBytes(bytes);
    }

    test('copyAttachmentFiles gives each copy a new file with the same name and order', () async {
      final manual = pdf('manual', name: 'Fox 38 Manual');
      final photo = Attachment(id: 'photo', extension: '.jpg', name: 'IMG_1234.jpg');
      await storeFile(manual, [1, 2, 3]);
      await storeFile(photo, [4, 5]);

      final copies = await AttachmentActions.copyAttachmentFiles([manual, photo]);

      expect(copies.map((a) => a.name), ['Fox 38 Manual', 'IMG_1234.jpg']);
      expect(copies.map((a) => a.extension), ['.pdf', '.jpg']);
      expect(copies.map((a) => a.id), isNot(contains(anyOf('manual', 'photo'))));
      expect(await (await service.resolve(copies[0].filename)).readAsBytes(), [1, 2, 3]);
      expect(await (await service.resolve(copies[1].filename)).readAsBytes(), [4, 5]);
      expect(await service.exists(manual.filename), isTrue);
      expect(await service.exists(photo.filename), isTrue);
    });

    test('deleteUnsaved deletes every file when the form was discarded', () async {
      final a = pdf('a');
      final b = pdf('b');
      await storeFile(a, [1]);
      await storeFile(b, [2]);

      await AttachmentActions.deleteUnsaved([a, b], saved: null);

      expect(await service.exists(a.filename), isFalse);
      expect(await service.exists(b.filename), isFalse);
    });

    test('deleteUnsaved keeps the files that were saved', () async {
      final a = pdf('a');
      final b = pdf('b');
      await storeFile(a, [1]);
      await storeFile(b, [2]);

      await AttachmentActions.deleteUnsaved([a, b], saved: [b.copyWith(name: 'Renamed')]);

      expect(await service.exists(a.filename), isFalse);
      expect(await service.exists(b.filename), isTrue);
    });
  });

  group('removeAttachmentReferences', () {
    late AppDatabase database;
    late AppRepository appRepository;

    setUp(() {
      database = AppDatabase.memory();
      appRepository = AppRepository(database);
    });

    tearDown(() async {
      await appRepository.disposeAndAwaitCancellation();
      await database.close();
    });

    test('strips the filenames from setups, bikes and components', () async {
      final shared = pdf('shared');
      final kept = pdf('kept');
      final bike = Bike(name: 'Bike', person: null, attachments: [shared, kept]);
      final otherBike = Bike(name: 'Other', person: null, attachments: [kept]);
      final component = Component(
        name: 'Fork',
        componentType: ComponentType.fork,
        installations: [Installation.sinceBeginning(parent: bike.id)],
        adjustments: [],
        attachments: [kept, shared],
      );
      final setup = Setup(
        tags: {},
        datetime: DateTime(2026).toUtc(),
        datetimeLocal: DateTime(2026),
        bike: bike.id,
        person: null,
        bikeAdjustmentValues: {},
        personAdjustmentValues: {},
        attachments: [shared],
      );
      await appRepository.addBikes([bike, otherBike]);
      await appRepository.addComponents([component]);
      await appRepository.addSetups([setup]);
      await pumpEventQueue();

      await AttachmentActions.removeAttachmentReferences(appRepository, filenames: {shared.filename});
      await pumpEventQueue();

      expect(appRepository.bikes[bike.id]!.attachments, [kept]);
      expect(appRepository.bikes[otherBike.id]!.attachments, [kept]);
      expect(appRepository.components[component.id]!.attachments, [kept]);
      expect(appRepository.setups[setup.id]!.attachments, isEmpty);
    });
  });
}
