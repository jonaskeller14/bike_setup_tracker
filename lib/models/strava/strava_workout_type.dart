part of 'strava_activity.dart';

enum StravaWorkoutType {
  none,
  race,
  workout;

  static StravaWorkoutType fromRaw(int? raw) => switch (raw) {
        11 => StravaWorkoutType.race,
        12 => StravaWorkoutType.workout,
        _ => StravaWorkoutType.none,
      };

  bool get isNotable => this != StravaWorkoutType.none;

  String get label => switch (this) {
        StravaWorkoutType.none => 'Activity',
        StravaWorkoutType.race => 'Race',
        StravaWorkoutType.workout => 'Workout',
      };

  IconData get icon => switch (this) {
        StravaWorkoutType.none => Icons.circle_outlined,
        StravaWorkoutType.race => Icons.emoji_events,
        StravaWorkoutType.workout => Icons.fitness_center,
      };
}
