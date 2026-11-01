import 'package:bike_setup_tracker/l10n/l10n.dart';
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
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/utils/to_spreadsheet.dart';
import 'package:excel/excel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final german = lookupAppLocalizations(const Locale('de'));
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
    isBookmarked: true,
    bikeAdjustmentValues: const {'adj1': NumericalValue(2.5)},
    personAdjustmentValues: const {},
    weather: ContextWeather(
      currentDateTime: DateTime(2026, 5, 1, 10),
      currentHumidity: 80,
      currentSoilMoisture0to7cm: 0.25,
    ),
  );
  final rule = TaskRule(
    id: 'tr1',
    name: 'Service fork',
    tags: const {},
    priority: TaskPriority.high,
    association: const ComponentTaskAssociation('c1'),
    interval: const DistanceThreshold(2500500),
  );
  final entry = TaskEntry(
    name: 'Serviced',
    dateTimeUTC: DateTime.utc(2026, 5, 2, 9),
    dateTimeLocal: DateTime(2026, 5, 2, 9),
    taskRule: 'tr1',
    association: const ComponentTaskAssociation('c1'),
    snapshot: const ComponentStats(distance: 12345, movingTime: Duration(minutes: 90), activityCount: 3),
  );
  final feedback = RideFeedback(
    bike: 'b1',
    setupId: 's1',
    dateTimeUTC: DateTime.utc(2026, 5, 3, 12),
    dateTimeLocal: DateTime(2026, 5, 3, 12),
    comparisons: {
      const FeedbackComparison(referenceSetupId: 's0', aspect: OverallAspect(), outcome: 2),
    },
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

  late AppSettings settings;
  late SelectedData data;

  setUpAll(() => initializeDateFormatting('de'));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings = AppSettings()
      ..enableTask = true
      ..enableRating = true;
    data = SelectedData(
      bikes: {'b1': Bike(id: 'b1', name: 'Hightower', person: null)},
      components: {'c1': fork},
      setups: {'s1': setup, 's0': reference},
      taskRules: {'tr1': rule},
      taskEntries: {entry.id: entry},
      feedbacks: {feedback.id: feedback},
    );
  });

  tearDown(() => settings.dispose());

  group('toCsv', () {
    test('keeps the English output', () {
      final csv = SpreadsheetExport.toCsv(data, settings, englishL10n);

      expect(csv, contains('"General"'));
      expect(csv, contains('"Name","DateTime","Tags","Notes","Place","Altitude [m]","Bookmarked","Bike"'));
      expect(csv, contains('"Humidity [%]"'));
      expect(csv, contains('"Yes"'));
      expect(csv, contains('"2.5"'));
      expect(csv, contains('"0.25"'));
      expect(csv, contains('"Task Log"'));
      expect(csv, contains('"Component: Fork"'));
      expect(csv, contains('"2,500.5 km"'));
      expect(csv, contains('"12.3","0","1.5","3"'));
      expect(csv, contains('"Compared to"'));
      expect(csv, contains('"Better"'));
    });

    test('follows the language in headers, labels and numbers', () {
      final csv = SpreadsheetExport.toCsv(data, settings, german);

      expect(csv, contains('"Allgemein"'));
      expect(csv, contains('"Name","Datum/Uhrzeit","Tags","Notizen","Ort","Höhe [m]","Mit Lesezeichen","Bike"'));
      expect(csv, contains('"Luftfeuchtigkeit [%]"'));
      expect(csv, contains('"Ja"'));
      expect(csv, contains('"2,5"'));
      expect(csv, contains('"0,25"'));
      expect(csv, contains('"Aufgabenprotokoll"'));
      expect(csv, contains('"Komponente: Fork"'));
      expect(csv, contains('"Priorität"'));
      expect(csv, contains('"2.500,5 km"'));
      expect(csv, contains('"12,3","0","1,5","3"'));
      expect(csv, contains('"Verglichen mit"'));
      expect(csv, contains('"Ergebnis"'));
    });

    test('writes dates the same way in every language', () {
      final english = SpreadsheetExport.toCsv(data, settings, englishL10n);
      final de = SpreadsheetExport.toCsv(data, settings, german);

      for (final csv in [english, de]) {
        expect(csv, contains('"2026-05-01 10:00"'));
        expect(csv, contains('"2026-05-02 09:00"'));
      }
    });
  });

  group('toExcel', () {
    test('names the sheets in the language', () {
      final english = Excel.decodeBytes(SpreadsheetExport.toExcel(data, settings, englishL10n)!);
      final de = Excel.decodeBytes(SpreadsheetExport.toExcel(data, settings, german)!);

      expect(english.sheets.keys, containsAll(['Task Log', 'Feedback']));
      expect(de.sheets.keys, containsAll(['Aufgabenprotokoll', 'Feedback']));
      expect(de.sheets.keys, isNot(contains('Task Log')));
    });

    test('translates the header rows', () {
      final workbook = Excel.decodeBytes(SpreadsheetExport.toExcel(data, settings, german)!);

      final taskHeaders = workbook['Aufgabenprotokoll'].rows.first.map((c) => c?.value.toString()).toList();
      expect(taskHeaders, containsAll(['Notizen', 'Verknüpfung', 'Aufgabenregel', 'Intervall']));
      final feedbackHeaders = workbook['Feedback'].rows.first.map((c) => c?.value.toString()).toList();
      expect(feedbackHeaders, containsAll(['Datum/Uhrzeit', 'Verglichen mit', 'Ergebnis', 'Probleme']));
    });

    test('names the sheet of an empty export in the language', () {
      final workbook = Excel.decodeBytes(SpreadsheetExport.toExcel(SelectedData(), settings, german)!);

      expect(workbook.sheets.keys, contains('Keine Daten'));
    });
  });
}
