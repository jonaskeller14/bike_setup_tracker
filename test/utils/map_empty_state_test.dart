import 'package:bike_setup_tracker/utils/map_empty_state.dart';
import 'package:flutter_test/flutter_test.dart';

bool anyData({
  bool hasSetups = false,
  bool hasRatingEntries = false,
  bool hasStravaActivities = false,
  bool ratingEnabled = false,
  bool stravaActive = false,
}) => hasAnyPositionedMapData(
  hasSetups: hasSetups,
  hasRatingEntries: hasRatingEntries,
  hasStravaActivities: hasStravaActivities,
  ratingEnabled: ratingEnabled,
  stravaActive: stravaActive,
);

void main() {
  group('hasAnyPositionedMapData', () {
    test('is false when no source holds a positioned item', () {
      expect(anyData(ratingEnabled: true, stravaActive: true), false);
    });

    test('setups always count', () {
      expect(anyData(hasSetups: true), true);
    });

    test('rating entries only count while ratings are enabled', () {
      expect(anyData(hasRatingEntries: true), false);
      expect(anyData(hasRatingEntries: true, ratingEnabled: true), true);
    });

    test('strava activities only count while strava is active', () {
      expect(anyData(hasStravaActivities: true), false);
      expect(anyData(hasStravaActivities: true, stravaActive: true), true);
    });

    test('disabled sources alone leave the map without data', () {
      expect(anyData(hasRatingEntries: true, hasStravaActivities: true), false);
    });
  });

  group('mapEmptyReason', () {
    test('is null while pins are visible', () {
      expect(mapEmptyReason(1, false), null);
      expect(mapEmptyReason(3, true), null);
    });

    test('is none when nothing positioned exists', () {
      expect(mapEmptyReason(0, false), MapEmptyReason.none);
    });

    test('is filtered when positioned data exists but no pin shows', () {
      expect(mapEmptyReason(0, true), MapEmptyReason.filtered);
    });

    test('is none when the only positioned data comes from a disabled source', () {
      final reason = mapEmptyReason(0, anyData(hasStravaActivities: true));

      expect(reason, MapEmptyReason.none);
    });

    test('is filtered when every layer is hidden but data exists', () {
      final reason = mapEmptyReason(0, anyData(hasSetups: true));

      expect(reason, MapEmptyReason.filtered);
    });
  });
}
