import 'package:bike_setup_tracker/services/file_save_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns saved and forwards JSON filename, extension, and bytes', () async {
    String? receivedFileName;
    FileType? receivedType;
    List<String>? receivedExtensions;
    Uint8List? receivedBytes;
    final service = FileSaveService(({
      required String fileName,
      required FileType type,
      List<String>? allowedExtensions,
      required Uint8List bytes,
    }) async {
      receivedFileName = fileName;
      receivedType = type;
      receivedExtensions = allowedExtensions;
      receivedBytes = bytes;
      return Uri.file('/saved/export.json');
    });

    final outcome = await service.saveFile(
      fileName: 'export.json',
      bytes: [1, 2, 3],
      extension: 'json',
    );

    expect(outcome, FileSaveOutcome.saved);
    expect(receivedFileName, 'export.json');
    expect(receivedType, FileType.custom);
    expect(receivedExtensions, ['json']);
    expect(receivedBytes, isA<Uint8List>());
    expect(receivedBytes, [1, 2, 3]);
  });

  test('returns cancelled and forwards ZIP filename and extension', () async {
    String? receivedFileName;
    List<String>? receivedExtensions;
    final service = FileSaveService(({
      required String fileName,
      required FileType type,
      List<String>? allowedExtensions,
      required Uint8List bytes,
    }) async {
      receivedFileName = fileName;
      receivedExtensions = allowedExtensions;
      return null;
    });

    final outcome = await service.saveFile(
      fileName: 'bundle.zip',
      bytes: const [],
      extension: 'zip',
    );

    expect(outcome, FileSaveOutcome.cancelled);
    expect(receivedFileName, 'bundle.zip');
    expect(receivedExtensions, ['zip']);
  });

  test('lets platform errors propagate', () async {
    final service = FileSaveService(({
      required String fileName,
      required FileType type,
      List<String>? allowedExtensions,
      required Uint8List bytes,
    }) async {
      throw PlatformException(code: 'save_failed');
    });

    expect(
      () => service.saveFile(
        fileName: 'export.json',
        bytes: const [],
        extension: 'json',
      ),
      throwsA(isA<PlatformException>()),
    );
  });
}
