import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/services/attachment_storage_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory documentsDirectory;
  late Directory temporaryDirectory;
  late AttachmentStorageService service;

  setUp(() async {
    documentsDirectory = await Directory.systemTemp.createTemp('attachment_storage_docs_');
    temporaryDirectory = await Directory.systemTemp.createTemp('attachment_storage_tmp_');
    service = AttachmentStorageService();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pathProviderChannel, (
      call,
    ) async {
      switch (call.method) {
        case 'getApplicationDocumentsDirectory':
          return documentsDirectory.path;
        case 'getTemporaryDirectory':
          return temporaryDirectory.path;
      }
      return null;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      null,
    );
    await documentsDirectory.delete(recursive: true);
    await temporaryDirectory.delete(recursive: true);
  });

  Future<File> sourceFile(String name, List<int> bytes) async {
    final file = File(p.join(temporaryDirectory.path, name));
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> storeFile(Attachment attachment, List<int> bytes) async {
    await service.ensureDir();
    await (await service.resolve(attachment.filename)).writeAsBytes(bytes);
  }

  group('AttachmentStorageService', () {
    test('stores files in the flat attachments directory', () async {
      expect(await service.getAttachmentsPath(), p.join(documentsDirectory.path, 'attachments'));
    });

    test('importPicked copies the file and keeps its original name', () async {
      final source = await sourceFile('IMG_1234.JPG', [1, 2, 3]);

      final attachment = await service.importPicked(XFile(source.path));

      expect(attachment.name, 'IMG_1234.JPG');
      expect(attachment.extension, '.jpg');
      expect(attachment.filename, '${attachment.id}.jpg');
      final stored = await service.resolve(attachment.filename);
      expect(await stored.readAsBytes(), [1, 2, 3]);
      expect(source.existsSync(), isTrue);
    });

    test('importFile streams the file and keeps its original name', () async {
      final attachment = await service.importFile(_FakePlatformFile('Fox 38 Manual.PDF', [1, 2, 3]));

      expect(attachment.name, 'Fox 38 Manual.PDF');
      expect(attachment.extension, '.pdf');
      expect(await (await service.resolve(attachment.filename)).readAsBytes(), [1, 2, 3]);
    });

    test('importFile accepts a file of exactly the size cap', () async {
      final attachment = await service.importFile(
        _FakePlatformFile('manual.pdf', [1], length: AttachmentStorageService.maxFileBytes),
      );

      expect(await service.exists(attachment.filename), isTrue);
    });

    test('importFile rejects a file above the size cap without storing it', () async {
      await expectLater(
        service.importFile(_FakePlatformFile('huge.pdf', [1], length: AttachmentStorageService.maxFileBytes + 1)),
        throwsA(isA<AttachmentTooLargeException>().having((e) => e.name, 'name', 'huge.pdf')),
      );

      final dir = Directory(await service.getAttachmentsPath());
      expect(dir.existsSync() ? dir.listSync() : const <FileSystemEntity>[], isEmpty);
    });

    test('importPicked rejects an image above the size cap', () async {
      final source = await sourceFile('huge.jpg', List.filled(AttachmentStorageService.maxFileBytes + 1, 0));

      await expectLater(
        service.importPicked(XFile(source.path)),
        throwsA(isA<AttachmentTooLargeException>()),
      );
    });

    test('copyExisting yields a distinct file with the same name and extension', () async {
      final original = Attachment(extension: '.pdf', name: 'Fox 38 Service Manual');
      await storeFile(original, [4, 5, 6]);

      final copy = await service.copyExisting(original);

      expect(copy.id, isNot(original.id));
      expect(copy.name, original.name);
      expect(copy.extension, original.extension);
      expect(await (await service.resolve(copy.filename)).readAsBytes(), [4, 5, 6]);
      expect(await service.exists(original.filename), isTrue);
    });

    test('copyExisting returns the attachment unchanged when its file is missing', () async {
      final missing = Attachment(extension: '.pdf', name: 'Missing');

      expect(await service.copyExisting(missing), missing);
    });

    test('deleteFiles removes the given files and skips missing ones', () async {
      final keep = Attachment(extension: '.jpg', name: 'keep.jpg');
      final remove = Attachment(extension: '.jpg', name: 'remove.jpg');
      await storeFile(keep, [1]);
      await storeFile(remove, [2]);

      await service.deleteFiles([remove.filename, 'missing.pdf']);

      expect(await service.exists(keep.filename), isTrue);
      expect(await service.exists(remove.filename), isFalse);
    });

    test('deleteAll removes the attachments directory', () async {
      await storeFile(Attachment(extension: '.pdf', name: 'Manual'), [1]);

      await service.deleteAll();

      expect(Directory(await service.getAttachmentsPath()).existsSync(), isFalse);
    });

    test('a subset bundle includes attachments of its setups, bikes and components only', () async {
      final database = AppDatabase.memory();
      addTearDown(database.close);

      final setupAttachment = Attachment(extension: '.jpg', name: 'setup.jpg');
      final bikeAttachment = Attachment(extension: '.pdf', name: 'Frame Manual');
      final componentAttachment = Attachment(extension: '', name: 'notes');
      final otherAttachment = Attachment(extension: '.jpg', name: 'other.jpg');
      for (final attachment in [setupAttachment, bikeAttachment, componentAttachment, otherAttachment]) {
        await storeFile(attachment, [7]);
      }

      final now = DateTime.now();
      final subset = SelectedData(
        bikes: {'b1': Bike(id: 'b1', name: 'Bike', person: null, attachments: [bikeAttachment])},
        components: {
          'c1': Component(
            id: 'c1',
            name: 'Fork',
            componentType: ComponentType.fork,
            installations: const [],
            attachments: [componentAttachment],
          ),
        },
        setups: {
          's1': Setup(
            id: 's1',
            datetime: now,
            datetimeLocal: now,
            tags: const {},
            bike: 'b1',
            person: null,
            bikeAdjustmentValues: const {},
            personAdjustmentValues: const {},
            attachments: [setupAttachment],
          ),
        },
      );

      final bundle = await service.exportBundle(database, selectedData: subset);
      final archive = ZipDecoder().decodeBytes(await bundle.readAsBytes());
      final names = archive.files.map((f) => f.name).toSet();

      expect(names, contains('data.json'));
      expect(
        names.where((name) => name.startsWith('attachments/')),
        unorderedEquals([
          'attachments/${setupAttachment.filename}',
          'attachments/${bikeAttachment.filename}',
          'attachments/${componentAttachment.filename}',
        ]),
      );
    });

    test('a full bundle includes every stored file', () async {
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final unlinked = Attachment(extension: '.jpg', name: 'unlinked.jpg');
      await storeFile(unlinked, [1]);

      final bundle = await service.exportBundle(database);
      final archive = ZipDecoder().decodeBytes(await bundle.readAsBytes());

      expect(archive.files.map((f) => f.name), contains('attachments/${unlinked.filename}'));
    });
  });
}

final class _FakePlatformFile extends PlatformFile {
  _FakePlatformFile(this.name, List<int> bytes, {int? length})
    : _bytes = Uint8List.fromList(bytes),
      _length = length ?? bytes.length;

  @override
  final String name;
  final Uint8List _bytes;
  final int _length;

  @override
  Uri get uri => Uri.parse('content://fake/$name');

  @override
  XFile get xFile => XFile.fromData(_bytes, name: name);

  @override
  Future<int> length() async => _length;

  @override
  Future<Uint8List> readAsBytes() async => _bytes;

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(_bytes);
}
