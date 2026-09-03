import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_hint.dart';
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
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const goldenViewport = Size(390, 844);
const goldenScenarioConstraints = BoxConstraints.tightFor(
  width: 390,
  height: 844,
);

class _MockSubscriptionService extends Mock implements SubscriptionService {}

Future<void> settleGolden(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

class GoldenTestHarness {
  static const trailBikeId = 'golden-bike-trail';
  static const gravelBikeId = 'golden-bike-gravel';
  static const forkId = 'golden-component-fork';
  static const gravelWheelId = 'golden-component-gravel-wheel';
  static const spareWheelId = 'golden-component-spare-wheel';
  static const pressureId = 'golden-adjustment-pressure';
  static const reboundId = 'golden-adjustment-rebound';
  static const modeId = 'golden-adjustment-mode';
  static const lockoutId = 'golden-adjustment-lockout';
  static const oldestSetupId = 'golden-setup-oldest';
  static const olderSetupId = 'golden-setup-older';
  static const newerSetupId = 'golden-setup-newer';

  final AppDatabase database;
  final AppRepository repository;
  final AppSettings settings;
  final AppHintService hintService;
  final SubscriptionService subscriptionService;

  GoldenTestHarness._({
    required this.database,
    required this.repository,
    required this.settings,
    required this.hintService,
    required this.subscriptionService,
  });

  Setup get newerSetup => repository.setups[newerSetupId]!;

  static Future<GoldenTestHarness> create() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.path,
    );

    final database = AppDatabase.memory();
    final seedRepository = AppRepository(database);
    await _seed(seedRepository);
    seedRepository.dispose();

    final repository = AppRepository(database);
    await _waitForSeed(repository);

    final settings = AppSettings()
      ..showOnboarding = false
      ..enableRating = false
      ..enablePerson = false;

    final subscriptionService = _MockSubscriptionService();
    when(
      () => subscriptionService.hasStravaEntitlement,
    ).thenReturn(false);
    final hintService = AppHintService(
      appRepository: repository,
      appSettings: settings,
    );
    await hintService.load();
    await hintService.dismiss(AppHint.gettingStartedV1);

    return GoldenTestHarness._(
      database: database,
      repository: repository,
      settings: settings,
      hintService: hintService,
      subscriptionService: subscriptionService,
    );
  }

  static Future<void> _seed(AppRepository repository) async {
    await repository.addBike(
      Bike(
        id: trailBikeId,
        name: 'Trail Bike',
        notes: 'Enduro setup',
        person: null,
        orderIndex: 0,
      ),
    );
    await repository.addBike(
      Bike(
        id: gravelBikeId,
        name: 'Gravel Bike',
        notes: 'Fast all-road build',
        person: null,
        orderIndex: 1,
      ),
    );

    await repository.addComponent(
      Component(
        id: forkId,
        name: 'Factory Fork',
        componentType: ComponentType.fork,
        orderIndex: 0,
        installations: [
          Installation.sinceBeginning(
            id: 'golden-installation-fork',
            componentId: forkId,
            parent: trailBikeId,
          ),
        ],
        adjustments: [
          NumericalAdjustment(
            id: pressureId,
            name: 'Air pressure',
            notes: 'Main spring pressure',
            unit: AdjustmentUnit.fromLegacy('psi'),
            min: 40,
            max: 140,
          ),
          StepAdjustment(
            id: reboundId,
            name: 'Rebound',
            notes: 'Clicks from closed',
            unit: AdjustmentUnit.fromLegacy('clicks'),
            min: 0,
            max: 20,
            step: 1,
            visualization: StepAdjustmentVisualization.slider,
          ),
          CategoricalAdjustment(
            id: modeId,
            name: 'Compression mode',
            notes: 'Damper mode',
            unit: null,
            options: const {'Open', 'Trail', 'Firm'},
          ),
          BooleanAdjustment(
            id: lockoutId,
            name: 'Lockout',
            notes: 'Climb switch',
            unit: null,
          ),
        ],
      ),
    );
    await repository.addComponent(
      Component(
        id: gravelWheelId,
        name: 'Carbon Wheelset',
        componentType: ComponentType.wheelFront,
        orderIndex: 0,
        installations: [
          Installation.sinceBeginning(
            id: 'golden-installation-gravel-wheel',
            componentId: gravelWheelId,
            parent: gravelBikeId,
          ),
        ],
      ),
    );
    await repository.addComponent(
      Component(
        id: spareWheelId,
        name: 'Spare Alloy Wheel',
        componentType: ComponentType.wheelRear,
        orderIndex: 0,
        installations: [
          Installation.sinceBeginning(
            id: 'golden-uninstallation-spare-wheel',
            componentId: spareWheelId,
          ),
        ],
      ),
    );

    await repository.addSetup(
      Setup(
        id: oldestSetupId,
        name: 'First ride setup',
        datetime: DateTime.utc(2026, 6, 10, 7),
        datetimeLocal: DateTime(2026, 6, 10, 9),
        notes: 'Comfortable starting point',
        tags: const {'Baseline'},
        bike: trailBikeId,
        person: null,
        bikeAdjustmentValues: const {
          pressureId: 78.0,
          reboundId: 4,
          modeId: ['Open'],
          lockoutId: false,
        },
        personAdjustmentValues: const {},
      ),
    );
    await repository.addSetup(
      Setup(
        id: olderSetupId,
        name: 'Rocky baseline',
        datetime: DateTime.utc(2026, 6, 12, 8, 30),
        datetimeLocal: DateTime(2026, 6, 12, 10, 30),
        notes: 'Dry trail baseline',
        tags: const {'Dry'},
        bike: trailBikeId,
        person: null,
        bikeAdjustmentValues: const {
          pressureId: 82.0,
          reboundId: 6,
          modeId: ['Trail'],
          lockoutId: false,
        },
        personAdjustmentValues: const {},
      ),
    );
    await repository.addSetup(
      Setup(
        id: newerSetupId,
        name: 'Race day setup',
        datetime: DateTime.utc(2026, 6, 14, 7, 15),
        datetimeLocal: DateTime(2026, 6, 14, 9, 15),
        notes: 'More support for race pace',
        tags: const {'Race'},
        bike: trailBikeId,
        person: null,
        bikeAdjustmentValues: const {
          pressureId: 84.0,
          reboundId: 8,
          modeId: ['Trail'],
          lockoutId: true,
        },
        personAdjustmentValues: const {},
      ),
    );
  }

  static Future<void> _waitForSeed(AppRepository repository) async {
    for (var attempt = 0; attempt < 100; attempt++) {
      if (repository.bikes.length == 2 &&
          repository.components.length == 3 &&
          repository.setups.length == 3 &&
          repository.setups[newerSetupId]?.isCurrent == true) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    throw StateError('Golden fixture did not finish loading.');
  }

  Widget wrap({required Brightness brightness, required Widget child}) {
    const mediaQueryData = MediaQueryData(
      size: goldenViewport,
      devicePixelRatio: 1,
      textScaler: TextScaler.noScaling,
      disableAnimations: true,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>.value(value: settings),
        ChangeNotifierProvider<AppRepository>.value(value: repository),
        ChangeNotifierProvider<AppHintService>.value(value: hintService),
        ChangeNotifierProvider<SubscriptionService>.value(
          value: subscriptionService,
        ),
      ],
      child: SizedBox(
        width: goldenViewport.width,
        height: goldenViewport.height,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: brightness == Brightness.light ? materialAppTheme : materialAppDarkTheme,
          builder: (context, child) => MediaQuery(
            data: mediaQueryData,
            child: child!,
          ),
          home: child,
        ),
      ),
    );
  }

  Future<void> dispose() async {
    repository.dispose();
    settings.dispose();
    hintService.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await database.close();
  }
}
