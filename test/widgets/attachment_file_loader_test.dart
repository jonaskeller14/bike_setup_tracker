import 'dart:async';
import 'dart:io';

import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/services/cloud_sync_service.dart';
import 'package:bike_setup_tracker/services/sync/attachment_sync.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/attachment_file_loader.dart';
import 'package:bike_setup_tracker/widgets/attachment_strip.dart';
import 'package:bike_setup_tracker/widgets/attachment_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../goldens/support/localized_test_app.dart';

/// A cloud sync whose downloads the test completes.
class _FakeCloudSync extends Fake with ChangeNotifier implements CloudSyncService {
  @override
  bool isActive;

  final List<({String filename, bool force, Completer<AttachmentDownloadResult> result})> requests = [];

  _FakeCloudSync({this.isActive = true});

  void becomeActive() {
    isActive = true;
    notifyListeners();
  }

  @override
  Future<AttachmentDownloadResult> downloadAttachment(Attachment attachment, {bool force = false}) {
    final completer = Completer<AttachmentDownloadResult>();
    requests.add((filename: attachment.filename, force: force, result: completer));
    return completer.future;
  }
}

void main() {
  late Directory dir;
  final photo = Attachment(id: 'photo', extension: '.jpg', name: 'photo.jpg');

  // Synchronous file access: widget tests run in a fake-async zone.
  setUp(() {
    dir = Directory.systemTemp.createTempSync('attachment_loader_');
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  Widget app(Widget child, {_FakeCloudSync? sync, ThemeData? theme}) {
    final home = Scaffold(body: child);
    return localizedTestApp(
      theme: theme ?? materialAppTheme,
      home: sync == null ? home : ChangeNotifierProvider<CloudSyncService>.value(value: sync, child: home),
    );
  }

  Widget loader({VoidCallback? onChanged}) => AttachmentFileLoader(
    attachment: photo,
    attachmentsDir: dir.path,
    onChanged: onChanged,
    builder: (context, file, state) => Text('${state.status.name}/${state.result?.name}'),
  );

  group('AttachmentFileLoader', () {
    testWidgets('a file on this device is used without asking the cloud', (tester) async {
      File(p.join(dir.path, photo.filename)).writeAsBytesSync([1]);
      final sync = _FakeCloudSync();

      await tester.pumpWidget(app(loader(), sync: sync));

      expect(find.text('ready/null'), findsOneWidget);
      expect(sync.requests, isEmpty);
    });

    testWidgets('without cloud sync a missing file is just missing', (tester) async {
      await tester.pumpWidget(app(loader()));
      expect(find.text('missing/notSyncing'), findsOneWidget);

      await tester.pumpWidget(app(loader(), sync: _FakeCloudSync(isActive: false)));
      expect(find.text('missing/notSyncing'), findsOneWidget);
    });

    testWidgets('a missing file loads from the cloud and then shows', (tester) async {
      final sync = _FakeCloudSync();
      var changed = 0;

      await tester.pumpWidget(app(loader(onChanged: () => changed++), sync: sync));
      expect(find.text('loading/null'), findsOneWidget);
      expect(sync.requests.single.filename, photo.filename);
      expect(sync.requests.single.force, isFalse);

      File(p.join(dir.path, photo.filename)).writeAsBytesSync([1]);
      sync.requests.single.result.complete(AttachmentDownloadResult.downloaded);
      await tester.pump();

      expect(find.text('ready/downloaded'), findsOneWidget);
      expect(changed, 1);
    });

    testWidgets('a file the cloud lacks can be asked for again', (tester) async {
      final sync = _FakeCloudSync();
      late AttachmentFileState seen;
      await tester.pumpWidget(
        app(
          AttachmentFileLoader(
            attachment: photo,
            attachmentsDir: dir.path,
            builder: (context, file, state) {
              seen = state;
              return Text('${state.status.name}/${state.result?.name}/${state.cloudIssue}');
            },
          ),
          sync: sync,
        ),
      );
      sync.requests.single.result.complete(AttachmentDownloadResult.notInCloud);
      await tester.pump();
      expect(find.text('missing/notInCloud/true'), findsOneWidget);

      seen.retry();
      await tester.pump();

      expect(find.text('loading/null/false'), findsOneWidget);
      expect(sync.requests, hasLength(2));
      expect(sync.requests.last.force, isTrue);
    });

    testWidgets('a session that comes up after the first build triggers the download', (tester) async {
      final sync = _FakeCloudSync(isActive: false);
      await tester.pumpWidget(app(loader(), sync: sync));
      expect(find.text('missing/notSyncing'), findsOneWidget);

      sync.becomeActive();
      await tester.pump();

      expect(find.text('loading/null'), findsOneWidget);
      expect(sync.requests, hasLength(1));
    });

    testWidgets('an answer that arrives after the widget is gone does nothing', (tester) async {
      final sync = _FakeCloudSync();
      await tester.pumpWidget(app(loader(), sync: sync));

      await tester.pumpWidget(app(const SizedBox.shrink(), sync: sync));
      sync.requests.single.result.complete(AttachmentDownloadResult.downloaded);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('attachment strip and viewer while the file is fetched', () {
    for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
      testWidgets('the thumbnail shows a spinner, then the cloud-off icon ($label)', (tester) async {
        final sync = _FakeCloudSync();
        await tester.pumpWidget(
          app(AttachmentStrip(attachments: [photo], attachmentsDir: dir.path), sync: sync, theme: theme),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(Image), findsNothing);

        sync.requests.single.result.complete(AttachmentDownloadResult.notInCloud);
        await tester.pump();

        expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('the viewer says why an image is missing and offers a retry ($label)', (tester) async {
        final sync = _FakeCloudSync();
        await tester.pumpWidget(
          app(AttachmentViewer(attachments: [photo], attachmentsDir: dir.path), sync: sync, theme: theme),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        sync.requests.single.result.complete(AttachmentDownloadResult.offline);
        await tester.pump();

        expect(find.textContaining('No connection'), findsOneWidget);
        await tester.tap(find.text('Try again'));
        await tester.pump();
        expect(sync.requests, hasLength(2));
        expect(sync.requests.last.force, isTrue);
      });

      testWidgets('the viewer of a PDF enables sharing once the file arrived ($label)', (tester) async {
        final pdf = Attachment(id: 'manual', extension: '.pdf', name: 'Manual');
        final sync = _FakeCloudSync();
        await tester.pumpWidget(
          app(AttachmentViewer(attachments: [pdf], attachmentsDir: dir.path), sync: sync, theme: theme),
        );
        expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);

        File(p.join(dir.path, pdf.filename)).writeAsBytesSync([1, 2, 3]);
        sync.requests.single.result.complete(AttachmentDownloadResult.downloaded);
        await tester.pump();

        expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
        expect(find.text('3 B'), findsOneWidget);
      });
    }
  });
}
