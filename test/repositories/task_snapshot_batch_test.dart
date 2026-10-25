import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/component_stats.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Allow Drift streams to propagate through subscriptions.
Future<void> pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

DateTime _day(int day, [int hour = 0]) => DateTime.utc(2024, 1, day, hour);

Installation _onBike(String bikeId, DateTime at) =>
    BikeInstallation(bikeId: bikeId, dateTimeUTC: at, dateTimeLocal: at.toLocal());

Installation _onComponent(String componentId, DateTime at) =>
    ComponentInstallation(parentComponentId: componentId, dateTimeUTC: at, dateTimeLocal: at.toLocal());

/// The per-entry SQL sums in another order than the timeline, so fractional
/// values may differ in the last bits.
void _expectSameStats(ComponentStats? actual, ComponentStats expected, String reason) {
  expect(actual, isNotNull, reason: reason);
  expect(actual!.distance, closeTo(expected.distance, 1e-6), reason: '$reason distance');
  expect(actual.elevationGain, closeTo(expected.elevationGain, 1e-6), reason: '$reason elevation');
  expect(actual.kilojoules, closeTo(expected.kilojoules, 1e-6), reason: '$reason kilojoules');
  expect(actual.movingTime, expected.movingTime, reason: '$reason moving time');
  expect(actual.elapsedTime, expected.elapsedTime, reason: '$reason elapsed time');
  expect(actual.activityCount, expected.activityCount, reason: '$reason activity count');
}

/// Bikes A and B (wheel swaps between them) and C (deleted), a fork with a
/// damper and a seal nested three levels deep, a wheel with its tire that
/// moves between the bikes and is uninstalled and reinstalled, an archived
/// chain, and a crank whose ring stays behind when the crank is deleted.
class _Fixture {
  _Fixture(this.database, this.repository);

  final AppDatabase database;
  final AppRepository repository;

  final bikeA = Bike(
    name: 'A',
    person: null,
    stravaGear: 'gA',
    initialStats: const ComponentStats(
      distance: 500.25,
      elevationGain: 40.5,
      movingTime: Duration(hours: 2),
      elapsedTime: Duration(hours: 3),
      activityCount: 4,
      kilojoules: 12.5,
    ),
  );
  final bikeB = Bike(name: 'B', person: null, stravaGear: 'gB');
  final bikeC = Bike(name: 'C', person: null, stravaGear: 'gC');

  late final fork = Component(
    name: 'Fork',
    componentType: ComponentType.fork,
    installations: [Installation.sinceBeginning(parent: bikeA.id)],
    initialStats: const ComponentStats(distance: 100.5, movingTime: Duration(minutes: 30), activityCount: 1),
  );
  late final damper = Component(
    name: 'Damper',
    componentType: ComponentType.other,
    installations: [Installation.componentSinceBeginning(parentComponentId: fork.id)],
  );
  late final seal = Component(
    name: 'Seal',
    componentType: ComponentType.other,
    installations: [_onComponent(damper.id, _day(3))],
  );
  late final wheel = Component(
    name: 'Wheel',
    componentType: ComponentType.other,
    installations: [
      _onBike(bikeA.id, _day(1)),
      _onBike(bikeB.id, _day(10)),
      Uninstallation(dateTimeUTC: _day(15), dateTimeLocal: _day(15).toLocal()),
      _onBike(bikeA.id, _day(20)),
    ],
  );
  late final tire = Component(
    name: 'Tire',
    componentType: ComponentType.other,
    installations: [Installation.componentSinceBeginning(parentComponentId: wheel.id)],
    initialStats: const ComponentStats(distance: 7.75, kilojoules: 1.25),
  );
  late final chain = Component(
    name: 'Chain',
    componentType: ComponentType.chain,
    installations: [
      _onBike(bikeA.id, _day(1)),
      Archival(dateTimeUTC: _day(12), dateTimeLocal: _day(12).toLocal()),
    ],
  );
  late final crank = Component(
    name: 'Crank',
    componentType: ComponentType.other,
    installations: [_onBike(bikeA.id, _day(1))],
  );
  late final ring = Component(
    name: 'Ring',
    componentType: ComponentType.other,
    installations: [_onComponent(crank.id, _day(2))],
  );
  late final onDeletedBike = Component(
    name: 'On C',
    componentType: ComponentType.other,
    installations: [Installation.sinceBeginning(parent: bikeC.id)],
  );

