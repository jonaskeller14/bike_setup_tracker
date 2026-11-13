import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/component_stats.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/models/task/task_trigger.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/sync/task_trigger_remote.dart';
import 'package:bike_setup_tracker/services/task_status_service.dart';
import 'package:bike_setup_tracker/services/task_trigger_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Allow Drift streams to propagate through subscriptions.
Future<void> pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

const _km = 1000.0;

StravaActivity _ride(
  int id, {
  required String gearId,
  required double meters,
  required DateTime startUtc,
  Duration movingTime = const Duration(hours: 1),
}) => StravaActivity(
  id: id,
  name: 'Ride $id',
  athlete: 1,
  sportType: SportType.Ride,
  startDate: startUtc,
  startDateLocal: startUtc.toLocal(),
  gearId: gearId,
  startLat: 0,
  startLon: 0,
  distance: meters,
  totalElevationGain: 0,
  movingTime: movingTime,
  elapsedTime: movingTime,
);

TaskTrigger _trigger(
  String ruleId, {
  String gearId = 'g1',
  TaskTriggerMetric metric = TaskTriggerMetric.distance,
  DateTime? countFrom,
  required double needed,
  String title = 'Chain wax',
}) => TaskTrigger(
  ruleId: ruleId,
  gearId: gearId,
  metric: metric,
  countFrom: countFrom ?? TaskTrigger.earliestCountFrom(DateTime.now()),
  needed: needed,
  title: title,
);

class _FakeRemote implements TaskTriggerRemote {
  final Map<String, Map<String, TaskTrigger>> stored = {};
  int lists = 0;
  final List<({List<TaskTrigger> upserts, List<String> deletes})> applied = [];
  Exception? failApplyWith;

  @override
  Future<Map<String, TaskTrigger>> list(String uid) async {
    lists++;
    return {...?stored[uid]};
  }

  @override
  Future<void> apply(String uid, {required List<TaskTrigger> upserts, required List<String> deletes}) async {
    final error = failApplyWith;
    if (error != null) throw error;
    applied.add((upserts: upserts, deletes: deletes));
    final triggers = stored.putIfAbsent(uid, () => {});
    for (final trigger in upserts) {
      triggers[trigger.ruleId] = trigger;
    }
    deletes.forEach(triggers.remove);
  }
}

