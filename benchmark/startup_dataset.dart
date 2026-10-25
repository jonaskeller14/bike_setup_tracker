import 'dart:math';

import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/component_stats.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/models/strava/strava_athlete.dart';
import 'package:bike_setup_tracker/models/strava/strava_gear.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/utils/file_import.dart';

class StartupDatasetScale {
  final int bikes;
  final int years;
  final int activities;
  final int setupsPerBikePerMonth;

  const StartupDatasetScale({
    this.bikes = 10,
    this.years = 5,
    this.activities = 10000,
    this.setupsPerBikePerMonth = 2,
  });
}

/// One position on a bike. Only leaf slots wear out, so a replaced part never
/// strands children on its predecessor.
class _Slot {
  final String key;
  final ComponentType type;
  final String? parent;
  final int? replaceEveryDays;

  const _Slot(this.key, this.type, {this.parent, this.replaceEveryDays});
}

/// Parents are listed before their children.
const _slots = [
  _Slot('frame', ComponentType.frame),
  _Slot('headset', ComponentType.headset, parent: 'frame'),
  _Slot('headsetBearing', ComponentType.bearing, parent: 'headset', replaceEveryDays: 400),
  _Slot('bottomBracket', ComponentType.bottomBracket, parent: 'frame'),
  _Slot('bbBearing', ComponentType.bearing, parent: 'bottomBracket', replaceEveryDays: 300),
  _Slot('fork', ComponentType.fork),
  _Slot('shock', ComponentType.shock),
  _Slot('stem', ComponentType.stem),
  _Slot('grips', ComponentType.grip, replaceEveryDays: 240),
  _Slot('wheelFront', ComponentType.wheelFront),
  _Slot('tireFront', ComponentType.tire, parent: 'wheelFront', replaceEveryDays: 300),
  _Slot('discFront', ComponentType.brakeDisc, parent: 'wheelFront', replaceEveryDays: 700),
  _Slot('wheelRear', ComponentType.wheelRear),
  _Slot('tireRear', ComponentType.tire, parent: 'wheelRear', replaceEveryDays: 200),
  _Slot('discRear', ComponentType.brakeDisc, parent: 'wheelRear', replaceEveryDays: 600),
  _Slot('cassette', ComponentType.casette, parent: 'wheelRear', replaceEveryDays: 500),
  _Slot('crank', ComponentType.crank),
  _Slot('chainring', ComponentType.chainring, parent: 'crank', replaceEveryDays: 450),
  _Slot('chain', ComponentType.chain, replaceEveryDays: 120),
  _Slot('derailleur', ComponentType.derailleur),
  _Slot('shifter', ComponentType.shifter),
  _Slot('shiftCable', ComponentType.shiftInnerCable, parent: 'shifter', replaceEveryDays: 365),
  _Slot('caliperFront', ComponentType.brakeCalliper),
  _Slot('padsFront', ComponentType.brakePad, parent: 'caliperFront', replaceEveryDays: 150),
  _Slot('caliperRear', ComponentType.brakeCalliper),
  _Slot('padsRear', ComponentType.brakePad, parent: 'caliperRear', replaceEveryDays: 120),
  _Slot('leverFront', ComponentType.brakeLever),
  _Slot('leverRear', ComponentType.brakeLever),
  _Slot('saddle', ComponentType.saddle),
  _Slot('seatpost', ComponentType.seatpost),
  _Slot('pedals', ComponentType.pedal, replaceEveryDays: 500),
];

/// A component generation and the span it sat in its slot.
class _Generation {
  final Component component;
  final DateTime from;
  final DateTime? to;

  const _Generation(this.component, this.from, this.to);

  bool activeAt(DateTime t) => !t.isBefore(from) && (to == null || t.isBefore(to!));
}

