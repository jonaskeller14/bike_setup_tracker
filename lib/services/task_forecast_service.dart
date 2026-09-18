import '../models/activity_rate_window.dart';
import '../models/component.dart';
import '../models/component_stats.dart';
import '../models/task/task_entry.dart';
import '../models/task/task_progress_context.dart';
import '../models/task/task_rule.dart';
import '../models/task/task_threshold/task_threshold.dart';

class TaskForecast {
  final DateTime dueDate;
  final ActivityRateWindow? sample;

  const TaskForecast({
    required this.dueDate,
    this.sample,
  });
}

class TaskForecastService {
  const TaskForecastService._();

  static const int sampleSize = 10;
  static const Duration maxLookback = Duration(days: 180);
  static const int _minSamples = 2;
  static const Duration _minSpan = Duration(days: 3);

  /// When [rule] is expected to come due, or `null`
  static TaskForecast? predict({
    required TaskRule rule,
    required ComponentStats currentStats,
    required DateTime now,
    required Map<String, ActivityRateWindow> bikeRates,
    Component? component,
    TaskEntry? lastEntry,
    DateTime? componentInstallationDate,
  }) {
    final interval = rule.interval;
    if (interval == null || !interval.isPositive) return null;
    if (!rule.repeat && lastEntry != null) return null;

    return switch (interval) {
      DateTimeThreshold() => _fromDeadline(interval, rule.delay, now),
      AccumulatingThreshold() => _fromRemaining(
        interval: interval,
        rule: rule,
        // Same baseline TaskStatusService measures progress against, so the
        // forecast and the progress bar cannot disagree about the target.
        context: TaskProgressContext(
          currentStats: currentStats,
          baselineStats: lastEntry?.snapshot ?? ComponentStats.zero(),
          now: now,
          baselineDate:
              lastEntry?.dateTimeUTC ??
              componentInstallationDate ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        ),
        now: now,
        bikeRates: bikeRates,
        component: component,
      ),
    };
  }

  /// A fixed deadline is its own forecast. Only a duration delay moves it,
  /// exactly as [DateTimeThreshold.progress] reads it.
  static TaskForecast? _fromDeadline(DateTimeThreshold interval, TaskThreshold? delay, DateTime now) {
    final deadline = interval.deadline.add(delay is DurationThreshold ? delay.days : Duration.zero);
    return deadline.isAfter(now) ? TaskForecast(dueDate: deadline) : null;
  }

  static TaskForecast? _fromRemaining({
    required AccumulatingThreshold interval,
    required TaskRule rule,
    required TaskProgressContext context,
    required DateTime now,
    required Map<String, ActivityRateWindow> bikeRates,
    required Component? component,
  }) {
    final remaining = interval.totalTarget(rule.delay) - interval.accumulated(context);
    if (remaining <= 0) return null;

    // Elapsed time advances at exactly one day per day, so a duration interval
    // is exact and needs no sample at all.
    if (interval is DurationThreshold) {
      return TaskForecast(dueDate: now.add(Duration(microseconds: remaining.round())));
    }

    final window = _sampleFor(rule: rule, component: component, now: now, bikeRates: bikeRates);
    final until = window?.timeToAccumulate(interval, remaining, now: now);
    if (until == null) return null;

    return TaskForecast(dueDate: now.add(until), sample: window);
  }

  /// The window to extrapolate from, or `null` when it is too thin to trust.
  ///
  /// A bike rule uses its own bike; a component rule uses the bike it is
  /// installed on *right now*. Ride attribution is all-or-nothing, so a
  /// component's forward rate is definitionally its current bike's rate — its
  /// own history is the same number over a worse sample. An uninstalled or
  /// archived component has no bike and accrues nothing, so it gets no forecast.
  static ActivityRateWindow? _sampleFor({
    required TaskRule rule,
    required Component? component,
    required DateTime now,
    required Map<String, ActivityRateWindow> bikeRates,
  }) {
    final bikeId = rule.association.bikeId ?? component?.bikeAt(now);
    final window = bikeId != null ? bikeRates[bikeId] : null;
    if (window == null || window.count < _minSamples || window.sampleSpan < _minSpan) return null;
    return window;
  }
}
