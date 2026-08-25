import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/app_hint_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// `pumpAndSettle` never returns here: the repository keeps scheduling frames
/// while its drift streams churn, so — like `setup_list_perf_test` — these
/// tests advance time explicitly instead.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Shared fixture for the setup-row widget tests: an in-memory database with
/// one bike carrying a fork with two adjustments, plus the provider stack the
/// rows read from.
///
/// Build it from `setUp`, never from the test body — a repository constructed
/// inside the widget-test zone deadlocks on its first write.
class SetupTileHarness {
  static const String bikeId = 'bike1';
  static const String forkId = 'fork1';
  static const String reboundId = 'adj-rebound';
  static const String pressureId = 'adj-pressure';

  final AppDatabase database;
  AppRepository repository;
  final AppSettings settings;
  final AppHintService hintService;

  SetupTileHarness._(this.database, this.repository, this.settings, this.hintService);

  /// [installationLocal] adds a second, dated installation so the timeline has
  /// a non-setup row to check alignment against.
  static Future<SetupTileHarness> create({DateTime? installationLocal}) async {
    final database = AppDatabase.memory();
    final repository = AppRepository(database);

    await repository.addBike(Bike(id: bikeId, name: 'Test Bike', person: null));
    await repository.addComponent(
      Component(
        id: forkId,
        name: 'Test Fork',
        componentType: ComponentType.fork,
        installations: [
          Installation.sinceBeginning(parent: bikeId),
          if (installationLocal != null)
            Installation(
              parent: bikeId,
              dateTimeUTC: installationLocal.toUtc(),
              dateTimeLocal: installationLocal,
            ),
        ],
        adjustments: [
          StepAdjustment(
            id: reboundId,
            name: 'Rebound',
            notes: '',
            unit: AdjustmentUnit.fromLegacy('clicks'),
            min: 0,
            max: 10,
            step: 1,
            visualization: StepAdjustmentVisualization.slider,
          ),
          StepAdjustment(
            id: pressureId,
            name: 'Pressure',
            notes: '',
            unit: AdjustmentUnit.fromLegacy('psi'),
            min: 0,
            max: 200,
            step: 1,
            visualization: StepAdjustmentVisualization.slider,
          ),
        ],
      ),
    );

    final settings = AppSettings();
    final hintService = AppHintService(appRepository: repository, appSettings: settings);
    await hintService.load();
    return SetupTileHarness._(database, repository, settings, hintService);
  }

  Setup buildSetup({
    required String name,
    required DateTime local,
    Map<String, dynamic> values = const {},
    String? notes,
  }) {
    return Setup(
      name: name,
      datetime: local.toUtc(),
      datetimeLocal: local,
      notes: notes,
      tags: {},
      bike: bikeId,
      person: null,
      bikeAdjustmentValues: Map<String, dynamic>.from(values),
      personAdjustmentValues: {},
    );
  }

  Future<void> addSetups(WidgetTester tester, List<Setup> setups) async {
    await tester.runAsync(() async {
      for (final setup in setups) {
        await repository.addSetup(setup);
      }
    });
  }

  /// Re-reads everything from the database, the way a fresh app launch does —
  /// this is what resolves the transient `isCurrent` / previous-value state.
  Future<void> reload(WidgetTester tester) async {
    repository.dispose();
    repository = AppRepository(database);
    hintService.update(appRepository: repository, appSettings: settings);
    await tester.runAsync(() async {
      var attempts = 0;
      while (repository.setups.isEmpty && attempts < 20) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        attempts++;
      }
    });
  }

  Widget _providers(Widget app) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>.value(value: settings),
        ChangeNotifierProvider<AppRepository>.value(value: repository),
        ChangeNotifierProvider<AppHintService>.value(value: hintService),
        ChangeNotifierProvider<SubscriptionService>(create: (_) => SubscriptionService()),
      ],
      child: app,
    );
  }

  Widget wrap(Widget child, {double width = 400}) {
    return _providers(
      MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: SingleChildScrollView(child: child),
            ),
          ),
        ),
      ),
    );
  }

  /// Like [wrap] but hands the child the whole screen — for scrollable widgets
  /// that build their own viewport.
  Widget wrapFullScreen(Widget child) {
    return _providers(
      MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  Future<void> dispose() async {
    repository.dispose();
    settings.dispose();
    hintService.dispose();
    await database.close();
  }
}
