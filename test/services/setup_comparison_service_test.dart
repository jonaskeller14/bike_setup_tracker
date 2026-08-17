import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
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
    Iterable<Bike> bikes = const [],
    bool includeContext = false,
    bool includePerson = false,
    bool includeTags = false,
    bool includeImages = false,
  }) {
    return SetupComparisonService.build(
      setupA: a,
      setupB: b,
      bikes: bikes,
      components: components,
      persons: persons,
      includeContext: includeContext,
      includePerson: includePerson,
      includeTags: includeTags,
      includeImages: includeImages,
    );
  }

  group('SetupComparisonService.build', () {
    test('projects context with strict references and feature-gated tags and images', () {
      final alex = Person(id: 'person-a', name: 'Alex', adjustments: const []);
      final result = compare(
        a: setup(
          id: 'a',
          bike: bikeA,
          person: alex.id,
          notes: 'first note',
          tags: {'dry', 'fast'},
          images: ['one.jpg', 'two.jpg'],
        ),
        b: setup(
          id: 'b',
          bike: bikeB,
          person: 'missing-person',
          notes: 'second note',
          tags: {'fast', 'dry'},
          images: ['two.jpg', 'one.jpg'],
        ),
        bikes: [
          Bike(id: bikeA, name: 'Bike A', person: null),
          Bike(id: bikeB, name: 'Bike B', person: null),
        ],
        persons: [alex],
        includeContext: true,
        includePerson: true,
        includeTags: true,
        includeImages: true,
      );

      final context = result.groups.firstWhere((group) => group.kind == SetupComparisonGroupKind.context);
      final rows = {for (final row in context.rows) row.id: row};
      expect(rows['bike']!.isDifferent, isTrue);
      expect(rows['person']!.valueB.value, isA<SetupComparisonReference>());
      expect((rows['person']!.valueB.value as SetupComparisonReference).label, 'Person not found');
      expect(rows['notes']!.isDifferent, isTrue);
      expect(rows['tags']!.isDifferent, isFalse);
      expect(rows['images']!.isDifferent, isTrue);
    });

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
      final onlyA = component(id: 'only-a', name: 'Only A', bike: bikeA);
      final onlyB = component(id: 'only-b', name: 'Only B', bike: bikeB);
      final result = compare(
        a: setup(id: 'a', bike: bikeA, at: DateTime.utc(2026, 1, 1)),
        b: setup(id: 'b', bike: bikeB, at: DateTime.utc(2026, 1, 3)),
        components: [onlyA, moved, onlyB],
      );

      expect(result.groups.map((group) => group.ownerId), ['only-a', 'moved', 'only-b']);
      expect(result.groups[1].ownerStateA, SetupComparisonOwnerState.installedOrLinked);
      expect(result.groups[1].ownerStateB, SetupComparisonOwnerState.installedOrLinked);
    });

    test('records dangling, absent, and deleted data without losing structural differences', () {
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
      final deletedGroup = result.groups.firstWhere((group) => group.kind == SetupComparisonGroupKind.deletedValues);
      expect(removedGroup.ownerStateA, SetupComparisonOwnerState.installedOrLinked);
      expect(removedGroup.ownerStateB, SetupComparisonOwnerState.dangling);
      expect(removedGroup.rows.single.valueB.provenance, SetupComparisonValueProvenance.dangling);
      expect(structuralGroup.rows, isEmpty);
      expect(structuralGroup.differenceCount, 1);
      expect(deletedGroup.rows.single.label, 'deleted-id');
      expect(deletedGroup.rows.single.valueB.provenance, SetupComparisonValueProvenance.deleted);
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
