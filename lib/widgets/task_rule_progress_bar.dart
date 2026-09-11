
import 'package:flutter/material.dart';

import '../models/task/task_threshold/task_threshold.dart';

class TaskRuleProgressBar extends StatelessWidget {
  static const double _height = 4;

  static const Key originalTargetKey = ValueKey('task-progress-original-target');

  final TaskThreshold interval;
  final TaskThreshold? delay;
  final double progress;
  final Color statusColor;

  const TaskRuleProgressBar({
    super.key,
    required this.interval,
    required this.delay,
    required this.progress,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final bar = LinearProgressIndicator(
      value: progress.clamp(0.0, 1.0),
      backgroundColor: statusColor.withValues(alpha: 0.2),
      color: statusColor,
      minHeight: _height,
      borderRadius: BorderRadius.circular(2),
    );

    final originalTarget = _originalTargetFraction(interval, delay);
    if (originalTarget == null) return bar;

    return Stack(
      children: [
        bar,
        Positioned.fill(
          child: Align(
            alignment: Alignment(originalTarget * 2 - 1, 0),
            child: SizedBox(
              key: originalTargetKey,
              width: 2,
              height: _height,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

double? _originalTargetFraction(TaskThreshold interval, TaskThreshold? delay) {
  if (delay == null || !delay.isPositive || interval is! AccumulatingThreshold) return null;
  final total = interval.totalTarget(delay);
  if (total <= 0) return null;
  final fraction = interval.target / total;
  return fraction > 0 && fraction < 1 ? fraction : null;
}
