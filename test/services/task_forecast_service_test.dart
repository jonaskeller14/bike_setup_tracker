import 'package:bike_setup_tracker/models/activity_rate_window.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/component_stats.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/services/task_forecast_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskForecastService.predict', () {
    final now = DateTime.utc(2024, 6, 1);
    const bikeId = 'bike-1';
    const componentId = 'comp-1';

    /// A window of [count] activities covering [span] and ending [idle] ago.
    ActivityRateWindow window({
      double distance = 0,
      double elevationGain = 0,
      Duration movingTime = Duration.zero,
      Duration elapsedTime = Duration.zero,
      int count = 10,
      Duration span = const Duration(days: 10),
      Duration idle = Duration.zero,
    }) {
      final lastStart = now.subtract(idle);
      return ActivityRateWindow(
        sum: ComponentStats(
          distance: distance,
          elevationGain: elevationGain,
          movingTime: movingTime,
          elapsedTime: elapsedTime,
          activityCount: count,
        ),
        firstStart: lastStart.subtract(span),
        lastStart: lastStart,
        count: count,
      );
    }

    Component component(List<Installation> installations) => Component(
      id: componentId,
      name: 'Chain',
      componentType: ComponentType.other,
      installations: installations,
    );

    Installation installedOn(String bike, {required Duration ago}) => BikeInstallation(
      bikeId: bike,
      componentId: componentId,
      dateTimeUTC: now.subtract(ago),
      dateTimeLocal: now.subtract(ago),
    );

    group('Distance interval', () {
      final rule = TaskRule(
        name: 'Chain Wax',
        association: const BikeTaskAssociation(bikeId),
        interval: const DistanceThreshold(300000), // 300 km
        tags: const {},
      );

      test('Remaining distance divided by the window rate', () {
        // 200 km over 10 days = 20 km/day, with 200 km still to go.
        final forecast = TaskForecastService.predict(
          rule: rule,
          currentStats: ComponentStats.zero().copyWith(distance: 100000),
          now: now,
          bikeRates: {bikeId: window(distance: 200000)},
        );

        expect(forecast, isNotNull);
        expect(forecast!.dueDate, now.add(const Duration(days: 10)));
        expect(forecast.sample?.count, 10);
      });

      test('Fractional days are kept at sub-day resolution', () {
        // 150 km remaining at 20 km/day = 7.5 days.
        final forecast = TaskForecastService.predict(
          rule: rule,
          currentStats: ComponentStats.zero().copyWith(distance: 150000),
          now: now,
          bikeRates: {bikeId: window(distance: 200000)},
        );

        expect(forecast!.dueDate, now.add(const Duration(days: 7, hours: 12)));
      });

      test('Only the delta since the last entry counts', () {
        final entry = TaskEntry(
          name: 'Waxed',
          taskRule: rule.id,
          dateTimeUTC: now.subtract(const Duration(days: 5)),
          dateTimeLocal: now.subtract(const Duration(days: 5)),
          snapshot: ComponentStats.zero().copyWith(distance: 500000),
        );

        // 600 km on the clock, 500 km at the last wax: 100 km done, 200 km to go.
        final forecast = TaskForecastService.predict(
          rule: rule,
          currentStats: ComponentStats.zero().copyWith(distance: 600000),
          now: now,
          bikeRates: {bikeId: window(distance: 200000)},
          lastEntry: entry,
        );

        expect(forecast!.dueDate, now.add(const Duration(days: 10)));
      });

      test('Idle time since the last ride slows the pace', () {
        // The same 200 km, but the bike has sat for 10 days: 20 days of
        // calendar time for the sample, so 10 km/day and 200 km still to go.
        final forecast = TaskForecastService.predict(
          rule: rule,
          currentStats: ComponentStats.zero().copyWith(distance: 100000),
          now: now,
          bikeRates: {bikeId: window(distance: 200000, idle: const Duration(days: 10))},
        );

        expect(forecast!.dueDate, now.add(const Duration(days: 20)));
      });

      test('A delay of the same kind pushes the target out', () {
        final delayed = rule.copyWith(delay: const DistanceThreshold(50000));

        // 350 km target, 100 km done: 250 km at 20 km/day = 12.5 days.
        final forecast = TaskForecastService.predict(
          rule: delayed,
          currentStats: ComponentStats.zero().copyWith(distance: 100000),
          now: now,
          bikeRates: {bikeId: window(distance: 200000)},
        );

        expect(forecast!.dueDate, now.add(const Duration(days: 12, hours: 12)));
      });
    });

    group('No prediction', () {
      final rule = TaskRule(
        name: 'Chain Wax',
        association: const BikeTaskAssociation(bikeId),
        interval: const DistanceThreshold(300000),
        tags: const {},
      );

      TaskForecast? predictFor({
        required TaskRule rule,
        ComponentStats? currentStats,
        Map<String, ActivityRateWindow>? bikeRates,
        TaskEntry? lastEntry,
      }) {
        return TaskForecastService.predict(
          rule: rule,
          currentStats: currentStats ?? ComponentStats.zero(),
          now: now,
          bikeRates: bikeRates ?? {bikeId: window(distance: 200000)},
          lastEntry: lastEntry,
        );
      }

      test('Plain todo without an interval', () {
        expect(
          predictFor(
            rule: TaskRule(name: 'Buy bar tape', tags: const {}),
          ),
          isNull,
        );
      });

      test('Rule that is already due', () {
        expect(predictFor(rule: rule, currentStats: ComponentStats.zero().copyWith(distance: 300000)), isNull);
      });

      test('Rule that is overdue', () {
        expect(predictFor(rule: rule, currentStats: ComponentStats.zero().copyWith(distance: 400000)), isNull);
      });

      test('Completed one-off rule', () {
        final entry = TaskEntry(
          name: 'Done',
          taskRule: rule.id,
          dateTimeUTC: now,
          dateTimeLocal: now,
          snapshot: ComponentStats.zero(),
        );
        expect(predictFor(rule: rule.copyWith(repeat: false), lastEntry: entry), isNull);
      });

      test('No window for the bike at all', () {
        expect(predictFor(rule: rule, bikeRates: const {}), isNull);
      });

      test('Zero rate: the bike is linked but was not ridden', () {
        expect(predictFor(rule: rule, bikeRates: {bikeId: window()}), isNull);
      });

      test('Fewer samples than the minimum', () {
        expect(predictFor(rule: rule, bikeRates: {bikeId: window(distance: 200000, count: 1)}), isNull);
      });

      test('Span below the minimum: one busy weekend', () {
        expect(
          predictFor(
            rule: rule,
            bikeRates: {bikeId: window(distance: 200000, count: 5, span: const Duration(days: 2))},
          ),
          isNull,
        );
      });

      test('A burst that ended days ago is still too bunched up to use', () {
        // now - firstStart is 7 days, but the rides themselves cover 2.
        expect(
          predictFor(
            rule: rule,
            bikeRates: {
              bikeId: window(
                distance: 200000,
                count: 5,
                span: const Duration(days: 2),
                idle: const Duration(days: 5),
              ),
            },
          ),
          isNull,
        );
      });

      test('Span exactly at the minimum still predicts', () {
        // 200 km over 3 days = 66.67 km/day, with 300 km to go = 4.5 days.
        final forecast = predictFor(
          rule: rule,
          bikeRates: {bikeId: window(distance: 200000, count: 5, span: const Duration(days: 3))},
        );

        expect(forecast!.dueDate, now.add(const Duration(days: 4, hours: 12)));
      });
    });

    group('Rate source resolution', () {
      final rule = TaskRule(
        name: 'Chain Wax',
        association: const ComponentTaskAssociation(componentId),
        interval: const DistanceThreshold(300000),
        tags: const {},
      );

      final rates = {
        'bike-slow': window(distance: 100000), // 10 km/day
        'bike-fast': window(distance: 300000), // 30 km/day
      };

      test('A component forecasts at the rate of the bike it is on', () {
        final forecast = TaskForecastService.predict(
          rule: rule,
          currentStats: ComponentStats.zero(),
          now: now,
          bikeRates: rates,
          component: component([installedOn('bike-slow', ago: const Duration(days: 100))]),
        );

        expect(forecast!.dueDate, now.add(const Duration(days: 30)));
      });

      test('A component just moved to a busier bike forecasts at the new rate', () {
        final forecast = TaskForecastService.predict(
          rule: rule,
          currentStats: ComponentStats.zero(),
          now: now,
          bikeRates: rates,
          component: component([
            installedOn('bike-slow', ago: const Duration(days: 100)),
            installedOn('bike-fast', ago: const Duration(days: 1)),
          ]),
        );

        expect(forecast!.dueDate, now.add(const Duration(days: 10)));
      });

      test('An uninstalled component accrues nothing and gets no forecast', () {
        final forecast = TaskForecastService.predict(
          rule: rule,
          currentStats: ComponentStats.zero(),
          now: now,
          bikeRates: rates,
          component: component([
            installedOn('bike-fast', ago: const Duration(days: 100)),
            Uninstallation(componentId: componentId, dateTimeUTC: now, dateTimeLocal: now),
          ]),
        );

        expect(forecast, isNull);
      });

      test('An archived component gets no forecast', () {
        final forecast = TaskForecastService.predict(
          rule: rule,
          currentStats: ComponentStats.zero(),
          now: now,
          bikeRates: rates,
          component: component([
            installedOn('bike-fast', ago: const Duration(days: 100)),
            Archival(componentId: componentId, dateTimeUTC: now, dateTimeLocal: now),
          ]),
        );

        expect(forecast, isNull);
      });
    });

    group('Other interval kinds', () {
      test('Duration interval is exact and needs no sample', () {
        final rule = TaskRule(
          name: 'Monthly check',
          association: const BikeTaskAssociation(bikeId),
          interval: const DurationThreshold(Duration(days: 30)),
          tags: const {},
        );

        final forecast = TaskForecastService.predict(
          rule: rule,
          currentStats: ComponentStats.zero(),
          now: now,
          bikeRates: const {},
          componentInstallationDate: now.subtract(const Duration(days: 10, hours: 6)),
        );

        expect(forecast!.dueDate, now.add(const Duration(days: 19, hours: 18)));
        expect(forecast.sample, isNull);
      });

      test('DateTime interval short-circuits to its own deadline', () {
        final deadline = now.add(const Duration(days: 40));
        final rule = TaskRule(
          name: 'Service booking',
          interval: DateTimeThreshold(deadline),
          tags: const {},
        );

        final forecast = TaskForecastService.predict(
          rule: rule,
          currentStats: ComponentStats.zero(),
          now: now,
          bikeRates: const {},
        );

        expect(forecast!.dueDate, deadline);
        expect(forecast.sample, isNull);
      });

      test('A duration delay moves the deadline out', () {
        final deadline = now.add(const Duration(days: 40));
        final rule = TaskRule(
          name: 'Service booking',
          interval: DateTimeThreshold(deadline),
          delay: const DurationThreshold(Duration(days: 5)),
          tags: const {},
        );

        final forecast = TaskForecastService.predict(
          rule: rule,
          currentStats: ComponentStats.zero(),
          now: now,
          bikeRates: const {},
        );

        expect(forecast!.dueDate, deadline.add(const Duration(days: 5)));
      });

      test('A deadline in the past is not forecast', () {
        final rule = TaskRule(
          name: 'Service booking',
          interval: DateTimeThreshold(now.subtract(const Duration(days: 1))),
          tags: const {},
        );

        expect(
          TaskForecastService.predict(
            rule: rule,
            currentStats: ComponentStats.zero(),
            now: now,
            bikeRates: const {},
          ),
          isNull,
        );
      });

      test('Ride count rates below one per day survive', () {
        // 5 rides over 10 days = 0.5 rides/day, with 10 rides to go = 20 days.
        final rule = TaskRule(
          name: 'Check bolts',
          association: const BikeTaskAssociation(bikeId),
          interval: const ActivityCountThreshold(10),
          tags: const {},
        );

        final forecast = TaskForecastService.predict(
          rule: rule,
          currentStats: ComponentStats.zero(),
          now: now,
          bikeRates: {bikeId: window(count: 5)},
        );

        expect(forecast!.dueDate, now.add(const Duration(days: 20)));
      });

      test('Moving time interval uses the window moving time', () {
        // 10 h over 10 days = 1 h/day, with 20 h to go = 20 days.
        final rule = TaskRule(
          name: 'Suspension service',
          association: const BikeTaskAssociation(bikeId),
          interval: const MovingTimeThreshold(Duration(hours: 20)),
          tags: const {},
        );

        final forecast = TaskForecastService.predict(
          rule: rule,
          currentStats: ComponentStats.zero(),
          now: now,
          bikeRates: {bikeId: window(movingTime: const Duration(hours: 10))},
        );

        expect(forecast!.dueDate, now.add(const Duration(days: 20)));
      });

      test('Elevation interval uses the window elevation', () {
        // 10000 m over 10 days = 1000 m/day, with 5000 m to go = 5 days.
        final rule = TaskRule(
          name: 'Brake pads',
          association: const BikeTaskAssociation(bikeId),
          interval: const ElevationThreshold(5000),
          tags: const {},
        );

        final forecast = TaskForecastService.predict(
          rule: rule,
          currentStats: ComponentStats.zero(),
          now: now,
          bikeRates: {bikeId: window(elevationGain: 10000)},
        );

        expect(forecast!.dueDate, now.add(const Duration(days: 5)));
      });
    });
  });
}

extension on ComponentStats {
  ComponentStats copyWith({
    double? distance,
    double? elevationGain,
    Duration? movingTime,
    Duration? elapsedTime,
    int? activityCount,
  }) {
    return ComponentStats(
      distance: distance ?? this.distance,
      elevationGain: elevationGain ?? this.elevationGain,
      movingTime: movingTime ?? this.movingTime,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      activityCount: activityCount ?? this.activityCount,
    );
  }
}
