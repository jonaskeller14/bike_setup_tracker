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

  group('mapPinState', () {
    test('is success while pins are visible', () {
      expect(mapPinState(1, false), MapPinState.success);
      expect(mapPinState(3, true), MapPinState.success);
    });

    test('is none when nothing positioned exists', () {
      expect(mapPinState(0, false), MapPinState.none);
    });

    test('is filtered when positioned data exists but no pin shows', () {
      expect(mapPinState(0, true), MapPinState.filtered);
    });

    test('is none when the only positioned data comes from a disabled source', () {
      final reason = mapPinState(0, anyData(hasStravaActivities: true));
      expect(reason, MapPinState.none);
    });

    test('is filtered when every layer is hidden but data exists', () {
      final reason = mapPinState(0, anyData(hasSetups: true));
      expect(reason, MapPinState.filtered);
    });
  });
}
