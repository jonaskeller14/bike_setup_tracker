part of 'strava_activity.dart';

// ignore_for_file: constant_identifier_names
enum SportType {
  AlpineSki("Alpine Ski"),
  BackcountrySki("Backcountry Ski"),
  Badminton("Badminton"),
  Canoeing("Canoeing"),
  Crossfit("Crossfit"),
  EBikeRide("E-Bike Ride"),
  Elliptical("Elliptical"),
  EMountainBikeRide("E-Mountain Bike Ride"),
  Golf("Golf"),
  GravelRide("Gravel Ride"),
  Handcycle("Handcycle"),
  HighIntensityIntervalTraining("HIIT"),
  Hike("Hike"),
  IceSkate("Ice Skate"),
  InlineSkate("Inline Skate"),
  Kayaking("Kayaking"),
  Kitesurf("Kitesurf"),
  MountainBikeRide("Mountain Bike Ride"),
  NordicSki("Nordic Ski"),
  Pickleball("Pickleball"),
  Pilates("Pilates"),
  Racquetball("Racquetball"),
  Ride("Ride"),
  RockClimbing("Rock Climbing"),
  RollerSki("Roller Ski"),
  Rowing("Rowing"),
  Run("Run"),
  Sail("Sail"),
  Skateboard("Skateboard"),
  Snowboard("Snowboard"),
  Snowshoe("Snowshoe"),
  Soccer("Soccer"),
  Squash("Squash"),
  StairStepper("Stair Stepper"),
  StandUpPaddling("Stand Up Paddling"),
  Surfing("Surfing"),
  Swim("Swim"),
  TableTennis("Table Tennis"),
  Tennis("Tennis"),
  TrailRun("Trail Run"),
  Velomobile("Velomobile"),
  VirtualRide("Virtual Ride"),
  VirtualRow("Virtual Row"),
  VirtualRun("Virtual Run"),
  Walk("Walk"),
  WeightTraining("Weight Training"),
  Wheelchair("Wheelchair"),
  Windsurf("Windsurf"),
  Workout("Workout"),
  Yoga("Yoga"),
  Other("Other");

  final String label;
  const SportType(this.label);

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
