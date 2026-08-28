import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_hint.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/app_hint_service.dart';
import 'package:drift/drift.dart' show Value;
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

  test('defaults missing, unknown, and malformed statuses to unseen', () async {
    SharedPreferences.setMockInitialValues({
      'app_hint.garageGesturesV1.status': 'futureStatus',
      'app_hint.setupTasksV1.status': false,
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

  test('installation timeline dismissal is persisted', () async {
    final service = createService();
    await service.load();
    await service.dismiss(AppHint.installationTimelineV1);

    final reloaded = createService();
    await reloaded.load();

    expect(
      reloaded.statusOf(AppHint.installationTimelineV1),
      AppHintStatus.dismissed,
    );
  });

  test('installation timeline offer is limited to simple histories', () async {
    final service = createService();
    await service.load();
    final simpleHistory = [Installation.sinceBeginning(parent: 'bike')];
    final now = DateTime.now();
    final complexHistory = [
      ...simpleHistory,
      Uninstallation(dateTimeUTC: now.toUtc(), dateTimeLocal: now),
    ];

    expect(service.shouldOfferInstallationTimeline(simpleHistory), isTrue);
    expect(service.shouldOfferInstallationTimeline(complexHistory), isFalse);

    settings.enableInstallationTimeline = true;
    expect(service.shouldOfferInstallationTimeline(simpleHistory), isFalse);
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
    expect(
      service.activeHintFor(AppHintPlacement.garageHeader),
      AppHint.gettingStartedV1,
    );

    final firstBike = Bike(name: 'First', person: null);
    final secondBike = Bike(name: 'Second', person: null);
    await repository.addBike(firstBike);
    await repository.addBike(secondBike);
    await pumpEventQueue();
    service.update(appRepository: repository, appSettings: settings);
    expect(
      service.activeHintFor(AppHintPlacement.garageHeader),
      AppHint.gettingStartedV1,
    );

    await repository.addComponent(
      Component(
        name: 'Chain',
        componentType: ComponentType.chain,
        installations: [Installation.sinceBeginning(parent: firstBike.id)],
      ),
    );
    final now = DateTime.now();
    await repository.addSetup(
      Setup(
        datetime: now.toUtc(),
        datetimeLocal: now,
        tags: const {},
        bike: firstBike.id,
        person: null,
        bikeAdjustmentValues: const {},
        personAdjustmentValues: const {},
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
    final now = DateTime.now();
    await repository.addSetup(
      Setup(
        datetime: now.toUtc(),
        datetimeLocal: now,
        tags: const {},
        bike: firstBike.id,
        person: null,
        bikeAdjustmentValues: const {},
        personAdjustmentValues: const {},
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

  test('First Steps takes priority over setup suggestions', () async {
    final service = createService();
    await service.load();

    expect(
      service.activeHintFor(AppHintPlacement.setupHeader),
      AppHint.gettingStartedV1,
    );
  });

  test('Task takes priority over Calendar after First Steps are complete', () async {
    final firstBike = Bike(name: 'First', person: null);
    await repository.addBike(firstBike);
    await repository.addComponent(
      Component(
        name: 'Chain',
        componentType: ComponentType.chain,
        installations: [Installation.sinceBeginning(parent: firstBike.id)],
      ),
    );
    final now = DateTime.now();
    for (var index = 0; index < 2; index++) {
      await repository.addSetup(
        Setup(
          datetime: now.add(Duration(minutes: index)).toUtc(),
          datetimeLocal: now.add(Duration(minutes: index)),
          tags: const {},
          bike: firstBike.id,
          person: null,
          bikeAdjustmentValues: const {},
          personAdjustmentValues: const {},
        ),
      );
    }
    await pumpEventQueue();

    final service = createService();
    await service.load();
    service.update(appRepository: repository, appSettings: settings);

    expect(service.activeHintFor(AppHintPlacement.setupHeader), AppHint.setupTasksV1);

    settings.enableTask = true;
    service.update(appRepository: repository, appSettings: settings);
    expect(service.activeHintFor(AppHintPlacement.setupHeader), AppHint.setupCalendarV1);
  });

  test('Strava link hint requires an unlinked gear', () async {
    final service = createService();
    await service.load();

    expect(service.activeHintFor(AppHintPlacement.stravaDashboardGear), isNull);

    await database.stravaDao.upsertGear(
      StravaGearsCompanion(
        id: const Value('gear-1'),
        lastModified: Value(DateTime.now()),
        name: const Value('Road bike'),
      ),
    );
    await pumpEventQueue();
    service.update(appRepository: repository, appSettings: settings);
    expect(service.activeHintFor(AppHintPlacement.stravaDashboardGear), AppHint.stravaLinkGearV1);

    await repository.addBike(Bike(name: 'Road bike', person: null, stravaGear: 'gear-1'));
    await pumpEventQueue();
    service.update(appRepository: repository, appSettings: settings);
    expect(service.activeHintFor(AppHintPlacement.stravaDashboardGear), isNull);
  });

}
