import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_hint.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/app_hint_service.dart';
import 'package:bike_setup_tracker/widgets/hints/app_hint_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late AppRepository repository;
  late AppSettings settings;
  late AppHintService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    repository = AppRepository(database);
    settings = AppSettings();
    await settings.loadAppSettings();

    final firstBike = Bike(name: 'First', person: null);
    await repository.addBike(firstBike);
    await repository.addBike(Bike(name: 'Second', person: null));
    await repository.addComponent(
      Component(
        name: 'Chain',
        componentType: ComponentType.chain,
        installations: [Installation.sinceBeginning(parent: firstBike.id)],
      ),
    );

    service = AppHintService(appRepository: repository, appSettings: settings);
    await service.load();
    service.update(appRepository: repository, appSettings: settings);
  });

  tearDown(() async {
    service.dispose();
    repository.dispose();
    settings.dispose();
    await database.close();
  });

  Widget buildSubject() => MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider.value(
        value: service,
        child: const AppHintSlot(placement: AppHintPlacement.garageHeader),
      ),
    ),
  );

  testWidgets('renders no widget when no hint is active', (tester) async {
    await service.dismiss(AppHint.garageGesturesV1);

    await tester.pumpWidget(buildSubject());

    expect(find.text('Gestures in Garage'), findsNothing);
  });

  testWidgets('dismisses the Garage hint and persists its status', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Gestures in Garage'), findsOneWidget);
    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pump();

    expect(find.text('Gestures in Garage'), findsNothing);
    expect(service.statusOf(AppHint.garageGesturesV1), AppHintStatus.dismissed);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('app_hint.garageGesturesV1.status'), 'dismissed');
  });
}
