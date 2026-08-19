import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/pages/setup_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dialogTitle = 'Previous Setup has changed. Reset Values?';

class _MockSubscriptionService extends Mock implements SubscriptionService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.path,
    );
  });

  testWidgets('moving an edited setup forward does not treat it as its own previous setup', (tester) async {
    final harness = (await tester.runAsync(() => _SetupPageHarness.create(editedMinute: 55)))!;
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.wrap(SetupPage.edit(setup: harness.editedSetup)));
    await tester.pumpAndSettle();
    await _changeTimeTo1156(tester, from: '11:55');

    expect(find.text(_dialogTitle), findsNothing);
    expect(find.widgetWithText(ActionChip, '11:56'), findsOneWidget);
  });

  testWidgets('moving an edited setup past another setup shows the reset dialog', (tester) async {
    final harness = (await tester.runAsync(
      () => _SetupPageHarness.create(editedMinute: 54, crossingMinute: 55),
    ))!;
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.wrap(SetupPage.edit(setup: harness.editedSetup)));
    await tester.pumpAndSettle();
    await _changeTimeTo1156(tester, from: '11:54');

    expect(find.text(_dialogTitle), findsOneWidget);
  });
}

Future<void> _changeTimeTo1156(WidgetTester tester, {required String from}) async {
  await tester.tap(find.widgetWithText(ActionChip, from));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Switch to text input mode'));
  await tester.pumpAndSettle();

  final fields = find.descendant(
    of: find.byType(TimePickerDialog),
    matching: find.byType(TextField),
  );
  expect(fields, findsNWidgets(2));
  await tester.enterText(fields.first, '11');
  await tester.enterText(fields.last, '56');
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

class _SetupPageHarness {
  static const _bikeId = 'bike';
  static const _componentId = 'component';
  static const _adjustmentId = 'adjustment';
  static const _editedSetupId = 'edited_setup';

  final AppDatabase database;
  final AppRepository repository;
  final AppSettings settings;
  final SubscriptionService subscriptionService;

  _SetupPageHarness({
    required this.database,
    required this.repository,
    required this.settings,
    required this.subscriptionService,
  });

  Setup get editedSetup => repository.setups[_editedSetupId]!;

  static Future<_SetupPageHarness> create({
    required int editedMinute,
    int? crossingMinute,
  }) async {
    final database = AppDatabase.memory();
    final seedRepository = AppRepository(database);
    await seedRepository.addBike(Bike(id: _bikeId, name: 'Test Bike', person: null));
    await seedRepository.addComponent(
      Component(
        id: _componentId,
        name: 'Fork',
        componentType: ComponentType.fork,
        adjustments: [
          TextAdjustment(
            id: _adjustmentId,
            name: 'Pressure',
            notes: null,
            unit: AdjustmentUnit.fromLegacy('psi'),
          ),
        ],
        installations: [Installation.sinceBeginning(parent: _bikeId)],
      ),
    );

    final editedLocal = DateTime(2025, 1, 1, 11, editedMinute);
    await seedRepository.addSetup(
      Setup(
        id: _editedSetupId,
        name: 'Edited Setup',
        datetime: editedLocal.toUtc(),
        datetimeLocal: editedLocal,
        tags: const {},
        bike: _bikeId,
        person: null,
        bikeAdjustmentValues: const {_adjustmentId: '80'},
        personAdjustmentValues: const {},
      ),
    );

    if (crossingMinute != null) {
      final crossingLocal = DateTime(2025, 1, 1, 11, crossingMinute);
      await seedRepository.addSetup(
        Setup(
          id: 'crossing_setup',
          name: 'Crossing Setup',
          datetime: crossingLocal.toUtc(),
          datetimeLocal: crossingLocal,
          tags: const {},
          bike: _bikeId,
          person: null,
          bikeAdjustmentValues: const {_adjustmentId: '85'},
          personAdjustmentValues: const {},
        ),
      );
    }
    seedRepository.dispose();

    final repository = AppRepository(database);
    await _waitForData(repository, expectedSetups: crossingMinute == null ? 1 : 2);
    final settings = AppSettings()..showOnboarding = false;
    return _SetupPageHarness(
      database: database,
      repository: repository,
      settings: settings,
      subscriptionService: _MockSubscriptionService(),
    );
  }

  Widget wrap(Widget home) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: repository),
        ChangeNotifierProvider.value(value: subscriptionService),
      ],
      child: MaterialApp(
        theme: materialAppTheme,
        home: MediaQuery(
          data: const MediaQueryData(alwaysUse24HourFormat: true),
          child: home,
        ),
      ),
    );
  }

  Future<void> dispose() async {
    repository.dispose();
    settings.dispose();
    await database.close();
  }

  static Future<void> _waitForData(AppRepository repository, {required int expectedSetups}) async {
    for (var attempt = 0; attempt < 100; attempt++) {
      if (repository.bikes.length == 1 &&
          repository.components.length == 1 &&
          repository.setups.length == expectedSetups) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    throw StateError('SetupPage test fixture did not finish loading.');
  }
}
