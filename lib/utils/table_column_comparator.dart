import 'package:collection/collection.dart';

import '../models/adjustment/adjustment.dart';
import '../models/bike.dart';
import '../models/setup.dart';
import 'table_column.dart';

Comparator<Setup> _by<T extends Comparable<Object>>(T Function(Setup setup) key) =>
    (a, b) => key(a).compareTo(key(b));

Adjustment? adjustmentForColumn(
  TableColumn column,
  Iterable<Adjustment> componentAdjustments,
  Iterable<Adjustment> personAdjustments,
) => switch (column) {
  ComponentAdjustmentColumn(:final adjustmentId) => componentAdjustments.firstWhereOrNull((a) => a.id == adjustmentId),
  PersonAttributeColumn(:final adjustmentId) => personAdjustments.firstWhereOrNull((a) => a.id == adjustmentId),
  SetupTableColumn() || RatingMetricColumn() || RatingScoreColumn() => null,
};

Comparator<Setup>? tableColumnComparator(
  TableColumn column, {
  required AdjustmentValue? Function(Setup setup, TableColumn column) valueFor,
  required Iterable<Adjustment> componentAdjustments,
  required Iterable<Adjustment> personAdjustments,
  required Map<String, Bike> bikes,
  required Map<String, int> setupActivityCounts,
}) {
  switch (column) {
    case SetupTableColumn(column: final setupColumn):
      return setupColumnComparator(setupColumn, bikes: bikes, setupActivityCounts: setupActivityCounts);
    case RatingScoreColumn() || RatingMetricColumn():
      return _by((s) => valueFor(s, column)?.asNum ?? double.negativeInfinity);
    case ComponentAdjustmentColumn() || PersonAttributeColumn():
      final adjustment = adjustmentForColumn(column, componentAdjustments, personAdjustments);
      if (adjustment == null) return null;

      AdjustmentValue? value(Setup setup) => valueFor(setup, column);

      return switch (adjustment) {
        BooleanAdjustment() || StepAdjustment() || DurationAdjustment() => _by((s) => value(s)?.asNum ?? 0),
        NumericalAdjustment() => _by((s) => value(s)?.asNum ?? double.negativeInfinity),
        CategoricalAdjustment() || TextAdjustment() => _by((s) => value(s)?.display ?? ''),
      };
  }
}

Comparator<Setup> setupColumnComparator(
  SetupColumn column, {
  required Map<String, Bike> bikes,
  required Map<String, int> setupActivityCounts,
}) {
  return switch (column) {
    SetupColumn.name => _by((s) => s.displayName),
    SetupColumn.notes => _by((s) => s.notes ?? ''),
    SetupColumn.tags => _by((s) => s.tags.join('; ')),
    SetupColumn.date => _by((s) => s.datetime),
    SetupColumn.time => _by((s) => s.datetime.copyWith(year: 0, month: 0, day: 0)),
    SetupColumn.place => _by((s) => s.place?.locality ?? ''),
    SetupColumn.altitude => _by((s) => s.position?.altitude ?? double.negativeInfinity),
    SetupColumn.bike => _by((s) => bikes[s.bike]?.name ?? ''),
    SetupColumn.bookmarked => _by((s) => s.isBookmarked ? 1 : 0),
    SetupColumn.activities => _by((s) => setupActivityCounts[s.id] ?? 0),
    SetupColumn.weatherCode => _by((s) => s.weather?.getWeatherCodeLabel() ?? ''),
    SetupColumn.temperature => _by((s) => s.weather?.currentTemperature ?? double.negativeInfinity),
    SetupColumn.precipitation => _by((s) => s.weather?.dayAccumulatedPrecipitation ?? double.negativeInfinity),
    SetupColumn.humidity => _by((s) => s.weather?.currentHumidity ?? double.negativeInfinity),
    SetupColumn.windSpeed => _by((s) => s.weather?.currentWindSpeed ?? double.negativeInfinity),
    SetupColumn.soilMoisture => _by((s) => s.weather?.currentSoilMoisture0to7cm ?? double.negativeInfinity),
    SetupColumn.condition => _by((s) => s.weather?.condition?.value ?? ''),
  };
}
