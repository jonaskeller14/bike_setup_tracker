import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
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
  static const changedAdjustmentId = 'rebound';
  static const unchangedAdjustmentId = 'pressure';

  final AppDatabase database;
  AppRepository repository;
  final AppSettings settings;

  CompareSetupsHarness._(this.database, this.repository, this.settings);

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
    return CompareSetupsHarness._(database, repository, AppSettings());
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

  Setup setup({
    required String id,
    required String name,
    required DateTime local,
    String bike = bikeId,
    Map<String, dynamic> values = const {},
    String? notes,
    Set<String> tags = const {},
    List<String> images = const [],
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
  }

  Widget wrap(Widget child, {double width = 390, bool dark = false}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>.value(value: settings),
        ChangeNotifierProvider<AppRepository>.value(value: repository),
        ChangeNotifierProvider<SubscriptionService>(create: (_) => SubscriptionService()),
      ],
      child: MaterialApp(
        theme: materialAppTheme,
        darkTheme: materialAppDarkTheme,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: Scaffold(
          body: SizedBox(width: width, child: child),
        ),
      ),
    );
  }

  Future<void> dispose() async {
    repository.dispose();
    settings.dispose();
    await database.close();
  }
}
