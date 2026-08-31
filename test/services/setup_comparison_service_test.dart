import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/setup_comparison.dart';
import 'package:bike_setup_tracker/services/setup_comparison_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bikeA = 'bike-a';
  const bikeB = 'bike-b';

  Setup setup({
    required String id,
    required String bike,
    String? person,
    String? notes,
    Set<String> tags = const {},
    List<String> images = const [],
    Map<String, dynamic> bikeValues = const {},
    Map<String, dynamic> personValues = const {},
    Map<String, dynamic> previousBikeValues = const {},
    Map<String, dynamic> previousPersonValues = const {},
    DateTime? at,
  }) {
    return Setup(
        id: id,
        datetime: at ?? DateTime.utc(2026, 1, 2),
        datetimeLocal: (at ?? DateTime.utc(2026, 1, 2)).toLocal(),
        notes: notes,
        tags: tags,
        bike: bike,
        person: person,
        bikeAdjustmentValues: bikeValues,
        personAdjustmentValues: personValues,
        images: images,
      )
      ..previousBikeAdjustmentValues = previousBikeValues
      ..previousPersonAdjustmentValues = previousPersonValues;
  }

  Component component({
    required String id,
    required String name,
    required String bike,
    List<Adjustment> adjustments = const [],
    ComponentType type = ComponentType.fork,
    List<Installation>? installations,
  }) {
    return Component(
      id: id,
      name: name,
      componentType: type,
      installations: installations ?? [Installation.sinceBeginning(parent: bike)],
      adjustments: adjustments,
    );
  }

  TextAdjustment text(String id, [String? name]) => TextAdjustment(
    id: id,
    name: name ?? id,
    notes: null,
    unit: null,
  );

  SetupComparison compare({
    required Setup a,
    required Setup b,
    Iterable<Component> components = const [],
    Iterable<Person> persons = const [],
  }) {
    return SetupComparisonService.build(
      setupA: a,
      setupB: b,
      components: components,
      persons: persons,
    );
  }

  group('SetupComparisonService.build', () {
    test('uses explicit and inherited effective values without treating provenance as a difference', () {
      final adjustment = text('pressure');
      final fork = component(id: 'fork', name: 'Fork', bike: bikeA, adjustments: [adjustment]);
      final result = compare(
        a: setup(id: 'current', bike: bikeA, bikeValues: {'pressure': 80}),
        b: setup(id: 'older', bike: bikeA, previousBikeValues: {'pressure': 80}),
        components: [fork],
      );

      final row = result.groups.single.rows.single;
      expect(row.valueA.provenance, SetupComparisonValueProvenance.explicit);
      expect(row.valueB.provenance, SetupComparisonValueProvenance.inherited);
      expect(row.isDifferent, isFalse);
      expect(result.differenceCount, 0);
    });

    test('distinguishes an explicit null from an absent value', () {
      final adjustment = text('cleared');
      final fork = component(id: 'fork', name: 'Fork', bike: bikeA, adjustments: [adjustment]);
      final result = compare(
        a: setup(id: 'a', bike: bikeA, bikeValues: {'cleared': null}),
        b: setup(id: 'b', bike: bikeA),
        components: [fork],
      );

      final row = result.groups.single.rows.single;
      expect(row.valueA.provenance, SetupComparisonValueProvenance.explicit);
      expect(row.valueA.value, isNull);
      expect(row.valueB.provenance, SetupComparisonValueProvenance.unavailable);
      expect(row.isDifferent, isTrue);
    });

    test('compares scalar, duration, and categorical values with deep list equality', () {
      final adjustments = <Adjustment>[
        text('number'),
        BooleanAdjustment(id: 'bool', name: 'bool', notes: null, unit: null),
        text('text'),
        DurationAdjustment(id: 'duration', name: 'duration', notes: null, unit: null),
        CategoricalAdjustment(
          id: 'list',
          name: 'list',
          notes: null,
          unit: null,
          options: const {'open', 'closed'},
          multiSelect: true,
        ),
        CategoricalAdjustment(
          id: 'counted',
          name: 'counted',
          notes: null,
          unit: null,
          options: const {'open', 'closed'},
          multiSelect: true,
          counted: true,
        ),
      ];
      final fork = component(id: 'fork', name: 'Fork', bike: bikeA, adjustments: adjustments);
      final values = <String, dynamic>{
        'number': 2.5,
        'bool': true,
        'text': 'trail',
        'duration': const Duration(seconds: 45),
        'list': ['open', 'closed'],
        'counted': ['open', 'open'],
      };
      final result = compare(
        a: setup(id: 'a', bike: bikeA, bikeValues: values),
        b: setup(
          id: 'b',
          bike: bikeA,
          bikeValues: {
            ...values,
            'counted': ['open'],
          },
        ),
        components: [fork],
      );

      expect(result.groups.single.rows.where((row) => row.isDifferent).map((row) => row.id), ['counted']);
    });

    test('joins adjustments by UUID and keeps A-first then B-only order', () {
      final aOne = text('a-one', 'Same label');
      final aTwo = text('a-two');
      final bSameLabel = text('b-one', 'Same label');
      final bTwo = text('b-two');
      final fork = component(
        id: 'fork',
        name: 'Fork',
        bike: bikeA,
        adjustments: [aOne, aTwo, bSameLabel, bTwo],
      );
      final result = compare(
        a: setup(id: 'a', bike: bikeA, bikeValues: {'a-one': 1, 'a-two': 2}),
        b: setup(id: 'b', bike: bikeA, bikeValues: {'b-one': 1, 'b-two': 2}),
        components: [fork],
      );

      final rows = result.groups.single.rows;
      expect(rows.map((row) => row.id), ['a-one', 'a-two', 'b-one', 'b-two']);
      expect(rows.every((row) => row.isDifferent), isTrue);
    });

    test('matches a moved component by UUID across bikes and preserves component ordering', () {
      final adjustment = text('rebound');
      final moved = component(
        id: 'moved',
        name: 'Shock',
        bike: bikeA,
        adjustments: [adjustment],
        installations: [
          Installation(parent: bikeA, dateTimeUTC: DateTime.utc(2026), dateTimeLocal: DateTime(2026)),
          Installation(parent: bikeB, dateTimeUTC: DateTime.utc(2026, 1, 2), dateTimeLocal: DateTime(2026, 1, 2)),
        ],
      );
      final onlyA = component(
        id: 'only-a',
        name: 'Only A',
        bike: bikeA,
        type: ComponentType.shock,
      );
      final onlyB = component(
        id: 'only-b',
        name: 'Only B',
        bike: bikeB,
        type: ComponentType.tire,
      );
      final result = compare(
        a: setup(id: 'a', bike: bikeA, at: DateTime.utc(2026, 1, 1)),
        b: setup(id: 'b', bike: bikeB, at: DateTime.utc(2026, 1, 3)),
        components: [onlyA, moved, onlyB],
      );

      expect(result.groups.map((group) => group.ownerId), ['only-a', 'moved', 'only-b']);
      expect(result.groups[1].ownerStateA, SetupComparisonOwnerState.installedOrLinked);
      expect(result.groups[1].ownerStateB, SetupComparisonOwnerState.installedOrLinked);
    });

    test('pairs only one-sided same-type components and keeps their adjustments independent', () {
      final frontA = component(
        id: 'a-front',
        name: '29 Front Maxxis Tire',
        bike: bikeA,
        type: ComponentType.tire,
        adjustments: [text('a-pressure', 'Pressure'), text('a-insert', 'Insert')],
      );
      final rearA = component(
        id: 'a-rear',
        name: 'Rear Schwalbe Tire 27.5',
        bike: bikeA,
        type: ComponentType.tire,
        adjustments: [text('a-rebound', 'Rebound')],
      );
      final rearB = component(
        id: 'b-1-rear',
        name: '27.5 Schwalbe Rear Tire',
        bike: bikeB,
        type: ComponentType.tire,
        adjustments: [text('b-rebound', 'Rebound')],
      );
      final frontB = component(
        id: 'b-2-front',
        name: 'Maxxis Tire Front 29',
        bike: bikeB,
        type: ComponentType.tire,
        adjustments: [text('b-pressure', 'Pressure'), text('b-insert', 'Insert')],
      );
      final result = compare(
        a: setup(
          id: 'a',
          bike: bikeA,
          bikeValues: {'a-pressure': 20, 'a-insert': 'yes', 'a-rebound': 5},
        ),
        b: setup(
          id: 'b',
          bike: bikeB,
          bikeValues: {'b-pressure': 21, 'b-insert': 'no', 'b-rebound': 6},
        ),
        components: [frontA, rearA, rearB, frontB],
      );

      expect(result.groups, hasLength(2));
      final frontPair = result.groups.firstWhere((group) => group.componentA?.id == 'a-front');
      final rearPair = result.groups.firstWhere((group) => group.componentA?.id == 'a-rear');
      expect(frontPair.componentB?.id, 'b-2-front');
      expect(rearPair.componentB?.id, 'b-1-rear');
      expect(frontPair.isInferredComponentPair, isTrue);
      expect(frontPair.rows, isEmpty);
      expect(frontPair.independentRowsA.map((row) => row.id), ['a-pressure', 'a-insert']);
      expect(frontPair.independentRowsB.map((row) => row.id), ['b-pressure', 'b-insert']);
      expect(frontPair.independentRowsA.first.valueA.value, 20);
      expect(frontPair.independentRowsB.first.valueB.value, 21);
      expect(frontPair.independentRowsA.every((row) => !row.isDifferent), isTrue);
      expect(frontPair.differenceCount, 1);
      expect(result.differenceCount, 2);
    });

    test('pairs components replaced between two setups on the same bike', () {
      final oldTire = component(
        id: 'old-tire',
        name: 'Front Tire 29',
        bike: bikeA,
        type: ComponentType.tire,
        adjustments: [text('old-pressure', 'Pressure')],
        installations: [
          Installation.sinceBeginning(parent: bikeA),
          Installation(
            parent: null,
            dateTimeUTC: DateTime.utc(2026, 1, 2),
            dateTimeLocal: DateTime(2026, 1, 2),
          ),
        ],
      );
      final newTire = component(
        id: 'new-tire',
        name: '29 Front Tire New',
        bike: bikeA,
        type: ComponentType.tire,
        adjustments: [text('new-pressure', 'Pressure')],
        installations: [
          Installation(
            parent: bikeA,
            dateTimeUTC: DateTime.utc(2026, 1, 2),
            dateTimeLocal: DateTime(2026, 1, 2),
          ),
        ],
      );
      final result = compare(
        a: setup(
          id: 'before',
          bike: bikeA,
          at: DateTime.utc(2026, 1, 1),
          bikeValues: {'old-pressure': 20},
        ),
        b: setup(
          id: 'after',
          bike: bikeA,
          at: DateTime.utc(2026, 1, 3),
          bikeValues: {'new-pressure': 22},
        ),
        components: [oldTire, newTire],
      );

      expect(result.groups, hasLength(1));
      expect(result.groups.single.isInferredComponentPair, isTrue);
      expect(result.groups.single.componentA?.id, 'old-tire');
      expect(result.groups.single.componentB?.id, 'new-tire');
      expect(result.groups.single.independentRowsA.single.valueA.value, 20);
      expect(result.groups.single.independentRowsB.single.valueB.value, 22);
    });

    test('pairs zero-similarity candidates deterministically and leaves same-type surplus one-sided', () {
      final a = component(
        id: 'a-component',
        name: 'Alpha',
        bike: bikeA,
        type: ComponentType.other,
      );
      final firstB = component(
        id: 'b-first',
        name: 'Zulu',
        bike: bikeB,
        type: ComponentType.other,
      );
      final secondB = component(
        id: 'b-second',
        name: 'Whiskey',
        bike: bikeB,
        type: ComponentType.other,
      );
      final result = compare(
        a: setup(id: 'a', bike: bikeA, at: DateTime.utc(2026, 1, 1)),
        b: setup(id: 'b', bike: bikeB, at: DateTime.utc(2026, 1, 3)),
        components: [a, secondB, firstB],
      );

      expect(result.groups, hasLength(2));
      expect(result.groups.first.componentA?.id, 'a-component');
      expect(result.groups.first.componentB?.id, 'b-first');
      expect(result.groups.first.isInferredComponentPair, isTrue);
      expect(result.groups.last.componentA, isNull);
      expect(result.groups.last.componentB?.id, 'b-second');

      final reversed = compare(
        a: setup(id: 'b', bike: bikeB),
        b: setup(id: 'a', bike: bikeA),
        components: [a, secondB, firstB],
      );
      expect(reversed.groups, hasLength(2));
      expect(reversed.groups.first.componentA?.id, 'b-second');
      expect(reversed.groups.first.componentB, isNull);
      expect(reversed.groups.last.componentA?.id, 'b-first');
      expect(reversed.groups.last.componentB?.id, 'a-component');
    });

    test('maximizes similarity across the complete candidate assignment', () {
      final aFirst = component(
        id: 'a-first',
        name: 'Alpha',
        bike: bikeA,
        adjustments: [text('a-first-adjustment', 'First')],
      );
      final aSecond = component(
        id: 'a-second',
        name: 'Alpha',
        bike: bikeA,
        adjustments: [text('a-second-adjustment', 'Second')],
      );
      final bFirst = component(
        id: 'b-first',
        name: 'Alpha',
        bike: bikeB,
        adjustments: [text('b-first-adjustment', 'Second')],
      );
      final bSecond = component(
        id: 'b-second',
        name: 'Zulu',
        bike: bikeB,
        adjustments: [text('b-second-adjustment', 'First')],
      );
      final result = compare(
        a: setup(id: 'a', bike: bikeA),
        b: setup(id: 'b', bike: bikeB),
        components: [aFirst, aSecond, bFirst, bSecond],
      );

      expect(
        result.groups.map((group) => (group.componentA?.id, group.componentB?.id)),
        [('a-first', 'b-second'), ('a-second', 'b-first')],
      );
    });

    test('never infers a replacement for a component present in both setups', () {
      final shared = component(id: 'shared', name: 'Shared Fork', bike: bikeA);
      final replacement = component(
        id: 'replacement',
        name: 'Shared Fork 2',
        bike: bikeB,
      );
      final result = compare(
        a: setup(id: 'a', bike: bikeA, at: DateTime.utc(2026, 1, 1)),
        b: setup(id: 'b', bike: bikeB, at: DateTime.utc(2026, 1, 3)),
        components: [
          shared.copyWith(
            installations: [
              Installation.sinceBeginning(parent: bikeA),
              Installation(
                parent: bikeB,
                dateTimeUTC: DateTime.utc(2026, 1, 2),
                dateTimeLocal: DateTime(2026, 1, 2),
              ),
            ],
          ),
          replacement,
        ],
      );

      final sharedGroup = result.groups.firstWhere((group) => group.ownerId == 'shared');
      expect(sharedGroup.isInferredComponentPair, isFalse);
      expect(sharedGroup.componentA?.id, 'shared');
      expect(sharedGroup.componentB?.id, 'shared');
      final replacementGroup = result.groups.firstWhere((group) => group.ownerId == 'replacement');
      expect(replacementGroup.componentA, isNull);
    });

    test('ignores dangling and deleted values while preserving structural differences', () {
      final adjustment = text('legacy-value');
      final removed = component(
        id: 'removed',
        name: 'Removed Fork',
        bike: bikeA,
        adjustments: [adjustment],
        installations: [
          Installation(parent: bikeA, dateTimeUTC: DateTime.utc(2026), dateTimeLocal: DateTime(2026)),
          Installation(parent: null, dateTimeUTC: DateTime.utc(2026, 1, 2), dateTimeLocal: DateTime(2026, 1, 2)),
        ],
      );
      final structural = component(
        id: 'structural',
        name: 'Structural',
        bike: bikeA,
        installations: [
          Installation(parent: bikeA, dateTimeUTC: DateTime.utc(2026), dateTimeLocal: DateTime(2026)),
          Installation(parent: null, dateTimeUTC: DateTime.utc(2026, 1, 2), dateTimeLocal: DateTime(2026, 1, 2)),
        ],
      );
      final result = compare(
        a: setup(id: 'a', bike: bikeA, at: DateTime.utc(2026, 1, 1)),
        b: setup(
          id: 'b',
          bike: bikeA,
          at: DateTime.utc(2026, 1, 3),
          bikeValues: {'legacy-value': 9, 'deleted-id': 'orphan'},
        ),
        components: [removed, structural],
      );

      final removedGroup = result.groups.firstWhere((group) => group.ownerId == 'removed');
      final structuralGroup = result.groups.firstWhere((group) => group.ownerId == 'structural');
      expect(removedGroup.ownerStateA, SetupComparisonOwnerState.installedOrLinked);
      expect(removedGroup.ownerStateB, SetupComparisonOwnerState.absent);
      expect(removedGroup.rows.single.valueB.provenance, SetupComparisonValueProvenance.unavailable);
      expect(structuralGroup.rows, isEmpty);
      expect(structuralGroup.differenceCount, 1);
      expect(result.groups.map((group) => group.ownerId), ['removed', 'structural']);
    });

    test('joins people strictly by ID, including distinct names and null people', () {
      final riderAdjustment = text('rider-adj');
      final alexA = Person(id: 'alex-a', name: 'Alex', adjustments: [riderAdjustment]);
      final alexB = Person(id: 'alex-b', name: 'Alex', adjustments: [riderAdjustment]);
      final result = compare(
        a: setup(id: 'a', bike: bikeA, person: alexA.id),
        b: setup(id: 'b', bike: bikeA, person: alexB.id),
        persons: [alexA, alexB],
      );

      expect(result.groups.map((group) => group.ownerId), ['alex-a', 'alex-b']);
      expect(result.groups.every((group) => group.isDifferent), isTrue);
      expect(
        compare(
          a: setup(id: 'a', bike: bikeA),
          b: setup(id: 'b', bike: bikeA),
          persons: [alexA],
        ).groups,
        isEmpty,
      );
    });
  });

  group('SetupComparisonService.resolveTargets', () {
    test('selects only a distinct current setup on B bike for implicit targets', () {
      final historical = setup(id: 'historical', bike: bikeA);
      final current = setup(id: 'current', bike: bikeA)..isCurrent = true;
      final otherCurrent = setup(id: 'other-current', bike: bikeB)..isCurrent = true;
      final result = SetupComparisonService.resolveTargets(
        setupB: historical,
        setups: [otherCurrent, current, historical],
      );

      expect(result, isA<SetupComparisonTargets>());
      expect((result as SetupComparisonTargets).setupA.id, 'current');
      expect(result.setupB.id, 'historical');
    });

    test('returns typed unavailable results when no distinct current setup is usable', () {
      final current = setup(id: 'current', bike: bikeA)..isCurrent = true;
      expect(
        SetupComparisonService.resolveTargets(setupB: current, setups: [current]),
        isA<SetupComparisonTargetsUnavailable>(),
      );
      expect(
        SetupComparisonService.resolveTargets(
          setupB: setup(id: 'only', bike: bikeA),
          setups: [],
        ),
        isA<SetupComparisonTargetsUnavailable>(),
      );
    });

    test('rejects equal explicit inputs and accepts ordered cross-bike inputs', () {
      final a = setup(id: 'a', bike: bikeA);
      final b = setup(id: 'b', bike: bikeB);
      expect(
        SetupComparisonService.resolveTargets(setupA: a, setupB: a, setups: const []),
        isA<SetupComparisonTargetsEqualInput>(),
      );
      final result = SetupComparisonService.resolveTargets(setupA: a, setupB: b, setups: const []);
      expect(result, isA<SetupComparisonTargets>());
      expect((result as SetupComparisonTargets).setupA, same(a));
      expect(result.setupB, same(b));
    });
  });
}
