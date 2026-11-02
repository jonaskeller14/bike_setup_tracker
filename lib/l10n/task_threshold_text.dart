import 'package:intl/intl.dart';

import '../models/task/task_threshold/task_threshold.dart';
import 'app_localizations.dart';

extension TaskThresholdText on TaskThreshold {
  /// "2,000 km", "6 months", "12 Mar 2026", in the language of [l10n].
  String toDisplayValue(
    AppLocalizations l10n, {
    String distanceUnit = 'km',
    String altitudeUnit = 'm',
    String dateFormat = 'yyyy-MM-dd',
    String? numberLocale,
  }) {
    final locale = numberLocale ?? l10n.localeName;
    final grouped = NumberFormat.decimalPattern(locale);
    return switch (this) {
      DistanceThreshold(:final meters) =>
        '${NumberFormat('#,##0.#', locale).format(distanceUnit == 'mi' ? meters / 1609.344 : meters / 1000)} $distanceUnit',
      ElevationThreshold(:final meters) =>
        '${grouped.format((altitudeUnit == 'ft' ? meters * 3.28084 : meters).round())} $altitudeUnit',
      MovingTimeThreshold(:final hours) || ElapsedTimeThreshold(:final hours) => '${grouped.format(hours.inHours)} h',
      DurationThreshold(:final days) => '${grouped.format(days.inDays)} ${l10n.taskUnitDays(days.inDays)}',
      ActivityCountThreshold(:final count) => '${grouped.format(count)} ${l10n.taskUnitRides(count)}',
      KilojoulesThreshold(:final kilojoules) => '${grouped.format(kilojoules.round())} kJ',
      DateTimeThreshold(:final deadline) => DateFormat(dateFormat, l10n.localeName).format(deadline.toLocal()),
    };
  }
}

/// "every 2,000 km", "every 6 months", "every year", in the language of [l10n].
String taskIntervalLabel(
  TaskThreshold interval,
  AppLocalizations l10n, {
  String distanceUnit = 'km',
  String altitudeUnit = 'm',
}) {
  if (interval is DurationThreshold) {
    final days = interval.days.inDays;
    for (final (dayCount, label) in [
      (365, l10n.taskIntervalEveryYears),
      (30, l10n.taskIntervalEveryMonths),
      (7, l10n.taskIntervalEveryWeeks),
      (1, l10n.taskIntervalEveryDays),
    ]) {
      if (days < dayCount || days % dayCount != 0) continue;
      return label(days ~/ dayCount);
    }
  }
  return l10n.taskIntervalEvery(interval.toDisplayValue(l10n, distanceUnit: distanceUnit, altitudeUnit: altitudeUnit));
}
