import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/feedback/test_session_method.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/services/test_session_service.dart';
import 'package:flutter_test/flutter_test.dart';

StepAdjustment step(String id) => StepAdjustment(
  id: id,
  name: id,
  notes: '',
  unit: null,
  min: 0,
  max: 20,
  step: 1,
  visualization: StepAdjustmentVisualization.slider,
);

Setup setup(
  String id, {
  Map<String, AdjustmentValue> bike = const {},
  Map<String, AdjustmentValue> person = const {},
}) {
  final local = DateTime(2026, 5, 1, 10);
  return Setup(
    id: id,
    datetime: local.toUtc(),
    datetimeLocal: local,
    tags: const {'t'},
    notes: 'notes',
    bike: 'bike',
    person: 'rider',
    bikeAdjustmentValues: bike,
    personAdjustmentValues: person,
  );
}

TestSession session({
  List<String> knobs = const ['a', 'b'],
  Map<String, AdjustmentValue> locks = const {},
  bool ended = false,
}) {
  final started = DateTime(2026, 5, 2, 9);
  return TestSession(
    id: 'ts',
    bike: 'bike',
    adjustmentIds: knobs,
    locks: locks,
    startedAtUTC: started.toUtc(),
    startedAtLocal: started,
    endedAtUTC: ended ? started.toUtc() : null,
    endedAtLocal: ended ? started : null,
  );
}

void main() {
  group('knobsFor', () {
    test('lists the tunable adjustments of the components, then the rider', () {
      final fork = Component(
        id: 'fork',
        name: 'Fork',
        componentType: ComponentType.fork,
        installations: const [],
        adjustments: [
          step('rebound'),
          TextAdjustment(id: 'note', name: 'Note', notes: null, unit: null),
        ],
      );
      final rider = Person(id: 'rider', name: 'Rider', adjustments: [step('weight')]);

      final knobs = TestSessionService.knobsFor(bikeComponents: [fork], rider: rider);

      expect(knobs.map((k) => (k.adjustment.id, k.ownerName, k.isRider)), [
        ('rebound', 'Fork', false),
        ('weight', 'Rider', true),
      ]);
    });

    test('is empty without adjustments', () {
      expect(TestSessionService.knobsFor(bikeComponents: const []), isEmpty);
    });
  });

  test('differingAdjustmentIds lists the values that are not the same everywhere', () {
    final differing = TestSessionService.differingAdjustmentIds([
      setup('s1', bike: {'a': const StepValue(1), 'same': const StepValue(3)}, person: {'p': const StepValue(1)}),
      setup('s2', bike: {'a': const StepValue(2), 'same': const StepValue(3)}, person: {'p': const StepValue(1)}),
      setup('s3', bike: {'a': const StepValue(2), 'same': const StepValue(3), 'missing': const StepValue(1)}, person: {'p': const StepValue(1)}),
    ]);

    expect(differing, ['a', 'missing']);
  });

  group('editableIds', () {
    test('are the knobs minus the locked ones', () {
      expect(TestSessionService.editableIds(session()), {'a', 'b'});
      expect(TestSessionService.editableIds(session(locks: {'a': const StepValue(1)})), {'b'});
    });

    test('are none once the session has ended', () {
      expect(TestSessionService.editableIds(session(ended: true)), isEmpty);
    });
  });

  group('run', () {
    final now = DateTime(2026, 5, 3, 14, 30);

    test('copies the values, stamps now and joins the session', () {
      final source = setup('s1', bike: {'a': const StepValue(1), 'x': const StepValue(9)}, person: {'p': const StepValue(4)});

      final run = TestSessionService.run(source: source, session: session(), number: 2, now: now);

      expect(run.id, isNot(source.id));
      expect(run.name, 'Run 2');
      expect(run.testSessionId, 'ts');
      expect(run.datetimeLocal, now);
      expect(run.datetime, now.toUtc());
      expect(run.bike, 'bike');
      expect(run.person, 'rider');
      expect(run.bikeAdjustmentValues, source.bikeAdjustmentValues);
      expect(run.personAdjustmentValues, source.personAdjustmentValues);
      expect(run.tags, isEmpty, reason: 'tags and notes belong to the source');
      expect(run.notes, isNull);
    });

    test('puts the locked values on top, also when copying an older run', () {
      final source = setup('s1', bike: {'a': const StepValue(1), 'x': const StepValue(9)}, person: {'p': const StepValue(4)});

      final run = TestSessionService.run(
        source: source,
        session: session(locks: {'a': const StepValue(7), 'p': const StepValue(6), 'unknown': const StepValue(1)}),
        number: 3,
        now: now,
      );

      expect(run.bikeAdjustmentValues, {'a': const StepValue(7), 'x': const StepValue(9)});
      expect(run.personAdjustmentValues, {'p': const StepValue(6)});
    });
  });

  test('goalLabel names the end and the quality, and falls back to the slug for custom issues', () {
    expect(
      TestSessionService.goalLabel(const EndAspect(FeedbackEnd.front, FeedbackAttribute.calm), (slug) => slug),
      'Front · Calm',
    );
    expect(TestSessionService.goalLabel(const CustomAspect('arm-pump'), (slug) => 'Arm pump'), 'Arm pump');
  });

  group('expectedRuns', () {
    test('scales with the knobs for Fine-tune and Explore', () {
      expect(TestSessionService.expectedRuns(const PatternSearch(), 2), 'about 8 runs');
      expect(TestSessionService.expectedRuns(const OrthogonalArray(), 4), 'about 6 runs');
    });

    test('follows the candidates for Compare, and says nothing for Free or without knobs', () {
      expect(TestSessionService.expectedRuns(const Tournament(candidateSetupIds: ['a', 'b', 'c']), 2), 'about 4 runs');
      expect(TestSessionService.expectedRuns(null, 3), isNull);
      expect(TestSessionService.expectedRuns(const PatternSearch(), 0), isNull);
    });
  });
}
