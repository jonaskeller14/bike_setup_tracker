// Renders every state of UpdateRequiredPage, the full-screen gate shown when
// this build is below min_supported_build, to PNGs in
// build/gallery/update_required_page/ (git-ignored). Skipped by default (see
// dart_test.yaml); run it on demand with:
//
//   flutter test test/gallery/update_required_page_gallery_test.dart --run-skipped
//
// overview_light.png and overview_dark.png hold everything on one page; each
// screenshot is also written on its own.
//
// The page shows no user data, so every text on screen comes from the UI.
//
// Besides the pictures, the second test checks that no layout traps the user:
// in every language, width and text scale both buttons can be reached and do
// their job.
@Tags(['gallery'])
library;

import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/pages/update_required_page.dart';
import 'package:bike_setup_tracker/services/file_save_service.dart';
import 'package:bike_setup_tracker/utils/app_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../goldens/support/localized_test_app.dart';
import 'gallery_harness.dart';

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
const _urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

class _RecordingFileSaveService extends FileSaveService {
  final Exception? error;
  int calls = 0;

  _RecordingFileSaveService({this.error});

  @override
  Future<FileSaveOutcome> saveFile({
    required String fileName,
    required List<int> bytes,
    required String extension,
  }) async {
    calls++;
    if (error != null) throw error!;
    return FileSaveOutcome.saved;
  }
}

class _Layout {
  final String label;
  final Size size;
  final double textScale;
  final EdgeInsets padding;

  const _Layout(this.label, this.size, {this.textScale = 1, this.padding = EdgeInsets.zero});
}

const _layouts = [
  _Layout('320 px', Size(320, 568)),
  _Layout('320 px · text 2.0', Size(320, 568), textScale: 2),
  _Layout('wide', Size(800, 600)),
  _Layout('wide · text 2.0', Size(800, 600), textScale: 2),
];

const _notchLayout = _Layout(
  'notch and home indicator',
  Size(390, 844),
  padding: EdgeInsets.only(top: 47, bottom: 34),
);

const _appKey = ValueKey('update-required-app');