/// A deterministic dataset of a heavy, long-time user, for timing app start:
/// wear parts replaced on a schedule (most components are retired
/// generations, some archived), subcomponents up to three levels deep, wheels
/// swapped between bikes, partial setups, tasks with completion history and
/// Strava activities. Dates count back from `today`, so task statuses and the
/// activity-rate lookback look alike on every run.
class StartupDataset {
  final SelectedData data;
  final List<StravaAthlete> athletes;
  final List<StravaGear> gears;
  final List<StravaActivity> activities;

  StartupDataset._(this.data, this.athletes, this.gears, this.activities);

  Map<String, int> get counts => {
    'bikes': data.bikes.length,
    'components': data.components.length,
    'installations': data.components.values.fold(0, (sum, c) => sum + c.installations.length),
    'adjustments': data.components.values.fold(0, (sum, c) => sum + c.adjustments.length),
    'setups': data.setups.length,
    'taskRules': data.taskRules.length,
    'taskEntries': data.taskEntries.length,
    'activities': activities.length,
  };

  /// Imports like a backup restore, then writes the activities directly rather
  /// than through a Strava sync: the sync recomputes every task-entry snapshot,
  /// which at this size takes hours. Snapshots stay empty; start never reads
  /// more than the stored column, so the timings do not depend on them.
  Future<void> seed(AppRepository repository) async {
    await FileImport.replace(remoteData: data, database: repository.database);
    await repository.setStravaAthletes(athletes);
    await repository.setStravaGears(gears);
    await repository.database.stravaDao.upsertActivities(activities.map((a) => a.toCompanion()));
  }

