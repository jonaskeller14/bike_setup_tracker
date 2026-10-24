import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/daos/setups_dao.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/component_preset.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/context/context_position.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_comparison.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_observation.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/feedback/test_session_method.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/strava/strava_athlete.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mappers Test', () {
    test('Bike Mapping', () {
      final bike = Bike(
        id: 'bike1',
        name: 'Road Bike',
        person: 'person1',
        isDeleted: false,
        lastModified: DateTime(2023, 1, 1).toUtc(),
      );

      // Model -> Companion
      final companion = bike.toCompanion();
      expect(companion.id.value, 'bike1');
      expect(companion.name.value, 'Road Bike');
      expect(companion.person.value, 'person1');
      expect(companion.isDeleted.value, false);

      // DB Row -> Model
      final data = BikeDb(
        id: 'bike1',
        name: 'Road Bike',
        person: 'person1',
        isDeleted: false,
        lastModified: DateTime(2023, 1, 1).toUtc(),
        orderIndex: 0,
        initialDistance: 5000,
        initialElevationGain: 100,
        initialMovingTime: const Duration(hours: 2),
        initialElapsedTime: const Duration(hours: 3),
        initialActivityCount: 4,
        initialKilojoules: 900,
        attachments: const [],
      );
      final model = data.toModel();
      expect(model.id, 'bike1');
      expect(model.name, 'Road Bike');
      expect(model.person, 'person1');
      expect(model.isDeleted, false);
      expect(model.initialStats.distance, 5000);
      expect(model.initialStats.movingTime, const Duration(hours: 2));
      expect(model.initialStats.activityCount, 4);
      expect(model.initialStats.kilojoules, 900);
    });

    test('Person Mapping', () {
      final person = Person(
        id: 'person1',
        name: 'Jonas',
        adjustments: [
          NumericalAdjustment(id: 'adj1', name: 'Weight', notes: '', unit: AdjustmentUnit.fromLegacy('kg')),
        ],
        isDeleted: false,
        lastModified: DateTime(2023, 1, 1).toUtc(),
      );

      // Model -> Companion
      final companion = person.toCompanion();
      expect(companion.id.value, 'person1');
      expect(companion.name.value, 'Jonas');

      // DB Row -> Model
      final data = PersonDb(
        id: 'person1',
        name: 'Jonas',
        isDeleted: false,
        lastModified: DateTime(2023, 1, 1).toUtc(),
        orderIndex: 0,
      );
      final model = data.toModel(adjustments: [
        NumericalAdjustment(id: 'adj1', name: 'Weight', notes: '', unit: AdjustmentUnit.fromLegacy('kg')),
      ]);
      expect(model.id, 'person1');
      expect(model.name, 'Jonas');
      expect(model.adjustments.first.name, 'Weight');
    });

    test('Component Mapping', () {
      final component = Component(
        id: 'comp1',
        name: 'Fork',
        componentType: ComponentType.fork,
        installations: [Installation.sinceBeginning(parent: 'bike1')],
        adjustments: [
          StepAdjustment(id: 'adj2', name: 'Rebound', notes: '', unit: AdjustmentUnit.fromLegacy('clicks'), min: 0, max: 20, step: 1, visualization: StepAdjustmentVisualization.slider),
        ],
        isDeleted: false,
        lastModified: DateTime(2023, 1, 1).toUtc(),
      );

      // Model -> Companion
      final companion = component.toCompanion();
      expect(companion.id.value, 'comp1');
      expect(companion.name.value, 'Fork');
      expect(companion.componentType.value, ComponentType.fork);

      // DB Row -> Model
      final data = ComponentDb(
        id: 'comp1',
        name: 'Fork',
        componentType: ComponentType.fork,
        isDeleted: false,
        lastModified: DateTime(2023, 1, 1).toUtc(),
        orderIndex: 0,
        initialDistance: 0.0,
        initialElevationGain: 0.0,
        initialMovingTime: Duration.zero,
        initialElapsedTime: Duration.zero,
        initialActivityCount: 0,
        initialKilojoules: 0.0,
        attachments: const [],
      );
      final model = data.toModel(
        adjustments: [
          StepAdjustment(id: 'adj2', name: 'Rebound', notes: '', unit: AdjustmentUnit.fromLegacy('clicks'), min: 0, max: 20, step: 1, visualization: StepAdjustmentVisualization.slider),
        ],
        installations: [Installation.sinceBeginning(parent: 'bike1')],
      );
      expect(model.id, 'comp1');
      expect(model.componentType, ComponentType.fork);
      expect(model.installations.first.parent, 'bike1');
    });

    test('Component Mapping carries preset provenance both ways', () {
      // `updateComponent` replaces the whole row, so a mapper that dropped
      // these would silently clear the provenance on every component edit.
      final preset = ComponentPreset(const {'brand': 'fox', 'component_type': 'fork', 'model': '36', 'damper': 'grip_x2'});
      final component = Component(
        id: 'comp1',
        name: 'FOX 36 Factory',
        componentType: ComponentType.fork,
        installations: const [],
        lastModified: DateTime(2023, 1, 1).toUtc(),
        preset: preset,
      );

      final companion = component.toCompanion();
      expect(companion.preset.value, preset);

      final model = ComponentDb(
        id: 'comp1',
        name: 'FOX 36 Factory',
        componentType: ComponentType.fork,
        isDeleted: false,
        lastModified: DateTime(2023, 1, 1).toUtc(),
        orderIndex: 0,
        initialDistance: 0.0,
        initialElevationGain: 0.0,
        initialMovingTime: Duration.zero,
        initialElapsedTime: Duration.zero,
        initialActivityCount: 0,
        initialKilojoules: 0.0,
        preset: preset,
        attachments: const [],
      ).toModel();
      expect(model.preset, preset);
    });

    test('Setup Mapping', () {
      final setup = Setup(
        id: 'setup1',
        name: 'Race Setup',
        datetime: DateTime(2023, 1, 1).toUtc(),
        datetimeLocal: DateTime(2023, 1, 1),
        tags: const {'race'},
        bike: 'bike1',
        person: 'person1',
        bikeAdjustmentValues: const {'adj1': StepValue(10)},
        personAdjustmentValues: const {'adj2': StepValue(5)},
      );

      // Model -> Companion
      final companion = setup.toCompanion();
      expect(companion.id.value, 'setup1');
      expect(companion.name.value, 'Race Setup');
      expect(companion.tags.value, {'race'});
      expect(companion.bikeId.value, 'bike1');

      // DB Row -> Model
      final data = SetupDb(
        id: 'setup1',
        name: 'Race Setup',
        datetime: DateTime(2023, 1, 1).toUtc(),
        datetimeLocal: DateTime(2023, 1, 1),
        tags: {'race'},
        bikeId: 'bike1',
        personId: 'person1',
        isDeleted: false,
        lastModified: DateTime(2023, 1, 1).toUtc(),
        attachments: const [],
        isBookmarked: false,
      );
      
      final model = data.toModel();

      expect(model.id, 'setup1');
      expect(model.tags, contains('race'));
      expect(model.bike, 'bike1');
    });

    test('Setup Value Parsing (int vs double)', () {
      final setupDb = SetupDb(
        id: 's1',
        bikeId: 'b1',
        isDeleted: false,
        lastModified: DateTime.now().toUtc(),
        name: 'Test Setup',
        datetime: DateTime.now().toUtc(),
        datetimeLocal: DateTime.now(),
        tags: {},
        attachments: const [],
        isBookmarked: false,
      );

      final stepAdj = const AdjustmentDb(
        id: 'adj_step',
        name: 'Step Adj',
        type: AdjustmentType.step,
        orderIndex: 0,
        componentId: 'c1',
      );

      final numericalAdj = const AdjustmentDb(
        id: 'adj_num',
        name: 'Num Adj',
        type: AdjustmentType.numerical,
        orderIndex: 1,
        componentId: 'c1',
      );

      final values = [
        TypedSetupValue(
          adjustment: stepAdj,
          value: const SetupAdjustmentValueDb(setupId: 's1', adjustmentId: 'adj_step', value: '10'),
        ),
        TypedSetupValue(
          adjustment: numericalAdj,
          value: const SetupAdjustmentValueDb(setupId: 's1', adjustmentId: 'adj_num', value: '10.5'),
        ),
      ];

      final model = setupDb.toModel(values: values);

      expect(model.bikeAdjustmentValues['adj_step'], const StepValue(10));
      expect(model.bikeAdjustmentValues['adj_num'], const NumericalValue(10.5));
    });

    group('Detailed Adjustment Mapping', () {
      test('Adjustment Table -> Model', () {
        final data = const AdjustmentDb(
          id: 'adj1',
          name: 'Pressure',
          type: AdjustmentType.numerical,
          unit: 'psi',
          orderIndex: 0,
          jsonPayload: '{"version":1,"type":"numerical","min":0.0,"max":300.0}',
        );
        
        final model = data.toModel();
        expect(model, isA<NumericalAdjustment>());
        expect(model.name, 'Pressure');
        expect(model.unit?.label, 'psi');
        expect((model as NumericalAdjustment).min, 0.0);
      });
    });

    group('Installation DB mapper', () {
      final utc = DateTime.utc(2024, 6, 1, 12);
      final local = DateTime(2024, 6, 1, 12);

      test('parentType=bike with parent yields BikeInstallation', () {
        final db = InstallationDb(
          id: 'i1',
          componentId: 'c1',
          parent: 'b1',
          parentType: InstallationParentType.bike,
          dateTimeUTC: utc,
          dateTimeLocal: local,
        );
        final model = db.toModel();
        expect(model, isA<BikeInstallation>());
        expect((model as BikeInstallation).bikeId, 'b1');
        expect(model.id, 'i1');
      });

      test('toCompanion takes the owning componentId from the caller', () {
        final companion = BikeInstallation(id: 'i1', bikeId: 'b1', dateTimeUTC: utc, dateTimeLocal: local)
            .toCompanion(componentId: 'c1');
        expect(companion.componentId.value, 'c1');
        expect(companion.parent.value, 'b1');
      });

      test('parentType=none yields Uninstallation', () {
        final db = InstallationDb(
          id: 'i2',
          componentId: 'c1',
          parent: null,
          parentType: InstallationParentType.none,
          dateTimeUTC: utc,
          dateTimeLocal: local,
        );
        expect(db.toModel(), isA<Uninstallation>());
      });

      test('parentType=component yields ComponentInstallation', () {
        final db = InstallationDb(
          id: 'nested-i',
          componentId: 'tire',
          parent: 'wheel',
          parentType: InstallationParentType.component,
          dateTimeUTC: utc,
          dateTimeLocal: local,
        );
        final model = db.toModel();
        expect(model, isA<ComponentInstallation>());
        expect((model as ComponentInstallation).parentComponentId, 'wheel');
      });

      test('parentType=archived yields Archival', () {
        final db = InstallationDb(
          id: 'i3',
          componentId: 'c1',
          parent: null,
          parentType: InstallationParentType.archived,
          dateTimeUTC: utc,
          dateTimeLocal: local,
        );
        expect(db.toModel(), isA<Archival>());
      });

      test('parentType=bike with null parent falls back to Uninstallation', () {
        // Defensive: a corrupted row with parentType=bike but no parent id.
        final db = InstallationDb(
          id: 'i4',
          componentId: 'c1',
          parent: null,
          parentType: InstallationParentType.bike,
          dateTimeUTC: utc,
          dateTimeLocal: local,
        );
        expect(db.toModel(), isA<Uninstallation>());
      });
    });

    group('Installation JSON round-trip', () {
      final utc = DateTime.utc(2024, 6, 1, 12);
      final local = DateTime(2024, 6, 1, 12);

      test('BikeInstallation round-trips', () {
        final original = BikeInstallation(
          id: 'i1',
          bikeId: 'b1',
          dateTimeUTC: utc,
          dateTimeLocal: local,
        );
        final json = original.toJson();
        expect(json['type'], 'bike');
        expect(json['parent'], 'b1');

        final restored = Installation.fromJson(json);
        expect(restored, isA<BikeInstallation>());
        expect((restored as BikeInstallation).bikeId, 'b1');
        expect(restored.id, 'i1');
      });

      test('Uninstallation round-trips', () {
        final original = Uninstallation(
          id: 'i2',
          dateTimeUTC: utc,
          dateTimeLocal: local,
        );
        final json = original.toJson();
        expect(json['type'], 'none');
        expect(json['parent'], isNull);

        final restored = Installation.fromJson(json);
        expect(restored, isA<Uninstallation>());
      });

      test('ComponentInstallation round-trips and preserves subtype when copied', () {
        final original = ComponentInstallation(
          id: 'nested-i',
          parentComponentId: 'wheel',
          dateTimeUTC: utc,
          dateTimeLocal: local,
        );
        final json = original.toJson();
        expect(json['type'], 'component');
        expect(json['parent'], 'wheel');

        final restored = Installation.fromJson(json);
        expect(restored, isA<ComponentInstallation>());
        expect((restored as ComponentInstallation).parentComponentId, 'wheel');
        expect(restored.copyWith(id: 'new-id'), isA<ComponentInstallation>());
      });

      test('componentId is not serialised; a legacy key is ignored', () {
        final json = BikeInstallation(id: 'i1', bikeId: 'b1', dateTimeUTC: utc, dateTimeLocal: local).toJson();
        expect(json.containsKey('componentId'), isFalse);

        final restored = Installation.fromJson({...json, 'componentId': 'stale'});
        expect(restored, BikeInstallation(id: 'i1', bikeId: 'b1', dateTimeUTC: utc, dateTimeLocal: local));
      });

      test('Archival round-trips', () {
        final original = Archival(
          id: 'i3',
          dateTimeUTC: utc,
          dateTimeLocal: local,
        );
        final json = original.toJson();
        expect(json['type'], 'archived');
        expect(json['parent'], isNull);

        final restored = Installation.fromJson(json);
        expect(restored, isA<Archival>());
        expect(restored.id, 'i3');
      });

      test('legacy JSON without type field: non-null parent → BikeInstallation', () {
        final json = <String, dynamic>{
          'id': 'i4',
          'componentId': 'c1',
          'parent': 'b1',
          'dateTimeUTC': utc.toIso8601String(),
          'dateTimeLocal': local.toIso8601String(),
          // no 'type' key — simulates a backup from an old app version
        };
        final result = Installation.fromJson(json);
        expect(result, isA<BikeInstallation>());
        expect((result as BikeInstallation).bikeId, 'b1');
      });

      test('legacy JSON without type field: null parent → Uninstallation', () {
        final json = <String, dynamic>{
          'id': 'i5',
          'componentId': 'c1',
          'parent': null,
          'dateTimeUTC': utc.toIso8601String(),
          'dateTimeLocal': local.toIso8601String(),
        };
        final result = Installation.fromJson(json);
        expect(result, isA<Uninstallation>());
      });
    });

    test('attachments survive a database round trip on setups, bikes and components', () async {
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final attachments = [
        Attachment(id: 'm', extension: '.pdf', name: 'Service Manual'),
        Attachment(id: 'p', extension: '.jpg', name: 'IMG_1.jpg'),
      ];

      final bike = Bike(id: 'b1', name: 'Bike', person: null, attachments: attachments);
      final component = Component(
        id: 'c1',
        name: 'Fork',
        componentType: ComponentType.fork,
        installations: const [],
        attachments: attachments.reversed.toList(),
      );
      final now = DateTime.now();
      final setup = Setup(
        id: 's1',
        datetime: now,
        datetimeLocal: now,
        tags: const {},
        bike: 'b1',
        person: null,
        bikeAdjustmentValues: const {},
        personAdjustmentValues: const {},
        attachments: attachments,
      );
      await database.into(database.bikes).insert(bike.toCompanion());
      await database.into(database.components).insert(component.toCompanion());
      await database.into(database.setups).insert(setup.toCompanion());

      final bikeRow = await database.select(database.bikes).getSingle();
      final componentRow = await database.select(database.components).getSingle();
      final setupRow = await database.select(database.setups).getSingle();
      expect(bikeRow.toModel().attachments, attachments);
      expect(componentRow.toModel().attachments, attachments.reversed.toList());
      expect(setupRow.toModel().attachments, attachments);
    });

    test('attachments survive a database round trip on task rules and task entries', () async {
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final attachments = [
        Attachment(id: 'm', extension: '.pdf', name: 'Service Manual'),
        Attachment(id: 'p', extension: '.jpg', name: 'IMG_1.jpg'),
      ];

      final rule = TaskRule(id: 'tr1', name: 'Service fork', tags: const {}, attachments: attachments);
      final now = DateTime.now();
      final entry = TaskEntry(
        id: 'te1',
        name: 'Fork serviced',
        dateTimeUTC: now,
        dateTimeLocal: now,
        taskRule: 'tr1',
        attachments: attachments.reversed.toList(),
      );
      await database.into(database.taskRules).insert(rule.toCompanion());
      await database.into(database.taskEntries).insert(entry.toCompanion());

      final ruleRow = await database.select(database.taskRules).getSingle();
      final entryRow = await database.select(database.taskEntries).getSingle();
      expect(ruleRow.toModel().attachments, attachments);
      expect(entryRow.toModel().attachments, attachments.reversed.toList());
    });

    test('StravaAthlete Mapping', () {
      final athlete = StravaAthlete(
        id: 123,
        firstname: 'Jonas',
        lastname: 'Keller',
        profile: 'https://example.com/profile.jpg',
        gears: const {'gear1', 'gear2'},
        lastModified: DateTime(2023, 1, 1).toUtc(),
      );

      // Model -> Companion
      final companion = athlete.toCompanion();
      expect(companion.id.value, 123);
      expect(companion.firstname.value, 'Jonas');
      expect(companion.gears.value, {'gear1', 'gear2'});

      // DB Row -> Model
      final data = StravaAthleteDb(
        id: 123,
        firstname: 'Jonas',
        lastname: 'Keller',
        profile: 'https://example.com/profile.jpg',
        gears: {'gear1', 'gear2'},
        lastModified: DateTime(2023, 1, 1).toUtc(),
      );
      final model = data.toModel();
      expect(model.id, 123);
      expect(model.firstname, 'Jonas');
      expect(model.gears, {'gear1', 'gear2'});
    });
  });

  group('Feedback mapping', () {
    late AppDatabase database;

    setUp(() => database = AppDatabase.memory());
    tearDown(() => database.close());

    test('a setup keeps its test session through a database round trip', () async {
      final setup = Setup(
        id: 's1',
        lastModified: DateTime.utc(2026, 10, 1),
        datetime: DateTime.utc(2026, 10, 1, 9),
        datetimeLocal: DateTime(2026, 10, 1, 11),
        tags: const {},
        bike: 'b1',
        person: null,
        bikeAdjustmentValues: const {},
        personAdjustmentValues: const {},
        testSessionId: 'session1',
      );
      await database.into(database.setups).insert(setup.toCompanion());

      final row = await database.select(database.setups).getSingle();
      expect(row.testSessionId, 'session1');
      expect(row.toModel(), setup);
    });

    test('a feedback with observations and comparisons survives a database round trip', () async {
      final feedback = RideFeedback(
        id: 'f1',
        lastModified: DateTime.utc(2026, 10, 1),
        bike: 'b1',
        setupId: 's2',
        stravaActivityId: 12345678901,
        dateTimeUTC: DateTime.utc(2026, 10, 1, 10),
        dateTimeLocal: DateTime(2026, 10, 1, 12),
        notes: 'Wet roots',
        position: const ContextPosition(latitude: 47.1, longitude: 8.2),
        observations: {
          const FeedbackObservation.flag(IssueKey(FeedbackEnd.front, FeedbackAttribute.comfort)),
          const FeedbackObservation.flag(IssueKey(FeedbackEnd.rear, FeedbackAttribute.calm)),
          const FeedbackObservation(key: UnknownFeedbackKey('future:m1'), value: 102.5, textValue: '102500000'),
          const FeedbackObservation(key: UnknownFeedbackKey('future.key'), value: 3),
        },
        comparisons: {
          const FeedbackComparison(referenceSetupId: 's1', aspect: OverallAspect(), outcome: 2),
          const FeedbackComparison(
            referenceSetupId: 's1',
            aspect: EndAspect(FeedbackEnd.front, FeedbackAttribute.comfort),
            outcome: -1,
          ),
          const FeedbackComparison(referenceSetupId: 's0', aspect: OverallAspect(), outcome: 0),
        },
      );
      await database.feedbackDao.insertFeedbackWithChildren(
        feedback: feedback.toCompanion(),
        observations: feedback.observationCompanions(),
        comparisons: feedback.comparisonCompanions(),
      );

      final rows = await database.feedbackDao.watchAllFeedbacksWithChildren().first;
      expect(rows, hasLength(1));
      expect(rows.single.observations, hasLength(4));
      expect(rows.single.comparisons, hasLength(3));
      final restored = rows.single.toModel();
      expect(restored, feedback);
      expect(restored.dateTimeLocal.isUtc, isFalse);
    });

    group('test session', () {
      TestSession build({TestSessionMethod? method}) => TestSession(
        id: 'session1',
        lastModified: DateTime.utc(2026, 10, 1),
        bike: 'b1',
        name: 'Fork rebound',
        method: method,
        adjustmentIds: const ['pressure', 'lsr'],
        goal: const [
          EndAspect(FeedbackEnd.front, FeedbackAttribute.calm),
          UnknownAspect('future.aspect'),
        ],
        locks: const {'lsr': StepValue(8)},
        startedAtUTC: DateTime.utc(2026, 10, 1, 9),
        startedAtLocal: DateTime(2026, 10, 1, 11),
        endedAtUTC: DateTime.utc(2026, 10, 1, 12),
        endedAtLocal: DateTime(2026, 10, 1, 14),
        notes: 'Dry',
        proposals: const {
          'run2': {'lsr': StepValue(10)},
          'run3': {'lsr': StepValue(8), 'pressure': NumericalValue(72.5)},
        },
      );
      const adjustmentTypes = {'lsr': AdjustmentType.step, 'pressure': AdjustmentType.numerical};

      Future<TestSession> roundTrip(TestSession session, {Map<String, AdjustmentType> types = adjustmentTypes}) async {
        await database.feedbackDao.upsertTestSession(session.toCompanion());
        final row = (await database.feedbackDao.watchAllTestSessions().first).single;
        return row.toModel(adjustmentTypes: types);
      }

      for (final method in <TestSessionMethod?>[
        null,
        const PatternSearch(),
        const OrthogonalArray(),
        const Tournament(candidateSetupIds: ['s1', 's2']),
      ]) {
        test('survives a database round trip with method ${method?.type ?? 'free'}', () async {
          final session = build(method: method);
          final restored = await roundTrip(session);
          expect(restored, session);
          expect(restored.adjustmentIds, ['pressure', 'lsr']);
          expect(restored.startedAtLocal.isUtc, isFalse);
        });
      }

      test('a running session keeps its end unset', () async {
        final session = build().copyWith(endedAtUTC: null, endedAtLocal: null);
        final restored = await roundTrip(session);
        expect(restored.isRunning, isTrue);
        expect(restored, session);
      });

      test('values of unknown adjustments stay unresolved and resolve once typed', () async {
        final session = build();
        final untyped = await roundTrip(session, types: const {});
        expect(untyped.locks['lsr'], isA<UnresolvedValue>());
        expect(untyped.proposals['run3']!['pressure'], isA<UnresolvedValue>());

        await database.feedbackDao.upsertTestSession(untyped.toCompanion());
        expect(await roundTrip(untyped), session);
      });
    });
  });
}
