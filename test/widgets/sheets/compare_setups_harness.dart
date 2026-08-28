import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_hint.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/context/context_position.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/app_hint_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

class CompareSetupsHarness {
  static const bikeId = 'bike-a';
  static const secondBikeId = 'bike-b';
  static const componentId = 'fork';
  static const extraComponentId = 'shock';
  static const changedAdjustmentId = 'rebound';
  static const unchangedAdjustmentId = 'pressure';

  final AppDatabase database;
  AppRepository repository;
  final AppSettings settings;
  final AppHintService hintService;

  CompareSetupsHarness._(this.database, this.repository, this.settings, this.hintService);

  static Future<CompareSetupsHarness> create({int extraAdjustments = 0}) async {
    final database = AppDatabase.memory();
    final repository = AppRepository(database);
    await repository.addBike(Bike(id: bikeId, name: 'Bike A', person: null));
    await repository.addBike(Bike(id: secondBikeId, name: 'Bike B', person: null));
    await repository.addComponent(
      Component(
        id: componentId,
        name: 'Fork',
        componentType: ComponentType.fork,
        installations: [Installation.sinceBeginning(parent: bikeId)],
        adjustments: [
          _adjustment(changedAdjustmentId, 'Rebound'),
          _adjustment(unchangedAdjustmentId, 'Pressure'),
          for (var index = 0; index < extraAdjustments; index++) _adjustment('extra-$index', 'Adjustment $index'),
        ],
      ),
    );
    final settings = AppSettings();
    final hintService = AppHintService(appRepository: repository, appSettings: settings);
    await hintService.load();
    await hintService.dismiss(AppHint.setupComparisonV1);
    return CompareSetupsHarness._(database, repository, settings, hintService);
  }

  static StepAdjustment _adjustment(String id, String name) {
    return StepAdjustment(
      id: id,
      name: name,
      notes: '',
      unit: AdjustmentUnit.fromLegacy('clicks'),
      min: 0,
      max: 100,
      step: 1,
      visualization: StepAdjustmentVisualization.slider,
    );
  }

  Future<void> addExtraAdjustments(WidgetTester tester, {int count = 12}) async {
    await tester.runAsync(
      () => repository.addComponent(
        Component(
          id: extraComponentId,
          name: 'Shock',
          componentType: ComponentType.shock,
          installations: [Installation.sinceBeginning(parent: bikeId)],
          adjustments: [
            for (var index = 0; index < count; index++) _adjustment('extra-$index', 'Adjustment $index'),
          ],
        ),
      ),
    );
  }

  Setup setup({
    required String id,
    required String name,
    required DateTime local,
    String bike = bikeId,
    Map<String, dynamic> values = const {},
    String? notes,
    Set<String> tags = const {},
    List<String> images = const [],
    ContextPosition? position,
  }) {
    return Setup(
      id: id,
      name: name,
      datetime: local.toUtc(),
      datetimeLocal: local,
      notes: notes,
      tags: tags,
      bike: bike,
      person: null,
      position: position,
      bikeAdjustmentValues: Map<String, dynamic>.from(values),
      personAdjustmentValues: {},
      images: images,
    );
  }

  Future<void> addSetups(WidgetTester tester, Iterable<Setup> setups) async {
    await tester.runAsync(() async {
      for (final setup in setups) {
        await repository.addSetup(setup);
      }
    });
  }

  Future<void> reload(WidgetTester tester) async {
    repository.dispose();
    repository = AppRepository(database);
    await tester.runAsync(() async {
      var attempts = 0;
      while (repository.setups.isEmpty && attempts < 20) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        attempts++;
      }
    });
    hintService.update(appRepository: repository, appSettings: settings);
  }

  Widget wrap(Widget child, {double width = 390, double? height, bool dark = false}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>.value(value: settings),
        ChangeNotifierProvider<AppRepository>.value(value: repository),
        ChangeNotifierProvider<AppHintService>.value(value: hintService),
        ChangeNotifierProvider<SubscriptionService>(create: (_) => SubscriptionService()),
      ],
      child: MaterialApp(
        theme: materialAppTheme,
        darkTheme: materialAppDarkTheme,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: Scaffold(
          body: SizedBox(width: width, height: height, child: child),
        ),
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
