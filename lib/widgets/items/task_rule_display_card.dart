import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/task/task_rule.dart';
import '../../models/task/task_threshold/task_threshold.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../utils/task_actions.dart';
import '../task_rule_progress_bar.dart';
import 'task_rule_list_card.dart';

String taskForecastDueLabel(DateTime dueLocal, DateTime nowLocal, String dateFormat) {
  final days = DateUtils.dateOnly(dueLocal).difference(DateUtils.dateOnly(nowLocal)).inDays;
  if (days <= 0) return 'today';
  if (days == 1) return 'tomorrow';
  if (days < 14) return 'in $days days';
  if (days < 56) {
    final weeks = days ~/ 7;
    return 'in $weeks weeks';
  }
  return DateFormat(dateFormat).format(dueLocal);
}

class TaskRuleDisplayCard extends StatelessWidget {
  final TaskRule taskRule;
  final bool showStatus;
  final String? heroTag;
  final bool showForcast;

  const TaskRuleDisplayCard({
    super.key,
    required this.taskRule,
    required this.showStatus,
    this.heroTag,
    this.showForcast = true,
  });

  /// A forecast carrying a rate sample was extrapolated from riding, so it
  /// needs the Strava entitlement behind it and reads as a rough countdown.
  /// One without a sample is exact — a date or duration trigger — so it names
  /// the day rather than restating the countdown the detail row already shows.
  String? _forecastLabel(
    BuildContext context,
    AppRepository appRepository,
    TaskStatus status,
    String dateFormat,
  ) {
    if (taskRule.interval == null || status.isDue) return null;
    final forecast = appRepository.getTaskRuleForecast(taskRule);
    if (forecast == null) return null;
    final now = DateTime.now();
    final due = forecast.dueDate.toLocal();
    if (!due.isAfter(now)) return null;
    if (forecast.sample == null) return DateFormat(dateFormat).format(due);
    if (!context.select<SubscriptionService, bool>((s) => s.hasStravaEntitlement)) return null;
    return taskForecastDueLabel(due, now, dateFormat);
  }

