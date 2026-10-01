import 'package:bike_setup_tracker/models/filters/activity_filter.dart';
import 'package:bike_setup_tracker/models/filters/numeric_range.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("StravaActivityQuery", () {
    test("defaults to the activities of every gear", () {
      expect(const StravaActivityQuery().gearId, null);
    });

    test("is equal by value, so an unchanged selection never re-pages", () {
      // An equal value that is not the same instance.
      final gearId = ["g", "1"].join();
      expect(StravaActivityQuery(gearId: gearId), const StravaActivityQuery(gearId: "g1"));
      expect(const StravaActivityQuery(), isNot(same(StravaActivityQuery(gearId: gearId))));
      expect(const StravaActivityQuery(gearId: "g1").hashCode, const StravaActivityQuery(gearId: "g1").hashCode);
    });

    test("differs per gear and from the unscoped query", () {
      expect(const StravaActivityQuery(gearId: "g1"), isNot(const StravaActivityQuery(gearId: "g2")));
      expect(const StravaActivityQuery(gearId: "g1"), isNot(const StravaActivityQuery()));
    });

    test("copyWith replaces the gear and keeps it when omitted", () {
      const query = StravaActivityQuery(gearId: "g1");

      expect(query.copyWith(gearId: "g2"), const StravaActivityQuery(gearId: "g2"));
      expect(query.copyWith(), query);
    });

    test("defaults to no activity criteria", () {
      expect(const StravaActivityQuery().activity, const ActivityFilter());
    });

    test("differs per activity criteria, so a changed range re-pages", () {
      const longRides = ActivityFilter(distance: NumericRange(min: 50000));

      expect(const StravaActivityQuery(activity: longRides), isNot(const StravaActivityQuery()));
      expect(
        const StravaActivityQuery(gearId: "g1", activity: longRides),
        isNot(const StravaActivityQuery(gearId: "g1", activity: ActivityFilter(distance: NumericRange(min: 60000)))),
      );
    });

    test("is equal by value with activity criteria", () {
      // An equal value that is not the same instance.
      final min = [50000.0].first;
      final query = StravaActivityQuery(gearId: "g1", activity: ActivityFilter(distance: NumericRange(min: min)));
      const other = StravaActivityQuery(gearId: "g1", activity: ActivityFilter(distance: NumericRange(min: 50000)));

      expect(query, other);
      expect(query.hashCode, other.hashCode);
    });

    test("copyWith replaces the activity criteria and keeps the gear", () {
      const query = StravaActivityQuery(gearId: "g1");
      const hilly = ActivityFilter(elevationGain: NumericRange(min: 1000));

      expect(query.copyWith(activity: hilly), const StravaActivityQuery(gearId: "g1", activity: hilly));
      expect(query.copyWith(activity: hilly).copyWith(gearId: "g2").activity, hilly);
    });
  });
}
