import 'package:flutter_test/flutter_test.dart';
import 'package:bike_setup_tracker/models/task_threshold.dart';
import 'dart:convert';

void main() {
  test('Serialize and deserialize DurationThreshold', () {
    final threshold = DurationThreshold(Duration(days: 30));
    final jsonString = jsonEncode(threshold.toJson());
    final decodedJson = jsonDecode(jsonString);
    final newThreshold = TaskThreshold.fromJson(decodedJson) as DurationThreshold;
    expect(newThreshold.days.inDays, 30);
  });
}
