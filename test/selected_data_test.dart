import 'dart:convert';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/task_rule.dart';
import 'package:bike_setup_tracker/models/task_threshold.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Serialize and deserialize SelectedData with TaskRule interval', () {
    final rule = TaskRule(
      id: "uuid123",
      isDeleted: false,
      lastModified: DateTime.now().toUtc(),
      name: 'Test',
      priority: TaskPriority.medium,
      componentId: "c1",
      bikeId: null,
      interval: const DurationThreshold(Duration(days: 30)),
      delay: const DistanceThreshold(500),
      repeat: true,
      tags: const {},
    );

    final selectedData = SelectedData(taskRules: {rule.id: rule});

    final exportMap = {
      'persons': [],
      'bikes': [],
      'setups': [],
      'components': [],
      'ratings': [],
      'taskRules': selectedData.taskRules.values.map((tr) => tr.toJson()).toList(),
      'taskEntries': [],
    };
    
    final jsonString = jsonEncode(exportMap);

    final decodedData = jsonDecode(jsonString) as Map<String, dynamic>;
    final importedData = SelectedData.fromJson(decodedData);
    
    final importedRule = importedData.taskRules.values.first;
    expect(importedRule.interval, isNotNull);
    expect(importedRule.interval, isA<DurationThreshold>());
  });
}