void main() {
  group('TaskStatusService.remaining', () {
    final now = DateTime.utc(2026, 11, 13);

    double? remaining(TaskRule rule, {ComponentStats stats = ComponentStats.zero, TaskEntry? lastEntry}) =>
        TaskStatusService.remaining(rule: rule, currentStats: stats, now: now, lastEntry: lastEntry);

    TaskRule rule({TaskThreshold? interval, TaskThreshold? delay, bool repeat = true}) => TaskRule(
      name: 'Chain',
      tags: const {},
      association: const BikeTaskAssociation('b1'),
      interval: interval,
      delay: delay,
      repeat: repeat,
    );

    test('is what is left to the target in the interval unit, delay included', () {
      const ridden = ComponentStats(distance: 120 * _km, movingTime: Duration(hours: 3));
      expect(remaining(rule(interval: const DistanceThreshold(500 * _km)), stats: ridden), 380 * _km);
      expect(
        remaining(
          rule(interval: const DistanceThreshold(500 * _km), delay: const DistanceThreshold(100 * _km)),
          stats: ridden,
        ),
        480 * _km,
      );
      expect(
        remaining(rule(interval: const MovingTimeThreshold(Duration(hours: 10))), stats: ridden),
        const Duration(hours: 7).inMicroseconds,
      );
    });

    test('measures from the last entry', () {
      final entry = TaskEntry(
        name: 'Done',
        taskRule: 'r1',
        dateTimeUTC: now,
        dateTimeLocal: now.toLocal(),
        snapshot: const ComponentStats(distance: 100 * _km),
      );
      expect(
        remaining(
          rule(interval: const DistanceThreshold(500 * _km)),
          stats: const ComponentStats(distance: 150 * _km),
          lastEntry: entry,
        ),
        450 * _km,
      );
    });

    test('is null once due, without an interval and for a finished one-off', () {
      expect(
        remaining(
          rule(interval: const DistanceThreshold(500 * _km)),
          stats: const ComponentStats(distance: 500 * _km),
        ),
        isNull,
      );
      expect(remaining(rule()), isNull);
      final entry = TaskEntry(name: 'Done', taskRule: 'r1', dateTimeUTC: now, dateTimeLocal: now.toLocal());
      expect(remaining(rule(interval: const DistanceThreshold(500 * _km), repeat: false), lastEntry: entry), isNull);
    });
  });

  group('TaskTrigger', () {
    test('counts from the 1st of the month two months back at the earliest', () {
      expect(TaskTrigger.earliestCountFrom(DateTime.utc(2026, 11, 13, 9)), DateTime.utc(2026, 9));
      expect(TaskTrigger.earliestCountFrom(DateTime.utc(2026, 1, 31)), DateTime.utc(2025, 11));
      expect(TaskTrigger.earliestCountFrom(DateTime.utc(2026, 11, 30, 23, 59)), DateTime.utc(2026, 9));
    });

    test('counts from a later window start, rounded up to the second', () {
      final now = DateTime.utc(2026, 11, 13);
      expect(TaskTrigger.countFromFor(now: now, windowStarts: [null, DateTime.utc(2020)]), DateTime.utc(2026, 9));
      expect(
        TaskTrigger.countFromFor(
          now: now,
          windowStarts: [DateTime.utc(2026, 10, 1, 8, 0, 0, 1), DateTime.utc(2026, 10, 2, 8, 0, 0, 0, 1)],
        ),
        DateTime.utc(2026, 10, 2, 8, 0, 1),
      );
    });

    test('takes the metric from rides-based thresholds only, in the backend unit', () {
      expect(TaskTriggerMetric.of(const DistanceThreshold(1)), TaskTriggerMetric.distance);
      expect(TaskTriggerMetric.of(const MovingTimeThreshold(Duration(hours: 1))), TaskTriggerMetric.movingTime);
      expect(TaskTriggerMetric.of(const ActivityCountThreshold(3)), TaskTriggerMetric.activityCount);
      expect(TaskTriggerMetric.of(const DurationThreshold(Duration(days: 30))), isNull);
      expect(
        TaskTriggerMetric.movingTime.fromThresholdUnit(const Duration(hours: 2).inMicroseconds.toDouble()),
        7200,
      );
      expect(TaskTriggerMetric.distance.fromThresholdUnit(1234.5), 1234.5);
    });

    test('clips the title by characters and rounds what is needed', () {
      final trigger = _trigger('r1', needed: 1234.4, title: '${'a' * 99}👍🏽tail');
      expect(trigger.title, '${'a' * 99}👍🏽');
      expect(trigger.needed, 1234);
    });
  });

  group('AppRepository.taskTriggers', () {
    late AppDatabase database;
    late AppRepository repository;
    final now = DateTime.now().toUtc();
    final earliest = TaskTrigger.earliestCountFrom(now);
    // The database keeps entries to the second and installations to the minute.
    final dayAgo = DateTime.utc(now.year, now.month, now.day, now.hour, now.minute).subtract(const Duration(days: 1));

    setUp(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);
      await pumpEventQueue();
    });

    tearDown(() => database.close());

    Future<Bike> addBike(String? gearId) async {
      final bike = Bike(name: 'Bike $gearId', person: null, stravaGear: gearId);
      await repository.addBikes([bike]);
      await pumpEventQueue();
      return bike;
    }

    Future<TaskRule> addRule(TaskAssociation association, {TaskThreshold? interval}) async {
      final rule = TaskRule(
        name: 'Chain wax',
        tags: const {},
        association: association,
        interval: interval ?? const DistanceThreshold(500 * _km),
      );
      await repository.addTaskRules([rule]);
      await pumpEventQueue();
      return rule;
    }

    Future<void> addRides(List<StravaActivity> rides) async {
      await repository.setStravaActivities(rides);
      await pumpEventQueue();
    }

    test('a bike rule needs the rides since countFrom plus what is left', () async {
      final bike = await addBike('g1');
      final rule = await addRule(BikeTaskAssociation(bike.id));
      await addRides([
        _ride(1, gearId: 'g1', meters: 300 * _km, startUtc: now.subtract(const Duration(days: 200))),
        _ride(2, gearId: 'g1', meters: 100 * _km, startUtc: now.subtract(const Duration(days: 2))),
        _ride(3, gearId: 'other', meters: 999 * _km, startUtc: now.subtract(const Duration(days: 1))),
      ]);

      expect(await repository.taskTriggers(), [_trigger(rule.id, countFrom: earliest, needed: 200 * _km)]);
    });

    test('a new ride keeps the trigger, a late one from before countFrom lowers what is needed', () async {
      final bike = await addBike('g1');
      await addRule(BikeTaskAssociation(bike.id));
      await addRides([
        _ride(1, gearId: 'g1', meters: 100 * _km, startUtc: now.subtract(const Duration(days: 2))),
      ]);
      final before = (await repository.taskTriggers()).single;

      await addRides([_ride(2, gearId: 'g1', meters: 42.4 * _km, startUtc: now.subtract(const Duration(hours: 2)))]);
      expect((await repository.taskTriggers()).single, before);

      await addRides([_ride(3, gearId: 'g1', meters: 50 * _km, startUtc: now.subtract(const Duration(days: 400)))]);
      expect((await repository.taskTriggers()).single.needed, before.needed - 50 * _km);
    });

    test('a finished task counts from its entry', () async {
      final bike = await addBike('g1');
      final rule = await addRule(BikeTaskAssociation(bike.id));
      await addRides([
        _ride(1, gearId: 'g1', meters: 300 * _km, startUtc: now.subtract(const Duration(days: 3))),
      ]);
      expect((await repository.taskTriggers()).single.needed, 500 * _km);

      final entryDate = dayAgo;
      await repository.addTaskEntries([
        TaskEntry(
          name: 'Waxed',
          taskRule: rule.id,
          association: BikeTaskAssociation(bike.id),
          dateTimeUTC: entryDate,
          dateTimeLocal: entryDate.toLocal(),
          snapshot: await repository.getStatsAt(bikeId: bike.id, date: entryDate),
        ),
      ]);
      await pumpEventQueue();

      expect(await repository.taskTriggers(), [_trigger(rule.id, countFrom: entryDate, needed: 500 * _km)]);
    });

    test('a component counts on the bike it is on now, from when it got there', () async {
      final bikeA = await addBike('gA');
      final bikeB = await addBike('gB');
      final moved = dayAgo;
      final component = Component(
        name: 'Chain',
        componentType: ComponentType.chain,
        installations: [
          Installation.sinceBeginning(parent: bikeA.id),
          Installation(parent: bikeB.id, dateTimeUTC: moved, dateTimeLocal: moved.toLocal()),
        ],
      );
      await repository.addComponents([component]);
      await addRides([
        _ride(1, gearId: 'gA', meters: 200 * _km, startUtc: now.subtract(const Duration(days: 5))),
        _ride(2, gearId: 'gB', meters: 50 * _km, startUtc: now.subtract(const Duration(hours: 2))),
      ]);
      final rule = await addRule(ComponentTaskAssociation(component.id));

      // 250 km so far, 50 of them on gB since the move: rides on gB from then on need 300 km.
      expect(await repository.taskTriggers(), [
        _trigger(rule.id, gearId: 'gB', countFrom: moved, needed: 300 * _km),
      ]);
    });

    test('a moving-time rule needs seconds', () async {
      final bike = await addBike('g1');
      final rule = await addRule(
        BikeTaskAssociation(bike.id),
        interval: const MovingTimeThreshold(Duration(hours: 10)),
      );
      await addRides([
        _ride(1, gearId: 'g1', meters: 0, startUtc: now.subtract(const Duration(days: 2))),
        _ride(2, gearId: 'g1', meters: 0, startUtc: now.subtract(const Duration(days: 1))),
      ]);

      expect(await repository.taskTriggers(), [
        _trigger(rule.id, metric: TaskTriggerMetric.movingTime, countFrom: earliest, needed: 10 * 3600),
      ]);
    });

    test('no trigger for an archived component, a bike without gear, a due or calendar rule', () async {
      final bike = await addBike('g1');
      final noGear = await addBike(null);
      final archivedAt = now.subtract(const Duration(days: 1));
      final archived = Component(
        name: 'Old chain',
        componentType: ComponentType.chain,
        installations: [
          Installation.sinceBeginning(parent: bike.id),
          Archival(dateTimeUTC: archivedAt, dateTimeLocal: archivedAt.toLocal()),
        ],
      );
      await repository.addComponents([archived]);
      await addRule(ComponentTaskAssociation(archived.id));
      await addRule(BikeTaskAssociation(noGear.id));
      await addRule(BikeTaskAssociation(bike.id), interval: const DurationThreshold(Duration(days: 30)));
      await addRule(const GeneralTaskAssociation(), interval: const DurationThreshold(Duration(days: 30)));
      await addRule(BikeTaskAssociation(bike.id), interval: const DistanceThreshold(10 * _km));
      await addRides([
        _ride(1, gearId: 'g1', meters: 20 * _km, startUtc: now.subtract(const Duration(hours: 2))),
      ]);

      expect(await repository.taskTriggers(), isEmpty);
    });
  });

  group('TaskTriggerService', () {
    late AppDatabase database;
    late AppRepository repository;
    late _FakeRemote remote;
    late TaskTriggerService service;
    late Bike bike;

    setUp(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);
      remote = _FakeRemote();
      service = TaskTriggerService(repository, remote: remote, debounce: const Duration(hours: 1));
      bike = Bike(name: 'Bike', person: null, stravaGear: 'g1');
      await repository.addBikes([bike]);
      await pumpEventQueue();
    });

    tearDown(() async {
      service.dispose();
      await database.close();
    });

    Future<TaskRule> addRule(double km) async {
      final rule = TaskRule(
        name: 'Rule $km',
        tags: const {},
        association: BikeTaskAssociation(bike.id),
        interval: DistanceThreshold(km * _km),
      );
      await repository.addTaskRules([rule]);
      await pumpEventQueue();
      return rule;
    }

    test('does nothing while cloud sync is off', () async {
      await addRule(100);
      service.update(uid: null);

      await service.sync();

      expect(remote.lists, 0);
      expect(remote.applied, isEmpty);
    });

    test('first run reads the cloud once, writes what changed and removes stale triggers', () async {
      final kept = await addRule(100);
      final added = await addRule(200);
      remote.stored['u1'] = {
        kept.id: _trigger(kept.id, needed: 100 * _km, title: kept.name),
        'gone': _trigger('gone', needed: 5, title: 'Gone'),
      };
      service.update(uid: 'u1');

      await service.sync();

      expect(remote.lists, 1);
      expect(remote.applied.single.upserts.map((t) => t.ruleId), [added.id]);
      expect(remote.applied.single.deletes, ['gone']);
      expect(remote.stored['u1']!.keys, unorderedEquals([kept.id, added.id]));
    });

    test('writes nothing when nothing changed or after a ride, and only the change afterwards', () async {
      final rule = await addRule(100);
      service.update(uid: 'u1');
      await service.sync();
      remote.applied.clear();

      await service.sync();
      await repository.setStravaActivities([
        _ride(1, gearId: 'g1', meters: 30 * _km, startUtc: DateTime.now().toUtc().subtract(const Duration(hours: 1))),
      ]);
      await pumpEventQueue();
      await service.sync();
      expect(remote.applied, isEmpty);

      await repository.editTaskRules([rule.copyWith(interval: const DistanceThreshold(300 * _km))]);
      await pumpEventQueue();
      await service.sync();

      expect(remote.lists, 1);
      expect(remote.applied.single.upserts.single.needed, 300 * _km);
      expect(remote.applied.single.deletes, isEmpty);
    });

    test('a deleted rule removes its trigger', () async {
      final rule = await addRule(100);
      service.update(uid: 'u1');
      await service.sync();

      await repository.removeTaskRules([rule]);
      await pumpEventQueue();
      await service.sync();

      expect(remote.applied.last.deletes, [rule.id]);
      expect(remote.stored['u1'], isEmpty);
    });

    test('a failed write reads the cloud again on the next run', () async {
      await addRule(100);
      service.update(uid: 'u1');
      remote.failApplyWith = FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');

      await service.sync();
      remote.failApplyWith = null;
      await service.sync();

      expect(remote.lists, 2);
      expect(remote.stored['u1'], hasLength(1));
    });

    test('another account starts from its own cloud copy', () async {
      await addRule(100);
      service.update(uid: 'u1');
      await service.sync();

      service.update(uid: 'u2');
      await service.sync();

      expect(remote.lists, 2);
      expect(remote.stored['u2'], hasLength(1));
    });
  });

  group('FirestoreTaskTriggerRemote', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreTaskTriggerRemote remote;
    final countFrom = DateTime.utc(2026, 9);

    setUp(() {
      firestore = FakeFirebaseFirestore();
      remote = FirestoreTaskTriggerRemote(firestore: firestore);
    });

    DocumentReference<Map<String, dynamic>> doc(String ruleId) =>
        firestore.collection('users').doc('u1').collection('task_triggers').doc(ruleId);

    Map<String, dynamic> stored({String metric = 'distance', Object? needed = 10, String title = 'Chain'}) => {
      'gearId': 'g1',
      'metric': metric,
      'countFrom': Timestamp.fromDate(countFrom),
      'needed': ?needed,
      'title': title,
    };

    test('writes whole docs, which drops the server-set notifiedAt, and deletes', () async {
      await doc('r1').set({...stored(title: 'Old'), 'notifiedAt': Timestamp.now()});
      await doc('r2').set(stored(title: 'Gone'));

      await remote.apply(
        'u1',
        upserts: [_trigger('r1', metric: TaskTriggerMetric.kilojoules, countFrom: countFrom, needed: 1234.4)],
        deletes: ['r2'],
      );

      final data = (await doc('r1').get()).data()!;
      expect(data.keys, unorderedEquals(['gearId', 'metric', 'countFrom', 'needed', 'title', 'updatedAt']));
      expect(data['metric'], 'kilojoules');
      expect((data['countFrom'] as Timestamp).toDate().toUtc(), countFrom);
      expect(data['needed'], 1234.0);
      expect((await doc('r2').get()).exists, isFalse);
    });

    test('reads back what it wrote and skips malformed docs', () async {
      final trigger = _trigger('r1', metric: TaskTriggerMetric.movingTime, countFrom: countFrom, needed: 3600);
      await remote.apply('u1', upserts: [trigger], deletes: const []);
      await doc('r2').set(stored(needed: null));
      await doc('r3').set(stored(metric: 'gearTotal'));

      expect(await remote.list('u1'), {'r1': trigger});
    });

    test('splits more than 500 writes into several batches', () async {
      await remote.apply(
        'u1',
        upserts: [for (var i = 0; i < 501; i++) _trigger('r$i', needed: i.toDouble(), title: 'T')],
        deletes: const [],
      );

      expect(await remote.list('u1'), hasLength(501));
    });
  });
}
