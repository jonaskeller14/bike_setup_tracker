import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/models/strava/strava_scope.dart';
import 'package:flutter_test/flutter_test.dart';

StravaActivity activity({required int id, String? gearId}) => StravaActivity(
      id: id,
      name: "Ride $id",
      athlete: 1,
      sportType: SportType.Ride,
      startDate: DateTime.utc(2023, 1, id),
      startDateLocal: DateTime(2023, 1, id),
      gearId: gearId,
      startLat: null,
      startLon: null,
      distance: null,
      totalElevationGain: null,
      movingTime: Duration.zero,
      elapsedTime: Duration.zero,
    );

void main() {
  group("StravaScope.forBike", () {
    test("no selection is every activity", () {
      expect(StravaScope.forBike(null), isA<AllStravaActivities>());
    });

    test("a bike with a linked gear is scoped to that gear", () {
      final scope = StravaScope.forBike(Bike(name: "Enduro", person: null, stravaGear: "g1"));
      expect(scope, isA<GearStravaActivities>());
      expect((scope as GearStravaActivities).gearId, "g1");
    });

    test("a bike without a linked gear owns nothing", () {
      expect(
        StravaScope.forBike(Bike(name: "Hardtail", person: null, stravaGear: null)),
        isA<NoStravaActivities>(),
      );
    });
  });

  group("StravaScope.matches", () {
    test("all accepts every activity, gear or not", () {
      const scope = StravaScope.all();
      expect(scope.matches(activity(id: 1, gearId: "g1")), true);
      expect(scope.matches(activity(id: 2)), true);
    });

    test("gear accepts only its own gear", () {
      const scope = StravaScope.gear("g1");
      expect(scope.matches(activity(id: 1, gearId: "g1")), true);
      expect(scope.matches(activity(id: 2, gearId: "g2")), false);
      // An activity with no gear is unattributed, not this gear's.
      expect(scope.matches(activity(id: 3)), false);
    });

    test("none rejects everything", () {
      const scope = StravaScope.none();
      expect(scope.matches(activity(id: 1, gearId: "g1")), false);
      expect(scope.matches(activity(id: 2)), false);
    });
  });

  group("StravaScope.signature", () {
    test("distinguishes the three cases and each gear", () {
      final signatures = {
        const StravaScope.all().signature,
        const StravaScope.none().signature,
        const StravaScope.gear("g1").signature,
        const StravaScope.gear("g2").signature,
      };
      expect(signatures, hasLength(4));
    });

    test("is stable for the same scope, so an unchanged selection never re-pages", () {
      expect(const StravaScope.gear("g1").signature, const StravaScope.gear("g1").signature);
      expect(
        StravaScope.forBike(Bike(name: "A", person: null, stravaGear: "g1")).signature,
        const StravaScope.gear("g1").signature,
      );
    });
  });
}