void main() {
  late Directory output;
  late Directory files;
  late AppDatabase database;
  late List<String> launchedUrls;
  late bool canLaunch;

  setUpAll(() async => output = await prepareGallery('update_required_page'));

  setUp(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    files = await Directory.systemTemp.createTemp('update_required_gallery_');
    database = AppDatabase.memory();
    launchedUrls = [];
    canLaunch = true;
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_pathProviderChannel, (call) async => files.path);
    messenger.setMockMethodCallHandler(_urlLauncherChannel, (call) async {
      final url = (call.arguments as Map)['url'] as String;
      switch (call.method) {
        case 'canLaunch':
          return canLaunch;
        case 'launch':
          launchedUrls.add(url);
          return true;
      }
      return null;
    });
  });

  tearDown(() async {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_pathProviderChannel, null);
    messenger.setMockMethodCallHandler(_urlLauncherChannel, null);
    await database.close();
    await files.delete(recursive: true);
  });

  Future<void> pumpPage(
    WidgetTester tester,
    ThemeData theme,
    _Layout layout, {
    Locale locale = const Locale('en'),
    FileSaveService? fileSaveService,
    Key? key,
  }) async {
    tester.view.physicalSize = layout.size;
    tester.view.padding = FakeViewPadding(top: layout.padding.top, bottom: layout.padding.bottom);
    await tester.pumpWidget(
      RepaintBoundary(
        key: key ?? _appKey,
        child: localizedTestApp(
          theme: theme,
          locale: locale,
          debugShowCheckedModeBanner: false,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(layout.textScale)),
            child: child!,
          ),
          home: UpdateRequiredPage(database: database, fileSaveService: fileSaveService),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Export does real file IO (backup, ZIP in an isolate), which fake async
  /// never completes, so the tap and the wait run on the real event loop.
  Future<void> tapAndWait(WidgetTester tester, Finder button, bool Function() done) async {
    await tester.runAsync(() async {
      await tester.tap(button);
      for (var i = 0; i < 100 && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  for (final (name, theme, background, textColor) in galleryThemes) {
    testWidgets('renders the $name gallery', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      final session = GallerySession(tester, output, themeName: name, background: background, textColor: textColor);

      for (final locale in AppLocalizations.supportedLocales) {
        for (final (index, layout) in _layouts.indexed) {
          final key = ValueKey('${locale.languageCode}-$index');
          await pumpPage(tester, theme, layout, locale: locale, key: key);
          final slug = '${locale.languageCode}_${layout.label.replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
          final RenderRepaintBoundary boundary = tester.renderObject(find.byKey(key));
          await session.add(slug, '${locale.languageCode} · ${layout.label}', boundary);

          if (layout.textScale > 1 && layout.size.width < 400) {
            final l10n = lookupAppLocalizations(locale);
            await tester.ensureVisible(find.text(l10n.updateRequiredNoUpdateHint));
            await tester.pumpAndSettle();
            await session.add(
              '${slug}_end',
              '${locale.languageCode} · ${layout.label} · scrolled to the end',
              boundary,
            );
          }
        }
      }

      await pumpPage(tester, theme, _notchLayout);
      await session.add('notch', 'en · ${_notchLayout.label}', tester.renderObject(find.byKey(_appKey)));

      final saved = _RecordingFileSaveService();
      await pumpPage(tester, theme, _layouts.first, fileSaveService: saved, key: const ValueKey('saved'));
      await tapAndWait(tester, find.text('Export backup'), () => saved.calls > 0);
      await session.add(
        'export_saved',
        'Export backup · saved',
        tester.renderObject(find.byKey(const ValueKey('saved'))),
      );

      final failing = _RecordingFileSaveService(error: const FileSystemException('Disk full'));
      await pumpPage(tester, theme, _layouts.first, fileSaveService: failing, key: const ValueKey('failed'));
      await tapAndWait(tester, find.text('Export backup'), () => failing.calls > 0);
      await session.add(
        'export_failed',
        'Export backup · failed',
        tester.renderObject(find.byKey(const ValueKey('failed'))),
      );

      canLaunch = false;
      await pumpPage(tester, theme, _layouts.first, key: const ValueKey('no-store'));
      await tester.tap(find.text('Update'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await session.add(
        'update_no_store',
        'Update · no app can open the store',
        tester.renderObject(find.byKey(const ValueKey('no-store'))),
      );

      await session.finish();
    });
  }

  testWidgets('in every language and layout both buttons can be reached and work', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    final theme = galleryThemes.first.$2;

    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      for (final (index, layout) in [..._layouts, _notchLayout].indexed) {
        final label = '${locale.languageCode} · ${layout.label}';
        final saveService = _RecordingFileSaveService();
        launchedUrls.clear();
        await pumpPage(
          tester,
          theme,
          layout,
          locale: locale,
          fileSaveService: saveService,
          key: ValueKey('${locale.languageCode}-$index'),
        );

        await tester.ensureVisible(find.text(l10n.updateRequiredUpdate));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.updateRequiredUpdate));
        await tester.pumpAndSettle();
        expect(launchedUrls, [AppInfo.playStoreUrl], reason: '$label: Update does not open the store');

        await tester.ensureVisible(find.text(l10n.updateRequiredExportBackup));
        await tester.pumpAndSettle();
        await tapAndWait(tester, find.text(l10n.updateRequiredExportBackup), () => saveService.calls > 0);
        expect(saveService.calls, 1, reason: '$label: Export backup does not save');
        expect(find.text(l10n.exportFileSaved), findsOneWidget, reason: '$label: no confirmation after export');
        await tester.pumpAndSettle(const Duration(seconds: 6));
      }
    }

    launchedUrls.clear();
    await pumpPage(tester, theme.copyWith(platform: TargetPlatform.iOS), _layouts.first, key: const ValueKey('ios'));
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(launchedUrls, [AppInfo.appStorePageUrl], reason: 'iOS opens the App Store page, not the review sheet');
  });
}
