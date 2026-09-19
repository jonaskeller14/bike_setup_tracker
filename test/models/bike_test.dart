import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bike Model Tests', () {
    test("Version 0: fromJson() / toJson()", () {
      final jsonVersion0 = {
        "id": "6b55cf93-4f42-4449-ba2e-88ce763bbe83",
        "isDeleted": false,
        "lastModified": "2025-12-10T22:03:34.833974",
        "name": "Raaw Madonna V2.2",
      };
      final bikeVersion0A = Bike.fromJson(jsonVersion0);
      final bikeVersion0B = Bike.fromJson(bikeVersion0A.toJson());
      expect(bikeVersion0A == bikeVersion0B, true);
    });

    test("Version 1: fromJson() / toJson()", () {
      final jsonVersion1 = {
        "version": 1,
        "id": "6b55cf93-4f42-4449-ba2e-88ce763bbe83",
        "isDeleted": false,
        "lastModified": "2025-12-10T22:03:34.833974",
        "name": "Raaw Madonna V2.2",
        "person": "4019a1ef-ddd8-4794-99c9-8aea0469ec1c",
      };
      final bikeVersion1A = Bike.fromJson(jsonVersion1);
      final bikeVersion1B = Bike.fromJson(bikeVersion1A.toJson());
      expect(bikeVersion1A == bikeVersion1B, true);
    });

    test("Version 4: fromJson() defaults initialStats to zero", () {
      final bike = Bike.fromJson({
        "version": 4,
        "id": "6b55cf93-4f42-4449-ba2e-88ce763bbe83",
        "isDeleted": false,
        "lastModified": "2025-12-10T22:03:34.833974",
        "name": "Raaw Madonna V2.2",
      });
      expect(bike.initialStats, ComponentStats.zero());
    });

    test("Version 5: fromJson() / toJson() roundtrips initialStats", () {
      final bike = Bike(
        name: "Raaw Madonna V2.2",
        person: null,
        initialStats: const ComponentStats(
          distance: 5000000,
          elevationGain: 80000,
          movingTime: Duration(hours: 250),
          elapsedTime: Duration(hours: 300),
          activityCount: 120,
          kilojoules: 90000,
        ),
      );
      final json = bike.toJson();
      expect(json['version'], 5);
      expect(Bike.fromJson(json), bike);
    });

    test("deepCopy keeps initialStats", () {
      final bike = Bike(
        name: "Raaw Madonna V2.2",
        person: null,
        initialStats: const ComponentStats(distance: 5000000),
      );
      expect(bike.deepCopy().initialStats, bike.initialStats);
    });

    test('Version -1: fromJson() should throw exception for unknown version', () {
      final json = {'version': -1, 'name': 'Future Bike'};
      expect(() => Bike.fromJson(json), throwsException);
    });
  });
}
