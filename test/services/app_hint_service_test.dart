import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_hint.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
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
    // Closing the database right after dispose() races its fire-and-forget
    // subscription cancellation and can hang; wait for cancellation first.
    await repository.disposeAndAwaitCancellation();
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
    await repository.addBikes([firstBike, secondBike]);
    await pumpEventQueue();
    service.update(appRepository: repository, appSettings: settings);
    expect(
      service.activeHintFor(AppHintPlacement.garageHeader),
      AppHint.gettingStartedV1,
    );

    await repository.addComponents([
      Component(
        name: 'Chain',
        componentType: ComponentType.chain,
        installations: [Installation.sinceBeginning(parent: firstBike.id)],
      ),
    ]);
    final now = DateTime.now();
    await repository.addSetups([
      Setup(
        datetime: now.toUtc(),
        datetimeLocal: now,
        tags: const {},
        bike: firstBike.id,
        person: null,
        bikeAdjustmentValues: const {},
        personAdjustmentValues: const {},
      ),
    ]);
    await pumpEventQueue();
    service.update(appRepository: repository, appSettings: settings);
    expect(
      service.activeHintFor(AppHintPlacement.garageHeader),
      AppHint.garageGesturesV1,
    );
  });

  test('Task gestures hint requires a due task that can be delayed', () async {
    final service = createService();
    await service.load();

    final bike = Bike(name: 'Bike', person: null);
    await repository.addBikes([bike]);
    await repository.addComponents([
      Component(
        name: 'Chain',
        componentType: ComponentType.chain,
        installations: [Installation.sinceBeginning(parent: bike.id)],
      ),
    ]);
    final now = DateTime.now();
    await repository.addSetups([
      Setup(
        datetime: now.toUtc(),
        datetimeLocal: now,
        tags: const {},
        bike: bike.id,
        person: null,
        bikeAdjustmentValues: const {},
        personAdjustmentValues: const {},
      ),
    ]);
    await repository.addTaskRules([TaskRule(name: 'No interval', tags: const {})]);
    await pumpEventQueue();
    service.update(appRepository: repository, appSettings: settings);
    expect(service.activeHintFor(AppHintPlacement.taskHeader), isNull);

    await repository.addTaskRules([
      TaskRule(name: 'Monthly', tags: const {}, interval: const DurationThreshold(Duration(days: 30))),
    ]);
    await pumpEventQueue();
    service.update(appRepository: repository, appSettings: settings);
    expect(service.activeHintFor(AppHintPlacement.taskHeader), AppHint.taskGesturesV1);

    settings.enableTaskDelay = false;
    service.update(appRepository: repository, appSettings: settings);
    expect(service.activeHintFor(AppHintPlacement.taskHeader), isNull);

    settings.enableTaskDelay = true;
    await service.dismiss(AppHint.taskGesturesV1);
    final reloaded = createService();
    await reloaded.load();
    expect(reloaded.activeHintFor(AppHintPlacement.taskHeader), isNull);
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
    await repository.addBikes([firstBike, Bike(name: 'Second', person: null)]);
    await repository.addComponents([
      Component(
        name: 'Chain',
        componentType: ComponentType.chain,
        installations: [Installation.sinceBeginning(parent: firstBike.id)],
      ),
    ]);
    final now = DateTime.now();
    await repository.addSetups([
      Setup(
        datetime: now.toUtc(),
        datetimeLocal: now,
        tags: const {},
        bike: firstBike.id,
        person: null,
        bikeAdjustmentValues: const {},
        personAdjustmentValues: const {},
      ),
    ]);
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
    await repository.addBikes([firstBike]);
    await repository.addComponents([
      Component(
        name: 'Chain',
        componentType: ComponentType.chain,
        installations: [Installation.sinceBeginning(parent: firstBike.id)],
      ),
    ]);
    final now = DateTime.now();
    for (var index = 0; index < 2; index++) {
      await repository.addSetups([
        Setup(
          datetime: now.add(Duration(minutes: index)).toUtc(),
          datetimeLocal: now.add(Duration(minutes: index)),
          tags: const {},
          bike: firstBike.id,
          person: null,
          bikeAdjustmentValues: const {},
          personAdjustmentValues: const {},
        ),
      ]);
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

    await repository.addBikes([Bike(name: 'Road bike', person: null, stravaGear: 'gear-1')]);
    await pumpEventQueue();
    service.update(appRepository: repository, appSettings: settings);
    expect(service.activeHintFor(AppHintPlacement.stravaDashboardGear), isNull);
  });

  test('setup comparison hint is available until dismissed', () async {
    final service = createService();
    await service.load();
    expect(service.activeHintFor(AppHintPlacement.setupComparison), AppHint.setupComparisonV1);

    await service.dismiss(AppHint.setupComparisonV1);
    expect(service.activeHintFor(AppHintPlacement.setupComparison), isNull);
  });

  group('component feature offers', () {
    late Bike bike;

    Component part(String name, ComponentType type, {String? bikeId, String? parentComponentId}) => Component(
          name: name,
          componentType: type,
          installations: [
            if (parentComponentId != null)
              Installation.componentSinceBeginning(parentComponentId: parentComponentId)
            else
              Installation.sinceBeginning(parent: bikeId),
          ],
        );

    Future<void> addComponents(List<Component> components) async {
      await repository.addComponents(components);
      await pumpEventQueue();
    }

    setUp(() async {
      bike = Bike(name: 'Trail', person: null);
      await repository.addBikes([bike]);
      await pumpEventQueue();
    });

    test('Subcomponents is offered for a part once its typical parent exists', () async {
      final service = createService();
      await service.load();
      expect(service.subcomponentsMountParent(ComponentType.tire), isNull);

      final wheel = part('Front Wheel', ComponentType.wheelFront, bikeId: bike.id);
      await addComponents([wheel]);

      expect(service.subcomponentsMountParent(ComponentType.tire, currentBikeId: bike.id)?.id, wheel.id);
      // The frame is the bike itself, and a chain has no typical parent.
      expect(service.subcomponentsMountParent(ComponentType.wheelFront), isNull);
      expect(service.subcomponentsMountParent(ComponentType.chain), isNull);
    });

    test('Subcomponents is not offered once enabled or handled, or to a part carrying parts', () async {
      final fork = part('Fork', ComponentType.fork, bikeId: bike.id);
      final calliper = part('Calliper', ComponentType.brakeCalliper, bikeId: bike.id);
      await addComponents([fork, calliper]);
      await addComponents([part('Pad', ComponentType.brakePad, parentComponentId: calliper.id)]);
      final service = createService();
      await service.load();

      expect(service.subcomponentsMountParent(ComponentType.brakeCalliper)?.id, fork.id);
      expect(service.subcomponentsMountParent(ComponentType.brakeCalliper, componentId: calliper.id), isNull);

      settings.enableInstallOnComponent = true;
      expect(service.subcomponentsMountParent(ComponentType.brakeCalliper), isNull);

      settings.enableInstallOnComponent = false;
      await service.dismiss(AppHint.subcomponentsV1);
      expect(service.subcomponentsMountParent(ComponentType.brakeCalliper), isNull);
    });

    test('the timeline is offered on a move once there is a second bike', () async {
      final service = createService();
      await service.load();
      final installed = [Installation.sinceBeginning(parent: bike.id)];

      expect(service.shouldOfferInstallationTimelineOnMove(installed), isFalse);

      await repository.addBikes([Bike(name: 'Enduro', person: null)]);
      await pumpEventQueue();
      expect(service.shouldOfferInstallationTimelineOnMove(installed), isTrue);
      expect(service.shouldOfferInstallationTimelineOnMove([Installation.sinceBeginning()]), isFalse);

      settings.enableInstallationTimeline = true;
      expect(service.shouldOfferInstallationTimelineOnMove(installed), isFalse);
    });

    test('the Garage suggests Subcomponents for a crowded bike with a part and its parent', () async {
      final now = DateTime.now();
      await repository.addSetups([
        Setup(
          datetime: now.toUtc(),
          datetimeLocal: now,
          tags: const {},
          bike: bike.id,
          person: null,
          bikeAdjustmentValues: const {},
          personAdjustmentValues: const {},
        ),
      ]);
      await addComponents([
        part('Front Wheel', ComponentType.wheelFront, bikeId: bike.id),
        part('Front Tire', ComponentType.tire, bikeId: bike.id),
        for (var i = 0; i < 5; i++) part('Bearing $i', ComponentType.bearing, bikeId: null),
        for (var i = 0; i < 5; i++) part('Spoke $i', ComponentType.other, bikeId: bike.id),
      ]);
      final service = createService();
      await service.load();
      service.update(appRepository: repository, appSettings: settings);
      expect(service.activeHintFor(AppHintPlacement.garageHeader), isNull, reason: '7 parts on the bike');

      await addComponents([part('Spoke 5', ComponentType.other, bikeId: bike.id)]);
      service.update(appRepository: repository, appSettings: settings);
      expect(service.activeHintFor(AppHintPlacement.garageHeader), AppHint.subcomponentsV1);
    });
  });

  group('release hints', () {
    // Stand-ins for real announcements: hints that no other eligibility rule
    // offers in the Garage or Setup header, so only the release rule can.
    const oldFeature = AppHint.installationTimelineV1;
    const recentFeature = AppHint.stravaLinkGearV1;
    const currentFeature = AppHint.setupComparisonV1;
    const releaseBuilds = {oldFeature: 40, recentFeature: 41, currentFeature: 42};

    AppHintService createReleaseService({int currentBuild = 42}) => AppHintService(
      appRepository: repository,
      appSettings: settings,
      releaseBuilds: releaseBuilds,
      currentBuild: currentBuild,
    );

    /// The Getting Started hint outranks release hints, so a repository with
    /// content is a precondition for every case but the priority one.
    Future<void> seedContent() async {
      final bike = Bike(name: 'First', person: null);
      await repository.addBikes([bike]);
      await repository.addComponents([
        Component(
          name: 'Chain',
          componentType: ComponentType.chain,
          installations: [Installation.sinceBeginning(parent: bike.id)],
        ),
      ]);
      final now = DateTime.now();
      await repository.addSetups([
        Setup(
          datetime: now.toUtc(),
          datetimeLocal: now,
          tags: const {},
          bike: bike.id,
          person: null,
          bikeAdjustmentValues: const {},
          personAdjustmentValues: const {},
        ),
      ]);
      await pumpEventQueue();
    }

    test('a first run announces the installed build only', () async {
      await seedContent();
      final service = createReleaseService();
      await service.load();
      service.update(appRepository: repository, appSettings: settings);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getInt('app_hint.releaseBaselineBuild'), 41);
      // Older features count as seen — nobody gets a backlog on the first run.
      expect(service.activeHintFor(AppHintPlacement.garageHeader), currentFeature);
    });

    test('the same hint shows in Garage and Setups until it is dismissed', () async {
      SharedPreferences.setMockInitialValues({'app_hint.releaseBaselineBuild': 39});
      await seedContent();
      final service = createReleaseService();
      await service.load();
      service.update(appRepository: repository, appSettings: settings);

      // Oldest first, in both lists at once.
      expect(service.activeHintFor(AppHintPlacement.garageHeader), oldFeature);
      expect(service.activeHintFor(AppHintPlacement.setupHeader), oldFeature);

      await service.dismiss(oldFeature);
      expect(service.activeHintFor(AppHintPlacement.garageHeader), isNull);
      expect(service.activeHintFor(AppHintPlacement.setupHeader), isNull);

      // A skipped release is caught up one feature per app start.
      final reloaded = createReleaseService();
      await reloaded.load();
      reloaded.update(appRepository: repository, appSettings: settings);

      expect(reloaded.statusOf(oldFeature), AppHintStatus.dismissed);
      expect(reloaded.activeHintFor(AppHintPlacement.garageHeader), recentFeature);
    });

    test('the baseline is pinned once, so an ignored hint survives an update', () async {
      await seedContent();
      final service = createReleaseService();
      await service.load();

      // Closing the app without acting on the hint, then updating again.
      final reloaded = createReleaseService(currentBuild: 43);
      await reloaded.load();
      reloaded.update(appRepository: repository, appSettings: settings);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getInt('app_hint.releaseBaselineBuild'), 41);
      expect(reloaded.activeHintFor(AppHintPlacement.garageHeader), currentFeature);
    });

    test('an unreleased hint is never announced', () async {
      SharedPreferences.setMockInitialValues({'app_hint.releaseBaselineBuild': 39});
      await seedContent();
      final service = createReleaseService(currentBuild: 40);
      await service.load();
      service.update(appRepository: repository, appSettings: settings);

      expect(service.activeHintFor(AppHintPlacement.garageHeader), oldFeature);
      await service.dismiss(oldFeature);

      final reloaded = createReleaseService(currentBuild: 40);
      await reloaded.load();
      reloaded.update(appRepository: repository, appSettings: settings);
      expect(reloaded.activeHintFor(AppHintPlacement.garageHeader), isNull);
    });

    test('Getting Started outranks a pending release hint', () async {
      SharedPreferences.setMockInitialValues({'app_hint.releaseBaselineBuild': 39});
      final service = createReleaseService();
      await service.load();

      expect(service.activeHintFor(AppHintPlacement.garageHeader), AppHint.gettingStartedV1);
    });

    test('resetAll replays every release hint', () async {
      await seedContent();
      final service = createReleaseService();
      await service.load();
      await service.dismiss(currentFeature);
      await service.resetAll();
      service.update(appRepository: repository, appSettings: settings);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getInt('app_hint.releaseBaselineBuild'), 0);
      expect(service.activeHintFor(AppHintPlacement.garageHeader), oldFeature);
    });
  });
}
