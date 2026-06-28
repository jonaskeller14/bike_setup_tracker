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
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/data_export_service.dart';

const String loremIpsum = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.";

void main() async {
  final data = AppRepository(AppDatabase.memory());
  final bikes = <Bike>[];
  for (final idx in List.generate(100, (idx) => idx)) {
    final b = Bike(name: "Bike #$idx: $loremIpsum", person: null);
    await data.addBike(b);
    bikes.add(b);
  }
  await Future.delayed(Duration.zero);

  for (final idx in List.generate(100, (idx) => idx)) {
    await data.addComponent(Component(
      name: "Component #$idx: $loremIpsum", 
      installations: [Installation.sinceBeginning(parent: bikes.first.id)], 
      componentType: ComponentType.frame, 
      adjustments: [
        BooleanAdjustment(
          name: "BooleanAdjustment #1: $loremIpsum", 
          notes: loremIpsum, 
          unit: null,
        ),
        CategoricalAdjustment(
          name: "CategoricalAdjustment #1: $loremIpsum", 
          notes: loremIpsum, 
          unit: null,
          options: {loremIpsum},
        ),
        StepAdjustment(
          name: "StepAdjustment #1: $loremIpsum",  
          notes: loremIpsum, 
          unit: null, 
          step: 1, 
          min: 0, 
          max: 10, 
          visualization: StepAdjustmentVisualization.slider,
        ),
        NumericalAdjustment(
          name: "NumericalAdjustment #1: $loremIpsum",
          notes: loremIpsum, 
          unit: null,
        ),
        DurationAdjustment(
          name: "DurationAdjustment #1: $loremIpsum",
          notes: loremIpsum, 
          unit: null,
        ),
        TextAdjustment(
          name: "TextAdjustment #1: $loremIpsum",
          notes: loremIpsum, 
          unit: null,
        )
      ]
    ));
  }

  for (final idx in List.generate(100, (idx) => idx)) {
    await data.addSetup(Setup(
      name: "Setup #$idx: $loremIpsum", 
      notes: loremIpsum,
      tags: {},
      bike: bikes.first.id, 
      datetime: DateTime(2000).add(Duration(minutes: idx)).toUtc(),
      datetimeLocal: DateTime(2000).add(Duration(minutes: idx)),
      person: null,
      bikeAdjustmentValues: {}, 
      personAdjustmentValues: {}, 
    ));
  }

  for (final idx in List.generate(100, (idx) => idx)) {
    await data.addPerson(Person(
      name: "Person #$idx: $loremIpsum", 
      adjustments: [],
    ));
  }

  for (final idx in List.generate(100, (idx) => idx)) {
    await data.addRating(Rating(
      name: "Rating #$idx: $loremIpsum",
      filterType: FilterType.global,
      filter: null,
      metrics: [],
    ));
  }
  
  final exportData = await DataExportService.backupDatabaseToJson(data.database);
  final encoder = const JsonEncoder.withIndent('  ');
  final jsonString = encoder.convert(exportData);

  final file = File('test/overflow_test.json');
  
  await file.create(recursive: true);
  await file.writeAsString(jsonString);

  data.dispose();
  await data.database.close();
}
