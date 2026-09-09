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
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/data_export_service.dart';

const String loremIpsum = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.";

void main() async {
  final data = AppRepository(AppDatabase.memory());

  // Create 100 bikes (only first has long text)
  final bikes = [
    for (final idx in List.generate(100, (idx) => idx))
      Bike(
        name: idx == 0 ? "Bike #0: $loremIpsum" : "Bike #$idx",
        person: null,
      ),
  ];
  await data.addBikes(bikes);
  await Future<void>.delayed(Duration.zero);

  // Create 100 persons (only first has long text and notes)
  final persons = [
    for (final idx in List.generate(100, (idx) => idx))
      Person(
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
      ),
  ];
  await data.addPersons(persons);
  await Future<void>.delayed(Duration.zero);

  // Create 100 components, distributed across bikes with various statuses
  final components = [
    for (final idx in List.generate(100, (idx) => idx))
      Component(
        name: idx == 0 ? "Component #0: $loremIpsum" : "Component #$idx",
        installations: [
          BikeInstallation(
            bikeId: bikes[idx % bikes.length].id,
            dateTimeUTC: DateTime(2020).add(Duration(days: idx)).toUtc(),
            dateTimeLocal: DateTime(2020).add(Duration(days: idx)),
          ),
          if (idx % 3 == 0)
            Uninstallation(
              dateTimeUTC: DateTime(2025).toUtc(),
              dateTimeLocal: DateTime(2025),
            ),
          if (idx % 5 == 0)
            Archival(
              dateTimeUTC: DateTime(2024).toUtc(),
              dateTimeLocal: DateTime(2024),
            ),
        ],
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
      ),
  ];
  await data.addComponents(components);

  // Create 100 setups (only first has long text)
  final setups = [
    for (final idx in List.generate(100, (idx) => idx))
      Setup(
        name: idx == 0 ? "Setup #0: $loremIpsum" : "Setup #$idx",
        notes: idx == 0 ? loremIpsum : null,
        tags: {},
        bike: bikes[idx % bikes.length].id,
        datetime: DateTime(2000).add(Duration(minutes: idx)).toUtc(),
        datetimeLocal: DateTime(2000).add(Duration(minutes: idx)),
        person: idx == 0 ? data.persons.values.first.id : null,
        bikeAdjustmentValues: {},
        personAdjustmentValues: {},
      ),
  ];
  await data.addSetups(setups);

  // Create 100 ratings with metrics (only first has long text)
  final ratings = [
    for (final idx in List.generate(100, (idx) => idx))
      Rating(
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
      ),
  ];
  await data.addRatings(ratings);
  await Future<void>.delayed(Duration.zero);

  // Add task rules (one per component, only first has long text)
  final componentsList = data.components.values.toList();
  for (final idx in List.generate(componentsList.length, (idx) => idx)) {
    await data.addTaskRules([TaskRule(
      name: idx == 0
          ? "Check drivetrain: $loremIpsum"
          : "Check drivetrain #$idx",
      notes: idx == 0 ? loremIpsum : null,
      tags: {},
      componentId: componentsList[idx].id,
      interval: const DurationThreshold(Duration(days: 30)),
    )]);
  }
  await Future<void>.delayed(Duration.zero);

  // Add task entries (one per task rule, only first has long text)
  if (data.taskRules.isNotEmpty) {
    int entryIdx = 0;
    for (final rule in data.taskRules.values) {
      await data.addTaskEntries([TaskEntry(
        name: "Completed check #$entryIdx",
        notes: entryIdx == 0 ? loremIpsum : null,
        dateTimeUTC: DateTime(2025).add(Duration(days: entryIdx)).toUtc(),
        dateTimeLocal: DateTime(2025).add(Duration(days: entryIdx)),
        taskRule: rule.id,
        snapshot: null,
      )]);
      entryIdx++;
    }
  }

  // Add rating entries to first rating
  if (data.ratings.isNotEmpty && data.setups.isNotEmpty) {
    final setupsList = data.setups.values.toList();
    final firstRating = data.ratings.values.first;
    final ratingEntries = [
      for (final idx in List.generate(50, (idx) => idx))
        RatingEntry(
          bike: setupsList[idx % setupsList.length].bike,
          setupId: setupsList[idx % setupsList.length].id,
          dateTimeUTC: DateTime(2025).add(Duration(days: idx)).toUtc(),
          dateTimeLocal: DateTime(2025).add(Duration(days: idx)),
          metricValues: {
            if (firstRating.metrics.isNotEmpty)
              firstRating.metrics.first.id: idx * 2,
          },
        ),
    ];
    await data.addRatingEntries(ratingEntries);
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
