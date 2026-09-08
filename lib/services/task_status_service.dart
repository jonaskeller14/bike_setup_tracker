import 'dart:math';

import '../models/component_stats.dart';
import '../models/task/task_entry.dart';
import '../models/task/task_progress_context.dart';
import '../models/task/task_rule.dart';

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

    final context = TaskProgressContext(
      currentStats: currentStats,
      baselineStats: lastEntry?.snapshot ?? ComponentStats.zero(),
      now: now,
      baselineDate:
          lastEntry?.dateTimeUTC ?? componentInstallationDate ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );

    // The interval that has come furthest is the one that is reached first, so
    // it decides both status and progress.
    final progress = intervals.map((interval) => interval.progress(context, delay: rule.delay)).reduce(max);
    return TaskStatus.fromProgress(progress);
  }
}
