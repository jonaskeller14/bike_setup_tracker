import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_comparison.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/services/data_selection_dependencies.dart';
import 'package:flutter_test/flutter_test.dart';

final _day = DateTime.utc(2026, 1, 1);

DataRef person(String id) => DataRef(DataKind.person, id);
DataRef bike(String id) => DataRef(DataKind.bike, id);
DataRef component(String id) => DataRef(DataKind.component, id);
DataRef setup(String id) => DataRef(DataKind.setup, id);
DataRef taskRule(String id) => DataRef(DataKind.taskRule, id);
DataRef taskEntry(String id) => DataRef(DataKind.taskEntry, id);
DataRef feedback(String id) => DataRef(DataKind.feedback, id);
DataRef testSession(String id) => DataRef(DataKind.testSession, id);

Person makePerson(String id, {List<Adjustment>? adjustments, bool isDeleted = false}) =>
    Person(id: id, name: id, adjustments: adjustments, isDeleted: isDeleted);

Bike makeBike(String id, {String? person, bool isDeleted = false}) =>
    Bike(id: id, name: id, person: person, isDeleted: isDeleted);

Component makeComponent(String id, {List<Installation> installations = const [], List<Adjustment>? adjustments}) =>
    Component(
      id: id,
      name: id,
      installations: installations,
      componentType: ComponentType.other,
      adjustments: adjustments,
    );

Setup makeSetup(
  String id, {
  required String bike,
  String? person,
  String? testSessionId,
  Map<String, AdjustmentValue> bikeValues = const {},
  Map<String, AdjustmentValue> personValues = const {},
}) => Setup(
  id: id,
  datetime: _day,
  datetimeLocal: _day,
  tags: const {},
  bike: bike,
  person: person,
  bikeAdjustmentValues: bikeValues,
  personAdjustmentValues: personValues,
  testSessionId: testSessionId,
);

TestSession makeTestSession(
  String id, {
  required String bike,
  List<String> adjustmentIds = const [],
  Map<String, AdjustmentValue>? locks,
}) => TestSession(
  id: id,
  bike: bike,
  adjustmentIds: adjustmentIds,
  locks: locks,
  startedAtUTC: _day,
  startedAtLocal: _day,
);

RideFeedback makeFeedback(
  String id, {
  required String bike,
  required String setupId,
  Set<String> comparedTo = const {},
}) => RideFeedback(
  id: id,
  bike: bike,
  setupId: setupId,
  dateTimeUTC: _day,
  dateTimeLocal: _day,
  comparisons: {
    for (final reference in comparedTo)
      FeedbackComparison(referenceSetupId: reference, aspect: const OverallAspect(), outcome: 1),
  },
);

TaskRule makeTaskRule(String id, {TaskAssociation association = const GeneralTaskAssociation()}) =>
    TaskRule(id: id, name: id, tags: const {}, association: association);

TaskEntry makeTaskEntry(
  String id, {
  required String taskRule,
  TaskAssociation association = const GeneralTaskAssociation(),
}) => TaskEntry(id: id, name: id, dateTimeUTC: _day, dateTimeLocal: _day, taskRule: taskRule, association: association);

Installation onBike(String bikeId) => BikeInstallation(bikeId: bikeId, dateTimeUTC: _day, dateTimeLocal: _day);

Installation onComponent(String parentId) =>
    ComponentInstallation(parentComponentId: parentId, dateTimeUTC: _day, dateTimeLocal: _day);

SelectedData data({
  List<Person> persons = const [],
  List<Bike> bikes = const [],
  List<Component> components = const [],
  List<Setup> setups = const [],
  List<TaskRule> taskRules = const [],
  List<TaskEntry> taskEntries = const [],
  List<RideFeedback> feedbacks = const [],
  List<TestSession> testSessions = const [],
}) => SelectedData(
  persons: {for (final item in persons) item.id: item},
  bikes: {for (final item in bikes) item.id: item},
  components: {for (final item in components) item.id: item},
  setups: {for (final item in setups) item.id: item},
  taskRules: {for (final item in taskRules) item.id: item},
  taskEntries: {for (final item in taskEntries) item.id: item},
  feedbacks: {for (final item in feedbacks) item.id: item},
  testSessions: {for (final item in testSessions) item.id: item},
);

DataSelection selectionOf(Iterable<DataRef> refs) => DataSelection()..addAll(refs);

