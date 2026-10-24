import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/setup_options_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => Directory.systemTemp.path,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      null,
    );
  });

  Setup setup(String id, int day) {
    final local = DateTime(2026, 5, day, 10);
    return Setup(
      id: id,
      datetime: local.toUtc(),
      datetimeLocal: local,
      tags: const {},
      bike: 'bike',
      person: null,
      bikeAdjustmentValues: const {},
      personAdjustmentValues: const {},
    );
  }

  Future<void> openMenu(WidgetTester tester, String setupId, {bool enableRating = true, bool running = false}) async {
    await tester.runAsync(() async {
      database = AppDatabase.memory();
      appRepository = AppRepository(database);
      appSettings = AppSettings()
        ..showOnboarding = false
        ..enableRating = enableRating;
      await appRepository.addBikes([Bike(id: 'bike', name: 'Test Bike', person: null)]);
      await appRepository.addSetups([setup('old', 1), setup('current', 2)]);
      if (running) {
        final started = DateTime(2026, 5, 3);
        await appRepository.addTestSessions([
          TestSession(
            bike: 'bike',
            adjustmentIds: const [],
            startedAtUTC: started.toUtc(),
            startedAtLocal: started,
          ),
        ]);
      }
      for (var attempt = 0; attempt < 100; attempt++) {
        if (appRepository.setups.length == 2 &&
            appRepository.setupHistory.isCurrent('current') &&
            appRepository.testSessions.length == (running ? 1 : 0)) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    addTearDown(() async {
      await tester.runAsync(() async {
        await appRepository.disposeAndAwaitCancellation();
        appSettings.dispose();
        await database.close();
      });
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appRepository),
        ],
        child: MaterialApp(
          theme: materialAppTheme,
          home: Scaffold(body: SetupOptionsMenu(setup: appRepository.setups[setupId]!)),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
  }

  testWidgets('the current setup offers to start a test session', (tester) async {
    await openMenu(tester, 'current');

    expect(find.text('Start Test Session'), findsOneWidget);
  });

  testWidgets('an older setup does not', (tester) async {
    await openMenu(tester, 'old');

    expect(find.text('Add Feedback'), findsOneWidget);
    expect(find.text('Start Test Session'), findsNothing);
  });

  testWidgets('neither does the current setup while a session runs on the bike', (tester) async {
    await openMenu(tester, 'current', running: true);

    expect(find.text('Start Test Session'), findsNothing);
  });

  testWidgets('nor with Feedback off', (tester) async {
    await openMenu(tester, 'current', enableRating: false);

    expect(find.text('Start Test Session'), findsNothing);
    expect(find.text('Edit'), findsOneWidget);
  });
}
