import 'package:flutter/foundation.dart';

import 'numeric_range.dart';

/// The Strava activity criteria besides the gear scope, both in metres. They
/// are applied only in SQL (see `StravaDao`), so there is no `matches`.
@immutable
class ActivityFilter {
  final NumericRange distance;
  final NumericRange elevationGain;

  const ActivityFilter({this.distance = const NumericRange(), this.elevationGain = const NumericRange()});

  bool get isActive => distance.isActive || elevationGain.isActive;

  ActivityFilter copyWith({NumericRange? distance, NumericRange? elevationGain}) =>
      ActivityFilter(distance: distance ?? this.distance, elevationGain: elevationGain ?? this.elevationGain);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityFilter && distance == other.distance && elevationGain == other.elevationGain;

  @override
  int get hashCode => Object.hash(distance, elevationGain);
}
