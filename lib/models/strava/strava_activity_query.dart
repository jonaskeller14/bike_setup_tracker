import 'package:flutter/foundation.dart';

import '../filters/activity_filter.dart';

/// Which Strava activities to read. Applied only in SQL (see `StravaDao`), so
/// the paged list, the map and search always agree.
@immutable
class StravaActivityQuery {
  /// `null` means the activities of every gear.
  final String? gearId;
  final ActivityFilter activity;

  const StravaActivityQuery({this.gearId, this.activity = const ActivityFilter()});

  StravaActivityQuery copyWith({String? gearId, ActivityFilter? activity}) =>
      StravaActivityQuery(gearId: gearId ?? this.gearId, activity: activity ?? this.activity);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StravaActivityQuery && gearId == other.gearId && activity == other.activity;

  @override
  int get hashCode => Object.hash(gearId, activity);
}
