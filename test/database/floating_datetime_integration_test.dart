import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/task_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Floating DateTime Serialization Logic', () {
    final String serverStartDateLocalStr = "2024-05-15T10:41:00"; 
    // Usually local times come without Z when our app creates them, but with Z if from old data
    final String serverStartDateStr = "2024-05-15T08:41:00Z";

    test('Setup handles floating time accurately via fromJson and toJson', () {
      final json = {
        "id": "s1",
        "isDeleted": false,
        "name": "Race Setup",
        "datetime": serverStartDateStr,
        "datetimeLocal": serverStartDateLocalStr,
        "tags": [],
        "bike": "b1",
        "person": "p1",
      };

      final setup = Setup.fromJson(json: json);
      expect(setup.datetime.isUtc, true);
      
      // Face value should be exactly 10 floating hours!
      expect(setup.datetimeLocal.isUtc, false, reason: "datetimeLocal must not be parsed as UTC!");
      expect(setup.datetimeLocal.hour, 10);

      // Verify that toJson strips the 'Z' on local times (assuming no microseconds)
      final outJson = setup.toJson();
      expect((outJson['datetimeLocal'] as String).endsWith('Z'), false);
    });

    test('Installation handles floating time accurately', () {
      final json = {
        "parent": "c1",
        "dateTimeUTC": serverStartDateStr,
        "dateTimeLocal": serverStartDateLocalStr,
      };

      final installation = Installation.fromJson(json);
      expect(installation.dateTimeLocal.isUtc, false);
      expect(installation.dateTimeLocal.hour, 10);

      final outJson = installation.toJson();
      expect((outJson['dateTimeLocal'] as String).endsWith('Z'), false);
    });

    test('TaskEntry handles floating time accurately', () {
       final json = {
        "id": "te1",
        "isDeleted": false,
        "lastModified": serverStartDateStr,
        "name": "Grease Chain",
        "taskRule": "tr1",
        "dateTimeUTC": serverStartDateStr,
        "dateTimeLocal": serverStartDateLocalStr,
      };

      final taskEntry = TaskEntry.fromJson(json);
      expect(taskEntry.dateTimeLocal.isUtc, false);
      expect(taskEntry.dateTimeLocal.hour, 10);

      final outJson = taskEntry.toJson();
      expect((outJson['dateTimeLocal'] as String).endsWith('Z'), false);
    });
  });
}
