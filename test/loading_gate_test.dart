import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/main.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/pages/loading_error_page.dart';
import 'package:bike_setup_tracker/pages/update_required_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/app_hint_service.dart';
import 'package:bike_setup_tracker/services/app_version_config.dart';
import 'package:bike_setup_tracker/utils/app_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAppVersionConfig implements AppVersionConfig {
  _FakeAppVersionConfig(this._load);

  final Future<int> Function() _load;
  int refreshCalls = 0;

  @override
  bool get supportedPlatform => true;

  @override
  Future<int> loadMinSupportedBuild() => _load();

  @override
  void refreshInBackground() => refreshCalls++;
}

class _MockAppRepository extends Mock implements AppRepository {}

/// The success branch is not covered: it mounts the whole service graph
/// (Strava, subscriptions, notifications), and the degraded settings and hints
/// branches need a throwing SharedPreferences store — both cost far more
/// mocking than the assertion would be worth. isAppBlocked has its own tests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final defaultReporter = recordBootError;
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late AppDatabase database;
  late AppRepository repository;
  late AppSettings settings;
  late AppHintService hintService;
  late List<String> reportedReasons;

  setUp(() {
    database = AppDatabase.memory();
    repository = AppRepository(database);
    settings = AppSettings();
    hintService = AppHintService(appRepository: repository, appSettings: settings);

    reportedReasons = [];
    recordBootError = (error, stack, {required reason}) => reportedReasons.add(reason);

    // Fails the database directory lookup — the one boot step with no fallback.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => throw PlatformException(code: 'unavailable'),
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      null,
    );
    recordBootError = defaultReporter;
    await database.close();
  });

  Widget gate({AppRepository? appRepository, AppVersionConfig? appVersionConfig}) => LoadingGate(
    appSettings: settings,
    appRepository: appRepository ?? repository,
    appHintService: hintService,
    createAppVersionConfig: () => appVersionConfig ?? _FakeAppVersionConfig(() async => 0),
  );

  Future<void> pumpGate(WidgetTester tester) async {
    await tester.pumpWidget(gate());
    await tester.pumpAndSettle();
  }

  testWidgets('a failed load shows the recovery page and reports it', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await pumpGate(tester);

    expect(find.byType(LoadingErrorPage), findsOneWidget);
    // Settings and hints succeeded, so their own handlers must stay quiet.
    expect(reportedReasons, ['App initialization failed']);
  });

  group('below the minimum supported build', () {
    late Directory documents;
    late _MockAppRepository loadedRepository;

    setUp(() async {
      documents = await Directory.systemTemp.createTemp('loading_gate_test_');
      // An existing database file skips the legacy migration.
      File('${documents.path}/bike_setup_tracker.sqlite').createSync();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        pathProviderChannel,
        (call) async => documents.path,
      );
      loadedRepository = _MockAppRepository();
      when(() => loadedRepository.database).thenReturn(database);
      when(() => loadedRepository.initialize()).thenAnswer((_) async {});
      when(() => loadedRepository.initialDataLoaded).thenAnswer((_) async {});
    });

    tearDown(() => documents.delete(recursive: true));

    // Startup checks the database file with real IO, which fake async never completes.
    Future<void> pumpBlocked(WidgetTester tester, _FakeAppVersionConfig config) async {
      await tester.pumpWidget(gate(appRepository: loadedRepository, appVersionConfig: config));
      for (var i = 0; i < 50 && find.byType(UpdateRequiredPage).evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
    }

    testWidgets('opens the gate in the user language and starts nothing else', (tester) async {
      SharedPreferences.setMockInitialValues({'app_settings.localeCode': 'de'});
      final config = _FakeAppVersionConfig(() async => AppInfo.buildNumber + 1);

      await pumpBlocked(tester, config);

      expect(find.byType(UpdateRequiredPage), findsOneWidget);
      expect(find.text('Update erforderlich'), findsOneWidget);
      // Filters are restored only once the app starts.
      verifyNever(() => loadedRepository.onFiltersChanged = any());
      expect(config.refreshCalls, 1);
      expect(reportedReasons, isEmpty);
    });
  });
}
