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
  });
}
