import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/component_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSubscriptionService extends Mock implements SubscriptionService {
  @override
  bool get hasStravaEntitlement => false;
}

void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;

  final bike = Bike(id: 'b1', name: 'Test Bike', person: null);
  final current = Component(
    id: 'c1',
    name: 'Current Fork',
    componentType: ComponentType.fork,
    installations: [Installation.sinceBeginning(parent: 'b1')],
    adjustments: [],
  );
  final spare = Component(
    id: 'c2',
    name: 'Spare Fork',
    componentType: ComponentType.fork,
    installations: const [],
    adjustments: [],
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
  });

  tearDown(() async {
    appRepository.dispose();
    appSettings.dispose();
    await database.close();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appRepository),
        ChangeNotifierProvider<SubscriptionService>(create: (_) => MockSubscriptionService()),
      ],
      child: MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ComponentActions.replaceComponent(context, component: current),
              child: const Text('replace'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> settleRepository(WidgetTester tester, bool Function() until) async {
    await tester.runAsync(() async {
      for (var attempts = 0; !until() && attempts < 100; attempts++) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets('replaceComponent installs the picked component and retires the current one', (tester) async {
    await tester.runAsync(() async {
      await appRepository.addBike(bike);
      await appRepository.addComponent(current);
      await appRepository.addComponent(spare);
    });
    appRepository.dispose();
    appRepository = AppRepository(database);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.runAsync(() => appRepository.initialDataLoaded);
    await tester.pumpAndSettle();
    expect(appRepository.components.keys, containsAll(['c1', 'c2']));

    await tester.tap(find.text('replace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Existing'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spare Fork').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await settleRepository(tester, () => appRepository.components['c2']?.bike == 'b1');

    final installed = appRepository.components['c2']!;
    final retired = appRepository.components['c1']!;

    // The spare takes over the bike, the replaced one is left on no bike.
    expect(installed.bike, 'b1');
    expect(retired.bike, isNull);

    // Both sides of the swap are logged at the same replacement date.
    expect(installed.installations.single.parent, 'b1');
    expect(retired.installations.length, 2);
    expect(retired.installations.last.parent, isNull);
    expect(retired.installations.last.dateTimeUTC, installed.installations.single.dateTimeUTC);

    expect(find.textContaining("Replaced 'Current Fork' with 'Spare Fork'"), findsOneWidget);
  });
}
