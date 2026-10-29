import 'component_stats.dart';

/// One activity credited to a component or bike, with the values its stats
/// sum. [wattSeconds] is average watts × moving time; kilojoules divide the
/// sum, like the stats queries do.
typedef CreditedActivity = ({
  int startSeconds,
  double distance,
  double elevationGain,
  int movingSeconds,
  int elapsedSeconds,
  double wattSeconds,
});

/// The stats of one component or bike at every point in its activity history,
/// so the stats as of any date are a binary search instead of a stats query.
class StatsTimeline {
  /// [initial] holds the stats before any activity (initial and inherited
  /// stats); [activities] may come in any order.
  StatsTimeline({required this.initial, required Iterable<CreditedActivity> activities}) {
    final sorted = activities.toList()..sort((a, b) => a.startSeconds.compareTo(b.startSeconds));
    var distance = 0.0;
    var elevationGain = 0.0;
    var movingSeconds = 0;
    var elapsedSeconds = 0;
    var wattSeconds = 0.0;
    for (final activity in sorted) {
      _startSeconds.add(activity.startSeconds);
      _distance.add(distance += activity.distance);
      _elevationGain.add(elevationGain += activity.elevationGain);
      _movingSeconds.add(movingSeconds += activity.movingSeconds);
      _elapsedSeconds.add(elapsedSeconds += activity.elapsedSeconds);
      _wattSeconds.add(wattSeconds += activity.wattSeconds);
    }
  }

  final ComponentStats initial;
  final _startSeconds = <int>[];
  final _distance = <double>[];
  final _elevationGain = <double>[];
  final _movingSeconds = <int>[];
  final _elapsedSeconds = <int>[];
  final _wattSeconds = <double>[];

  /// Counts the activities that start at or before [date], compared in whole
  /// seconds like the database stores them.
  ComponentStats at(DateTime date) {
    final seconds = date.millisecondsSinceEpoch ~/ 1000;
    var low = 0;
    var high = _startSeconds.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (_startSeconds[mid] <= seconds) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    if (low == 0) return initial;
    final last = low - 1;
    return ComponentStats(
      distance: initial.distance + _distance[last],
      elevationGain: initial.elevationGain + _elevationGain[last],
      movingTime: initial.movingTime + Duration(seconds: _movingSeconds[last]),
      elapsedTime: initial.elapsedTime + Duration(seconds: _elapsedSeconds[last]),
      activityCount: initial.activityCount + low,
      kilojoules: initial.kilojoules + _wattSeconds[last] / 1000.0,
    );
  }
}