  Widget _forecastWidget(BuildContext context, String forecastLabel, Color statusColor) {
    return Tooltip(
      message: 'Forecast for when this task will become due. Exact for date and duration '
          'intervals; for other intervals it is estimated from recent riding activity and '
          'needs a connected Strava subscription.',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 2,
        children: [
          Icon(Icons.insights, size: 13, color: statusColor.withValues(alpha: 0.5)),
          Text(
            forecastLabel,
            style: TextStyle(
              color: statusColor.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final appSettings = context.watch<AppSettings>();
    final status = appRepository.getTaskRuleStatus(taskRule);
    final isCompleted = status.type == TaskStatusType.completed;

    final component = taskRule.componentId != null ? appRepository.components[taskRule.componentId] : null;
    final statusColor = status.type.getStatusColor(context);
    final forecastLabel = showStatus && !isCompleted && appSettings.enableTaskDuePrediction
        ? _forecastLabel(context, appRepository, status, appSettings.dateFormat)
        : null;

    final card = Opacity(
      opacity: isCompleted ? 0.5 : 1,
      child: Card.outlined(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: showStatus
              ? Checkbox(
                  value: isCompleted,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: isCompleted ? null : (bool? value) async {
                    unawaited(HapticFeedback.lightImpact());
                    await TaskActions.addTaskEntry(
                      context,
                      taskRule: taskRule,
                      heroTag: heroTag,
                    );
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minTileHeight: 0,
          titleAlignment: ListTileTitleAlignment.top,
          title: Text(
            taskRule.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              decoration: isCompleted ? TextDecoration.lineThrough: null,
              decorationThickness: 2,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TaskRuleListCard.filterWidget(context, taskRule: taskRule, component: component, bikes: appRepository.bikes),
              if (appSettings.enableTaskPriority)
                TaskRuleListCard.priorityWidget(context, priority: taskRule.priority),
              if (appSettings.enableTaskTags && taskRule.tags.isNotEmpty)
                TaskRuleListCard.tagsWidget(context, tags: taskRule.tags),
              if (taskRule.notes != null && taskRule.notes!.isNotEmpty)
                TaskRuleListCard.notesWidget(context, notes: taskRule.notes!),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 8,
                children: [
                  if (taskRule.interval != null)
                    TaskIntervalText(
                      interval: taskRule.interval!,
                      delay: taskRule.delay,
                      repeat: taskRule.repeat,
                    ),
                  if (showStatus && !isCompleted && taskRule.interval != null)
                    Flexible(
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        children: [
                          _buildThresholdDetailRow(context, taskRule.interval!, taskRule.delay, status, statusColor, appSettings.distanceUnit, appSettings.altitudeUnit),
                          if (showForcast && forecastLabel != null) _forecastWidget(context, forecastLabel, statusColor),
                        ],
                      ),
                    ),
                ],
              ),
              if (showStatus && !isCompleted && taskRule.interval != null) ...[
                const SizedBox(height: 8),
                TaskRuleProgressBar(
                  interval: taskRule.interval!,
                  delay: taskRule.delay,
                  progress: status.progress,
                  statusColor: statusColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return heroTag == null ? card : Hero(tag: heroTag!, child: card);
  }

  Widget _buildThresholdDetailRow(BuildContext context, TaskThreshold interval, TaskThreshold? delay, TaskStatus status, Color statusColor, String distanceUnit, String altitudeUnit) {
    final detail = _thresholdDetail(interval, delay, status.progress, distanceUnit, altitudeUnit);
    if (detail == null) return const SizedBox.shrink();
    final isExceeded = status.isDue;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 2,
      children: [
        Icon(isExceeded ? Icons.warning_amber_rounded : Icons.arrow_forward, size: 13, color: statusColor),
        Flexible(
          child: Text(
            detail,
            style: TextStyle(color: statusColor, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _plural(int count, String singular, [String? plural]) =>
      count == 1 ? singular : (plural ?? '${singular}s');

  String? _thresholdDetail(TaskThreshold interval, TaskThreshold? delay, double progress, String distanceUnit, String altitudeUnit) {
    switch (interval) {
      case DistanceThreshold(:final meters):
        final totalM = meters + (delay is DistanceThreshold ? delay.meters : 0.0);
        if (totalM <= 0) return null;
        final diffM = (totalM - progress * totalM).abs();
        final converted = AppSettings.convertDistanceFromMeters(diffM, distanceUnit)!;
        final fmt = NumberFormat.decimalPattern();
        return progress < 1.0
            ? '${fmt.format(converted.round())} $distanceUnit remaining'
            : '${fmt.format(converted.round())} $distanceUnit exceeded';

      case ElevationThreshold(:final meters):
        final totalM = meters + (delay is ElevationThreshold ? delay.meters : 0.0);
        if (totalM <= 0) return null;
        final accumulatedM = progress * totalM;
        final diffM = (totalM - accumulatedM).abs();
        final converted = AppSettings.convertElevationFromMeters(diffM, altitudeUnit)!;
        final fmt = NumberFormat.decimalPattern();
        return progress < 1.0
            ? '${fmt.format(converted.round())} $altitudeUnit remaining'
            : '${fmt.format(converted.round())} $altitudeUnit exceeded';

      case MovingTimeThreshold(:final hours):
        final totalMicros = hours.inMicroseconds + (delay is MovingTimeThreshold ? delay.hours.inMicroseconds : 0);
        if (totalMicros <= 0) return null;
        final diff = Duration(microseconds: ((progress < 1.0 ? 1.0 - progress : progress - 1.0) * totalMicros).round());
        final label = progress < 1.0 ? 'remaining' : 'exceeded';
        final h = diff.inHours;
        final m = diff.inMinutes.remainder(60);
        return h > 0 ? '${h}h ${m}min $label' : '${m}min $label';

      case ElapsedTimeThreshold(:final hours):
        final totalMicros = hours.inMicroseconds + (delay is ElapsedTimeThreshold ? delay.hours.inMicroseconds : 0);
        if (totalMicros <= 0) return null;
        final diff = Duration(microseconds: ((progress < 1.0 ? 1.0 - progress : progress - 1.0) * totalMicros).round());
        final label = progress < 1.0 ? 'remaining' : 'exceeded';
        final h = diff.inHours;
        final m = diff.inMinutes.remainder(60);
        return h > 0 ? '${h}h ${m}min $label' : '${m}min $label';

      case DurationThreshold(:final days):
        final totalMicros = days.inMicroseconds + (delay is DurationThreshold ? delay.days.inMicroseconds : 0);
        if (totalMicros <= 0) return null;
        final diff = Duration(microseconds: ((progress < 1.0 ? 1.0 - progress : progress - 1.0) * totalMicros).round());
        final dayCount = diff.inDays;
        return '$dayCount ${_plural(dayCount, 'day')} ${progress < 1.0 ? 'remaining' : 'exceeded'}';

      case ActivityCountThreshold(:final count):
        final total = count + (delay is ActivityCountThreshold ? delay.count : 0);
        if (total <= 0) return null;
        final accumulated = (progress * total).round();
        final rides = progress < 1.0 ? total - accumulated : accumulated - total;
        return '$rides ${_plural(rides, 'ride')} ${progress < 1.0 ? 'remaining' : 'exceeded'}';

      case KilojoulesThreshold(:final kilojoules):
        final total = kilojoules + (delay is KilojoulesThreshold ? delay.kilojoules : 0.0);
        if (total <= 0) return null;
        final diff = (total - progress * total).abs();
        final fmt = NumberFormat.decimalPattern();
        return progress < 1.0
            ? '${fmt.format(diff.round())} kJ remaining'
            : '${fmt.format(diff.round())} kJ exceeded';

      case DateTimeThreshold(:final deadline):
        final effectiveDeadline = deadline.add(delay is DurationThreshold ? delay.days : Duration.zero);
        final now = DateTime.now().toUtc();
        final isBefore = now.isBefore(effectiveDeadline);
        final diff = isBefore ? effectiveDeadline.difference(now) : now.difference(effectiveDeadline);
        final days = diff.inDays;
        return '$days ${_plural(days, 'day')} ${isBefore ? 'remaining' : 'exceeded'}';
    }
  }
}
