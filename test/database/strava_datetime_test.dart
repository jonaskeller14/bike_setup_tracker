import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/converters/local_floating_datetime_converter.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StravaActivity DateTime Logic', () {
    final String serverStartDateLocalStr = "2024-05-15T10:41:00Z"; 
    // Usually strava gives local time with Z.
    final String serverStartDateStr = "2024-05-15T08:41:00Z";

    test('fromJson removes UTC flag and keeps floating hour', () {
      final json = {
        "id": 1,
        "name": "Morning Ride",
        "athleteId": 123,
        "sportType": "Ride",
        "startDate": serverStartDateStr,
        "startDateLocal": serverStartDateLocalStr,
        "movingTime": 3600,
        "elapsedTime": 3900,
      };

      final activity = StravaActivity.fromJson(json);

      // startDate should be absolute UTC
      expect(activity.startDate.isUtc, true);
      expect(activity.startDate.hour, 8); // 8 UTC

      // startDateLocal should be floating local (not UTC), preserving face value 10:41
      expect(activity.startDateLocal.isUtc, false);
      expect(activity.startDateLocal.hour, 10);
      expect(activity.startDateLocal.minute, 41);
    });

    test('fromFirestore matches fromJson formatting', () {
      final json = {
        "id": 1,
        "name": "Morning Ride",
        "athleteId": 123,
        "sportType": "Ride",
        "startDate": serverStartDateStr,
        "startDateLocal": serverStartDateLocalStr,
        "lastModified": Timestamp.now(),
        "movingTime": 3600,
        "elapsedTime": 3900,
      };

      final activity = StravaActivity.fromFirestore(json);

      expect(activity.startDate.isUtc, true);
      expect(activity.startDateLocal.isUtc, false);
      expect(activity.startDateLocal.hour, 10);
    });

    test('toJson generates non-Z trailing string for local time', () {
      final activity = StravaActivity(
        id: 1,
        name: "Morning Ride",
        athlete: 123,
        sportType: SportType.Ride,
        startDate: DateTime.utc(2024, 5, 15, 8, 41),
        startDateLocal: DateTime(2024, 5, 15, 10, 41), // floating local time
        gearId: "g1",
        startLat: null,
        startLon: null,
        distance: 10.0,
        totalElevationGain: 100.0,
        movingTime: Duration(minutes: 60),
        elapsedTime: Duration(minutes: 65),
      );

      final json = activity.toJson();
      
      expect((json['startDate'] as String).endsWith('Z'), true);
      // local time toString/iso8601 drops the Z
      expect((json['startDateLocal'] as String).endsWith('Z'), false);
    });
  });

  group('Drift LocalFloatingDateTimeConverter', () {
    const converter = LocalFloatingDateTimeConverter();

    test('toSql and fromSql mathematically preserve the floating Face Value', () {
      // Representing an activity at 10:41 AM Local Holiday Time
      final originalFloating = DateTime(2024, 5, 15, 10, 41);
      
      // Step 1: Save to Drift (toSql converts to UTC layout for stable absolute storage)
      final sqlRepresentation = converter.toSql(originalFloating);
      expect(sqlRepresentation.isUtc, true);
      expect(sqlRepresentation.hour, 10); // Protected into UTC

      // (Simulate database storing it as Unix Epoch Integer implicitly using millisecondsSinceEpoch)
      final databaseUnixEpoch = sqlRepresentation.millisecondsSinceEpoch;

      // ... Device travels to new Timezone ...

      // Step 2: Read from Drift (fromSql gets a locally shifted DateTime reconstructed by drift)
      final reconstructedByDrift = DateTime.fromMillisecondsSinceEpoch(databaseUnixEpoch);
      
      // Step 3: Converter safely reads the DB value back out 
      final restoredFloating = converter.fromSql(reconstructedByDrift);

      // Verify strict face value roundtrip
      expect(restoredFloating.isUtc, false);
      expect(restoredFloating.year, 2024);
      expect(restoredFloating.month, 5);
      expect(restoredFloating.day, 15);
      expect(restoredFloating.hour, 10);  // EXACTLY 10:41 NO MATTER WHERE THE APP IS!
      expect(restoredFloating.minute, 41);
    });
  });

  group('Drift Actual Database Read/Write', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.memory();
    });

    tearDown(() async {
      await database.close();
    });

    test('Writing and reading activity preserves floating local and absolute UTC times', () async {
      // 10:41 AM Floating
      final startDateLocal = DateTime(2024, 5, 15, 10, 41);
      // 08:41 AM UTC Absolute (same moment assuming +02:00)
      final startDate = DateTime.utc(2024, 5, 15, 8, 41);

      final activity = StravaActivityDb(
        id: 1,
        lastModified: DateTime.now().toUtc(),
        name: "Morning Ride",
        athlete: 123,
        sportType: SportType.Ride,
        startDate: startDate,
        startDateLocal: startDateLocal,
        movingTime: 3600,
        elapsedTime: 3900,
      );

      await database.into(database.stravaActivities).insert(activity);

      final result = await database.select(database.stravaActivities).getSingle();

      // Check `startDate` (Absolute UTC)
      expect(result.startDate.isUtc, true);
      expect(result.startDate.hour, 8); // Always 8 UTC
      
      // Check `startDateLocal` (Floating Wall Clock)
      expect(result.startDateLocal.isUtc, false);
      expect(result.startDateLocal.hour, 10); // Guaranteed 10 Floating Local!
    });
  });
}
