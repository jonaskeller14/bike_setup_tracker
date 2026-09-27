import 'dart:convert';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/rating/rating.dart';
import 'package:bike_setup_tracker/models/rating/rating_association.dart';
import 'package:bike_setup_tracker/models/rating/rating_entry.dart';
import 'package:bike_setup_tracker/models/rating/rating_metric.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Serialize and deserialize SelectedData with TaskRule interval', () {
    final rule = TaskRule(
      id: "uuid123",
      isDeleted: false,
      lastModified: DateTime.now().toUtc(),
      name: 'Test',
      priority: TaskPriority.medium,
      association: const ComponentTaskAssociation("c1"),
      interval: const DurationThreshold(Duration(days: 30)),
      delay: const DistanceThreshold(500),
      repeat: true,
      tags: const {},
    );

    final selectedData = SelectedData(taskRules: {rule.id: rule});

    final exportMap = <String, dynamic>{
      'persons': <dynamic>[],
      'bikes': <dynamic>[],
      'setups': <dynamic>[],
      'components': <dynamic>[],
      'ratings': <dynamic>[],
      'taskRules': selectedData.taskRules.values.map((tr) => tr.toJson()).toList(),
      'taskEntries': <dynamic>[],
    };
    
    final jsonString = jsonEncode(exportMap);

    final decodedData = jsonDecode(jsonString) as Map<String, dynamic>;
    final importedData = SelectedData.fromJson(decodedData);
    
    final importedRule = importedData.taskRules.values.first;
    expect(importedRule.interval, isNotNull);
    expect(importedRule.interval, isA<DurationThreshold>());
  });

  test('Import decodes adjustment values with their adjustment type', () {
    final bike = Bike(name: 'Bike', person: null);
    final note = TextAdjustment(name: 'Note', notes: null, unit: null);
    final side = CategoricalAdjustment(name: 'Side', notes: null, unit: null, options: {'Front', 'Rear'});
    final pressure = NumericalAdjustment(name: 'Pressure', notes: null, unit: null, min: 0, max: 300);
    final component = Component(
      name: 'Fork',
      installations: [Installation.sinceBeginning(parent: bike.id)],
      componentType: ComponentType.fork,
      adjustments: [note, side, pressure],
    );
    final riderNote = TextAdjustment(name: 'Rider note', notes: null, unit: null);
    final person = Person(name: 'Rider', adjustments: [riderNote]);
    final comment = TextAdjustment(name: 'Comment', notes: null, unit: null);
    final rating = Rating(
      name: 'Rating',
      association: const GlobalRatingAssociation(),
      metrics: [RatingMetric(adjustment: comment)],
    );
    final setup = Setup(
      id: 's1',
      datetime: DateTime.utc(2026, 9, 27),
      datetimeLocal: DateTime(2026, 9, 27),
      tags: const {},
      bike: bike.id,
      person: person.id,
      bikeAdjustmentValues: {note.id: TextValue.orNull('01:30:00')!, 'orphan': TextValue.orNull('01:30:00')!},
      personAdjustmentValues: const {},
    );
    // Legacy and loosely typed shapes found in older backups.
    final setupJson = setup.toJson();
    (setupJson['bikeAdjustmentValues'] as Map<String, dynamic>)
      ..[side.id] = 'Front'
      ..[pressure.id] = 89;
    setupJson['personAdjustmentValues'] = {riderNote.id: ''};
    final entry = RatingEntry(
      id: 'r1',
      bike: bike.id,
      setupId: setup.id,
      dateTimeUTC: DateTime.utc(2026, 9, 27),
      dateTimeLocal: DateTime(2026, 9, 27),
      metricValues: {comment.id: TextValue.orNull('0:10:00')!},
    );

    final exportMap = <String, dynamic>{
      'persons': [person.toJson()],
      'bikes': [bike.toJson()],
      'components': [component.toJson()],
      'setups': [setupJson],
      'ratings': [rating.toJson()],
      'ratingEntries': [entry.toJson()],
    };
    final importedData = SelectedData.fromJson(jsonDecode(jsonEncode(exportMap)) as Map<String, dynamic>);

    final importedSetup = importedData.setups['s1']!;
    expect(importedSetup.bikeAdjustmentValues[note.id], TextValue.orNull('01:30:00'));
    expect(importedSetup.bikeAdjustmentValues[side.id], CategoricalValue(['Front']));
    expect(importedSetup.bikeAdjustmentValues[pressure.id], const NumericalValue(89.0));
    // Unknown ids are kept unresolved instead of guessing a type.
    expect(importedSetup.bikeAdjustmentValues['orphan'], const UnresolvedValue('"01:30:00"'));
    expect(Setup.adjustmentValuesToJson(importedSetup.bikeAdjustmentValues)['orphan'], '01:30:00');
    expect(importedSetup.personAdjustmentValues, isEmpty);
    expect(importedData.ratingEntries['r1']!.metricValues[comment.id], TextValue.orNull('0:10:00'));
  });
}