  List<Component> get components => [fork, damper, seal, wheel, tire, chain, crank, ring, onDeletedBike];

  /// Activity dates: noon most days, plus some exactly at installation events.
  static final activityDates = [
    for (var day = 1; day <= 28; day++) _day(day, 12),
    _day(1),
    _day(3),
    _day(10),
    _day(12),
    _day(15),
    _day(20),
  ];

  Future<void> build() async {
    await repository.addBikes([bikeA, bikeB, bikeC]);
    await repository.addComponents(components);
    await pumpEventQueue();

    var id = 1;
    final activities = <StravaActivity>[];
    for (final date in activityDates) {
      for (final gear in ['gA', 'gB', 'gC']) {
        final n = id++;
        activities.add(
          StravaActivity(
            id: n,
            lastModified: DateTime.utc(2024, 2, 1),
            name: 'Ride $n',
            athlete: 1,
            sportType: SportType.Ride,
            startDate: date,
            startDateLocal: date.copyWith(isUtc: false),
            gearId: gear,
            startLat: null,
            startLon: null,
            distance: n.isEven ? 1000.1 * n + 0.3 : null,
            totalElevationGain: 10.7 * (n % 9),
            movingTime: Duration(minutes: 20 + n % 50),
            elapsedTime: Duration(minutes: 30 + n % 70),
            averageWatts: n % 3 == 0 ? null : 120.3 + n,
          ),
        );
      }
    }
    await database.stravaDao.upsertActivities(activities.map((a) => a.toCompanion()));

    // Straight to the DAO, without a snapshot: the refresh under test fills them.
    final associations = [
      for (final component in components) ComponentTaskAssociation(component.id),
      for (final bike in [bikeA, bikeB, bikeC]) BikeTaskAssociation(bike.id),
    ];
    final entryDates = [
      _day(1, 6),
      _day(10),
      _day(10, 12),
      _day(14, 23),
      _day(20, 12),
      _day(31),
      DateTime.utc(2023, 6, 1),
    ];
    for (final association in associations) {
      for (final date in entryDates) {
        await database.taskDao.insertEntry(
          TaskEntry(
            name: 'Serviced',
            taskRule: 'rule',
            association: association,
            dateTimeUTC: date,
            dateTimeLocal: date.toLocal(),
          ).toCompanion(),
        );
      }
    }

    await repository.removeComponents([crank]);
    await repository.removeBikes([bikeC]);
    await pumpEventQueue();
  }

  /// Every stored snapshot, active and trashed, against a per-entry lookup.
  Future<void> expectSnapshotsCurrent(String step) async {
    final rows = await database.taskDao.getAllEntriesBypass();
    expect(rows, isNotEmpty);
    for (final row in rows) {
      final entry = row.toModel();
      final expected = await repository.getStatsAt(
        componentId: entry.association.componentId,
        bikeId: entry.association.bikeId,
        date: entry.dateTimeUTC,
      );
      _expectSameStats(
        entry.snapshot,
        expected,
        '$step: ${entry.association.componentId ?? entry.association.bikeId} at ${entry.dateTimeUTC}',
      );
    }
  }
}

