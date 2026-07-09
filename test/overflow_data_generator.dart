import 'dart:convert';
import 'dart:io';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/rating.dart';
import 'package:bike_setup_tracker/models/rating_association.dart';
import 'package:bike_setup_tracker/models/rating_entry.dart';
import 'package:bike_setup_tracker/models/rating_metric.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/data_export_service.dart';

const String loremIpsum = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.";

void main() async {
  final data = AppRepository(AppDatabase.memory());
  final bikes = <Bike>[];
  final persons = <Person>[];
  final components = <Component>[];
  final ratings = <Rating>[];

  // Create 100 bikes (only first has long text)
  for (final idx in List.generate(100, (idx) => idx)) {
    final b = Bike(
      name: idx == 0 ? "Bike #0: $loremIpsum" : "Bike #$idx",
      person: null,
    );
    await data.addBike(b);
    bikes.add(b);
  }
  await Future.delayed(Duration.zero);

  // Create 100 persons (only first has long text and notes)
  for (final idx in List.generate(100, (idx) => idx)) {
    final p = Person(
      name: idx == 0 ? "Person #0: $loremIpsum" : "Person #$idx",
      adjustments: idx == 0
          ? [
              NumericalAdjustment(
                name: "Height: $loremIpsum",
                notes: loremIpsum,
                unit: AdjustmentUnit.fromLegacy("cm"),
              ),
              NumericalAdjustment(
                name: "Weight",
                notes: loremIpsum,
                unit: AdjustmentUnit.fromLegacy("kg"),
              ),
            ]
          : [],
      notes: idx == 0 ? loremIpsum : null,
    );
    await data.addPerson(p);
    persons.add(p);
  }
  await Future.delayed(Duration.zero);

  // Create 100 components, distributed across bikes with various statuses
  for (final idx in List.generate(100, (idx) => idx)) {
    final bikeIdx = idx % bikes.length;
    final isUninstalled = idx % 3 == 0;
    final isArchived = idx % 5 == 0;

    final installations = <Installation>[
      BikeInstallation(
        bikeId: bikes[bikeIdx].id,
        dateTimeUTC: DateTime(2020).add(Duration(days: idx)).toUtc(),
        dateTimeLocal: DateTime(2020).add(Duration(days: idx)),
      ),
    ];

    // Add uninstallation if needed
    if (isUninstalled) {
      installations.add(
        Uninstallation(
          dateTimeUTC: DateTime(2025).toUtc(),
          dateTimeLocal: DateTime(2025),
        ),
      );
    }

    // Add archival if needed
    if (isArchived) {
      installations.add(
        Archival(
          dateTimeUTC: DateTime(2024).toUtc(),
          dateTimeLocal: DateTime(2024),
        ),
      );
    }

    final component = Component(
      name: idx == 0 ? "Component #0: $loremIpsum" : "Component #$idx",
      installations: installations,
      componentType: ComponentType.values[idx % ComponentType.values.length],
      adjustments: idx == 0
          ? [
              BooleanAdjustment(
                name: "BooleanAdjustment: $loremIpsum",
                notes: loremIpsum,
                unit: null,
              ),
              CategoricalAdjustment(
                name: "CategoricalAdjustment: $loremIpsum",
                notes: loremIpsum,
                unit: null,
                options: {loremIpsum, "Option 2", "Option 3"},
              ),
              StepAdjustment(
                name: "StepAdjustment: $loremIpsum",
                notes: loremIpsum,
                unit: null,
                step: 1,
                min: 0,
                max: 10,
                visualization: StepAdjustmentVisualization.slider,
              ),
              NumericalAdjustment(
                name: "NumericalAdjustment: $loremIpsum",
                notes: loremIpsum,
                unit: AdjustmentUnit.fromLegacy("mm"),
              ),
              DurationAdjustment(
                name: "DurationAdjustment: $loremIpsum",
                notes: loremIpsum,
                unit: null,
              ),
              TextAdjustment(
                name: "TextAdjustment: $loremIpsum",
                notes: loremIpsum,
                unit: null,
              )
            ]
          : [],
    );
    await data.addComponent(component);
    components.add(component);
  }

  // Create 100 setups (only first has long text)
  for (final idx in List.generate(100, (idx) => idx)) {
    await data.addSetup(Setup(
      name: idx == 0 ? "Setup #0: $loremIpsum" : "Setup #$idx",
      notes: idx == 0 ? loremIpsum : null,
      tags: {},
      bike: bikes[idx % bikes.length].id,
      datetime: DateTime(2000).add(Duration(minutes: idx)).toUtc(),
      datetimeLocal: DateTime(2000).add(Duration(minutes: idx)),
      person: idx == 0 ? persons[0].id : null,
      bikeAdjustmentValues: {},
      personAdjustmentValues: {},
    ));
  }

  // Create 100 ratings with metrics (only first has long text)
  for (final idx in List.generate(100, (idx) => idx)) {
    final rating = Rating(
      name: idx == 0 ? "Rating #0: $loremIpsum" : "Rating #$idx",
      filterType: FilterType.global,
      filter: null,
      metrics: idx == 0
          ? [
              RatingMetric(
                adjustment: StepAdjustment(
                  name: "Speed: $loremIpsum",
                  notes: "Rate how fast this setup is",
                  unit: null,
                  step: 1,
                  min: 0,
                  max: 100,
                  visualization: StepAdjustmentVisualization.slider,
                ),
              ),
              RatingMetric(
                adjustment: StepAdjustment(
                  name: "Comfort Performance Evaluation Analysis",
                  notes: loremIpsum,
                  unit: null,
                  step: 1,
                  min: 0,
                  max: 10,
                  visualization: StepAdjustmentVisualization.slider,
                ),
              ),
            ]
          : [],
    );
    await data.addRating(rating);
    ratings.add(rating);
  }
  await Future.delayed(Duration.zero);

  // Add task rules (one per component, only first has long text)
  for (final idx in List.generate(components.length, (idx) => idx)) {
    await data.addTaskRule(TaskRule(
      name: idx == 0
          ? "Check drivetrain: $loremIpsum"
          : "Check drivetrain #$idx",
      notes: idx == 0 ? loremIpsum : null,
      tags: {},
      componentId: components[idx].id,
      interval: const DurationThreshold(Duration(days: 30)),
    ));
  }
  await Future.delayed(Duration.zero);

  // Add task entries (one per task rule, only first has long text)
  if (data.taskRules.isNotEmpty) {
    int entryIdx = 0;
    for (final rule in data.taskRules.values) {
      await data.addTaskEntry(TaskEntry(
        name: "Completed check #$entryIdx",
        notes: entryIdx == 0 ? loremIpsum : null,
        dateTimeUTC: DateTime(2025).add(Duration(days: entryIdx)).toUtc(),
        dateTimeLocal: DateTime(2025).add(Duration(days: entryIdx)),
        taskRule: rule.id,
        snapshot: null,
      ));
      entryIdx++;
    }
  }

  // Add rating entries to first rating
  if (ratings.isNotEmpty && data.setups.isNotEmpty) {
    final setupsList = data.setups.values.toList();
    for (final idx in List.generate(50, (idx) => idx)) {
      final setup = setupsList[idx % setupsList.length];
      await data.addRatingEntry(RatingEntry(
        bike: setup.bike,
        setupId: setup.id,
        dateTimeUTC: DateTime(2025).add(Duration(days: idx)).toUtc(),
        dateTimeLocal: DateTime(2025).add(Duration(days: idx)),
        metricValues: {
          if (ratings.first.metrics.isNotEmpty)
            ratings.first.metrics.first.id: idx * 2,
        },
      ));
    }
  }

  final exportData =
      await DataExportService.backupDatabaseToJson(data.database);
  final encoder = const JsonEncoder.withIndent('  ');
  final jsonString = encoder.convert(exportData);

  final file = File('test/overflow_test.json');

  await file.create(recursive: true);
  await file.writeAsString(jsonString);

  data.dispose();
  await data.database.close();
}
