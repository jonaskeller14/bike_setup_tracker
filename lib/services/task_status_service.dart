import 'dart:math';

import '../models/component_stats.dart';
import '../models/task/task_entry.dart';
import '../models/task/task_progress_context.dart';
import '../models/task/task_rule.dart';
import '../models/task/task_threshold/task_threshold.dart';

class TaskStatusService {
  const TaskStatusService._();

  static TaskStatus calculate({
    required TaskRule rule,
    required ComponentStats currentStats,
    required DateTime now,
    TaskEntry? lastEntry,
    DateTime? componentInstallationDate,
  }) {
    if (!rule.repeat && lastEntry != null) return TaskStatus.completed;

    final intervals = [if (rule.interval != null) rule.interval!];
    if (intervals.isEmpty) {
      // Plain todo: done once an entry exists, waiting to be ticked off otherwise.
      return lastEntry != null ? TaskStatus.completed : TaskStatus.open;
    }

    final context = _progressContext(
      currentStats: currentStats,
      now: now,
      lastEntry: lastEntry,
      componentInstallationDate: componentInstallationDate,
    );

    // The interval that has come furthest is the one that is reached first, so
    // it decides both status and progress.
    final progress = intervals.map((interval) => interval.progress(context, delay: rule.delay)).reduce(max);
    return TaskStatus.fromProgress(progress);
  }

  /// The delay that makes [rule] due right away without touching its interval,
  /// replacing any delay it has. Null when dropping the delay is enough, or when
  /// the interval is a deadline with no amount to pull in.
  static TaskThreshold? dueNowDelay({
    required TaskRule rule,
    required ComponentStats currentStats,
    required DateTime now,
    TaskEntry? lastEntry,
    DateTime? componentInstallationDate,
  }) {
    final interval = rule.interval;
    if (interval is! AccumulatingThreshold) return null;

    final context = _progressContext(
      currentStats: currentStats,
      now: now,
      lastEntry: lastEntry,
      componentInstallationDate: componentInstallationDate,
    );
    if (interval.isMet(context)) return null;
    return interval.dueNowDelay(context);
  }

  /// What is still to gather before [rule] becomes due, in its interval's
  /// unit ([AccumulatingThreshold.target]). Null unless the rule is open,
  /// measured by an accumulating interval and not due yet.
  static double? remaining({
    required TaskRule rule,
    required ComponentStats currentStats,
    required DateTime now,
    TaskEntry? lastEntry,
    DateTime? componentInstallationDate,
  }) {
    final interval = rule.interval;
    if (interval is! AccumulatingThreshold) return null;
    if (!rule.repeat && lastEntry != null) return null;

    final context = _progressContext(
      currentStats: currentStats,
      now: now,
      lastEntry: lastEntry,
      componentInstallationDate: componentInstallationDate,
    );
    final remaining = interval.totalTarget(rule.delay) - interval.accumulated(context);
    return remaining > 0 ? remaining : null;
  }

  static TaskProgressContext _progressContext({
    required ComponentStats currentStats,
    required DateTime now,
    TaskEntry? lastEntry,
    DateTime? componentInstallationDate,
  }) {
    return TaskProgressContext(
      currentStats: currentStats,
      baselineStats: lastEntry?.snapshot ?? ComponentStats.zero,
      now: now,
      baselineDate:
          lastEntry?.dateTimeUTC ?? componentInstallationDate ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
