import 'package:flutter_test/flutter_test.dart';
import 'package:bike_setup_tracker/models/bike.dart';

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
      final jsonVersion0 = {
        "version": 1,
        "id": "6b55cf93-4f42-4449-ba2e-88ce763bbe83",
        "isDeleted": false,
        "lastModified": "2025-12-10T22:03:34.833974",
        "name": "Raaw Madonna V2.2",
        "person": "4019a1ef-ddd8-4794-99c9-8aea0469ec1c",
      };
      final bikeVersion0A = Bike.fromJson(jsonVersion0);
      final bikeVersion0B = Bike.fromJson(bikeVersion0A.toJson());
      expect(bikeVersion0A == bikeVersion0B, true);
    });

    test('Version -1: fromJson() should throw exception for unknown version', () {
      final json = {'version': -1, 'name': 'Future Bike'};
      expect(() => Bike.fromJson(json), throwsException);
    });
  });
}
