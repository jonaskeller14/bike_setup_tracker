import 'package:bike_setup_tracker/models/strava/strava_athlete.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IDs', () {
    const bigId = 1234567890123456789;

    test('reads int and string IDs from Firestore', () {
      expect(StravaAthlete.fromFirestore(const {'id': bigId}).id, bigId);
      expect(StravaAthlete.fromFirestore(const {'id': '$bigId'}).id, bigId);
    });

    test('reads int and string IDs from JSON', () {
      expect(StravaAthlete.fromJson(const {'id': bigId}).id, bigId);
      expect(StravaAthlete.fromJson(const {'id': '$bigId'}).id, bigId);
    });
  });
}