  factory StartupDataset.generate({
    required DateTime today,
    StartupDatasetScale scale = const StartupDatasetScale(),
    int seed = 42,
  }) {
    final rng = Random(seed);
    final end = DateTime.utc(today.year, today.month, today.day);
    final start = end.subtract(Duration(days: 365 * scale.years));
    DateTime local(DateTime utc) => utc.add(const Duration(hours: 1)).copyWith(isUtc: false);
    Duration jitter(int days) => Duration(days: (days * (0.75 + rng.nextDouble() * 0.5)).round());
    T pick<T>(List<T> items) => items[rng.nextInt(items.length)];

    var nextId = 0;
    String id(String prefix) => '$prefix-${nextId++}';

    final persons = [
      for (var i = 0; i < 3; i++)
        Person(
          id: id('person'),
          name: 'Rider ${i + 1}',
          orderIndex: i,
          adjustments: [
            NumericalAdjustment(id: id('adj'), name: 'Weight', notes: null, unit: AdjustmentUnit.fromLegacy('kg')),
            NumericalAdjustment(id: id('adj'), name: 'Height', notes: null, unit: AdjustmentUnit.fromLegacy('cm')),
          ],
        ),
    ];

    // The last bike tracks distance by hand, without Strava.
    final gearCount = max(1, scale.bikes - 1);
    final gears = [for (var i = 0; i < gearCount; i++) StravaGear(id: 'g$i', name: 'Gear $i')];
    final unlinkedGear = StravaGear(id: 'g-unlinked', name: 'Commuter');

    final bikeStarts = <DateTime>[];
    final bikes = <Bike>[];
    for (var i = 0; i < scale.bikes; i++) {
      bikeStarts.add(start.add(Duration(days: 365 * scale.years * i ~/ (scale.bikes * 2))));
      bikes.add(
        Bike(
          id: id('bike'),
          name: 'Bike ${i + 1}',
          person: persons[i % persons.length].id,
          stravaGear: i < gearCount ? gears[i].id : null,
          orderIndex: i,
          initialStats: i.isEven
              ? const ComponentStats(distance: 1500000, elevationGain: 30000, activityCount: 60)
              : ComponentStats.zero,
        ),
      );
    }

    final components = <Component>[];
    final generations = <String, List<_Generation>>{}; // by '<bike>/<slot>'
    for (final (i, bike) in bikes.indexed) {
      final parentIds = <String, String>{};
      for (final slot in _slots) {
        final parentId = slot.parent == null ? null : parentIds[slot.parent]!;
        Installation install(DateTime at) => parentId == null
            ? BikeInstallation(id: id('inst'), bikeId: bike.id, dateTimeUTC: at, dateTimeLocal: local(at))
            : ComponentInstallation(
                id: id('inst'),
                parentComponentId: parentId,
                dateTimeUTC: at,
                dateTimeLocal: local(at),
              );

        final slotGenerations = generations['${bike.id}/${slot.key}'] = [];
        var from = bikeStarts[i];
        for (var generation = 0; ; generation++) {
          final replaceEvery = slot.replaceEveryDays;
          final retiredAt = replaceEvery == null ? null : from.add(jitter(replaceEvery));
          final retired = retiredAt != null && retiredAt.isBefore(end);
          final component = Component(
            id: id('component'),
            name: '${bike.name} ${slot.key} #${generation + 1}',
            componentType: slot.type,
            orderIndex: components.length,
            adjustments: _adjustmentsFor(slot.type, id),
            installations: [
              install(from),
              if (retired) Uninstallation(id: id('inst'), dateTimeUTC: retiredAt, dateTimeLocal: local(retiredAt)),
              if (retired && generation % 3 == 2)
                Archival(
                  id: id('inst'),
                  dateTimeUTC: retiredAt.add(const Duration(days: 1)),
                  dateTimeLocal: local(retiredAt.add(const Duration(days: 1))),
                ),
            ],
          );
          components.add(component);
          slotGenerations.add(_Generation(component, from, retired ? retiredAt : null));
          if (!retired) break;
          from = retiredAt;
        }
        parentIds[slot.key] = slotGenerations.first.component.id;
      }
    }

    // Front wheels of bike pairs trade places halfway through, taking their
    // tire and disc along: stats then follow a subtree across bikes.
    for (var i = 0; i + 1 < bikes.length; i += 2) {
      final swapAt = bikeStarts[i + 1].add(end.difference(bikeStarts[i + 1]) ~/ 2);
      for (final (from, to) in [(i, i + 1), (i + 1, i)]) {
        final wheel = generations['${bikes[from].id}/wheelFront']!.single.component;
        wheel.installations.add(
          BikeInstallation(id: id('inst'), bikeId: bikes[to].id, dateTimeUTC: swapAt, dateTimeLocal: local(swapAt)),
        );
      }
    }

    Iterable<_Generation> generationsAt(Bike bike, String slot, DateTime t) =>
        generations['${bike.id}/$slot']!.where((g) => g.activeAt(t));

    // Partial setups: each value is recorded with some probability, so most
    // have to be resolved from history.
    final setups = <Setup>[];
    final lastValues = <String, AdjustmentValue>{};
    AdjustmentValue nextValue(Adjustment adjustment) {
      final previous = lastValues[adjustment.id];
      final value = switch (adjustment) {
        NumericalAdjustment(:final min, :final max) => NumericalValue(
          ((previous as NumericalValue?)?.value ?? (min + max) / 2) + (rng.nextDouble() - 0.5) * (max - min) / 10,
        ),
        StepAdjustment(:final min, :final max) => StepValue(
          (((previous as StepValue?)?.value ?? (min + max) ~/ 2) + rng.nextInt(3) - 1).clamp(min, max),
        ),
        CategoricalAdjustment(:final options) => CategoricalValue([pick(options.toList())]),
        BooleanAdjustment() => BooleanValue(rng.nextDouble() < 0.2),
        _ => throw StateError('No value generator for ${adjustment.runtimeType}'),
      };
      return lastValues[adjustment.id] = value;
    }

    for (final (i, bike) in bikes.indexed) {
      final person = persons.firstWhere((p) => p.id == bike.person);
      for (var t = bikeStarts[i]; t.isBefore(end); t = t.add(jitter(30 ~/ scale.setupsPerBikePerMonth))) {
        final adjustments = [
          for (final slot in const ['fork', 'shock', 'tireFront', 'tireRear'])
            for (final generation in generationsAt(bike, slot, t)) ...generation.component.adjustments,
        ];
        setups.add(
          Setup(
            id: id('setup'),
            name: rng.nextDouble() < 0.3 ? 'Setup ${setups.length + 1}' : null,
            isDeleted: rng.nextDouble() < 0.01,
            isBookmarked: rng.nextDouble() < 0.05,
            datetime: t,
            datetimeLocal: local(t),
            notes: rng.nextDouble() < 0.2 ? 'Felt harsh on roots, softened compression.' : null,
            tags: {
              if (rng.nextDouble() < 0.3) pick(const ['Dry', 'Wet', 'Race', 'Bikepark', 'Baseline']),
            },
            bike: bike.id,
            person: person.id,
            bikeAdjustmentValues: {
              for (final adjustment in adjustments)
                if (rng.nextDouble() < 0.6) adjustment.id: nextValue(adjustment),
            },
            personAdjustmentValues: {
              if (rng.nextDouble() < 0.1) person.adjustments.first.id: NumericalValue(70 + rng.nextDouble() * 10),
            },
          ),
        );
      }
    }

    final taskRules = <TaskRule>[];
    final taskEntries = <TaskEntry>[];
    void addRule(String name, TaskAssociation association, TaskThreshold interval, DateTime from, int doneEveryDays) {
      final rule = TaskRule(
        id: id('rule'),
        name: name,
        priority: pick(TaskPriority.values),
        tags: {if (rng.nextDouble() < 0.3) 'Workshop'},
        association: association,
        interval: interval,
      );
      taskRules.add(rule);
      for (var t = from.add(jitter(doneEveryDays)); t.isBefore(end); t = t.add(jitter(doneEveryDays))) {
        taskEntries.add(
          TaskEntry(
            id: id('entry'),
            name: name,
            dateTimeUTC: t,
            dateTimeLocal: local(t),
            taskRule: rule.id,
            association: association,
          ),
        );
      }
    }

    for (final (i, bike) in bikes.indexed) {
      ComponentTaskAssociation latest(String slot) =>
          ComponentTaskAssociation(generations['${bike.id}/$slot']!.last.component.id);
      final since = generations['${bike.id}/chain']!.last.from;
      addRule('Lube chain', latest('chain'), const DistanceThreshold(150000), since, 14);
      addRule('Check chain wear', latest('chain'), const DistanceThreshold(800000), since, 45);
      addRule('Fork lower service', latest('fork'), const MovingTimeThreshold(Duration(hours: 50)), bikeStarts[i], 90);
      addRule(
        'Shock air can service',
        latest('shock'),
        const MovingTimeThreshold(Duration(hours: 50)),
        bikeStarts[i],
        90,
      );
      addRule('Check brake pads', latest('padsRear'), const DistanceThreshold(500000), bikeStarts[i], 40);
      addRule('Bleed brakes', latest('caliperRear'), const DurationThreshold(Duration(days: 365)), bikeStarts[i], 365);
      addRule(
        'Check tire pressure',
        latest('tireFront'),
        const DurationThreshold(Duration(days: 7)),
        bikeStarts[i],
        21,
      );
      addRule('Wash bike', BikeTaskAssociation(bike.id), const ActivityCountThreshold(5), bikeStarts[i], 20);
      addRule('Climbing block', BikeTaskAssociation(bike.id), const ElevationThreshold(10000), bikeStarts[i], 60);
    }
    addRule(
      'Renew insurance',
      const GeneralTaskAssociation(),
      const DurationThreshold(Duration(days: 365)),
      start,
      365,
    );
    addRule(
      'Plan bikepark trip',
      const GeneralTaskAssociation(),
      DateTimeThreshold(end.add(const Duration(days: 30))),
      start,
      180,
    );

    // Recently trashed, so the startup purge keeps them and the trash streams load rows.
    components.addAll([
      for (var i = 0; i < 5; i++)
        Component(
          id: id('component'),
          isDeleted: true,
          name: 'Trashed part ${i + 1}',
          componentType: ComponentType.other,
          installations: const [],
        ),
    ]);
    bikes.add(Bike(id: id('bike'), isDeleted: true, name: 'Sold bike', person: null));

    final rideTypes = [SportType.MountainBikeRide, SportType.Ride, SportType.GravelRide, SportType.EMountainBikeRide];
    final span = end.difference(start).inMinutes;
    final starts = [for (var i = 0; i < scale.activities; i++) start.add(Duration(minutes: rng.nextInt(span)))]..sort();
    final activities = <StravaActivity>[];
    for (final (i, startDate) in starts.indexed) {
      final linked = [
        for (final (b, bikeStart) in bikeStarts.indexed)
          if (b < gearCount && !startDate.isBefore(bikeStart)) gears[b].id,
      ];
      final roll = rng.nextDouble();
      final gearId = roll < 0.04 || linked.isEmpty ? null : (roll < 0.06 ? unlinkedGear.id : pick(linked));
      final distance = 5000 + rng.nextDouble() * 95000;
      final movingTime = Duration(seconds: (distance / (4 + rng.nextDouble() * 4)).round());
      activities.add(
        StravaActivity(
          id: i + 1,
          name: 'Ride ${i + 1}',
          athlete: 1,
          sportType: pick(rideTypes),
          startDate: startDate,
          startDateLocal: local(startDate),
          gearId: gearId,
          startLat: 47.5 + rng.nextDouble() * 0.5,
          startLon: 11 + rng.nextDouble() * 0.5,
          distance: distance,
          totalElevationGain: rng.nextDouble() * 2000,
          movingTime: movingTime,
          elapsedTime: movingTime * (1.1 + rng.nextDouble() * 0.3),
          workoutType: rng.nextDouble() < 0.05 ? 11 : 10,
          averageWatts: rng.nextDouble() < 0.6 ? 120 + rng.nextDouble() * 150 : null,
        ),
      );
    }

    return StartupDataset._(
      SelectedData(
        persons: {for (final p in persons) p.id: p},
        bikes: {for (final b in bikes) b.id: b},
        components: {for (final c in components) c.id: c},
        setups: {for (final s in setups) s.id: s},
        taskRules: {for (final r in taskRules) r.id: r},
        taskEntries: {for (final e in taskEntries) e.id: e},
      ),
      [
        StravaAthlete(
          id: 1,
          firstname: 'Bench',
          lastname: 'Mark',
          profile: null,
          gears: {for (final g in gears) g.id, unlinkedGear.id},
        ),
      ],
      [...gears, unlinkedGear],
      activities,
    );
  }

