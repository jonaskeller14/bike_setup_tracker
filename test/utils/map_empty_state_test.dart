import 'package:bike_setup_tracker/utils/map_empty_state.dart';
import 'package:flutter_test/flutter_test.dart';

bool anyData({
  bool hasSetups = false,
  bool hasFeedbacks = false,
  bool hasStravaActivities = false,
  bool feedbackEnabled = false,
  bool stravaActive = false,
}) => hasAnyPositionedMapData(
  hasSetups: hasSetups,
  hasFeedbacks: hasFeedbacks,
  hasStravaActivities: hasStravaActivities,
  feedbackEnabled: feedbackEnabled,
  stravaActive: stravaActive,
);

void main() {
  group('hasAnyPositionedMapData', () {
    test('is false when no source holds a positioned item', () {
      expect(anyData(feedbackEnabled: true, stravaActive: true), false);
    });

    test('setups always count', () {
      expect(anyData(hasSetups: true), true);
    });

    test('feedbacks only count while feedback is enabled', () {
      expect(anyData(hasFeedbacks: true), false);
      expect(anyData(hasFeedbacks: true, feedbackEnabled: true), true);
    });

    test('strava activities only count while strava is active', () {
      expect(anyData(hasStravaActivities: true), false);
      expect(anyData(hasStravaActivities: true, stravaActive: true), true);
    });

    test('disabled sources alone leave the map without data', () {
      expect(anyData(hasFeedbacks: true, hasStravaActivities: true), false);
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