void main() {
  group('DataRef', () {
    test('compares by kind and id', () {
      expect(bike('a'), bike('a'));
      expect(bike('a').hashCode, bike('a').hashCode);
      expect(bike('a'), isNot(setup('a')));
      expect(bike('a'), isNot(bike('b')));
    });
  });

  group('DataSelection', () {
    test('all selects every item of the dataset', () {
      final all = data(bikes: [makeBike('b1'), makeBike('b2')], persons: [makePerson('p1')]);
      final selection = DataSelection.all(all);

      expect(selection.count(DataKind.bike), 2);
      expect(selection.count(DataKind.person), 1);
      expect(selection.count(DataKind.setup), 0);
    });

    test('add, addAll and remove report what changed', () {
      final selection = DataSelection();

      expect(selection.add(bike('b1')), isTrue);
      expect(selection.add(bike('b1')), isFalse);
      expect(selection.addAll([bike('b1'), bike('b2'), setup('s1')]), {bike('b2'), setup('s1')});
      expect(selection.contains(setup('s1')), isTrue);
      expect(selection.remove(setup('s1')), isTrue);
      expect(selection.remove(setup('s1')), isFalse);
      expect(selection.contains(setup('s1')), isFalse);
    });

    test('toSelectedData keeps the dataset order and drops unknown ids', () {
      final all = data(bikes: [makeBike('b1'), makeBike('b2'), makeBike('b3')]);
      final selection = selectionOf([bike('b3'), bike('b1'), bike('unknown')]);

      expect(selection.toSelectedData(all).bikes.keys, ['b1', 'b3']);
    });
  });

  group('referencesOf', () {
    group('bike', () {
      test('references its rider', () {
        final deps = DataSelectionDependencies(
          data(
            persons: [makePerson('p1')],
            bikes: [makeBike('b1', person: 'p1')],
          ),
        );

        expect(deps.referencesOf(bike('b1')), {person('p1')});
      });

      test('without a rider references nothing', () {
        final deps = DataSelectionDependencies(data(bikes: [makeBike('b1')]));

        expect(deps.referencesOf(bike('b1')), isEmpty);
      });
    });

    group('person', () {
      test('references nothing', () {
        final deps = DataSelectionDependencies(data(persons: [makePerson('p1')]));

        expect(deps.referencesOf(person('p1')), isEmpty);
      });
    });

    group('component', () {
      test('references every installation bike and parent component', () {
        final deps = DataSelectionDependencies(
          data(
            bikes: [makeBike('b1'), makeBike('b2')],
            components: [
              makeComponent('wheel'),
              makeComponent('tire', installations: [onBike('b1'), onComponent('wheel'), onBike('b2')]),
            ],
          ),
        );

        expect(deps.referencesOf(component('tire')), {bike('b1'), bike('b2'), component('wheel')});
      });

      test('ignores a self-reference', () {
        final deps = DataSelectionDependencies(
          data(
            components: [
              makeComponent('c1', installations: [onComponent('c1')]),
            ],
          ),
        );

        expect(deps.referencesOf(component('c1')), isEmpty);
      });
    });

    group('setup', () {
      test('references its bike, rider and test session', () {
        final deps = DataSelectionDependencies(
          data(
            persons: [makePerson('p1')],
            bikes: [makeBike('b1')],
            setups: [makeSetup('s1', bike: 'b1', person: 'p1', testSessionId: 't1')],
            testSessions: [makeTestSession('t1', bike: 'b1')],
          ),
        );

        expect(deps.referencesOf(setup('s1')), {bike('b1'), person('p1'), testSession('t1')});
      });

      test('references the component and person owning its adjustment values', () {
        final fork = BooleanAdjustment(id: 'lockout', name: 'Lockout', notes: null, unit: null);
        final weight = BooleanAdjustment(id: 'pack', name: 'Pack', notes: null, unit: null);
        final deps = DataSelectionDependencies(
          data(
            persons: [
              makePerson('p1', adjustments: [weight]),
            ],
            bikes: [makeBike('b1')],
            components: [
              makeComponent('c1', adjustments: [fork]),
              makeComponent('c2'),
            ],
            setups: [
              makeSetup(
                's1',
                bike: 'b1',
                bikeValues: {'lockout': const BooleanValue(true)},
                personValues: {'pack': const BooleanValue(false)},
              ),
            ],
          ),
        );

        expect(deps.referencesOf(setup('s1')), {bike('b1'), component('c1'), person('p1')});
      });

      test('ignores values for an adjustment the dataset has no owner for', () {
        final deps = DataSelectionDependencies(
          data(
            bikes: [makeBike('b1')],
            setups: [
              makeSetup('s1', bike: 'b1', bikeValues: {'unknown': const BooleanValue(true)}),
            ],
          ),
        );

        expect(deps.referencesOf(setup('s1')), {bike('b1')});
      });
    });

    group('test session', () {
      test('references its bike and the owners of its adjustments and locks', () {
        final rebound = BooleanAdjustment(id: 'rebound', name: 'Rebound', notes: null, unit: null);
        final lockout = BooleanAdjustment(id: 'lockout', name: 'Lockout', notes: null, unit: null);
        final deps = DataSelectionDependencies(
          data(
            bikes: [makeBike('b1')],
            components: [
              makeComponent('fork', adjustments: [rebound]),
              makeComponent('shock', adjustments: [lockout]),
            ],
            testSessions: [
              makeTestSession(
                't1',
                bike: 'b1',
                adjustmentIds: ['rebound'],
                locks: {'lockout': const BooleanValue(true)},
              ),
            ],
          ),
        );

        expect(deps.referencesOf(testSession('t1')), {bike('b1'), component('fork'), component('shock')});
      });
    });

    group('feedback', () {
      test('references its bike, its setup and the compared setups', () {
        final deps = DataSelectionDependencies(
          data(
            bikes: [makeBike('b1')],
            setups: [
              makeSetup('s1', bike: 'b1'),
              makeSetup('s0', bike: 'b1'),
            ],
            feedbacks: [
              makeFeedback('f1', bike: 'b1', setupId: 's1', comparedTo: {'s0'}),
            ],
          ),
        );

        expect(deps.referencesOf(feedback('f1')), {bike('b1'), setup('s1'), setup('s0')});
      });
    });

    group('task rule', () {
      final all = data(
        bikes: [makeBike('b1')],
        components: [makeComponent('c1')],
        taskRules: [
          makeTaskRule('general'),
          makeTaskRule('onBike', association: const BikeTaskAssociation('b1')),
          makeTaskRule('onComponent', association: const ComponentTaskAssociation('c1')),
        ],
      );

      test('general references nothing', () {
        expect(DataSelectionDependencies(all).referencesOf(taskRule('general')), isEmpty);
      });

      test('bike association references the bike', () {
        expect(DataSelectionDependencies(all).referencesOf(taskRule('onBike')), {bike('b1')});
      });

      test('component association references the component', () {
        expect(DataSelectionDependencies(all).referencesOf(taskRule('onComponent')), {component('c1')});
      });
    });

    group('task entry', () {
      final all = data(
        bikes: [makeBike('b1')],
        components: [makeComponent('c1')],
        taskRules: [makeTaskRule('r1')],
        taskEntries: [
          makeTaskEntry('general', taskRule: 'r1'),
          makeTaskEntry('onBike', taskRule: 'r1', association: const BikeTaskAssociation('b1')),
          makeTaskEntry('onComponent', taskRule: 'r1', association: const ComponentTaskAssociation('c1')),
        ],
      );

      test('general references its rule', () {
        expect(DataSelectionDependencies(all).referencesOf(taskEntry('general')), {taskRule('r1')});
      });

      test('bike association references the rule and the bike', () {
        expect(DataSelectionDependencies(all).referencesOf(taskEntry('onBike')), {taskRule('r1'), bike('b1')});
      });

      test('component association references the rule and the component', () {
        expect(
          DataSelectionDependencies(all).referencesOf(taskEntry('onComponent')),
          {taskRule('r1'), component('c1')},
        );
      });
    });

    group('targets outside the dataset', () {
      test('are not references', () {
        final deps = DataSelectionDependencies(
          data(
            bikes: [makeBike('b1', person: 'gone')],
            components: [
              makeComponent('c1', installations: [onBike('gone'), onComponent('gone')]),
            ],
            setups: [makeSetup('s1', bike: 'gone', person: 'gone', testSessionId: 'gone')],
            feedbacks: [
              makeFeedback('f1', bike: 'gone', setupId: 'gone', comparedTo: {'gone'}),
            ],
            testSessions: [makeTestSession('t1', bike: 'gone')],
            taskRules: [makeTaskRule('r1', association: const BikeTaskAssociation('gone'))],
            taskEntries: [makeTaskEntry('e1', taskRule: 'gone', association: const ComponentTaskAssociation('gone'))],
          ),
        );

        for (final ref in [
          bike('b1'),
          component('c1'),
          setup('s1'),
          feedback('f1'),
          testSession('t1'),
          taskRule('r1'),
          taskEntry('e1'),
        ]) {
          expect(deps.referencesOf(ref), isEmpty, reason: '$ref');
        }
      });

      test('an item outside the dataset references nothing', () {
        expect(DataSelectionDependencies(data()).referencesOf(setup('missing')), isEmpty);
      });
    });
  });

  group('closureOf', () {
    test('follows feedback → setup → bike → rider', () {
      final deps = DataSelectionDependencies(
        data(
          persons: [makePerson('p1')],
          bikes: [makeBike('b1', person: 'p1')],
          setups: [makeSetup('s1', bike: 'b1')],
          feedbacks: [makeFeedback('f1', bike: 'b1', setupId: 's1')],
        ),
      );

      expect(deps.closureOf([feedback('f1')]), {feedback('f1'), setup('s1'), bike('b1'), person('p1')});
    });

    test('terminates on the setup ↔ test session cycle', () {
      final rebound = BooleanAdjustment(id: 'rebound', name: 'Rebound', notes: null, unit: null);
      final deps = DataSelectionDependencies(
        data(
          bikes: [makeBike('b1')],
          components: [
            makeComponent('fork', installations: [onBike('b1')], adjustments: [rebound]),
          ],
          setups: [
            makeSetup('s1', bike: 'b1', testSessionId: 't1', bikeValues: {'rebound': const BooleanValue(true)}),
          ],
          testSessions: [
            makeTestSession('t1', bike: 'b1', adjustmentIds: ['rebound']),
          ],
        ),
      );

      expect(deps.closureOf([setup('s1')]), {setup('s1'), testSession('t1'), bike('b1'), component('fork')});
    });

    test('terminates on a component parent cycle', () {
      final deps = DataSelectionDependencies(
        data(
          components: [
            makeComponent('a', installations: [onComponent('b')]),
            makeComponent('b', installations: [onComponent('a')]),
          ],
        ),
      );

      expect(deps.closureOf([component('a')]), {component('a'), component('b')});
    });

    test('follows nested components up to the bike', () {
      final deps = DataSelectionDependencies(
        data(
          bikes: [makeBike('b1')],
          components: [
            makeComponent('wheel', installations: [onBike('b1')]),
            makeComponent('tire', installations: [onComponent('wheel')]),
          ],
        ),
      );

      expect(deps.closureOf([component('tire')]), {component('tire'), component('wheel'), bike('b1')});
    });
  });

  group('issues', () {
    final all = data(
      persons: [makePerson('p1')],
      bikes: [makeBike('b1', person: 'p1')],
      setups: [
        makeSetup('s1', bike: 'b1'),
        makeSetup('s2', bike: 'b1'),
      ],
      taskRules: [makeTaskRule('r1')],
      taskEntries: [makeTaskEntry('e1', taskRule: 'r1')],
    );
    final deps = DataSelectionDependencies(all);

    test('a complete selection has no issues', () {
      expect(deps.issues(DataSelection.all(all)).isEmpty, isTrue);
    });

    test('an empty selection has no issues', () {
      expect(deps.issues(DataSelection()).isEmpty, isTrue);
    });

    test('without local data only the selection counts', () {
      final issues = deps.issues(selectionOf([setup('s2'), setup('s1'), taskEntry('e1')]));

      expect(issues.items.map((issue) => issue.item), [setup('s1'), setup('s2'), taskEntry('e1')]);
      expect(issues.items.first.missing, {bike('b1')});
      expect(issues.items.first.missingKinds, {DataKind.bike});
      expect(issues.affectedKinds, {DataKind.setup, DataKind.taskEntry});
      expect(issues.missing, {bike('b1'), taskRule('r1')});
      expect(issues.missingKinds, {DataKind.bike, DataKind.taskRule});
    });

    test('a target that is live on the device is covered', () {
      final local = data(bikes: [makeBike('b1')]);

      final issues = deps.issues(selectionOf([setup('s1')]), local: local);

      expect(issues.isEmpty, isTrue);
    });

    test('a target in the device trash is not covered', () {
      final local = data(bikes: [makeBike('b1', isDeleted: true)]);

      final issues = deps.issues(selectionOf([setup('s1')]), local: local);

      expect(issues.missing, {bike('b1')});
    });

    test('local coverage is checked per reference', () {
      final local = data(persons: [makePerson('p1')]);

      final issues = deps.issues(selectionOf([bike('b1'), setup('s1'), taskEntry('e1')]), local: local);

      expect(issues.items.map((issue) => issue.item), [taskEntry('e1')]);
    });

    test('an unticked item does not report its own references', () {
      final issues = deps.issues(selectionOf([person('p1')]));

      expect(issues.isEmpty, isTrue);
    });
  });
}
