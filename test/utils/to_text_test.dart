import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component_stats.dart';
import 'package:bike_setup_tracker/models/context/context_weather.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_comparison.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/utils/to_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../goldens/support/localized_test_app.dart';

void main() {
  final pressure = NumericalAdjustment(id: 'adj1', name: 'Pressure', notes: null, unit: null);
  final fork = Component(
    id: 'c1',
    name: 'Fork',
    installations: const [],
    componentType: ComponentType.fork,
    adjustments: [pressure],
  );
  final setup = Setup(
    id: 's1',
    name: 'Park day',
    datetime: DateTime.utc(2026, 5, 1, 10),
    datetimeLocal: DateTime(2026, 5, 1, 10),
    tags: const {},
    bike: 'b1',
    person: null,
    bikeAdjustmentValues: const {'adj1': NumericalValue(2.5)},
    personAdjustmentValues: const {},
    weather: ContextWeather(
      currentDateTime: DateTime(2026, 5, 1, 10),
      currentHumidity: 80,
      currentWindSpeed: 12,
    ),
  );
  final reference = Setup(
    id: 's0',
    name: 'Baseline',
    datetime: DateTime.utc(2026, 4, 1),
    datetimeLocal: DateTime(2026, 4, 1),
    tags: const {},
    bike: 'b1',
    person: null,
    bikeAdjustmentValues: const {},
    personAdjustmentValues: const {},
  );
  final rule = TaskRule(
    id: 'tr1',
    name: 'Service fork',
    tags: const {},
    association: const ComponentTaskAssociation('c1'),
  );
  final entry = TaskEntry(
    name: 'Serviced',
    dateTimeUTC: DateTime.utc(2026, 5, 2, 9),
    dateTimeLocal: DateTime(2026, 5, 2, 9),
    taskRule: 'tr1',
    association: const BikeTaskAssociation('b1'),
    snapshot: const ComponentStats(distance: 12345, movingTime: Duration(minutes: 90), activityCount: 1),
  );
  final feedback = RideFeedback(
    bike: 'b1',
    setupId: 's1',
    dateTimeUTC: DateTime.utc(2026, 5, 3, 12),
    dateTimeLocal: DateTime(2026, 5, 3, 12),
    comparisons: {
      FeedbackComparison(referenceSetupId: 's0', aspect: const OverallAspect(), outcome: 2),
    },
  );

  late AppSettings settings;

  setUpAll(() => initializeDateFormatting('de'));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings = AppSettings()
      ..enableTask = true
      ..enableRating = true;
  });

  tearDown(() => settings.dispose());

  Future<String> export(WidgetTester tester, Locale locale) async {
    late String text;
    final data = SelectedData(
      bikes: {'b1': Bike(id: 'b1', name: 'Hightower', person: null, isDeleted: true)},
      components: {'c1': fork},
      setups: {'s1': setup, 's0': reference},
      taskRules: {'tr1': rule},
      taskEntries: {entry.id: entry},
      feedbacks: {feedback.id: feedback},
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>.value(
        value: settings,
        child: localizedTestApp(
          locale: locale,
          home: Builder(
            builder: (context) {
              text = toText(context: context, selectedData: data);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return text;
  }

  testWidgets('keeps the English text', (tester) async {
    final text = await export(tester, const Locale('en'));

    expect(text, contains('BIKES:'));
    expect(text, contains('🚲 Hightower [DELETED]'));
    expect(text, contains('SETUPS:'));
    expect(text, contains('80 % Humidity'));
    expect(text, contains('12 km/h Wind'));
    expect(text, contains('- Pressure: 2.5'));
    expect(text, contains('TASK LOG:'));
    expect(text, contains('(Bike: Hightower)'));
    expect(text, contains('(Component: Fork)'));
    expect(text, contains('1 ride'));
    expect(text, contains('FEEDBACK:'));
    expect(text, contains('Better than Baseline'));
  });

  testWidgets('follows the language in headings, labels and numbers', (tester) async {
    final text = await export(tester, const Locale('de'));

    expect(text, contains('BIKES:'));
    expect(text, contains('🚲 Hightower [GELÖSCHT]'));
    expect(text, contains('80 % Luftfeuchtigkeit'));
    expect(text, contains('12 km/h Wind'));
    expect(text, contains('- Pressure: 2,5'));
    expect(text, contains('AUFGABENPROTOKOLL:'));
    expect(text, contains('(Bike: Hightower)'));
    expect(text, contains('(Komponente: Fork)'));
    expect(text, contains('1 Fahrt'));
    expect(text, isNot(contains('1 ride')));
    expect(text, isNot(contains('[DELETED]')));
    expect(text, isNot(contains('Humidity')));
  });

  testWidgets('does not change the app locale', (tester) async {
    await export(tester, const Locale('de'));

    expect(Intl.defaultLocale, isNot('de'));
  });
}
