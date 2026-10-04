import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/setup_history.dart';
import 'package:bike_setup_tracker/services/bike_adjustment_column_service.dart';
import 'package:bike_setup_tracker/services/component_hierarchy_resolver.dart';
import 'package:bike_setup_tracker/services/component_slot.dart';
import 'package:flutter_test/flutter_test.dart';

const bike = 'bike';

Installation onBike(int day) => BikeInstallation(
  bikeId: bike,
  dateTimeUTC: DateTime.utc(2026, 1, day),
  dateTimeLocal: DateTime(2026, 1, day),
);

Installation onComponent(String parentId, int day) => ComponentInstallation(
  parentComponentId: parentId,
  dateTimeUTC: DateTime.utc(2026, 1, day),
  dateTimeLocal: DateTime(2026, 1, day),
);

Installation uninstalled(int day) => Uninstallation(
  dateTimeUTC: DateTime.utc(2026, 1, day),
  dateTimeLocal: DateTime(2026, 1, day),
);

NumericalAdjustment pressure(String id, {String name = 'Pressure', String unit = 'psi'}) =>
    NumericalAdjustment(id: id, name: name, notes: null, unit: CustomUnit(unit));

Component component(
  String id,
  ComponentType type,
  List<Installation> installations, {
  List<Adjustment> adjustments = const [],
}) => Component(id: id, name: id, componentType: type, installations: installations, adjustments: adjustments);

