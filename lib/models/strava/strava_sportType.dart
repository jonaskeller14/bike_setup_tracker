part of 'strava_activity.dart';

// ignore_for_file: constant_identifier_names
enum SportType {
  AlpineSki,
  BackcountrySki,
  Badminton,
  Canoeing,
  Crossfit,
  EBikeRide,
  Elliptical,
  EMountainBikeRide,
  Golf,
  GravelRide,
  Handcycle,
  HighIntensityIntervalTraining,
  Hike,
  IceSkate,
  InlineSkate,
  Kayaking,
  Kitesurf,
  MountainBikeRide,
  NordicSki,
  Pickleball,
  Pilates,
  Racquetball,
  Ride,
  RockClimbing,
  RollerSki,
  Rowing,
  Run,
  Sail,
  Skateboard,
  Snowboard,
  Snowshoe,
  Soccer,
  Squash,
  StairStepper,
  StandUpPaddling,
  Surfing,
  Swim,
  TableTennis,
  Tennis,
  TrailRun,
  Velomobile,
  VirtualRide,
  VirtualRow,
  VirtualRun,
  Walk,
  WeightTraining,
  Wheelchair,
  Windsurf,
  Workout,
  Yoga,
  Other;

  factory SportType.fromString(String? value) {
    if (value == null) return SportType.Other;
    try {
      return SportType.values.byName(value);
    } catch (_) {
      return SportType.Other;
    }
  }

  IconData getIconData() {
    switch (this) {
      case SportType.MountainBikeRide || SportType.EMountainBikeRide || SportType.GravelRide || SportType.RockClimbing:
        return Icons.terrain;
      case SportType.Ride || SportType.EBikeRide || SportType.Handcycle || SportType.Velomobile || SportType.VirtualRide:
        return Icons.directions_bike;
      case SportType.Run || SportType.TrailRun || SportType.VirtualRun:
        return Icons.directions_run;
      case SportType.Hike || SportType.Walk || SportType.Snowshoe:
        return Icons.directions_walk;
      case SportType.Swim:
        return Icons.pool;
      case SportType.AlpineSki || SportType.BackcountrySki || SportType.NordicSki || SportType.RollerSki:
        return Icons.downhill_skiing;
      case SportType.Snowboard:
        return Icons.snowboarding;
      case SportType.Kayaking || SportType.Canoeing || SportType.StandUpPaddling:
        return Icons.kayaking;
      case SportType.Rowing || SportType.VirtualRow:
        return Icons.rowing;
      case SportType.WeightTraining || SportType.Crossfit || SportType.Workout || SportType.HighIntensityIntervalTraining || SportType.Elliptical || SportType.StairStepper:
        return Icons.fitness_center;
      case SportType.Yoga || SportType.Pilates:
        return Icons.self_improvement;
      case SportType.Tennis || SportType.Badminton || SportType.Pickleball || SportType.Racquetball || SportType.Squash || SportType.TableTennis:
        return Icons.sports_tennis;
      case SportType.Golf:
        return Icons.sports_golf;
      case SportType.Soccer:
        return Icons.sports_soccer;
      case SportType.IceSkate || SportType.InlineSkate:
        return Icons.ice_skating;
      case SportType.Skateboard:
        return Icons.skateboarding;
      case SportType.Sail || SportType.Windsurf || SportType.Kitesurf:
        return Icons.sailing;
      case SportType.Surfing:
        return Icons.surfing;
      case SportType.Wheelchair:
        return Icons.accessible;
      case SportType.Other:
        return Icons.question_mark;
    }
  }
}
