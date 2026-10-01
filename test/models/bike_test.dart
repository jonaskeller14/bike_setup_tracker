import 'package:bike_setup_tracker/models/attachment.dart';
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
      final bike = Bike.fromJson(const {
        "version": 4,
        "id": "6b55cf93-4f42-4449-ba2e-88ce763bbe83",
        "isDeleted": false,
        "lastModified": "2025-12-10T22:03:34.833974",
        "name": "Raaw Madonna V2.2",
      });
      expect(bike.initialStats, ComponentStats.zero);
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
      expect(json['version'], 6);
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

    test("Version 6: fromJson() / toJson() roundtrips attachments in order", () {
      final bike = Bike(
        name: "Raaw Madonna V2.2",
        person: null,
        attachments: [
          Attachment(id: 'b', extension: '.pdf', name: 'Frame Manual'),
          Attachment(id: 'a', extension: '.jpg', name: 'IMG_1234.jpg'),
        ],
      );
      final json = bike.toJson();
      expect(json['version'], 6);
      final restored = Bike.fromJson(json);
      expect(restored, bike);
      expect(restored.attachments.map((a) => a.id), ['b', 'a']);
    });

    test("Version 5: fromJson() without attachments reads an empty list", () {
      final bike = Bike.fromJson(const {'version': 5, 'name': 'Bike'});
      expect(bike.attachments, isEmpty);
    });

    test("attachments take part in equality", () {
      final bike = Bike(id: 'b1', name: 'Bike', person: null, lastModified: DateTime.utc(2026));
      final withAttachment = bike.copyWith(
        attachments: [Attachment(id: 'a', extension: '.pdf', name: 'Manual')],
      );
      expect(withAttachment == bike, isFalse);
      expect(withAttachment.copyWith(attachments: <Attachment>[]), bike);
    });

    test("deepCopy copies the attachments list", () {
      final attachments = [Attachment(id: 'a', extension: '.pdf', name: 'Manual')];
      final copy = Bike(name: 'Bike', person: null, attachments: attachments).deepCopy();
      expect(copy.attachments, attachments);
      expect(identical(copy.attachments, attachments), isFalse);
    });

    test('Version -1: fromJson() should throw exception for unknown version', () {
      final json = {'version': -1, 'name': 'Future Bike'};
      expect(() => Bike.fromJson(json), throwsException);
    });
  });
}
