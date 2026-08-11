import 'dart:convert';
import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/services/file_save_service.dart';
import 'package:bike_setup_tracker/utils/file_export.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingFileSaveService extends FileSaveService {
  final FileSaveOutcome outcome;
  final Object? error;
  String? fileName;
  List<int>? bytes;
  String? extension;

  RecordingFileSaveService({
    this.outcome = FileSaveOutcome.saved,
    this.error,
  });

  @override
  Future<FileSaveOutcome> saveFile({
    required String fileName,
    required List<int> bytes,
    required String extension,
  }) async {
    this.fileName = fileName;
    this.bytes = List<int>.from(bytes);
    this.extension = extension;
    if (error != null) throw error!;
    return outcome;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory testDirectory;
  late AppDatabase database;

  setUp(() async {
    testDirectory = await Directory.systemTemp.createTemp('file_export_test_');
    database = AppDatabase.memory();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pathProviderChannel, (
      call,
    ) async {
      switch (call.method) {
        case 'getTemporaryDirectory':
        case 'getApplicationDocumentsDirectory':
          return testDirectory.path;
      }
      return null;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      null,
    );
    await database.close();
    await testDirectory.delete(recursive: true);
  });

  Future<BuildContext> pumpContext(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (builderContext) {
              context = builderContext;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return context;
  }

  testWidgets('JSON save shows success and forwards generated JSON', (tester) async {
    final context = await pumpContext(tester);
    final service = RecordingFileSaveService();

    await FileExport.saveJson(
      context: context,
      database: database,
      fileSaveService: service,
    );
    await tester.pump();

    expect(find.text('File saved'), findsOneWidget);
    expect(service.fileName, matches(RegExp(r'^\d{8}_\d{6}_export\.json$')));
    expect(service.extension, 'json');
    expect(jsonDecode(utf8.decode(service.bytes!)), isA<Map<String, dynamic>>());
  });

  testWidgets('JSON save cancellation is silent', (tester) async {
    final context = await pumpContext(tester);
    final service = RecordingFileSaveService(
      outcome: FileSaveOutcome.cancelled,
    );

    await FileExport.saveJson(
      context: context,
      database: database,
      fileSaveService: service,
    );
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('File saved'), findsNothing);
    expect(find.textContaining('Export failed'), findsNothing);
  });

  testWidgets('JSON save failure shows themed error feedback', (tester) async {
    final context = await pumpContext(tester);
    final service = RecordingFileSaveService(error: StateError('save failed'));

    await FileExport.saveJson(
      context: context,
      database: database,
      fileSaveService: service,
    );
    await tester.pump();

    expect(find.textContaining('Export failed'), findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(
      snackBar.backgroundColor,
      Theme.of(context).colorScheme.errorContainer,
    );
  });

  testWidgets('image bundle save forwards ZIP filename and bytes', (tester) async {
    final context = await pumpContext(tester);
    final service = RecordingFileSaveService();

    await tester.runAsync(
      () => FileExport.saveImageBundle(
        context: context,
        database: database,
        fileSaveService: service,
      ),
    );
    await tester.pump();

    expect(find.text('File saved'), findsOneWidget);
    expect(
      service.fileName,
      matches(RegExp(r'^\d{8}_\d{6}_bike_setup_bundle\.zip$')),
    );
    expect(service.extension, 'zip');
    expect(service.bytes!.take(2), [0x50, 0x4b]);
  });

  testWidgets('latest backup save forwards recovered filename and bytes', (tester) async {
    final context = await pumpContext(tester);
    final service = RecordingFileSaveService();

    await tester.runAsync(() async {
      final backupDirectory = Directory('${testDirectory.path}/backup');
      await backupDirectory.create();
      final backup = File(
        '${backupDirectory.path}/20260811_120000_backup.json',
      );
      await backup.writeAsString('{"backup":true}');
      await FileExport.exportLatestBackup(
        context,
        fileSaveService: service,
      );
    });
    await tester.pump();

    expect(find.text('File saved'), findsOneWidget);
    expect(service.fileName, 'recovered_20260811_120000_backup.json');
    expect(service.extension, 'json');
    expect(utf8.decode(service.bytes!), '{"backup":true}');
  });
}
