import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_template.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/utils/task_preset_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

Component component(ComponentType type, {String id = 'c1'}) =>
    Component(id: id, name: type.label, installations: const [], componentType: type);

TaskRule rule({required String name, String? presetKey, String componentId = 'c1', bool isDeleted = false}) => TaskRule(
  name: name,
  tags: const {},
  association: ComponentTaskAssociation(componentId),
  presetKey: presetKey,
  isDeleted: isDeleted,
);

List<String> keys(List<TaskSuggestion> suggestions) => [for (final s in suggestions) s.key];

void main() {
  group('isTaskPresetConsumed', () {
    test('no rules means nothing is consumed', () {
      expect(isTaskPresetConsumed('chain:replace', const []), isFalse);
    });

    test('a rule with the key consumes it, whatever its name', () {
      expect(isTaskPresetConsumed('chain:replace', [rule(name: 'Kette tauschen', presetKey: 'chain:replace')]), isTrue);
    });

    test('a deleted rule does not consume it', () {
      expect(isTaskPresetConsumed('chain:replace', [rule(name: 'Replace chain', presetKey: 'chain:replace', isDeleted: true)]), isFalse);
    });

    test('a same-named rule without the key does not consume it', () {
      expect(isTaskPresetConsumed('chain:replace', [rule(name: 'Replace chain')]), isFalse);
    });
  });

  group('taskSuggestionsFor', () {
    final chain = component(ComponentType.chain);

    test('with Strava, activity intervals are used', () {
      final suggestions = taskSuggestionsFor(chain, existingRules: const [], hasStravaEntitlement: true);

      expect(keys(suggestions), ['chain:wear_check', 'chain:replace', 'chain:lube']);
      expect(suggestions.first.interval, const DistanceThreshold(500000));
      expect(suggestions.every((s) => !s.isFallback), isTrue);
    });

    test('without Strava, fallbacks are used and templates without one are hidden', () {
      final suggestions = taskSuggestionsFor(chain, existingRules: const [], hasStravaEntitlement: false);

      expect(keys(suggestions), ['chain:wear_check']);
      expect(suggestions.single.interval, const DurationThreshold(Duration(days: 30)));
      expect(suggestions.single.stravaInterval, const DistanceThreshold(500000));
      expect(suggestions.single.isFallback, isTrue);
    });

    test('a time-based template is used as is without Strava', () {
      final suggestions = taskSuggestionsFor(component(ComponentType.tire), existingRules: const [], hasStravaEntitlement: false);

      expect(keys(suggestions), ['tire:sealant']);
      expect(suggestions.single.isFallback, isFalse);
    });

    test('a component type without templates has no suggestions', () {
      expect(taskSuggestionsFor(component(ComponentType.saddle), existingRules: const [], hasStravaEntitlement: true), isEmpty);
    });

    test('carries the preselected flag', () {
      final suggestions = taskSuggestionsFor(chain, existingRules: const [], hasStravaEntitlement: true);

      expect({for (final s in suggestions) s.key: s.preselected}, {'chain:wear_check': true, 'chain:replace': false, 'chain:lube': false});
    });

    test('front and rear wheels share their templates', () {
      final front = taskSuggestionsFor(component(ComponentType.wheelFront), existingRules: const [], hasStravaEntitlement: true);
      final rear = taskSuggestionsFor(component(ComponentType.wheelRear), existingRules: const [], hasStravaEntitlement: true);

      expect(keys(front), ['wheel:spoke_tension', 'wheel:hub_bearing']);
      expect(keys(rear), keys(front));
    });

    group('consumption', () {
      test('consumed keys disappear, even when the rule was renamed', () {
        final suggestions = taskSuggestionsFor(
          chain,
          existingRules: [rule(name: 'Kette tauschen', presetKey: 'chain:replace')],
          hasStravaEntitlement: true,
        );

        expect(keys(suggestions), ['chain:wear_check', 'chain:lube']);
      });

      test('deleted rules do not consume', () {
        final suggestions = taskSuggestionsFor(
          chain,
          existingRules: [rule(name: 'Replace chain', presetKey: 'chain:replace', isDeleted: true)],
          hasStravaEntitlement: true,
        );

        expect(keys(suggestions), contains('chain:replace'));
      });

      test("another component's rules do not consume", () {
        final suggestions = taskSuggestionsFor(
          chain,
          existingRules: [rule(name: 'Replace chain', presetKey: 'chain:replace', componentId: 'c2')],
          hasStravaEntitlement: true,
        );

        expect(keys(suggestions), contains('chain:replace'));
      });
    });

    group('overrides', () {
      final fork = component(ComponentType.fork);
      const foxSource = "FOX 36 owner's manual";

      test('replace the interval and the source of a generic key', () {
        final suggestions = taskSuggestionsFor(
          fork,
          existingRules: const [],
          hasStravaEntitlement: true,
          overrides: const {
            'fork:lower_leg_service': TaskTemplateOverride(interval: MovingTimeThreshold(Duration(hours: 125)), source: foxSource),
          },
        );

        final lowerLeg = suggestions.firstWhere((s) => s.key == 'fork:lower_leg_service');
        expect(lowerLeg.interval, const MovingTimeThreshold(Duration(hours: 125)));
        expect(lowerLeg.source, foxSource);
        expect(lowerLeg.name, 'Lower leg service');
        expect(suggestions.firstWhere((s) => s.key == 'fork:full_service').source, isNull);
      });

      test('without Strava, an override without fallback leaves the generic template unchanged', () {
        final suggestions = taskSuggestionsFor(
          fork,
          existingRules: const [],
          hasStravaEntitlement: false,
          overrides: const {
            'fork:lower_leg_service': TaskTemplateOverride(interval: MovingTimeThreshold(Duration(hours: 125)), source: foxSource),
          },
        );

        final lowerLeg = suggestions.firstWhere((s) => s.key == 'fork:lower_leg_service');
        expect(lowerLeg.interval, const DurationThreshold(Duration(days: 180)));
        expect(lowerLeg.stravaInterval, const MovingTimeThreshold(Duration(hours: 50)));
        expect(lowerLeg.source, isNull);
        expect(lowerLeg.toTaskRule('c1').notes, endsWith('Recommended interval: every 6 months (time-based; every 50 h with Strava)'));
      });

      test("without Strava, an override's own fallback applies with its source", () {
        final suggestions = taskSuggestionsFor(
          fork,
          existingRules: const [],
          hasStravaEntitlement: false,
          overrides: const {
            'fork:full_service': TaskTemplateOverride(
              interval: MovingTimeThreshold(Duration(hours: 125)),
              fallbackInterval: DurationThreshold(Duration(days: 365)),
              source: foxSource,
            ),
          },
        );

        final full = suggestions.firstWhere((s) => s.key == 'fork:full_service');
        expect(full.interval, const DurationThreshold(Duration(days: 365)));
        expect(full.stravaInterval, const MovingTimeThreshold(Duration(hours: 125)));
        expect(full.source, foxSource);
      });

      test('a brand-only key is added after the generic templates', () {
        final suggestions = taskSuggestionsFor(
          fork,
          existingRules: const [],
          hasStravaEntitlement: true,
          overrides: const {
            'fork:air_spring_service': TaskTemplateOverride(
              name: 'Air spring service',
              interval: MovingTimeThreshold(Duration(hours: 125)),
              source: foxSource,
              preselected: true,
            ),
          },
        );

        expect(keys(suggestions), ['fork:lower_leg_service', 'fork:full_service', 'fork:air_spring_service']);
        expect(suggestions.last.name, 'Air spring service');
        expect(suggestions.last.preselected, isTrue);
        expect(suggestions.last.source, foxSource);
      });

      test('a brand-only key without fallback is hidden without Strava', () {
        final suggestions = taskSuggestionsFor(
          fork,
          existingRules: const [],
          hasStravaEntitlement: false,
          overrides: const {
            'fork:air_spring_service': TaskTemplateOverride(
              name: 'Air spring service',
              interval: MovingTimeThreshold(Duration(hours: 125)),
              source: foxSource,
            ),
          },
        );

        expect(keys(suggestions), isNot(contains('fork:air_spring_service')));
      });

      test('a brand-only key without a name is ignored', () {
        final suggestions = taskSuggestionsFor(
          fork,
          existingRules: const [],
          hasStravaEntitlement: true,
          overrides: const {
            'fork:air_spring_service': TaskTemplateOverride(interval: MovingTimeThreshold(Duration(hours: 125)), source: foxSource),
          },
        );

        expect(keys(suggestions), ['fork:lower_leg_service', 'fork:full_service']);
      });
    });
  });

  group('TaskSuggestion.toTaskRule', () {
    test('sets the association, the preset key and the generic source line', () {
      final suggestion = taskSuggestionsFor(
        component(ComponentType.chain),
        existingRules: const [],
        hasStravaEntitlement: true,
      ).firstWhere((s) => s.key == 'chain:replace');

      final created = suggestion.toTaskRule('c9');

      expect(created.association, const ComponentTaskAssociation('c9'));
      expect(created.presetKey, 'chain:replace');
      expect(created.name, 'Replace chain');
      expect(created.priority, TaskPriority.high);
      expect(created.repeat, isTrue);
      expect(created.interval, const DistanceThreshold(2000000));
      expect(created.notes, isNull);
    });

    test('keeps the template notes without an interval line for a generic interval', () {
      final suggestion = taskSuggestionsFor(
        component(ComponentType.chain),
        existingRules: const [],
        hasStravaEntitlement: true,
      ).firstWhere((s) => s.key == 'chain:wear_check');

      expect(suggestion.toTaskRule('c1').notes, suggestion.notes);
    });

    test('uses the fallback wording without Strava', () {
      final suggestion = taskSuggestionsFor(component(ComponentType.chain), existingRules: const [], hasStravaEntitlement: false).single;

      final created = suggestion.toTaskRule('c1');

      expect(created.interval, const DurationThreshold(Duration(days: 30)));
      expect(created.notes, endsWith('Recommended interval: every month (time-based; every 500 km with Strava)'));
    });

    test('names the override source', () {
      final suggestion = taskSuggestionsFor(
        component(ComponentType.fork),
        existingRules: const [],
        hasStravaEntitlement: true,
        overrides: const {
          'fork:lower_leg_service': TaskTemplateOverride(
            interval: MovingTimeThreshold(Duration(hours: 125)),
            source: "FOX 36 owner's manual https://example.com/fox36",
          ),
        },
      ).first;

      expect(
        suggestion.toTaskRule('c1').notes,
        endsWith("Recommended interval: every 125 h — FOX 36 owner's manual https://example.com/fox36"),
      );
    });

    test('formats the source line in the given distance unit', () {
      final suggestion = taskSuggestionsFor(component(ComponentType.chain), existingRules: const [], hasStravaEntitlement: false).single;

      expect(suggestion.toTaskRule('c1', distanceUnit: 'mi').notes, contains('every 310.7 mi with Strava'));
    });
  });
}
