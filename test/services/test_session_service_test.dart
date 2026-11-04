import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/l10n/test_session_text.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/feedback/test_session_method.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/setup_history.dart';
import 'package:bike_setup_tracker/services/bike_adjustment_column_service.dart';
import 'package:bike_setup_tracker/services/component_hierarchy_resolver.dart';
import 'package:bike_setup_tracker/services/setup_carry_over.dart';
import 'package:bike_setup_tracker/services/test_session_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/german_l10n.dart';

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

  group('differencesBetween', () {
    Installation onBike(int day) =>
        BikeInstallation(bikeId: 'bike', dateTimeUTC: DateTime.utc(2026, 1, day), dateTimeLocal: DateTime(2026, 1, day));

    Component fork(String id, List<Installation> installations, String rebound) => Component(
      id: id,
      name: id,
      componentType: ComponentType.fork,
      installations: installations,
      adjustments: [
        StepAdjustment(
          id: rebound,
          name: 'Rebound',
          notes: '',
          unit: null,
          min: 0,
          max: 20,
          step: 1,
          visualization: StepAdjustmentVisualization.slider,
        ),
      ],
    );

    Setup at(int day, {Map<String, AdjustmentValue> bike = const {}, Map<String, AdjustmentValue> person = const {}}) {
      final stamp = DateTime.utc(2026, 1, day, 12);
      return Setup(
        id: 's$day',
        datetime: stamp,
        datetimeLocal: stamp.toLocal(),
        tags: const {},
        bike: 'bike',
        person: 'rider',
        bikeAdjustmentValues: bike,
        personAdjustmentValues: person,
      );
    }

    final oldFork = fork('old-fork', [
      onBike(1),
      Uninstallation(dateTimeUTC: DateTime.utc(2026, 1, 5), dateTimeLocal: DateTime(2026, 1, 5)),
    ], 'old');
    final newFork = fork('new-fork', [onBike(5)], 'new');

    BikeAdjustmentProjection project(List<Setup> setups) => BikeAdjustmentColumnService.build(
      bikeId: 'bike',
      setups: setups,
      components: [oldFork, newFork],
      hierarchy: ComponentHierarchyResolver({'old-fork': oldFork, 'new-fork': newFork}),
      history: const SetupHistory(),
    );

    test('counts a replaced component and its successor as one column', () {
      final setups = [
        at(2, bike: {'old': const StepValue(8)}),
        at(6, bike: {'new': const StepValue(8)}),
        at(7, bike: {'new': const StepValue(4)}),
      ];

      final same = TestSessionService.differencesBetween(setups.take(2), project(setups));
      final differing = TestSessionService.differencesBetween(setups, project(setups));

      expect(same.count, 0);
      expect(same.adjustmentIds, isEmpty);
      expect(differing.count, 1);
      expect(differing.adjustmentIds, ['old', 'new']);
    });

    test('lists the rider attributes that are not the same everywhere', () {
      final setups = [
        at(2, bike: {'old': const StepValue(8)}, person: {'p': const StepValue(1), 'same': const StepValue(3)}),
        at(3, bike: {'old': const StepValue(8)}, person: {'p': const StepValue(2), 'same': const StepValue(3)}),
      ];

      final differences = TestSessionService.differencesBetween(setups, project(setups));

      expect(differences.adjustmentIds, ['p']);
      expect(differences.count, 1);
    });

    test('columnsOf finds the column of any of its adjustments', () {
      final projection = project([at(2, bike: {'old': const StepValue(8)}), at(6, bike: {'new': const StepValue(8)})]);

      expect(TestSessionService.columnsOf(['new'], projection), projection.columns);
      expect(TestSessionService.columnsOf(['other'], projection), isEmpty);
    });
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

  group('canResume', () {
    final ended = session(ended: true);

    Setup at(DateTime local, {String bike = 'bike', String? testSessionId}) => Setup(
      id: '$local$bike',
      datetime: local.toUtc(),
      datetimeLocal: local,
      tags: const {},
      bike: bike,
      person: null,
      bikeAdjustmentValues: const {},
      personAdjustmentValues: const {},
      testSessionId: testSessionId,
    );

    TestSession other(DateTime startedLocal, {String bike = 'bike', bool running = false}) => TestSession(
      id: 'other',
      bike: bike,
      adjustmentIds: const ['a'],
      startedAtUTC: startedLocal.toUtc(),
      startedAtLocal: startedLocal,
      endedAtUTC: running ? null : startedLocal.toUtc(),
      endedAtLocal: running ? null : startedLocal,
    );

    bool canResume({TestSession? session, List<TestSession> sessions = const [], List<Setup> setups = const []}) {
      final target = session ?? ended;
      return TestSessionService.canResume(target, sessions: [target, ...sessions], setups: setups);
    }

    final before = DateTime(2026, 5, 1, 9);
    final during = DateTime(2026, 5, 2, 10);
    final after = DateTime(2026, 5, 3, 9);

    test('an ended session with only its own runs and older setups may', () {
      expect(canResume(setups: [at(before), at(during, testSessionId: 'ts'), at(after, testSessionId: 'ts')]), isTrue);
    });

    test('a running session may not', () {
      expect(canResume(session: session()), isFalse);
    });

    test('an older session on the bike that has ended does not block', () {
      expect(canResume(sessions: [other(before)]), isTrue);
    });

    test('another running session on the bike blocks, even an older one', () {
      expect(canResume(sessions: [other(before, running: true)]), isFalse);
    });

    test('a newer session blocks, even without any runs left', () {
      expect(canResume(sessions: [other(after)]), isFalse);
    });

    test('a newer setup blocks', () {
      expect(canResume(setups: [at(after)]), isFalse);
    });

    test('a setup backdated between the runs blocks', () {
      expect(canResume(setups: [at(during), at(after, testSessionId: 'ts')]), isFalse);
    });

    test("another bike's setups and sessions don't block", () {
      expect(
        canResume(
          sessions: [other(after, bike: 'other bike', running: true)],
          setups: [at(after, bike: 'other bike')],
        ),
        isTrue,
      );
    });
  });

  group('run', () {
    final now = DateTime(2026, 5, 3, 14, 30);

    test('copies the values, stamps now and joins the session', () {
      final source = setup('s1', bike: {'a': const StepValue(1), 'x': const StepValue(9)}, person: {'p': const StepValue(4)});

      final run = TestSessionService.run(englishL10n, source: source, session: session(), number: 2, now: now);

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
      expect(run.sourceSetupId, 's1');
      expect(run.sourceKind, SetupSourceKind.testSessionRun);
    });

    test('puts the locked values on top, also when copying an older run', () {
      final source = setup('s1', bike: {'a': const StepValue(1), 'x': const StepValue(9)}, person: {'p': const StepValue(4)});

      final run = TestSessionService.run(englishL10n, 
        source: source,
        session: session(locks: {'a': const StepValue(7), 'p': const StepValue(6), 'unknown': const StepValue(1)}),
        number: 3,
        now: now,
      );

      expect(run.bikeAdjustmentValues, {'a': const StepValue(7), 'x': const StepValue(9)});
      expect(run.personAdjustmentValues, {'p': const StepValue(6)});
    });

    test('a Compare run rides its candidate as it is, even with a lock stored', () {
      final candidate = setup('s1', bike: {'a': const StepValue(1)});
      final compare = TestSession(
        id: 'ts',
        bike: 'bike',
        method: const Tournament(candidateSetupIds: ['s1', 's2']),
        adjustmentIds: const ['a'],
        locks: const {'a': StepValue(7)},
        startedAtUTC: DateTime.utc(2026, 5, 2, 7),
        startedAtLocal: DateTime(2026, 5, 2, 9),
      );

      final run = TestSessionService.run(englishL10n, source: candidate, session: compare, number: 2, now: now);

      expect(run.bikeAdjustmentValues, {'a': const StepValue(1)});
    });

    test('moves the values of replaced components to their successors', () {
      Component fork(String id, String adjustmentId) => Component(
        id: id,
        name: id,
        componentType: ComponentType.fork,
        installations: const [],
        adjustments: [step(adjustmentId)],
      );
      final oldFork = fork('old-fork', 'a');
      final newFork = fork('new-fork', 'b');
      final candidate = setup('s1', bike: {'a': const StepValue(1), 'x': const StepValue(9)});
      final carryOver = SetupCarryOver([
        CarryOverEntry(
          fromComponent: oldFork,
          from: oldFork.adjustments.single,
          value: const StepValue(1),
          toComponent: newFork,
          to: newFork.adjustments.single,
        ),
      ]);

      final run = TestSessionService.run(englishL10n, 
        source: candidate,
        session: session(),
        number: 2,
        carryOver: carryOver,
        now: now,
      );

      expect(run.bikeAdjustmentValues, {'x': const StepValue(9), 'b': const StepValue(1)});
      expect(run.sourceSetupId, 's1');
    });
  });

  group('runNotes', () {
    test("keeps the notes of a setup from outside the session and adds where it's from", () {
      final source = setup('s1').copyWith(name: 'Base');

      expect(
        TestSessionService.runNotes(englishL10n, source: source, session: session(), dateFormat: 'yyyy-MM-dd'),
        "notes\n\nCopy of 'Base' (2026-05-01)",
      );
    });

    test('drops the notes of an earlier run, so the copy lines do not pile up', () {
      final earlier = setup('r1').copyWith(name: 'Run 1', notes: "Felt harsh\n\nCopy of 'Base' (2026-05-01)", testSessionId: 'ts');

      expect(
        TestSessionService.runNotes(englishL10n, source: earlier, session: session(), dateFormat: 'dd.MM.yyyy'),
        "Copy of 'Run 1' (01.05.2026)",
      );
    });
  });

  test('goalLabel names the end and the quality, and falls back to the slug for custom issues', () {
    expect(
      testSessionGoalLabel(const EndAspect(FeedbackEnd.front, FeedbackAttribute.calm), (slug) => slug, englishL10n),
      'Front · Calm',
    );
    expect(testSessionGoalLabel(const CustomAspect('arm-pump'), (slug) => 'Arm pump', englishL10n), 'Arm pump');
  });

  test('labels follow the language', () {
    expect(testSessionMethodLabel(const PatternSearch(), germanL10n), 'Feinjustieren');
    expect(
      testSessionGoalLabel(const EndAspect(FeedbackEnd.rear, FeedbackAttribute.calm), (slug) => slug, germanL10n),
      'Hinten · Ruhe',
    );
    expect(testSessionExpectedRuns(const PatternSearch(), 2, germanL10n), 'etwa 8 Läufe');
    expect(germanL10n.testSessionUnnamed, 'Unbenannte Testsession');
  });

  group('expectedRuns', () {
    test('scales with the knobs for Fine-tune and Explore', () {
      expect(testSessionExpectedRuns(const PatternSearch(), 2, englishL10n), 'about 8 runs');
      expect(testSessionExpectedRuns(const OrthogonalArray(), 4, englishL10n), 'about 6 runs');
    });

    test('follows the candidates for Compare, and says nothing for Free or without knobs', () {
      expect(testSessionExpectedRuns(const Tournament(candidateSetupIds: ['a', 'b', 'c']), 2, englishL10n), 'about 4 runs');
      expect(testSessionExpectedRuns(null, 3, englishL10n), isNull);
      expect(testSessionExpectedRuns(const PatternSearch(), 0, englishL10n), isNull);
    });
  });
}