  static List<Adjustment> _adjustmentsFor(ComponentType type, String Function(String) id) => switch (type) {
    ComponentType.fork || ComponentType.shock => [
      NumericalAdjustment(
        id: id('adj'),
        name: 'Air pressure',
        notes: null,
        unit: AdjustmentUnit.fromLegacy('psi'),
        min: 40,
        max: 140,
      ),
      for (final (name, max) in const [('Rebound', 20), ('HSC', 10), ('LSC', 16)])
        StepAdjustment(
          id: id('adj'),
          name: name,
          notes: null,
          unit: AdjustmentUnit.fromLegacy('clicks'),
          step: 1,
          min: 0,
          max: max,
          visualization: StepAdjustmentVisualization.slider,
        ),
      CategoricalAdjustment(
        id: id('adj'),
        name: 'Mode',
        notes: null,
        unit: null,
        options: const {'Open', 'Trail', 'Firm'},
      ),
      BooleanAdjustment(id: id('adj'), name: 'Lockout', notes: null, unit: null),
    ],
    ComponentType.tire => [
      NumericalAdjustment(
        id: id('adj'),
        name: 'Pressure',
        notes: null,
        unit: AdjustmentUnit.fromLegacy('bar'),
        min: 1.2,
        max: 2.6,
      ),
    ],
    _ => [],
  };
}
