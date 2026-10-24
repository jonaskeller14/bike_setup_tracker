import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_comparison.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_observation.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.memory();
  });

  tearDown(() async {
    await database.close();
  });

  group('DAOs Test', () {
    test('BikesDao - Insert and watch', () async {
      final bikes = await database.bikesDao.watchAllBikes().first;
      expect(bikes, isEmpty);

      final bike = Bike(id: 'bike1', name: 'Mtb', person: null);
      await database.bikesDao.insertBike(bike.toCompanion());

      final updatedBikes = await database.bikesDao.watchAllBikes().first;
      expect(updatedBikes, hasLength(1));
      expect(updatedBikes.first.name, 'Mtb');
    });

    test('ComponentsDao - Insert and watch', () async {
      final components = await database.componentsDao.watchAllComponents().first;
      expect(components, isEmpty);

      final component = Component(
        id: 'comp1', 
        name: 'Fork', 
        componentType: ComponentType.fork,
        adjustments: const [],
        installations: const [],
      );
      await database.componentsDao.insertComponent(component.toCompanion());

      final updatedComponents = await database.componentsDao.watchAllComponents().first;
      expect(updatedComponents, hasLength(1));
      expect(updatedComponents.first.name, 'Fork');
    });

    test('ComponentsDao - Delete (Soft Delete)', () async {
      final component = Component(
        id: 'comp1', 
        name: 'Fork', 
        componentType: ComponentType.fork,
        installations: const [],
      );
      await database.componentsDao.insertComponent(component.toCompanion());

      await database.componentsDao.deleteComponent('comp1');

      final activeComponents = await database.componentsDao.watchAllComponents().first;
      expect(activeComponents, isEmpty);

      final deletedComponents = await database.componentsDao.watchDeletedComponents().first;
      expect(deletedComponents, hasLength(1));
      expect(deletedComponents.first.isDeleted, true);
    });

    test('BikesDao - Get bike by ID', () async {
      final bike = Bike(id: 'bike1', name: 'Mtb', person: null);
      await database.bikesDao.insertBike(bike.toCompanion());

      final fetched = await database.bikesDao.getBike('bike1');
      expect(fetched, isNotNull);
      expect(fetched?.name, 'Mtb');

      final nonExistent = await database.bikesDao.getBike('none');
      expect(nonExistent, isNull);
    });
  });

  group('Unresolved adjustment values', () {
    final keep = BooleanAdjustment(name: 'Lockout', notes: null, unit: null);
    final removed = DurationAdjustment(name: 'Warm-up', notes: null, unit: null);
    const removedValue = DurationValue(Duration(minutes: 90));

    Component component(List<Adjustment> adjustments) => Component(
          id: 'comp1',
          name: 'Fork',
          componentType: ComponentType.fork,
          adjustments: adjustments,
          installations: const [],
        );

    Future<void> saveComponent(List<Adjustment> adjustments) {
      return database.componentsDao.updateComponentWithData(
        component: component(adjustments).toCompanion(),
        adjustmentsList: [
          for (final (i, adjustment) in adjustments.indexed)
            adjustment.toCompanion(componentId: 'comp1', orderIndex: i),
        ],
        installationsList: [],
      );
    }

    Future<Setup> readSetup() async {
      final setups = await database.setupsDao.watchAllSetupsWithValues().first;
      final entry = setups.single;
      return entry.setup.toModel(values: entry.values);
    }

    setUp(() async {
      await database.componentsDao.insertComponent(component(const []).toCompanion());
      await saveComponent([keep, removed]);
      await database.setupsDao.insertSetupWithValues(
        setup: Setup(
          id: 's1',
          datetime: DateTime.utc(2026, 9, 27),
          datetimeLocal: DateTime(2026, 9, 27),
          tags: const {},
          bike: 'bike1',
          person: null,
          bikeAdjustmentValues: const {},
          personAdjustmentValues: const {},
        ).toCompanion(),
        bikeValues: {keep.id: const BooleanValue(true), removed.id: removedValue},
        personValues: const {},
      );
      // Removing an adjustment hard-deletes its row but keeps the value rows.
      await saveComponent([keep]);
    });

    test('a value of a removed adjustment is read as unresolved', () async {
      final setup = await readSetup();
      expect(setup.bikeAdjustmentValues, {
        keep.id: const BooleanValue(true),
        removed.id: UnresolvedValue(removedValue.encode()),
      });
    });

    test('saving the setup writes the unresolved value back unchanged', () async {
      final setup = await readSetup();
      await database.setupsDao.updateSetupWithValues(
        setup: setup.toCompanion(),
        bikeValues: setup.bikeAdjustmentValues,
        personValues: setup.personAdjustmentValues,
      );

      expect((await readSetup()).bikeAdjustmentValues, setup.bikeAdjustmentValues);
      // Re-adding the adjustment resolves the untouched value again.
      await saveComponent([keep, removed]);
      expect((await readSetup()).bikeAdjustmentValues[removed.id], removedValue);
    });

    test('removing the unresolved value deletes its row', () async {
      final setup = await readSetup();
      await database.setupsDao.updateSetupWithValues(
        setup: setup.toCompanion(),
        bikeValues: {keep.id: const BooleanValue(true)},
        personValues: setup.personAdjustmentValues,
      );

      expect(await database.setupsDao.watchValuesForSetup('s1').first, hasLength(1));
      expect((await readSetup()).bikeAdjustmentValues, {keep.id: const BooleanValue(true)});
    });
  });

  group('FeedbackDao', () {
    const frontHarsh = IssueKey(FeedbackEnd.front, FeedbackAttribute.comfort);
    const better = FeedbackComparison(referenceSetupId: 's1', aspect: OverallAspect(), outcome: 1);

    RideFeedback feedback({
      String id = 'f1',
      Set<FeedbackObservation>? observations,
      Set<FeedbackComparison>? comparisons,
    }) => RideFeedback(
      id: id,
      bike: 'bike1',
      setupId: 's2',
      dateTimeUTC: DateTime.utc(2026, 10, 1, 10),
      dateTimeLocal: DateTime(2026, 10, 1, 12),
      observations: observations ?? {const FeedbackObservation.flag(frontHarsh)},
      comparisons: comparisons ?? {better},
    );

    Future<void> insert(RideFeedback f) => database.feedbackDao.insertFeedbackWithChildren(
      feedback: f.toCompanion(),
      observations: f.observationCompanions(),
      comparisons: f.comparisonCompanions(),
    );

    Future<List<RideFeedback>> active() async =>
        (await database.feedbackDao.watchAllFeedbacksWithChildren().first).map((f) => f.toModel()).toList();

    test('a feedback without answers is still listed', () async {
      await insert(feedback(observations: {}, comparisons: {}));

      final feedbacks = await active();
      expect(feedbacks.single.observations, isEmpty);
      expect(feedbacks.single.comparisons, isEmpty);
    });

    test('children are grouped per feedback', () async {
      await insert(feedback());
      await insert(feedback(id: 'f2', observations: {const FeedbackObservation.flag(NoIssueKey())}, comparisons: {}));

      final byId = {for (final f in await active()) f.id: f};
      expect(byId['f1']!.issues, {frontHarsh});
      expect(byId['f1']!.comparisons, {better});
      expect(byId['f2']!.nothingStoodOut, isTrue);
      expect(byId['f2']!.comparisons, isEmpty);
    });

    test('upsert replaces the children as a whole', () async {
      await insert(feedback());

      final edited = feedback(
        observations: {const FeedbackObservation.flag(NoIssueKey())},
        comparisons: {const FeedbackComparison(referenceSetupId: 's0', aspect: OverallAspect(), outcome: -2)},
      );
      await database.feedbackDao.upsertFeedbackWithChildren(
        feedback: edited.toCompanion(),
        observations: edited.observationCompanions(),
        comparisons: edited.comparisonCompanions(),
      );

      final stored = (await active()).single;
      expect(stored.observations, edited.observations);
      expect(stored.comparisons, edited.comparisons);
    });

    test('soft delete moves a feedback to the deleted list and restore brings it back', () async {
      await insert(feedback());

      await database.feedbackDao.deleteFeedback('f1');
      expect(await active(), isEmpty);
      final deleted = await database.feedbackDao.watchDeletedFeedbacksWithChildren().first;
      expect(deleted.single.feedback.isDeleted, isTrue);
      expect(deleted.single.observations, hasLength(1));

      await database.feedbackDao.restoreFeedback('f1');
      expect((await active()).single.issues, {frontHarsh});
      expect(await database.feedbackDao.getAllFeedbacksWithChildrenBypass(), hasLength(1));
    });

    test('test sessions are soft deleted and restored', () async {
      final session = TestSession(
        id: 'session1',
        bike: 'bike1',
        adjustmentIds: const ['lsr'],
        startedAtUTC: DateTime.utc(2026, 10, 1, 9),
        startedAtLocal: DateTime(2026, 10, 1, 11),
      );
      await database.feedbackDao.upsertTestSession(session.toCompanion());

      await database.feedbackDao.deleteTestSession('session1');
      expect(await database.feedbackDao.watchAllTestSessions().first, isEmpty);
      expect((await database.feedbackDao.watchDeletedTestSessions().first).map((s) => s.id), ['session1']);

      await database.feedbackDao.restoreTestSession('session1');
      expect((await database.feedbackDao.watchAllTestSessions().first).map((s) => s.id), ['session1']);
      expect(await database.feedbackDao.getAllTestSessionsBypass(), hasLength(1));
    });

    test('purgeTrash removes expired feedback with its answers and sessions', () async {
      final expired = DateTime.now().toUtc().subtract(const Duration(days: 60));
      final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 30));
      await insert(feedback().copyWith(isDeleted: true, lastModified: expired));
      await insert(feedback(id: 'f2'));
      await database.feedbackDao.upsertTestSession(
        TestSession(
          id: 'old',
          isDeleted: true,
          lastModified: expired,
          bike: 'bike1',
          adjustmentIds: const [],
          startedAtUTC: expired,
          startedAtLocal: expired,
        ).toCompanion(),
      );

      await database.purgeTrash(cutoff);

      expect((await database.select(database.feedbacks).get()).map((f) => f.id), ['f2']);
      expect((await database.select(database.feedbackObservations).get()).map((o) => o.feedbackId), ['f2']);
      expect((await database.select(database.feedbackComparisons).get()).map((c) => c.feedbackId), ['f2']);
      expect(await database.select(database.testSessions).get(), isEmpty);
    });
  });
}
