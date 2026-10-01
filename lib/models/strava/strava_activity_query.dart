import 'package:flutter/foundation.dart';

import '../filters/activity_filter.dart';
import '../filters/local_date_range.dart';

/// Which Strava activities to read. Applied only in SQL (see `StravaDao`), so
/// the paged list, the map and search always agree.
@immutable
class StravaActivityQuery {
  /// `null` means the activities of every gear.
  final String? gearId;
  final ActivityFilter activity;

  /// `null` means the activities of every day.
  final LocalDateRange? dateRange;

  const StravaActivityQuery({this.gearId, this.activity = const ActivityFilter(), this.dateRange});

  StravaActivityQuery copyWith({String? gearId, ActivityFilter? activity, LocalDateRange? dateRange}) =>
      StravaActivityQuery(
        gearId: gearId ?? this.gearId,
        activity: activity ?? this.activity,
        dateRange: dateRange ?? this.dateRange,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StravaActivityQuery &&
          gearId == other.gearId &&
          activity == other.activity &&
          dateRange == other.dateRange;

  @override
  int get hashCode => Object.hash(gearId, activity, dateRange);
}
