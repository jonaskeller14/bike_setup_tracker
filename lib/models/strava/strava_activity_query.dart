import 'package:flutter/foundation.dart';

/// Which Strava activities to read. Applied only in SQL (see `StravaDao`), so
/// the paged list, the map and search always agree.
@immutable
class StravaActivityQuery {
  /// `null` means the activities of every gear.
  final String? gearId;

  const StravaActivityQuery({this.gearId});

  StravaActivityQuery copyWith({String? gearId}) => StravaActivityQuery(gearId: gearId ?? this.gearId);

  @override
  bool operator ==(Object other) => identical(this, other) || other is StravaActivityQuery && gearId == other.gearId;

  @override
  int get hashCode => gearId.hashCode;
}
