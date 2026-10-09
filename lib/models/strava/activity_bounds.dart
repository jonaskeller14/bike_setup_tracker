import 'package:flutter/foundation.dart';

/// The extremes over every synced Strava activity, whatever the filters say.
/// They size the filter sliders. Every field is `null` without activities.
@immutable
class ActivityBounds {
  /// The local wall-clock start of the earliest activity.
  final DateTime? firstStartLocal;

  /// In metres.
  final double? maxDistance;

  /// In metres.
  final double? maxElevationGain;

  const ActivityBounds({this.firstStartLocal, this.maxDistance, this.maxElevationGain});

  static const empty = ActivityBounds();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityBounds &&
          firstStartLocal == other.firstStartLocal &&
          maxDistance == other.maxDistance &&
          maxElevationGain == other.maxElevationGain;

  @override
  int get hashCode => Object.hash(firstStartLocal, maxDistance, maxElevationGain);
}