void main() {
  late AppDatabase database;
  late AppRepository repository;
  late _Fixture fixture;

  setUp(() async {
    database = AppDatabase.memory();
    repository = AppRepository(database);
    await pumpEventQueue();
    fixture = _Fixture(database, repository);
    await fixture.build();
  });

  tearDown(() async {
    await database.close();
  });

  test('a full refresh equals the per-entry stats queries', () async {
    await repository.refreshTaskEntrySnapshots();

    await fixture.expectSnapshotsCurrent('full refresh');
  });

  test('the fixture credits activities through every path', () async {
    await repository.refreshTaskEntrySnapshots();
    final snapshots = {
      for (final row in await database.taskDao.getAllEntriesBypass())
        if (row.toModel() case TaskEntry(
          association: final association,
          dateTimeUTC: final date,
          :final snapshot,
        ) when date == _day(31))
          (association.componentId ?? association.bikeId)!: snapshot!,
    };

    // Inherited from bike A and through the nesting.
    expect(snapshots[fixture.damper.id]!.distance, greaterThan(fixture.bikeA.initialStats.distance));
    expect(snapshots[fixture.seal.id]!.activityCount, lessThan(snapshots[fixture.damper.id]!.activityCount));
    // The tire follows the wheel onto bike B.
    expect(snapshots[fixture.tire.id]!.activityCount, snapshots[fixture.wheel.id]!.activityCount);
    // Deleted parent, deleted bike: nothing credited.
    expect(snapshots[fixture.ring.id], ComponentStats.zero);
    expect(snapshots[fixture.onDeletedBike.id], ComponentStats.zero);
    expect(snapshots[fixture.bikeC.id], ComponentStats.zero);
  });

  // A sync only refreshes the snapshots dated after its changes, so a snapshot
  // another edit left stale would stay stale: every edit must keep them current.
  test('snapshots stay current across edits', () async {
    await repository.refreshTaskEntrySnapshots();
    await fixture.expectSnapshotsCurrent('start');

    Component current(Component component) => repository.components[component.id]!;
    Future<void> step(String name, Future<void> Function() edit) async {
      await edit();
      await pumpEventQueue();
      await fixture.expectSnapshotsCurrent(name);
    }

    await step('back-dated installation edit', () {
      final wheel = current(fixture.wheel);
      return repository.editComponents([
        wheel.copyWith(
          installations: [
            wheel.installations[0],
            wheel.installations[1].copyWith(dateTimeUTC: _day(6), dateTimeLocal: _day(6).toLocal()),
            ...wheel.installations.skip(2),
          ],
        ),
      ]);
    });
    await step('subcomponent move', () {
      final seal = current(fixture.seal);
      return repository.editComponents([
        seal.copyWith(installations: [...seal.installations, _onComponent(fixture.wheel.id, _day(9))]),
      ]);
    });
    await step('uninstall', () {
      final fork = current(fixture.fork);
      return repository.editComponents([
        fork.copyWith(
          installations: [
            ...fork.installations,
            Uninstallation(dateTimeUTC: _day(18), dateTimeLocal: _day(18).toLocal()),
          ],
        ),
      ]);
    });
    await step('archive', () => repository.archiveComponent(current(fixture.tire), at: _day(22)));
    await step('delete a parent component', () => repository.removeComponents([current(fixture.wheel)]));
    await step(
      'restore it',
      () => repository.restoreComponents(repository.deletedComponents.where((c) => c.id == fixture.wheel.id)),
    );
    await step('delete a bike', () => repository.removeBikes([repository.bikes[fixture.bikeB.id]!]));
    await step(
      'restore it',
      () => repository.restoreBikes(repository.deletedBikes.where((b) => b.id == fixture.bikeB.id)),
    );
    await step(
      'component initial stats edit',
      () => repository.editComponents([
        current(fixture.fork).copyWith(initialStats: const ComponentStats(distance: 333.3, activityCount: 2)),
      ]),
    );
    await step(
      'bike initial stats edit',
      () => repository.editBikes([
        repository.bikes[fixture.bikeA.id]!.copyWith(initialStats: const ComponentStats(elevationGain: 9.9)),
      ]),
    );
    await step(
      'unlink a Strava gear',
      () => repository.editBikes([repository.bikes[fixture.bikeB.id]!.copyWith(stravaGear: null)]),
    );
    await step(
      'link it again',
      () => repository.editBikes([repository.bikes[fixture.bikeB.id]!.copyWith(stravaGear: 'gB')]),
    );
    // Like the calendar's drag: the snapshot the entry had travels along.
    await step('task entry date edit', () {
      final entries = repository.taskEntries.values.where((e) => e.association.componentId == fixture.tire.id);
      return repository.editTaskEntry([
        for (final entry in entries) entry.copyWith(dateTimeUTC: entry.dateTimeUTC.add(const Duration(days: 4))),
      ]);
    });
  });
}