Setup setup(
  String id,
  int day, {
  Map<String, AdjustmentValue> values = const {},
}) {
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

/// [previous] maps setup ids to the bike values they inherit.
BikeAdjustmentProjection project(
  List<Setup> setups,
  List<Component> components, {
  Map<String, Map<String, AdjustmentValue>> previous = const {},
}) => BikeAdjustmentColumnService.build(
  bikeId: bike,
  setups: setups,
  components: components,
  hierarchy: ComponentHierarchyResolver({for (final c in components) c.id: c}),
  history: SetupHistory(previousBikeValues: previous),
);

const frontTire = ComponentSlot(type: ComponentType.tire, parentType: ComponentType.wheelFront);
const rearTire = ComponentSlot(type: ComponentType.tire, parentType: ComponentType.wheelRear);

void main() {
  group('BikeAdjustmentColumnService.build', () {
    late Component frontWheel;
    late Component rearWheel;

    setUp(() {
      frontWheel = component('front-wheel', ComponentType.wheelFront, [onBike(1)]);
      rearWheel = component('rear-wheel', ComponentType.wheelRear, [onBike(1)]);
    });

    test('merges a tire replaced on the same wheel into one column', () {
      final tireA = component(
        'tire-a',
        ComponentType.tire,
        [onComponent('front-wheel', 1), uninstalled(5)],
        adjustments: [pressure('pa')],
      );
      final tireB = component(
        'tire-b',
        ComponentType.tire,
        [onComponent('front-wheel', 5)],
        adjustments: [pressure('pb')],
      );
      final s1 = setup('s1', 2, values: {'pa': const NumericalValue(25)});
      final s2 = setup('s2', 6, values: {'pb': const NumericalValue(22)});

      final projection = project(
        [s1, s2],
        [frontWheel, tireA, tireB],
        previous: {'s2': {'pa': const NumericalValue(25)}},
      );
      final columns = projection.columns.where((c) => c.lane.slot == frontTire).toList();

      expect(columns, hasLength(1));
      final column = columns.single;
      expect(projection.laneOf(column)!.members.map((m) => m.component.id), ['tire-a', 'tire-b']);
      expect(projection.columnLabel(column), 'Pressure · Tire (Front Wheel)');
      expect(projection.valueFor(s1, column), const NumericalValue(25));
      expect(projection.valueFor(s2, column), const NumericalValue(22));
      expect(projection.previousValueFor(s2, column), isNull);
      expect(projection.resolve(s2, column)!.component.id, 'tire-b');
      expect(projection.isDangling(s2, column), isFalse);
    });

    test('lets values follow the position when tires are rotated', () {
      final tireA = component(
        'tire-a',
        ComponentType.tire,
        [onComponent('front-wheel', 1), onComponent('rear-wheel', 5)],
        adjustments: [pressure('pa')],
      );
      final tireB = component(
        'tire-b',
        ComponentType.tire,
        [onComponent('rear-wheel', 1), onComponent('front-wheel', 5)],
        adjustments: [pressure('pb')],
      );
      final s1 = setup('s1', 2, values: {'pa': const NumericalValue(20), 'pb': const NumericalValue(25)});
      final s2 = setup('s2', 6, values: {'pa': const NumericalValue(26), 'pb': const NumericalValue(21)});

      final projection = project([s1, s2], [frontWheel, rearWheel, tireA, tireB]);
      final front = projection.columns.singleWhere((c) => c.lane.slot == frontTire);
      final rear = projection.columns.singleWhere((c) => c.lane.slot == rearTire);

      expect(
        [projection.valueFor(s1, front), projection.valueFor(s2, front)],
        [
          const NumericalValue(20),
          const NumericalValue(21),
        ],
      );
      expect(
        [projection.valueFor(s1, rear), projection.valueFor(s2, rear)],
        [
          const NumericalValue(25),
          const NumericalValue(26),
        ],
      );
    });

    test('puts two tires mounted on the bike at the same time into separate lanes', () {
      final tireA = component('tire-a', ComponentType.tire, [onBike(1)], adjustments: [pressure('pa')]);
      final tireB = component('tire-b', ComponentType.tire, [onBike(1)], adjustments: [pressure('pb')]);
      final s1 = setup('s1', 2, values: {'pa': const NumericalValue(20), 'pb': const NumericalValue(25)});

      final projection = project([s1], [tireA, tireB]);

      expect(projection.lanes.map((lane) => lane.label), ['Tire 1', 'Tire 2']);
      expect(projection.columns.map(projection.columnLabel), ['Pressure · Tire 1', 'Pressure · Tire 2']);
      expect(projection.columns.map((c) => projection.valueFor(s1, c)), [
        const NumericalValue(20),
        const NumericalValue(25),
      ]);
    });

    test('prefers the most similar lane when several lanes are free', () {
      final specialized = component(
        'specialized',
        ComponentType.tire,
        [onBike(1), uninstalled(5)],
        adjustments: [pressure('p1')],
      );
      final maxxis = component(
        'maxxis',
        ComponentType.tire,
        [onBike(1), uninstalled(5)],
        adjustments: [pressure('p2')],
      );
      final newMaxxis = component(
        'maxxis 2',
        ComponentType.tire,
        [onBike(5)],
        adjustments: [pressure('p3')],
      );

      final projection = project([setup('s1', 2), setup('s2', 6)], [specialized, maxxis, newMaxxis]);
      final maxxisLane = projection.lanes.singleWhere((lane) => lane.members.first.component.id == 'maxxis');

      expect(maxxisLane.members.map((m) => m.component.id), ['maxxis', 'maxxis 2']);
    });

    test('keeps one lane when the parent wheel is replaced while the tire stays', () {
      final oldWheel = component(
        'old-wheel',
        ComponentType.wheelFront,
        [onBike(1), uninstalled(5)],
      );
      final newWheel = component('new-wheel', ComponentType.wheelFront, [onBike(5)]);
      final tire = component(
        'tire',
        ComponentType.tire,
        [onComponent('old-wheel', 1), onComponent('new-wheel', 5)],
        adjustments: [pressure('p')],
      );
      final s1 = setup('s1', 2, values: {'p': const NumericalValue(20)});
      final s2 = setup('s2', 6, values: {'p': const NumericalValue(22)});

      final projection = project([s1, s2], [oldWheel, newWheel, tire]);
      final column = projection.columns.single;

      expect(projection.lanes.where((lane) => lane.slot == frontTire), hasLength(1));
      expect(projection.laneOf(column)!.members.single.setupIds, {'s1', 's2'});
      expect(
        [projection.valueFor(s1, column), projection.valueFor(s2, column)],
        [
          const NumericalValue(20),
          const NumericalValue(22),
        ],
      );
    });

    test('splits adjustments with the same name but a different unit', () {
      final forkA = component(
        'fork-a',
        ComponentType.fork,
        [onBike(1), uninstalled(5)],
        adjustments: [pressure('pa', unit: 'psi')],
      );
      final forkB = component(
        'fork-b',
        ComponentType.fork,
        [onBike(5)],
        adjustments: [pressure('pb', unit: 'bar')],
      );

      final projection = project([setup('s1', 2), setup('s2', 6)], [forkA, forkB]);

      expect(projection.lanes, hasLength(1));
      expect(projection.columns.map((c) => c.adjustment.unit), [const CustomUnit('bar'), const CustomUnit('psi')]);
    });

    test('splits adjustments with the same name but a different class', () {
      final forkA = component(
        'fork-a',
        ComponentType.fork,
        [onBike(1), uninstalled(5)],
        adjustments: [
          StepAdjustment(
            id: 'ra',
            name: 'Rebound',
            notes: null,
            unit: null,
            step: 1,
            min: 0,
            max: 10,
            visualization: StepAdjustmentVisualization.slider,
          ),
        ],
      );
      final forkB = component(
        'fork-b',
        ComponentType.fork,
        [onBike(5)],
        adjustments: [NumericalAdjustment(id: 'rb', name: ' rebound ', notes: null, unit: null)],
      );

      final projection = project([setup('s1', 2), setup('s2', 6)], [forkA, forkB]);

      expect(projection.columns.map((c) => c.adjustment.type), [NumericalAdjustment, StepAdjustment]);
    });

    test('matches adjustment names case- and whitespace-insensitively', () {
      final forkA = component(
        'fork-a',
        ComponentType.fork,
        [onBike(1), uninstalled(5)],
        adjustments: [pressure('pa', name: 'Air  Pressure')],
      );
      final forkB = component(
        'fork-b',
        ComponentType.fork,
        [onBike(5)],
        adjustments: [pressure('pb', name: 'air pressure')],
      );

      final projection = project([setup('s1', 2), setup('s2', 6)], [forkA, forkB]);

      expect(projection.columns, hasLength(1));
      expect(projection.adjustmentFor(projection.columns.single)!.id, 'pb');
    });

    test('resolves a value of a component that is not installed to its lane as dangling', () {
      final tireA = component(
        'tire-a',
        ComponentType.tire,
        [onComponent('front-wheel', 1), uninstalled(5)],
        adjustments: [pressure('pa')],
      );
      final s1 = setup('s1', 2, values: {'pa': const NumericalValue(25)});
      final s2 = setup('s2', 6, values: {'pa': const NumericalValue(23)});

      final projection = project([s1, s2], [frontWheel, tireA]);
      final column = projection.columns.single;

      expect(projection.isDangling(s1, column), isFalse);
      expect(projection.valueFor(s2, column), const NumericalValue(23));
      expect(projection.isDangling(s2, column), isTrue);
    });

    test('prefers the present component over a dangling value in the same lane', () {
      final tireA = component(
        'tire-a',
        ComponentType.tire,
        [onComponent('front-wheel', 1), uninstalled(5)],
        adjustments: [pressure('pa')],
      );
      final tireB = component(
        'tire-b',
        ComponentType.tire,
        [onComponent('front-wheel', 5)],
        adjustments: [pressure('pb')],
      );
      final s2 = setup('s2', 6, values: {'pa': const NumericalValue(25), 'pb': const NumericalValue(22)});

      final projection = project([setup('s1', 2), s2], [frontWheel, tireA, tireB]);
      final column = projection.columns.single;

      expect(projection.valueFor(s2, column), const NumericalValue(22));
      expect(projection.isDangling(s2, column), isFalse);
    });

    test('hides values of components that no lane owns', () {
      final otherBikeTire = component(
        'other',
        ComponentType.tire,
        [
          BikeInstallation(
            bikeId: 'other-bike',
            dateTimeUTC: DateTime.utc(2026),
            dateTimeLocal: DateTime(2026),
          ),
        ],
        adjustments: [pressure('po')],
      );

      final projection = project(
        [
          setup('s1', 2, values: {'po': const NumericalValue(30)}),
        ],
        [otherBikeTire],
      );

      expect(projection.lanes, isEmpty);
      expect(projection.columns, isEmpty);
    });

    test('uses the direct parent for a component nested two levels deep', () {
      final fork = component('fork', ComponentType.fork, [onBike(1)]);
      final wheel = component('wheel', ComponentType.wheelFront, [onComponent('fork', 1)]);
      final tire = component(
        'tire',
        ComponentType.tire,
        [onComponent('wheel', 1)],
        adjustments: [pressure('p')],
      );

      final projection = project([setup('s1', 2)], [fork, wheel, tire]);

      expect(projection.columns.single.lane.slot, frontTire);
      expect(projection.columnLabel(projection.columns.single), 'Pressure · Tire (Front Wheel)');
    });

    test('orders columns by slot, lane, and the latest component adjustment order', () {
      final fork = component('fork', ComponentType.fork, [onBike(1)], adjustments: [pressure('fork-p')]);
      final rearTireComponent = component(
        'rear-tire',
        ComponentType.tire,
        [onComponent('rear-wheel', 1)],
        adjustments: [pressure('rear-p')],
      );
      final oldFrontTire = component(
        'old-front',
        ComponentType.tire,
        [onComponent('front-wheel', 1), uninstalled(5)],
        adjustments: [
          pressure('old-p'),
          pressure('old-inserts', name: 'Inserts'),
        ],
      );
      final newFrontTire = component(
        'new-front',
        ComponentType.tire,
        [onComponent('front-wheel', 5)],
        adjustments: [
          pressure('new-width', name: 'Width', unit: 'mm'),
          pressure('new-p'),
        ],
      );
      final setups = [setup('s2', 6), setup('s1', 2)];
      final components = [newFrontTire, rearTireComponent, oldFrontTire, fork, frontWheel, rearWheel];

      final projection = project(setups, components);

      expect(projection.columns.map(projection.columnLabel), [
        'Pressure · Fork',
        'Width · Tire (Front Wheel)',
        'Pressure · Tire (Front Wheel)',
        'Inserts · Tire (Front Wheel)',
        'Pressure · Tire (Rear Wheel)',
      ]);
      expect(
        project(setups.reversed.toList(), components.reversed.toList()).columns,
        projection.columns,
      );
    });
  });

  group('BikeAdjustmentProjection.hasChanges', () {
    late Component fork;
    late BikeAdjustmentColumnKey column;

    setUp(() {
      fork = component('fork', ComponentType.fork, [onBike(1)], adjustments: [pressure('p')]);
      column = project([setup('s1', 2)], [fork]).columns.single;
    });

    test('is false when the value never changes', () {
      final setups = [
        setup('s1', 2, values: {'p': const NumericalValue(80)}),
        setup('s2', 3),
        setup('s3', 4, values: {'p': const NumericalValue(80)}),
      ];
      final previous = {
        's2': {'p': const NumericalValue(80)},
        's3': {'p': const NumericalValue(80)},
      };

      expect(project(setups, [fork], previous: previous).hasChanges(column, setups), isFalse);
    });

    test('is true when the value changes at least once', () {
      final setups = [
        setup('s1', 2, values: {'p': const NumericalValue(80)}),
        setup('s2', 3, values: {'p': const NumericalValue(85)}),
      ];
      final previous = {
        's2': {'p': const NumericalValue(80)},
      };

      expect(project(setups, [fork], previous: previous).hasChanges(column, setups), isTrue);
    });

    test('compares values across a replacement', () {
      final tireA = component(
        'tire-a',
        ComponentType.tire,
        [onBike(1), uninstalled(5)],
        adjustments: [pressure('pa')],
      );
      final tireB = component('tire-b', ComponentType.tire, [onBike(5)], adjustments: [pressure('pb')]);
      final same = [
        setup('s1', 2, values: {'pa': const NumericalValue(25)}),
        setup('s2', 6, values: {'pb': const NumericalValue(25)}),
      ];
      final different = [
        setup('s1', 2, values: {'pa': const NumericalValue(25)}),
        setup('s2', 6, values: {'pb': const NumericalValue(22)}),
      ];

      final sameProjection = project(same, [tireA, tireB]);
      final differentProjection = project(different, [tireA, tireB]);

      expect(sameProjection.hasChanges(sameProjection.columns.single, same), isFalse);
      expect(differentProjection.hasChanges(differentProjection.columns.single, different), isTrue);
    });
  });
}
