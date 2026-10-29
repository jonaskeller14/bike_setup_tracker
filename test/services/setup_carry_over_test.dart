import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/setup_history.dart';
import 'package:bike_setup_tracker/services/component_hierarchy_resolver.dart';
import 'package:bike_setup_tracker/services/setup_carry_over.dart';
import 'package:flutter_test/flutter_test.dart';

const bike = 'bike';
final now = DateTime.utc(2026, 1, 10, 12);

Installation onBike(int day) => BikeInstallation(
  bikeId: bike,
  dateTimeUTC: DateTime.utc(2026, 1, day),
  dateTimeLocal: DateTime(2026, 1, day),
);

Installation uninstalled(int day) => Uninstallation(
  dateTimeUTC: DateTime.utc(2026, 1, day),
  dateTimeLocal: DateTime(2026, 1, day),
);

StepAdjustment step(String id, String name, {int max = 20}) => StepAdjustment(
  id: id,
  name: name,
  notes: '',
  unit: null,
  min: 0,
  max: max,
  step: 1,
  visualization: StepAdjustmentVisualization.slider,
);

Component fork(String id, List<Installation> installations, List<Adjustment> adjustments) => Component(
  id: id,
  name: id,
  componentType: ComponentType.fork,
  installations: installations,
  adjustments: adjustments,
);

Setup setup(String id, int day, Map<String, AdjustmentValue> values) {
  final at = DateTime.utc(2026, 1, day, 12);
  return Setup(
    id: id,
    datetime: at,
    datetimeLocal: at.toLocal(),
    tags: const {},
    bike: bike,
    person: null,
    bikeAdjustmentValues: values,
    personAdjustmentValues: const {},
  );
}

SetupCarryOver translate(Setup candidate, List<Setup> setups, List<Component> components) =>
    SetupCarryOver.forSetup(
      setup: candidate,
      setups: setups,
      components: components,
      hierarchy: ComponentHierarchyResolver({for (final c in components) c.id: c}),
      history: const SetupHistory(),
      now: now,
    );

void main() {
  group('SetupCarryOver.forSetup', () {
    late Component oldFork;
    late Component newFork;
    late Setup before;
    late Setup after;

    setUp(() {
      oldFork = fork('old-fork', [onBike(1), uninstalled(5)], [step('old-rebound', 'Rebound')]);
      newFork = fork('new-fork', [onBike(5)], [step('new-rebound', 'Rebound', max: 10)]);
      before = setup('before', 2, {'old-rebound': const StepValue(8)});
      after = setup('after', 6, {'new-rebound': const StepValue(3)});
    });

    test('moves the value of a replaced component to the adjustment in the same column', () {
      final carryOver = translate(before, [before, after], [oldFork, newFork]);

      final entry = carryOver.entries.single;
      expect(entry.isApplicable, isTrue);
      expect((entry.fromComponent.id, entry.from.id), ('old-fork', 'old-rebound'));
      expect((entry.toComponent!.id, entry.to!.id), ('new-fork', 'new-rebound'));
      expect(carryOver.applyTo(before.bikeAdjustmentValues), {'new-rebound': const StepValue(8)});
    });

    test('keeps the other values and drops only the moved one', () {
      final carryOver = translate(before, [before, after], [oldFork, newFork]);

      expect(carryOver.applyTo({'old-rebound': const StepValue(8), 'other': const StepValue(1)}), {
        'other': const StepValue(1),
        'new-rebound': const StepValue(8),
      });
    });

    test('leaves a value that the new adjustment does not allow where it was', () {
      final tooHigh = setup('too-high', 2, {'old-rebound': const StepValue(15)});

      final carryOver = translate(tooHigh, [tooHigh, after], [oldFork, newFork]);

      expect(carryOver.entries.single.issue, CarryOverIssue.valueNotAllowed);
      expect(carryOver.applicable, isEmpty);
      expect(carryOver.applyTo(tooHigh.bikeAdjustmentValues), tooHigh.bikeAdjustmentValues);
    });

    test('rejects a categorical option the new adjustment lacks', () {
      CategoricalAdjustment mode(String id, Set<String> options) =>
          CategoricalAdjustment(id: id, name: 'Mode', notes: '', unit: null, options: options);
      final oldShock = fork('old-fork', [onBike(1), uninstalled(5)], [mode('old-mode', {'Open', 'Firm'})]);
      final newShock = fork('new-fork', [onBike(5)], [mode('new-mode', {'Open', 'Lock'})]);
      final open = setup('open', 2, {'old-mode': CategoricalValue(const ['Open'])});
      final firm = setup('firm', 3, {'old-mode': CategoricalValue(const ['Firm'])});

      expect(translate(open, [open, firm], [oldShock, newShock]).entries.single.isApplicable, isTrue);
      expect(translate(firm, [open, firm], [oldShock, newShock]).entries.single.issue, CarryOverIssue.valueNotAllowed);
    });

    test('skips a value when no component sits in that position any more', () {
      final carryOver = translate(before, [before], [oldFork]);

      expect(carryOver.entries.single.issue, CarryOverIssue.componentGone);
      expect(carryOver.entries.single.to, isNull);
    });

    test('skips a value when the new component has no such adjustment', () {
      final other = fork('new-fork', [onBike(5)], [step('compression', 'Compression')]);

      final carryOver = translate(before, [before, after], [oldFork, other]);

      expect(carryOver.entries.single.issue, CarryOverIssue.noMatchingAdjustment);
      expect(carryOver.entries.single.toComponent!.id, 'new-fork');
    });

    test('has nothing to move for a candidate recorded on the current component', () {
      expect(translate(after, [before, after], [oldFork, newFork]).isEmpty, isTrue);
    });

    test('places a component installed since the last setup', () {
      final carryOver = translate(before, [before], [oldFork, newFork]);

      expect(carryOver.entries.single.to!.id, 'new-rebound');
    });
  });
}
