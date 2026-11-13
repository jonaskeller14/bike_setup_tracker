import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/context/context_position.dart';
import 'package:bike_setup_tracker/models/context/context_weather.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/pages/forms/setup_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../goldens/support/localized_test_app.dart';

class _MockSubscriptionService extends Mock implements SubscriptionService {}

const _bikeId = 'bike';
const _pressureId = 'pressure';
const _referenceId = 'reference_setup';
const _editedId = 'edited_setup';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.path,
    );
  });

  testWidgets('marking a pressure while editing a setup saves the mark', (tester) async {
    final harness = (await tester.runAsync(_Harness.create))!;
    addTearDown(harness.dispose);
    harness.settings.enablePressureAssistant = true;

    await harness.openEdit(tester);
    final save = find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.check));

    await tester.tap(find.text('Set now'));
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(harness.result?.setNowAdjustmentIds, {_pressureId});
  });

  testWidgets('a saved mark stays when the pressure assistant is off', (tester) async {
    final harness = (await tester.runAsync(() => _Harness.create(editedMarks: {_pressureId})))!;
    addTearDown(harness.dispose);

    await harness.openEdit(tester);
    expect(find.text('Set now'), findsNothing);
    await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.check)));
    await tester.pumpAndSettle();

    expect(harness.result?.setNowAdjustmentIds, {_pressureId});
  });

  testWidgets('a saved mark is dropped when the setup has no recorded conditions', (tester) async {
    final harness = (await tester.runAsync(
      () => _Harness.create(editedMarks: {_pressureId}, editedHasConditions: false),
    ))!;
    addTearDown(harness.dispose);
    harness.settings.enablePressureAssistant = true;

    await harness.openEdit(tester);
    await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.check)));
    await tester.pumpAndSettle();

    expect(harness.result?.setNowAdjustmentIds, isEmpty);
  });
}

class _Harness {
  final AppDatabase database;
  final AppRepository repository;
  final AppSettings settings;
  Setup? result;

  _Harness({required this.database, required this.repository, required this.settings});

  static Future<_Harness> create({Set<String> editedMarks = const {}, bool editedHasConditions = true}) async {
    final database = AppDatabase.memory();
    final seed = AppRepository(database);
    await seed.addBikes([Bike(id: _bikeId, name: 'Test Bike', person: null)]);
    await seed.addComponents([
      Component(
        id: 'component',
        name: 'Fork',
        componentType: ComponentType.fork,
        adjustments: [
          NumericalAdjustment(
            id: _pressureId,
            name: 'Air Pressure',
            notes: null,
            unit: AdjustmentUnit.fromLegacy('psi'),
          ),
        ],
        installations: [Installation.sinceBeginning(parent: _bikeId)],
      ),
    ]);

    Setup setup(
      String id,
      DateTime datetime, {
      required double temperatureC,
      required double altitudeM,
      bool conditions = true,
      Set<String> marks = const {},
    }) => Setup(
      id: id,
      datetime: datetime,
      datetimeLocal: datetime.toLocal(),
      tags: const {},
      bike: _bikeId,
      person: null,
      bikeAdjustmentValues: const {_pressureId: NumericalValue(80.0)},
      personAdjustmentValues: const {},
      position: conditions ? ContextPosition(latitude: 47, longitude: 11, altitude: altitudeM) : null,
      weather: conditions ? ContextWeather(currentDateTime: datetime, currentTemperature: temperatureC) : null,
      setNowAdjustmentIds: marks,
    );

    await seed.addSetups([
      setup(_referenceId, DateTime.utc(2025, 1, 1, 10), temperatureC: 20, altitudeM: 400),
      setup(
        _editedId,
        DateTime.utc(2025, 1, 2, 10),
        temperatureC: 5,
        altitudeM: 1800,
        conditions: editedHasConditions,
        marks: editedMarks,
      ),
    ]);
    seed.dispose();

    final repository = AppRepository(database);
    for (var attempt = 0; attempt < 100 && repository.setups.length < 2; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    if (repository.setups.length < 2) throw StateError('SetupPage test fixture did not finish loading.');
    return _Harness(database: database, repository: repository, settings: AppSettings()..showOnboarding = false);
  }

  Future<void> openEdit(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: repository),
          ChangeNotifierProvider<SubscriptionService>.value(value: _MockSubscriptionService()),
        ],
        child: localizedTestApp(
          theme: materialAppTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.push<Setup>(
                    context,
                    MaterialPageRoute(builder: (_) => SetupPage.edit(setup: repository.setups[_editedId]!)),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> dispose() async {
    await repository.disposeAndAwaitCancellation();
    settings.dispose();
    await database.close();
  }
}
