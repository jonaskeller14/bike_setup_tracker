import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_hint.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/app_hint_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpEventQueue() => Future<void>.delayed(const Duration(milliseconds: 100));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late AppRepository repository;
  late AppSettings settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    repository = AppRepository(database);
    settings = AppSettings();
    await settings.loadAppSettings();
    await pumpEventQueue();
  });

  tearDown(() async {
    repository.dispose();
    settings.dispose();
    await database.close();
  });

  AppHintService createService() => AppHintService(
    appRepository: repository,
    appSettings: settings,
  );

  test('defaults missing and unknown statuses to unseen', () async {
    SharedPreferences.setMockInitialValues({
      'app_hint.garageGesturesV1.status': 'futureStatus',
    });
    final service = createService();
    await service.load();

    expect(service.statusOf(AppHint.garageGesturesV1), AppHintStatus.unseen);
    expect(service.statusOf(AppHint.setupTasksV1), AppHintStatus.unseen);
  });

  test('migrates legacy hint flags to persisted statuses', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('app_settings.showGarageListHint', false);
    await preferences.setBool('app_settings.showSetupTaskHint', true);

    final service = createService();
    await service.load();

    expect(service.statusOf(AppHint.garageGesturesV1), AppHintStatus.dismissed);
    expect(service.statusOf(AppHint.setupTasksV1), AppHintStatus.unseen);
    expect(preferences.getString('app_hint.garageGesturesV1.status'), 'dismissed');
    expect(preferences.getString('app_hint.setupTasksV1.status'), 'unseen');
    expect(preferences.getString('app_hint.setupCalendarV1.status'), 'unseen');
    expect(preferences.getBool('app_settings.showGarageListHint'), isNull);
    expect(preferences.getBool('app_settings.showSetupTaskHint'), isNull);
  });

  test('legacy migration is idempotent and preserves a new status', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('app_settings.showGarageListHint', false);

    final service = createService();
    await service.load();
    await preferences.setBool('app_settings.showGarageListHint', true);

    final reloaded = createService();
    await reloaded.load();

    expect(reloaded.statusOf(AppHint.garageGesturesV1), AppHintStatus.dismissed);
    expect(preferences.getBool('app_settings.showGarageListHint'), isNull);
  });

  test('dismiss and complete persist enum values across service recreation', () async {
    final service = createService();
    await service.load();
    await service.dismiss(AppHint.garageGesturesV1);
    await service.complete(AppHint.setupTasksV1);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('app_hint.garageGesturesV1.status'), 'dismissed');
    expect(preferences.getString('app_hint.setupTasksV1.status'), 'completed');

    final reloaded = createService();
    await reloaded.load();
    expect(reloaded.statusOf(AppHint.garageGesturesV1), AppHintStatus.dismissed);
    expect(reloaded.statusOf(AppHint.setupTasksV1), AppHintStatus.completed);
  });

  test('resetAll clears progress and the in-memory session guard', () async {
    final service = createService();
    await service.load();
    await service.dismiss(AppHint.garageGesturesV1);
    await service.resetAll();

    expect(service.statusOf(AppHint.garageGesturesV1), AppHintStatus.unseen);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('app_hint.garageGesturesV1.status'), isNull);
  });

  test('Garage gestures eligibility requires two bikes and a component', () async {
    final service = createService();
    await service.load();
    expect(service.activeHintFor(AppHintPlacement.garageHeader), isNull);

    final firstBike = Bike(name: 'First', person: null);
    final secondBike = Bike(name: 'Second', person: null);
    await repository.addBike(firstBike);
    await repository.addBike(secondBike);
    await pumpEventQueue();
    service.update(appRepository: repository, appSettings: settings);
    expect(service.activeHintFor(AppHintPlacement.garageHeader), isNull);

    await repository.addComponent(
      Component(
        name: 'Chain',
        componentType: ComponentType.chain,
        installations: [Installation.sinceBeginning(parent: firstBike.id)],
      ),
    );
    await pumpEventQueue();
    service.update(appRepository: repository, appSettings: settings);
    expect(
      service.activeHintFor(AppHintPlacement.garageHeader),
      AppHint.garageGesturesV1,
    );
  });

  test('handling a hint suppresses the session and notifies only on changes', () async {
    final service = createService();
    await service.load();
    var notifications = 0;
    service.addListener(() => notifications++);

    await service.dismiss(AppHint.garageGesturesV1);
    await service.dismiss(AppHint.garageGesturesV1);

    expect(notifications, 1);
    expect(service.activeHintFor(AppHintPlacement.garageHeader), isNull);
  });

  test('a recreated service starts a new session', () async {
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
    await pumpEventQueue();

    final service = createService();
    await service.load();
    expect(service.activeHintFor(AppHintPlacement.garageHeader), AppHint.garageGesturesV1);
    await service.dismiss(AppHint.setupTasksV1);
    expect(service.activeHintFor(AppHintPlacement.garageHeader), isNull);

    final reloaded = createService();
    await reloaded.load();

    // Progress remains persisted, while the session-level handling guard resets.
    expect(reloaded.statusOf(AppHint.setupTasksV1), AppHintStatus.dismissed);
    expect(reloaded.activeHintFor(AppHintPlacement.garageHeader), AppHint.garageGesturesV1);
  });
}
