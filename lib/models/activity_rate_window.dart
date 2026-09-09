import 'component_stats.dart';
import 'task/task_progress_context.dart';
import 'task/task_threshold/task_threshold.dart';

/// The most recent slice of a bike's activity history: what was ridden, how
/// long that took, and from how many activities.
///
/// Unlike the lifetime sums of `watchBikeStats`, this keeps the span the sample
/// covers, which is exactly what turns a sum into a rate.
class ActivityRateWindow {
  final ComponentStats sum;
  final DateTime firstStart;
  final DateTime lastStart;
  final int count;

  const ActivityRateWindow({
    required this.sum,
    required this.firstStart,
    required this.lastStart,
    required this.count,
  });

  /// Calendar time the sample itself covers. This is what says whether the
  /// window is spread out enough to mean anything, not what the rate divides by.
  Duration get sampleSpan => lastStart.difference(firstStart);

  /// How long it takes to gather [amount] more of whatever [threshold]
  /// measures, at the pace of this window up to [now], or `null` when the
  /// window carries no usable pace.
  ///
  /// The window is handed to `accumulated()` as a synthetic progress context —
  /// `delta` is what was ridden, `elapsed` how long that took — so the pace
  /// comes back in the threshold's own unit (meters, microseconds, rides)
  /// without this model knowing which unit that is, and [amount] cancels that
  /// unit out again. Staying in `double` throughout is what keeps sub-unit
  /// paces alive: [ComponentStats] counts rides in an `int`, so a stats-shaped
  /// rate would floor 0.4 rides/day to none.
  ///
  /// The pace is measured up to [now] rather than up to [lastStart] for two
  /// reasons. Idle time is real time in which nothing accrued, so a bike parked
  /// since spring slows down day by day instead of forecasting at its riding
  /// rate until the lookback drops it. And [count] activities span only
  /// `count - 1` gaps, so dividing by the sample's own span would read a rider
  /// doing exactly 100 km a day as doing 111.
  Duration? timeToAccumulate(AccumulatingThreshold threshold, double amount, {required DateTime now}) {
    final days = now.difference(firstStart).inMicroseconds / Duration.microsecondsPerDay;
    if (days <= 0) return null;

    final perDay = threshold.accumulated(_asProgress) / days;
    if (perDay <= 0) return null;

    return Duration(microseconds: (amount / perDay * Duration.microsecondsPerDay).round());
  }

  TaskProgressContext get _asProgress => TaskProgressContext(
    currentStats: sum,
    baselineStats: ComponentStats.zero(),
    now: lastStart,
    baselineDate: firstStart,
  );
}
