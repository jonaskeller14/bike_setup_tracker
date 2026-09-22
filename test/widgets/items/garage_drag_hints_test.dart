import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/garage_bike_card.dart';
import 'package:bike_setup_tracker/widgets/items/garage_uninstalled_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../overflow_data_generator.dart' show loremIpsum;

class MockSubscriptionService extends Mock implements SubscriptionService {
  @override
  bool get hasStravaEntitlement => false;
}

Component _component(String id, String name, List<Installation> installations, {int orderIndex = 0}) => Component(
  id: id,
  name: name,
  componentType: ComponentType.other,
  installations: installations,
  orderIndex: orderIndex,
);

Installation _onBike(String componentId, String bikeId) => BikeInstallation(
  componentId: componentId,
  bikeId: bikeId,
  dateTimeUTC: DateTime.utc(2026, 1, 1),
  dateTimeLocal: DateTime(2026, 1, 1),
);

Installation _onComponent(String componentId, String parentId) => ComponentInstallation(
  componentId: componentId,
  parentComponentId: parentId,
  dateTimeUTC: DateTime.utc(2026, 1, 1),
  dateTimeLocal: DateTime(2026, 1, 1),
);

Future<void> _pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

void main() {
  late AppDatabase database;
  late AppRepository repository;
  late AppSettings settings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    repository = AppRepository(database);
    settings = AppSettings();
  });

  tearDown(() async {
    settings.dispose();
    await repository.disposeAndAwaitCancellation();
    await database.close();
  });

  /// `wheel` sits on `bike-a` and carries `tire`; `seat` is installed directly.
  Future<void> seed({String wheelName = 'Wheel A', String targetBikeName = 'Bike B'}) async {
    await _pumpEventQueue();
    await repository.addBikes([
      Bike(id: 'bike-a', name: 'Bike A', person: null),
      Bike(id: 'bike-b', name: targetBikeName, person: null),
    ]);
    await repository.addComponents([
      _component('wheel', wheelName, [_onBike('wheel', 'bike-a')], orderIndex: 0),
      _component('tire', 'Tire', [_onComponent('tire', 'wheel')], orderIndex: 1),
      _component('seat', 'Seat', [_onBike('seat', 'bike-a')], orderIndex: 2),
    ]);
    await _pumpEventQueue();
  }

  Widget harness(Widget card) => MultiProvider(
    providers: [
      ChangeNotifierProvider<AppSettings>.value(value: settings),
      ChangeNotifierProvider<AppRepository>.value(value: repository),
      ChangeNotifierProvider<SubscriptionService>.value(value: MockSubscriptionService()),
    ],
    child: MaterialApp(
      theme: materialAppTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Draggable<Object>(
                data: 'component',
                feedback: const SizedBox(width: 10, height: 10),
                child: Container(
                  key: const Key('drag-source'),
                  width: 80,
                  height: 40,
                  color: Colors.grey,
                ),
              ),
              card,
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> pumpBikeCard(WidgetTester tester, ValueNotifier<Component?> notifier) async {
    await tester.pumpWidget(
      harness(
        GarageBikeCard(
          bike: repository.bikes['bike-b']!,
          index: 0,
          componentToShowDetails: null,
          onPressedComponent: (_) {},
          onAcceptWithDetails: ({required String? newBike}) {},
          setDraggedComponent: (component) => notifier.value = component,
          draggedComponentNotifier: notifier,
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpUninstalledCard(WidgetTester tester, ValueNotifier<Component?> notifier) async {
    await tester.pumpWidget(
      harness(
        GarageUninstalledCard(
          componentToShowDetails: null,
          onPressedComponent: (_) {},
          onAcceptWithDetails: ({required String? newBike}) {},
          onArchiveAccept: () {},
          setDraggedComponent: (component) => notifier.value = component,
          draggedComponentNotifier: notifier,
        ),
      ),
    );
    await tester.pump();
  }

  /// Drags the harness' draggable over [target] and keeps the pointer there.
  Future<TestGesture> hoverOver(WidgetTester tester, Finder target) async {
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('drag-source'))));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 1));
    await tester.pump();
    return gesture;
  }

  ValueNotifier<Component?> dragNotifier() {
    final notifier = ValueNotifier<Component?>(null);
    addTearDown(notifier.dispose);
    return notifier;
  }

  group('bike card', () {
    testWidgets('keeps the plain hint for a mounted child', (tester) async {
      await tester.runAsync(seed);
      final notifier = dragNotifier();
      await pumpBikeCard(tester, notifier);

      notifier.value = repository.components['tire'];
      await tester.pump();

      expect(find.text('Drag here to install on Bike B'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the plain hint for a directly installed component', (tester) async {
      await tester.runAsync(seed);
      final notifier = dragNotifier();
      await pumpBikeCard(tester, notifier);

      notifier.value = repository.components['seat'];
      await tester.pump();

      expect(find.text('Drag here to install on Bike B'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the plain release overlay for a mounted child', (tester) async {
      await tester.runAsync(seed);
      final notifier = dragNotifier();
      await pumpBikeCard(tester, notifier);

      notifier.value = repository.components['tire'];
      await tester.pump();
      final gesture = await hoverOver(tester, find.byType(GarageBikeCard));

      expect(find.text('Release to install to Bike B'), findsOneWidget);

      await gesture.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the plain release overlay for a directly installed component', (tester) async {
      await tester.runAsync(seed);
      final notifier = dragNotifier();
      await pumpBikeCard(tester, notifier);

      notifier.value = repository.components['seat'];
      await tester.pump();
      final gesture = await hoverOver(tester, find.byType(GarageBikeCard));

      expect(find.text('Release to install to Bike B'), findsOneWidget);

      await gesture.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('uninstall target', () {
    testWidgets('names the parent in the passive hint for a mounted child', (tester) async {
      await tester.runAsync(seed);
      final notifier = dragNotifier();
      await pumpUninstalledCard(tester, notifier);

      notifier.value = repository.components['tire'];
      await tester.pump();

      expect(find.text('Drag here to uninstall from Wheel A'), findsOneWidget);
      expect(find.text('Drag here to uninstall'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the plain hint for a directly installed component', (tester) async {
      await tester.runAsync(seed);
      final notifier = dragNotifier();
      await pumpUninstalledCard(tester, notifier);

      notifier.value = repository.components['seat'];
      await tester.pump();

      expect(find.text('Drag here to uninstall'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('names the parent in the release overlay for a mounted child', (tester) async {
      await tester.runAsync(seed);
      final notifier = dragNotifier();
      await pumpUninstalledCard(tester, notifier);

      notifier.value = repository.components['tire'];
      await tester.pump();
      final gesture = await hoverOver(
        tester,
        find.text('Drag components here to uninstall from bike'),
      );

      expect(find.text('Release to uninstall from Wheel A'), findsOneWidget);
      expect(find.text('Release to uninstall component'), findsNothing);

      await gesture.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the plain release overlay for a directly installed component', (tester) async {
      await tester.runAsync(seed);
      final notifier = dragNotifier();
      await pumpUninstalledCard(tester, notifier);

      notifier.value = repository.components['seat'];
      await tester.pump();
      final gesture = await hoverOver(
        tester,
        find.text('Drag components here to uninstall from bike'),
      );

      expect(find.text('Release to uninstall component'), findsOneWidget);

      await gesture.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a long bike name stays within the card', (tester) async {
    await tester.runAsync(() => seed(wheelName: loremIpsum, targetBikeName: loremIpsum));
    final notifier = dragNotifier();
    await pumpBikeCard(tester, notifier);

    notifier.value = repository.components['tire'];
    await tester.pump();

    final hint = find.textContaining('Drag here to install on');
    expect(hint, findsOneWidget);
    expect(
      tester.getSize(hint).width,
      lessThanOrEqualTo(tester.getSize(find.byType(GarageBikeCard)).width),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long parent name stays within the uninstall overlay', (tester) async {
    await tester.runAsync(() => seed(wheelName: loremIpsum));
    final notifier = dragNotifier();
    await pumpUninstalledCard(tester, notifier);

    notifier.value = repository.components['tire'];
    await tester.pump();

    final hint = find.textContaining('Drag here to uninstall from');
    expect(hint, findsOneWidget);
    expect(
      tester.getSize(hint).width,
      lessThanOrEqualTo(tester.getSize(find.byType(GarageUninstalledCard)).width),
    );
    expect(tester.takeException(), isNull);
  });
}
