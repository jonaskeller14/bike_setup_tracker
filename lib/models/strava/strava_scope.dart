import '../bike.dart';
import 'strava_activity.dart';

sealed class StravaScope {
  const StravaScope();

  const factory StravaScope.all() = AllStravaActivities;
  const factory StravaScope.gear(String gearId) = GearStravaActivities;
  const factory StravaScope.none() = NoStravaActivities;

  factory StravaScope.forBike(Bike? bike) {
    if (bike == null) return const StravaScope.all();
    final gear = bike.stravaGear;
    return gear == null ? const StravaScope.none() : StravaScope.gear(gear);
  }

  String get signature;
  bool matches(StravaActivity activity);
}

final class AllStravaActivities extends StravaScope {
  const AllStravaActivities();

  @override
  String get signature => 'all';

  @override
  bool matches(StravaActivity activity) => true;
}

final class GearStravaActivities extends StravaScope {
  final String gearId;

  const GearStravaActivities(this.gearId);

  @override
  String get signature => 'gear:$gearId';

  @override
  bool matches(StravaActivity activity) => activity.gearId == gearId;
}

final class NoStravaActivities extends StravaScope {
  const NoStravaActivities();

  @override
  String get signature => 'none';

  @override
  bool matches(StravaActivity activity) => false;
}
