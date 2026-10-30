import 'package:bike_setup_tracker/l10n/enum_labels.dart';
import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/context/context_weather.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/models/strava/strava_plan.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/tip_product.dart';
import 'package:bike_setup_tracker/utils/installation_issue.dart';
import 'package:bike_setup_tracker/utils/installation_timeline_validation.dart';
import 'package:bike_setup_tracker/utils/table_column.dart';
import 'package:drift/drift.dart' show EnumNameConverter;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final locales = {
    'en': lookupAppLocalizations(const Locale('en')),
    'de': lookupAppLocalizations(const Locale('de')),
  };

  void expectLabeled<T>(List<T> values, String Function(T value, AppLocalizations l10n) label) {
    for (final MapEntry(key: locale, value: l10n) in locales.entries) {
      for (final value in values) {
        expect(label(value, l10n), isNotEmpty, reason: '$value has no label in $locale');
      }
    }
  }

  group('every value has a label in en and de', () {
    test('ComponentTypeCategory', () => expectLabeled(ComponentTypeCategory.values, (v, l10n) => v.label(l10n)));
    test('ComponentType', () => expectLabeled(ComponentType.values, (v, l10n) => v.label(l10n)));
    test('UnitQuantity', () => expectLabeled(UnitQuantity.values, (v, l10n) => v.label(l10n)));
    test('TaskPriority', () => expectLabeled(TaskPriority.values, (v, l10n) => v.label(l10n)));
    test('StravaPlan', () {
      expectLabeled(StravaPlan.values, (v, l10n) => v.label(l10n));
      expectLabeled(StravaPlan.values, (v, l10n) => v.tagline(l10n));
      expectLabeled(StravaPlan.values, (v, l10n) => v.period(l10n));
    });
    test('StravaWorkoutType', () => expectLabeled(StravaWorkoutType.values, (v, l10n) => v.label(l10n)));
    test('SportType', () => expectLabeled(SportType.values, (v, l10n) => v.label(l10n)));
    test('Condition', () => expectLabeled(Condition.values, (v, l10n) => v.label(l10n)));
    test(
      'StepAdjustmentVisualization',
      () => expectLabeled(StepAdjustmentVisualization.values, (v, l10n) => v.label(l10n)),
    );
    test('TipProduct', () => expectLabeled(TipProduct.values, (v, l10n) => v.label(l10n)));
    test('InstallationIssue', () => expectLabeled(InstallationIssue.values, (v, l10n) => v.label(l10n)));
    test(
      'InstallationTimelineProblem',
      () => expectLabeled(InstallationTimelineProblem.values, (v, l10n) => v.label(l10n)),
    );
    test('SetupColumn', () => expectLabeled(SetupColumn.values, (v, l10n) => v.label(l10n)));
    test('TableColumnSection', () => expectLabeled(TableColumnSection.values, (v, l10n) => v.label(l10n)));
    test('weather codes', () {
      const codes = [0, 1, 2, 3, 45, 48, 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 71, 73, 75, 77, 80, 81, 82, 85, 86, 95, 96, 99];
      expectLabeled(codes, (code, l10n) => ContextWeather.getStaticWeatherCodeLabel(code, l10n)!);
      expect(ContextWeather.getStaticWeatherCodeLabel(null, locales['en']!), isNull);
    });
  });

  test('English labels keep the wording the app had before translation', () {
    final en = locales['en']!;
    expect(ComponentType.cockpit.label(en), 'Handlebar');
    expect(ComponentType.casette.label(en), 'Cassette');
    expect(ComponentType.wheelFront.label(en), 'Front Wheel');
    expect(UnitQuantity.springRate.label(en), 'Spring Rate');
    expect(StravaWorkoutType.none.label(en), 'Activity');
    expect(SportType.HighIntensityIntervalTraining.label(en), 'HIIT');
    expect(StepAdjustmentVisualization.minusButtonValuePlusButton.label(en), 'Plus/Minus Buttons');
    expect(SetupColumn.windSpeed.label(en), 'Windspeed');
    expect(TableColumnSection.personAttributes.label(en), 'Rider Attributes');
    expect(ContextWeather.getStaticWeatherCodeLabel(61, en), 'Slight rain');
    expect(ContextWeather.getStaticWeatherCodeLabel(7, en), 'Unknown');
    expect(StravaPlan.monthly.period(en), '/ month');
    expect(TipProduct.small.label(en), 'Buy me a coffee');
  });

  test('a component type inside a sentence is lowercase in English and keeps its capital in German', () {
    expect(ComponentType.fork.labelInSentence(locales['en']!), 'fork');
    expect(ComponentType.wheelFront.labelInSentence(locales['en']!), 'front wheel');
    expect(ComponentType.fork.labelInSentence(locales['de']!), 'Gabel');
  });

  test('German labels follow the glossary', () {
    final de = locales['de']!;
    expect(ComponentType.fork.label(de), 'Gabel');
    expect(ComponentType.shock.label(de), 'Dämpfer');
    expect(ComponentTypeCategory.suspension.label(de), 'Federung');
  });

  group('enums are persisted by name, never by label', () {
    test('component type in JSON and the database', () {
      for (final type in ComponentType.values) {
        final component = Component(id: 'c', name: 'c', componentType: type, installations: const []);
        expect(component.toJson()['componentType'], type.toString());
        expect(Component.fromJson(json: component.toJson()).componentType, type);
        expect(const EnumNameConverter(ComponentType.values).toSql(type), type.name);
      }
    });

    test('task priority in JSON and the database', () {
      for (final priority in TaskPriority.values) {
        final rule = TaskRule(name: 'r', tags: const {}, priority: priority);
        expect(rule.toJson()['priority'], priority.toString());
        expect(TaskRule.fromJson(rule.toJson()).priority, priority);
        expect(const EnumNameConverter(TaskPriority.values).toSql(priority), priority.name);
      }
    });

    test('weather condition in JSON', () {
      for (final condition in Condition.values) {
        final weather = ContextWeather(currentDateTime: DateTime.utc(2026), condition: condition);
        expect(weather.toJson()['condition'], condition.toString());
        expect(ContextWeather.fromJson(weather.toJson()).condition, condition);
      }
    });

    test('step visualization in JSON', () {
      for (final visualization in StepAdjustmentVisualization.values) {
        final adjustment = StepAdjustment(
          name: 'a',
          notes: null,
          unit: null,
          step: 1,
          min: 0,
          max: 10,
          visualization: visualization,
        );
        expect(adjustment.toJson()['visualization'], visualization.toString());
        expect(StepAdjustment.fromJson(adjustment.toJson()).visualization, visualization);
      }
    });

    test('unit quantity in the encoded unit', () {
      for (final quantity in UnitQuantity.values) {
        final unitId = unitCatalog[quantity]!.first.unitId;
        final unit = KnownUnit(quantity: quantity, unitId: unitId);
        expect(unit.encode(), '${quantity.name}:$unitId');
        expect(AdjustmentUnit.decode(unit.encode()), unit);
      }
    });

    test('sport type in the database', () {
      for (final type in SportType.values) {
        expect(const EnumNameConverter(SportType.values).toSql(type), type.name);
        expect(SportType.fromString(type.name), type);
      }
    });

    test('Strava plan in the entitlement', () {
      for (final plan in StravaPlan.values) {
        expect(StravaPlan.fromIosProductId(plan.iosProductId), plan);
        expect(StravaPlan.fromAndroidBasePlanId(plan.androidBasePlanId), plan);
      }
    });
  });
}
