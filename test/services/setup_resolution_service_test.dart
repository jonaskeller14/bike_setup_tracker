import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/services/setup_resolution_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SetupResolutionService Look-back Resolution', () {
    late TextAdjustment pressureAdj;
    late TextAdjustment reboundAdj;
    late Component fork;
    late Component shock;
    late Bike myBike;
    late Bike otherBike;
    late Person me;

    setUp(() {
      pressureAdj = TextAdjustment(
        id: 'adj_pressure',
        name: 'Pressure',
        notes: null,
        unit: AdjustmentUnit.fromLegacy('psi'),
      );

      reboundAdj = TextAdjustment(
        id: 'adj_rebound',
        name: 'Rebound',
        notes: null,
        unit: AdjustmentUnit.fromLegacy('clicks'),
      );

      myBike = Bike(id: 'bike_1', name: 'My Enduro', person: 'person_1');
      otherBike = Bike(id: 'bike_2', name: 'My Trail Bike', person: 'person_1');
      me = Person(id: 'person_1', name: 'Me', adjustments: []);

      fork = Component(
        id: 'comp_fork',
        name: 'Fork',
        componentType: ComponentType.fork,
        adjustments: [pressureAdj],
        installations: [Installation.sinceBeginning(parent: myBike.id)],
      );

      shock = Component(
        id: 'comp_shock',
        name: 'Shock',
        componentType: ComponentType.shock,
        adjustments: [reboundAdj],
        installations: [Installation.sinceBeginning(parent: myBike.id)], // installed on bike_1
      );
    });

    test('chronological resolution inherits values properly', () {
      // Intention: Verify that contiguous setups on the same bike correctly pass down sparse adjustment values.
      // Desired outcome: A later setup that does not record an adjustment inherits the value from the previous setup.
      // Not desired outcome: The later setup has no previous value, or has a default/blank value.

      final t1 = DateTime(2025, 1, 1).toUtc();
      final t2 = DateTime(2025, 1, 2).toUtc();
      final t3 = DateTime(2025, 1, 3).toUtc();

      final setup1 = Setup(
        id: 's1',
        name: 'Initial Setup',
        datetime: t1,
        datetimeLocal: t1.toLocal(),
        bike: myBike.id,
        person: me.id,
        tags: {},
        personAdjustmentValues: {},
        bikeAdjustmentValues: {pressureAdj.id: '80', reboundAdj.id: '5'},
      );

      final setup2 = Setup(
        id: 's2',
        name: 'Sparse Edit',
        datetime: t2,
        datetimeLocal: t2.toLocal(),
        bike: myBike.id,
        person: me.id,
        tags: {},
        personAdjustmentValues: {},
        bikeAdjustmentValues: {pressureAdj.id: '85'},
      );

      final setup3 = Setup(
        id: 's3',
        name: 'Future Setup',
        datetime: t3,
        datetimeLocal: t3.toLocal(),
        bike: myBike.id,
        person: me.id,
        tags: {},
        personAdjustmentValues: {},
        bikeAdjustmentValues: {},
      );

      final setups = {'s1': setup1, 's2': setup2, 's3': setup3};

      final result = SetupResolutionService.resolveSetups(
        setups: setups,
        bikes: {myBike.id: myBike},
        persons: {me.id: me},
        components: {fork.id: fork, shock.id: shock},
        ratings: {},
      );
      final resolved = result.setups;

      expect(resolved['s2']!.previousBikeAdjustmentValues[reboundAdj.id], '5');
      expect(resolved['s2']!.previousBikeAdjustmentValues[pressureAdj.id], '80');
      expect(resolved['s3']!.previousBikeAdjustmentValues[pressureAdj.id], '85');
      expect(resolved['s3']!.previousBikeAdjustmentValues[reboundAdj.id], '5');
    });

    test('historical edits propagate forward to sparse setups', () {
      // Intention: Verify that changing an older setup's snapshot propagates to future sparse setups without affecting explicitly overridden snapshots.
      // Desired outcome: If S1 is edited, S2 (sparse) inherits the new S1 value. S3 (which overrides the value) keeps its explicitly recorded value.
      // Not desired outcome: Editing S1 overwrites explicitly recorded values in S3, or fails to update inherited values in S2.

      final t1 = DateTime(2025, 1, 1).toUtc();
      final t2 = DateTime(2025, 1, 2).toUtc();
      final t3 = DateTime(2025, 1, 3).toUtc();

      // Original history was 80/5 -> sparse -> 90/6
      // Now User edits Setup 1 historically to 82/5
      final setup1 = Setup(
        id: 's1',
        name: 'Initial Setup',
        datetime: t1,
        datetimeLocal: t1.toLocal(),
        bike: myBike.id,
        person: me.id,
        tags: {},
        personAdjustmentValues: {},
        bikeAdjustmentValues: {pressureAdj.id: '82', reboundAdj.id: '5'},
      );

      final setup2 = Setup(
        id: 's2',
        name: 'Sparse Setup',
        datetime: t2,
        datetimeLocal: t2.toLocal(),
        bike: myBike.id,
        person: me.id,
        tags: {},
        personAdjustmentValues: {},
        bikeAdjustmentValues: {},
      );

      final setup3 = Setup(
        id: 's3',
        name: 'Override Setup',
        datetime: t3,
        datetimeLocal: t3.toLocal(),
        bike: myBike.id,
        person: me.id,
        tags: {},
        personAdjustmentValues: {},
        bikeAdjustmentValues: {pressureAdj.id: '90'}, // Explicitly overrides
      );

      final setups = {'s1': setup1, 's2': setup2, 's3': setup3};

      final result = SetupResolutionService.resolveSetups(
        setups: setups,
        bikes: {myBike.id: myBike},
        persons: {me.id: me},
        components: {fork.id: fork, shock.id: shock},
        ratings: {},
      );
      final resolved = result.setups;

      expect(resolved['s2']!.previousBikeAdjustmentValues[pressureAdj.id], '82');
      expect(resolved['s3']!.previousBikeAdjustmentValues[pressureAdj.id], '82');
      expect(resolved['s3']!.bikeAdjustmentValues[pressureAdj.id], '90');
    });

    test('component transfers carry adjustment values globally', () {
      // Intention: Verify that moving a component between bikes preserves its last known setup state.
      // Desired outcome: A setup on Bike B correctly inherits the component's state from the last setup on Bike A.
      // Not desired outcome: The component resets to a blank state on Bike B because the previous setup was on a different bike.

      final t1 = DateTime(2025, 1, 1).toUtc();
      final t2 = DateTime(2025, 1, 2).toUtc(); // Transfer happens here
      final t3 = DateTime(2025, 1, 3).toUtc();

      // Shock installed on myBike at t1, moved to otherBike at t2.
      final movingShock = Component(
        id: 'comp_shock',
        name: 'Shock',
        componentType: ComponentType.shock,
        adjustments: [reboundAdj],
        installations: [
          Installation(parent: myBike.id, dateTimeUTC: t1, dateTimeLocal: t1.toLocal()),
          Installation(parent: otherBike.id, dateTimeUTC: t2, dateTimeLocal: t2.toLocal()),
        ],
      );

      final setup1 = Setup(
        id: 's1',
        name: 'Setup on Bike 1',
        datetime: t1.add(const Duration(hours: 1)),
        datetimeLocal: t1.add(const Duration(hours: 1)).toLocal(),
        bike: myBike.id,
        person: me.id,
        tags: {},
        personAdjustmentValues: {},
        bikeAdjustmentValues: {reboundAdj.id: '7'}, // Set while on myBike
      );

      final setup2 = Setup(
        id: 's2',
        name: 'Setup on Bike 2',
        datetime: t3,
        datetimeLocal: t3.toLocal(),
        bike: otherBike.id,
        person: me.id, // now on otherBike
        tags: {},
        personAdjustmentValues: {},
        bikeAdjustmentValues: {}, // completely sparse
      );

      final result = SetupResolutionService.resolveSetups(
        setups: {'s1': setup1, 's2': setup2},
        bikes: {myBike.id: myBike, otherBike.id: otherBike},
        persons: {me.id: me},
        components: {movingShock.id: movingShock},
        ratings: {},
      );
      final resolved = result.setups;

      // s2 should inherit the shock value even though it's on a different bike
      expect(resolved['s2']!.previousBikeAdjustmentValues[reboundAdj.id], '7');
    });

    test('dangling values from edited installation timeline are preserved in snapshot, but excluded from previous calculation', () {
      // Intention: Verify behaviour when an older setup has a recorded value for a component that is later uninstalled, or was never installed according to an edited timeline.
      // Desired outcome: The recorded snapshot value in the old Setup is preserved (dangling value), but it is NOT inherited in `previousBikeAdjustmentValues` if the component is physically not on the bike at the time of the Setup.
      // Not desired outcome: The UI inherits values for components not on the bike, or the snapshot data is destructively discarded.

      final t1 = DateTime(2025, 1, 1).toUtc();
      final t2 = DateTime(2025, 1, 2).toUtc();

      // Fork installed initially
      final earlyFork = Component(
        id: 'comp_fork',
        name: 'Fork',
        componentType: ComponentType.fork,
        adjustments: [pressureAdj],
        installations: [
          Installation(parent: myBike.id, dateTimeUTC: t1, dateTimeLocal: t1.toLocal()),
          // Then removed at t2 (uninstalled)
          Installation(parent: null, dateTimeUTC: t2, dateTimeLocal: t2.toLocal()),
        ],
      );

      final setup1 = Setup(
        id: 's1',
        name: 'Before Removal',
        datetime: t1.add(const Duration(hours: 1)),
        datetimeLocal: t1.add(const Duration(hours: 1)).toLocal(),
        bike: myBike.id,
        person: me.id,
        tags: {},
        personAdjustmentValues: {},
        bikeAdjustmentValues: {pressureAdj.id: '80'}, // Recorded snapshot
      );

      final setup2 = Setup(
        id: 's2',
        name: 'After Removal',
        datetime: t2.add(const Duration(hours: 1)),
        datetimeLocal: t2.add(const Duration(hours: 1)).toLocal(),
        bike: myBike.id,
        person: me.id,
        tags: {},
        personAdjustmentValues: {},
        bikeAdjustmentValues: {pressureAdj.id: '80'}, // Let's say it recorded it historically, then timeline was edited
      );

      final result = SetupResolutionService.resolveSetups(
        setups: {'s1': setup1, 's2': setup2},
        bikes: {myBike.id: myBike},
        persons: {me.id: me},
        components: {earlyFork.id: earlyFork},
        ratings: {},
      );
      final resolved = result.setups;

      expect(resolved['s1']!.bikeAdjustmentValues[pressureAdj.id], '80');
      expect(resolved['s2']!.bikeAdjustmentValues[pressureAdj.id], '80');
      expect(resolved['s2']!.previousBikeAdjustmentValues.containsKey(pressureAdj.id), false);
    });

    test('intervening setup for different bike does not break resolution chain for a moved component', () {
      // Intention: Verify that the global state resolution handles "gaps" where an unrelated setup happens between two setups that share a component (transfer).
      // Desired outcome: Setup 3 inherits F1 settings from Setup 1, even if Setup 2 (intervening) was for a different bike and didn't mention F1.
      // Not desired outcome: Setup 3 loses F1 settings because the immediate predecessor (Setup 2) didn't include them in its filtered previous values.

      final t1 = DateTime(2025, 1, 1).toUtc();
      final t2 = DateTime(2025, 1, 2).toUtc();
      final t3 = DateTime(2025, 1, 3).toUtc();

      final s1 = Setup(
        id: 's1',
        name: 'Initial on A',
        datetime: t1,
        datetimeLocal: t1.toLocal(),
        bike: myBike.id,
        person: me.id,
        tags: {},
        personAdjustmentValues: {},
        bikeAdjustmentValues: {pressureAdj.id: '80'},
      );

      final s2 = Setup(
        id: 's2',
        name: 'Intervening on B',
        datetime: t2,
        datetimeLocal: t2.toLocal(),
        bike: otherBike.id,
        person: me.id,
        tags: {},
        personAdjustmentValues: {},
        bikeAdjustmentValues: {reboundAdj.id: '7'},
      );

      // Setup 3: Bike A, Sparse edit. F1 is on Bike A.
      final s3 = Setup(
        id: 's3',
        name: 'Follow-up on A',
        datetime: t3,
        datetimeLocal: t3.toLocal(),
        bike: myBike.id,
        person: me.id,
        tags: {},
        personAdjustmentValues: {},
        bikeAdjustmentValues: {}, // Will inherit from s1
      );

      final result = SetupResolutionService.resolveSetups(
        setups: {'s1': s1, 's2': s2, 's3': s3},
        bikes: {myBike.id: myBike, otherBike.id: otherBike},
        persons: {me.id: me},
        components: {fork.id: fork, shock.id: shock},
        ratings: {},
      );
      final resolved = result.setups;

      // s3 should inherit fork pressure '80' from s1, even though s2 was the most recent global setup.
      expect(resolved['s3']!.previousBikeAdjustmentValues[pressureAdj.id], '80');
    });

    test('resolveHistoricalStateAt correctly aggregates state up to a timestamp', () {
      // Intention: Verify the new centralized helper for SetupPage resolution works correctly.
      // Desired outcome: Returns a cumulative map of all adjustments up to the target time.

      final t1 = DateTime(2025, 1, 1).toUtc();
      final t2 = DateTime(2025, 1, 2).toUtc();

      final s1 = Setup(
        id: 's1',
        name: 'S1',
        datetime: t1,
        datetimeLocal: t1.toLocal(),
        bike: myBike.id,
        person: me.id,
        tags: {},
        personAdjustmentValues: {'person_adj_1': 'val1'},
        bikeAdjustmentValues: {pressureAdj.id: '80'},
      );

      final s2 = Setup(
        id: 's2',
        name: 'S2',
        datetime: t2,
        datetimeLocal: t2.toLocal(),
        bike: otherBike.id,
        person: me.id,
        tags: {},
        personAdjustmentValues: {},
        bikeAdjustmentValues: {reboundAdj.id: '7'},
      );

      final history = SetupResolutionService.resolveHistoricalStateAt(
        datetime: t2.add(const Duration(seconds: 1)),
        setups: [s1, s2],
        persons: {me.id: me},
      );

      expect(history[pressureAdj.id], '80');
      expect(history[reboundAdj.id], '7');
      // Person values are included in historical state for orange/green highlighting in SetupPage.
      expect(history['person_adj_1'], 'val1');
    });

    test('resolveHistoricalStateAt excludes the setup currently being edited', () {
      final originalTime = DateTime.utc(2025, 1, 1, 11, 55);
      final editedSetup = Setup(
        id: 'edited_setup',
        name: 'Edited Setup',
        datetime: originalTime,
        datetimeLocal: originalTime.toLocal(),
        bike: myBike.id,
        person: me.id,
        tags: {},
        personAdjustmentValues: {},
        bikeAdjustmentValues: {pressureAdj.id: '80'},
      );

      final history = SetupResolutionService.resolveHistoricalStateAt(
        datetime: originalTime.add(const Duration(minutes: 1)),
        setups: [editedSetup],
        persons: {me.id: me},
        excludedSetupId: editedSetup.id,
      );

      expect(history, isEmpty);
    });
  });
}
