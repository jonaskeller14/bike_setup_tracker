import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_comparison.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_observation.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cloud sync moves one document per root with its children embedded, and the
/// root's `lastModified` decides which version wins. A child-only edit that left
/// it untouched would never be synced and would lose against an older copy.
///
/// The column keeps whole seconds, so each test sets the stored value back to
/// the epoch instead of waiting for the clock to tick over.
Future<void> pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

void main() {
  late AppDatabase database;
  late AppRepository repository;
  final bike = Bike(name: 'Bike', person: null);
  final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  Future<void> ageRow(String table) => database.customStatement('UPDATE $table SET last_modified = 0');

  NumericalAdjustment pressure() => NumericalAdjustment(
        name: 'Pressure',
        notes: '',
        unit: AdjustmentUnit.fromLegacy('psi'),
      );

  Setup setupWith(Map<String, AdjustmentValue> values) => Setup(
        tags: const {},
        datetime: DateTime.utc(2026, 5, 1),
        datetimeLocal: DateTime(2026, 5, 1),
        bike: bike.id,
        person: null,
        bikeAdjustmentValues: values,
        personAdjustmentValues: const {},
      );

  setUp(() async {
    database = AppDatabase.memory();
    repository = AppRepository(database);
    await pumpEventQueue();
    await repository.addBikes([bike]);
    await pumpEventQueue();
  });

  tearDown(() async {
    await database.close();
  });

  test('editing only the adjustments of a component bumps the component', () async {
    final component = Component(
      name: 'Fork',
      componentType: ComponentType.fork,
      adjustments: [pressure()],
      installations: [Installation.sinceBeginning(parent: bike.id)],
    );
    await repository.addComponents([component]);
    await pumpEventQueue();
    await ageRow('components');

    await repository.editComponents([component.copyWith(adjustments: [...component.adjustments, pressure()])]);
    await pumpEventQueue();

    expect(repository.components[component.id]!.adjustments, hasLength(2));
    expect(repository.components[component.id]!.lastModified.isAfter(epoch), isTrue);
  });

  test('editing only the installations of a component bumps the component', () async {
    final component = Component(
      name: 'Fork',
      componentType: ComponentType.fork,
      installations: [Installation.sinceBeginning(parent: bike.id)],
    );
    await repository.addComponents([component]);
    await pumpEventQueue();
    await ageRow('components');
    final at = DateTime.utc(2026, 6, 1);

    await repository.editComponents([
      component.copyWith(installations: [
        ...component.installations,
        Installation(parent: null, dateTimeUTC: at, dateTimeLocal: at),
      ]),
    ]);
    await pumpEventQueue();

    final stored = (await database.componentsDao.getAllComponentsWithDataBypass()).single;
    expect(stored.installations, hasLength(2));
    expect(stored.component.lastModified.isAfter(epoch), isTrue);
  });

  test('editing only the adjustments of a person bumps the person', () async {
    final person = Person(name: 'Alex', adjustments: [pressure()]);
    await repository.addPersons([person]);
    await pumpEventQueue();
    await ageRow('persons');

    await repository.editPerson(person.copyWith(adjustments: [...person.adjustments, pressure()]));
    await pumpEventQueue();

    expect(repository.persons[person.id]!.adjustments, hasLength(2));
    expect(repository.persons[person.id]!.lastModified.isAfter(epoch), isTrue);
  });

  test('editing only the adjustment values of a setup bumps the setup', () async {
    final adjustment = pressure();
    final component = Component(
      name: 'Fork',
      componentType: ComponentType.fork,
      adjustments: [adjustment],
      installations: [Installation.sinceBeginning(parent: bike.id)],
    );
    final setup = setupWith({adjustment.id: const NumericalValue(100)});
    await repository.addComponents([component]);
    await repository.addSetups([setup]);
    await pumpEventQueue();
    await ageRow('setups');

    await repository.editSetups([setup.copyWith(bikeAdjustmentValues: {adjustment.id: const NumericalValue(95)})]);
    await pumpEventQueue();

    expect(repository.setups[setup.id]!.bikeAdjustmentValues[adjustment.id], const NumericalValue(95));
    expect(repository.setups[setup.id]!.lastModified.isAfter(epoch), isTrue);
  });

  test('editing only the observations and comparisons of a feedback bumps the feedback', () async {
    final setup = setupWith(const {});
    await repository.addSetups([setup]);
    final feedback = RideFeedback(
      bike: bike.id,
      setupId: setup.id,
      dateTimeUTC: DateTime.utc(2026, 5, 2),
      dateTimeLocal: DateTime(2026, 5, 2),
      comparisons: {FeedbackComparison(referenceSetupId: setup.id, aspect: const OverallAspect(), outcome: 1)},
    );
    await repository.addFeedbacks([feedback]);
    await pumpEventQueue();
    await ageRow('feedbacks');

    await repository.editFeedback(feedback.copyWith(
      observations: {const FeedbackObservation.flag(NoIssueKey())},
      comparisons: {FeedbackComparison(referenceSetupId: setup.id, aspect: const OverallAspect(), outcome: -1)},
    ));
    await pumpEventQueue();

    final stored = repository.feedbacks[feedback.id]!;
    expect(stored.observations, hasLength(1));
    expect(stored.comparisons.single.outcome, -1);
    expect(stored.lastModified.isAfter(epoch), isTrue);
  });
}
