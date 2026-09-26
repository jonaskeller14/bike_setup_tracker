import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/main.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/pages/loading_error_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/app_hint_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Only the fatal branch is covered. The success branch mounts the whole
/// service graph (Strava, subscriptions, notifications) and the degraded
/// branches need a throwing SharedPreferences store — both cost far more
/// mocking than the assertion would be worth.
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

  Future<void> pumpGate(WidgetTester tester) async {
    await tester.pumpWidget(
      LoadingGate(
        appSettings: settings,
        appRepository: repository,
        appHintService: hintService,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a failed load shows the recovery page and reports it', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await pumpGate(tester);

    expect(find.byType(LoadingErrorPage), findsOneWidget);
    // Settings and hints succeeded, so their own handlers must stay quiet.
    expect(reportedReasons, ['App initialization failed']);
  });
}
