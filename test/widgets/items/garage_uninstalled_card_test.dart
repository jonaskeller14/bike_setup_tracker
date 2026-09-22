import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/garage_uninstalled_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

Component _component(String id, List<Installation> installations) => Component(
  id: id,
  name: id,
  componentType: ComponentType.other,
  installations: installations,
);

void main() {
  late AppDatabase database;
  late AppRepository repository;
  late AppSettings settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    repository = AppRepository(database);
    settings = AppSettings();
    await _pumpEventQueue();

    await repository.addBikes([Bike(id: 'bike', name: 'Bike', person: null)]);
    await repository.addComponents([
      _component('parked', [
        Uninstallation(
          componentId: 'parked',
          dateTimeUTC: DateTime.utc(2026, 1, 2),
          dateTimeLocal: DateTime(2026, 1, 2),
        ),
      ]),
      _component('orphan', [
        BikeInstallation(
          componentId: 'orphan',
          bikeId: 'gone',
          dateTimeUTC: DateTime.utc(2026, 1, 1),
          dateTimeLocal: DateTime(2026, 1, 1),
        ),
      ]),
      _component('detached', [
        ComponentInstallation(
          componentId: 'detached',
          parentComponentId: 'gone',
          dateTimeUTC: DateTime.utc(2026, 1, 1),
          dateTimeLocal: DateTime(2026, 1, 1),
        ),
      ]),
    ]);
    await _pumpEventQueue();
  });

  tearDown(() async {
    settings.dispose();
    repository.dispose();
    await database.close();
  });

  Future<void> pumpCard(WidgetTester tester) async {
    final draggedComponent = ValueNotifier<Component?>(null);
    addTearDown(draggedComponent.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSettings>.value(value: settings),
          ChangeNotifierProvider<AppRepository>.value(value: repository),
        ],
        child: MaterialApp(
          theme: materialAppTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: GarageUninstalledCard(
                componentToShowDetails: null,
                onPressedComponent: (_) {},
                onAcceptWithDetails: ({required String? newBike}) {},
                onArchiveAccept: () {},
                setDraggedComponent: (_) {},
                draggedComponentNotifier: draggedComponent,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('keeps components with a broken placement and badges them', (tester) async {
    await pumpCard(tester);

    expect(find.byKey(const ValueKey('parked')), findsOneWidget);
    expect(find.byKey(const ValueKey('orphan')), findsOneWidget);
    expect(find.byKey(const ValueKey('detached')), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
