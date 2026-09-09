import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/context/context_position.dart';
import 'package:bike_setup_tracker/models/context/context_weather.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/utils/table_column.dart';
import 'package:bike_setup_tracker/utils/table_column_comparator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart' as geo;

void main() {
  final bikes = {
    'bike-a': Bike(id: 'bike-a', name: 'Alpha', person: null),
    'bike-b': Bike(id: 'bike-b', name: 'Beta', person: null),
  };

  Setup buildSetup({
    required String id,
    String? name,
    String? notes,
    Set<String>? tags,
    DateTime? datetime,
    String bike = 'bike-a',
    bool isBookmarked = false,
    String? locality,
    double? altitude,
    ContextWeather? weather,
    Map<String, dynamic>? bikeAdjustmentValues,
  }) {
    final effectiveDatetime = datetime ?? DateTime.utc(2025, 1, 1, 12);
    return Setup(
      id: id,
      name: name,
      notes: notes,
      tags: tags ?? const {},
      datetime: effectiveDatetime,
      datetimeLocal: effectiveDatetime,
      bike: bike,
      person: null,
      isBookmarked: isBookmarked,
      bikeAdjustmentValues: bikeAdjustmentValues ?? const {},
      personAdjustmentValues: const {},
      place: locality == null ? null : geo.Placemark(locality: locality),
      position: altitude == null ? null : ContextPosition(latitude: 0, longitude: 0, altitude: altitude),
      weather: weather,
    );
  }

  ContextWeather buildWeather({
    double? temperature,
    double? humidity,
    double? windSpeed,
    double? precipitation,
    double? soilMoisture,
    int? weatherCode,
    Condition? condition,
  }) {
    return ContextWeather(
      currentDateTime: DateTime.utc(2025, 1, 1, 12),
      currentTemperature: temperature,
      currentHumidity: humidity,
      currentWindSpeed: windSpeed,
      dayAccumulatedPrecipitation: precipitation,
      currentSoilMoisture0to7cm: soilMoisture,
      currentWeatherCode: weatherCode,
      condition: condition,
    );
  }

  /// Sorts [setups] ascending by [column] and returns the resulting ids.
  List<String> sortedIds(SetupColumn column, List<Setup> setups, {Map<String, int> activityCounts = const {}}) {
    final sorted = setups.toList()
      ..sort(setupColumnComparator(column, bikes: bikes, setupActivityCounts: activityCounts));
    return sorted.map((s) => s.id).toList();
  }

  group('general context columns', () {
    test('name falls back to the placeholder for unnamed setups', () {
      final setups = [
        buildSetup(id: 'unnamed'),
        buildSetup(id: 'alpha', name: 'Alpha'),
      ];
      expect(sortedIds(SetupColumn.name, setups), ['alpha', 'unnamed']);
    });

    test('notes, tags and place treat null as empty', () {
      final withValues = buildSetup(id: 'filled', notes: 'zzz', tags: {'zeta'}, locality: 'Zurich');
      final empty = buildSetup(id: 'empty');

      expect(sortedIds(SetupColumn.notes, [withValues, empty]), ['empty', 'filled']);
      expect(sortedIds(SetupColumn.tags, [withValues, empty]), ['empty', 'filled']);
      expect(sortedIds(SetupColumn.place, [withValues, empty]), ['empty', 'filled']);
    });

    test('date sorts chronologically, time ignores the date', () {
      final early = buildSetup(id: 'early', datetime: DateTime.utc(2025, 3, 1, 18));
      final late = buildSetup(id: 'late', datetime: DateTime.utc(2025, 6, 1, 6));

      expect(sortedIds(SetupColumn.date, [late, early]), ['early', 'late']);
      expect(sortedIds(SetupColumn.time, [early, late]), ['late', 'early']);
    });

    test('altitude sorts missing positions first', () {
      final setups = [
        buildSetup(id: 'high', altitude: 1800),
        buildSetup(id: 'none'),
        buildSetup(id: 'low', altitude: 400),
      ];
      expect(sortedIds(SetupColumn.altitude, setups), ['none', 'low', 'high']);
    });

    test('bike sorts by bike name, bookmarked puts unmarked setups first', () {
      expect(
        sortedIds(SetupColumn.bike, [buildSetup(id: 'beta', bike: 'bike-b'), buildSetup(id: 'alpha')]),
        ['alpha', 'beta'],
      );
      expect(
        sortedIds(SetupColumn.bookmarked, [buildSetup(id: 'marked', isBookmarked: true), buildSetup(id: 'plain')]),
        ['plain', 'marked'],
      );
    });

    test('activities sorts by count and treats a missing count as zero', () {
      final setups = [buildSetup(id: 'many'), buildSetup(id: 'none'), buildSetup(id: 'few')];
      expect(
        sortedIds(SetupColumn.activities, setups, activityCounts: {'many': 7, 'few': 2}),
        ['none', 'few', 'many'],
      );
    });
  });

  group('weather context columns', () {
    // Each setup carries a low value in its own field and a high value in every
    // other field, so a comparator reading the wrong field reverses the order.
    Setup setupWithOnly(String id, SetupColumn column) {
      double v(SetupColumn c) => c == column ? 1 : 100;
      return buildSetup(
        id: id,
        weather: buildWeather(
          temperature: v(SetupColumn.temperature),
          humidity: v(SetupColumn.humidity),
          windSpeed: v(SetupColumn.windSpeed),
          precipitation: v(SetupColumn.precipitation),
          soilMoisture: v(SetupColumn.soilMoisture),
        ),
      );
    }

    for (final column in [
      SetupColumn.temperature,
      SetupColumn.humidity,
      SetupColumn.windSpeed,
      SetupColumn.precipitation,
      SetupColumn.soilMoisture,
    ]) {
      test('${column.label} sorts by its own field', () {
        final low = setupWithOnly('low', column);
        final high = buildSetup(
          id: 'high',
          weather: buildWeather(
            temperature: 50,
            humidity: 50,
            windSpeed: 50,
            precipitation: 50,
            soilMoisture: 50,
          ),
        );
        expect(sortedIds(column, [high, low]), ['low', 'high']);
      });

      test('${column.label} sorts setups without weather first', () {
        final setups = [setupWithOnly('weather', column), buildSetup(id: 'none')];
        expect(sortedIds(column, setups), ['none', 'weather']);
      });
    }

    test('weather code sorts by its label', () {
      final setups = [
        buildSetup(id: 'coded', weather: buildWeather(weatherCode: 0)),
        buildSetup(id: 'none'),
      ];
      expect(sortedIds(SetupColumn.weatherCode, setups), ['none', 'coded']);
    });

    test('condition sorts by its label', () {
      final setups = [
        buildSetup(
          id: 'wet',
          weather: buildWeather(condition: Condition.wet),
        ),
        buildSetup(
          id: 'dry',
          weather: buildWeather(condition: Condition.dry),
        ),
      ];
      expect(sortedIds(SetupColumn.condition, setups), ['dry', 'wet']);
    });
  });

  group('tableColumnComparator', () {
    final numerical = NumericalAdjustment(id: 'sag', name: 'Sag', notes: null, unit: null);
    final boolean = BooleanAdjustment(id: 'lockout', name: 'Lockout', notes: null, unit: null);

    Setup withAdjustments(String id, Map<String, dynamic> values) => buildSetup(id: id, bikeAdjustmentValues: values);

    List<String> sortedByColumn(TableColumn column, List<Setup> setups) {
      final comparator = tableColumnComparator(
        column,
        valueFor: (setup, column) => switch (column) {
          ComponentAdjustmentColumn(:final adjustmentId) => setup.bikeAdjustmentValues[adjustmentId],
          RatingScoreColumn() => setup.bikeAdjustmentValues['score'],
          _ => null,
        },
        componentAdjustments: [numerical, boolean],
        personAdjustments: const [],
        bikes: bikes,
        setupActivityCounts: const {},
      );
      final sorted = setups.toList()..sort(comparator!);
      return sorted.map((s) => s.id).toList();
    }

    test('numerical adjustments sort numerically, not lexically', () {
      final setups = [
        withAdjustments('nine', {'sag': 9.0}),
        withAdjustments('eleven', {'sag': 11.0}),
        withAdjustments('missing', const {}),
      ];
      expect(
        sortedByColumn(ComponentAdjustmentColumn('sag', active: true), setups),
        ['missing', 'nine', 'eleven'],
      );
    });

    test('boolean adjustments sort false before true, missing counts as false', () {
      final setups = [
        withAdjustments('on', {'lockout': true}),
        withAdjustments('missing', const {}),
      ];
      expect(
        sortedByColumn(ComponentAdjustmentColumn('lockout', active: true), setups),
        ['missing', 'on'],
      );
    });

    test('rating columns sort unscored setups first', () {
      final setups = [
        withAdjustments('scored', {'score': 7.5}),
        withAdjustments('unscored', const {}),
      ];
      expect(sortedByColumn(RatingScoreColumn(active: true), setups), ['unscored', 'scored']);
    });

    test('returns null for an adjustment column whose adjustment is gone', () {
      final comparator = tableColumnComparator(
        ComponentAdjustmentColumn('deleted', active: true),
        valueFor: (setup, column) => null,
        componentAdjustments: [numerical],
        personAdjustments: const [],
        bikes: bikes,
        setupActivityCounts: const {},
      );
      expect(comparator, isNull);
    });
  });
}
