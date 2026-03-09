import 'dart:convert';
import 'dart:io';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_data.dart';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/rating.dart';
import 'package:bike_setup_tracker/models/setup.dart';

const String loremIpsum = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.";

void main() async {
  final data = AppData(AppDatabase.memory());
  for (final idx in List.generate(100, (idx) => idx)) {
    await data.addBike(Bike(name: "Bike #$idx: $loremIpsum", person: null));
  }
  await Future.delayed(Duration.zero);

  for (final idx in List.generate(100, (idx) => idx)) {
    await data.addComponent(Component(
      name: "Component #$idx: $loremIpsum", 
      installations: [Installation.sinceBeginning(parent: data.bikes.values.first.id)], 
      componentType: ComponentType.frame, 
      adjustments: [
        BooleanAdjustment(
          name: "BooleanAdjustment #1: $loremIpsum", 
          notes: loremIpsum, 
          unit: null,
          category: AdjustmentCategory.component,
        ),
        CategoricalAdjustment(
          name: "CategoricalAdjustment #1: $loremIpsum", 
          notes: loremIpsum, 
          unit: null,
          options: {loremIpsum},
          category: AdjustmentCategory.component,
        ),
        StepAdjustment(
          name: "StepAdjustment #1: $loremIpsum",  
          notes: loremIpsum, 
          unit: null, 
          step: 1, 
          min: 0, 
          max: 10, 
          visualization: StepAdjustmentVisualization.slider,
          category: AdjustmentCategory.component,
        ),
        NumericalAdjustment(
          name: "NumericalAdjustment #1: $loremIpsum",
          notes: loremIpsum, 
          unit: null,
          category: AdjustmentCategory.component,
        ),
        DurationAdjustment(
          name: "DurationAdjustment #1: $loremIpsum",
          notes: loremIpsum, 
          unit: null,
          category: AdjustmentCategory.component,
        ),
        TextAdjustment(
          name: "TextAdjustment #1: $loremIpsum",
          notes: loremIpsum, 
          unit: null,
          category: AdjustmentCategory.component,
        )
      ]
    ));
  }

  for (final idx in List.generate(100, (idx) => idx)) {
    await data.addSetup(Setup(
      name: "Setup #$idx: $loremIpsum", 
      notes: loremIpsum,
      tags: {},
      bike: data.bikes.values.first.id, 
      datetime: DateTime(2000).add(Duration(minutes: idx)).toUtc(),
      datetimeLocal: DateTime(2000).add(Duration(minutes: idx)),
      person: null,
      bikeAdjustmentValues: {}, 
      personAdjustmentValues: {}, 
      ratingAdjustmentValues: {},
      isCurrent: false,
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
      adjustments: [],
    ));
  }
  
  final encoder = JsonEncoder.withIndent('  ');
  final jsonString = encoder.convert(data.toJson());

  final file = File('test/overflow_test.json');
  
  await file.create(recursive: true);
  await file.writeAsString(jsonString);
}
