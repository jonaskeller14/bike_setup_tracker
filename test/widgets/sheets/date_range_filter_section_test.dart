import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/filters/local_date_range.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/repositories/filter_controller.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/filter_actions.dart';
import 'package:bike_setup_tracker/widgets/sheets/filter/date_range_filter_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifies like the real repository, so the section rebuilds on a filter change.
class _FakeAppRepository extends ChangeNotifier implements AppRepository {
  @override
  late final FilterController filters = FilterController(onChanged: notifyListeners);

  @override
  DateTime? firstEntryDay;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeAppRepository repository;
  late FilterController filters;
  late AppSettings settings;

  final may = LocalDateRange(start: DateTime(2024, 5, 10), end: DateTime(2024, 5, 12));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = _FakeAppRepository();
    filters = repository.filters;
    settings = AppSettings();
  });

  tearDown(() {
    settings.dispose();
    repository.dispose();
  });

  Future<void> pumpSection(WidgetTester tester, {ThemeData? theme}) => tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider<AppRepository>.value(value: repository),
      ],
      child: MaterialApp(
        theme: theme ?? materialAppTheme,
        home: const Scaffold(body: DateRangeFilterSection()),
      ),
    ),
  );

  FilterChip chip(WidgetTester tester) => tester.widget(find.byType(FilterChip));

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.byType(FilterChip));
    await tester.pumpAndSettle();
  }

  /// Types both days into the picker's text fields, which is independent of
  /// the month the calendar happens to show.
  Future<void> enterRange(WidgetTester tester, String start, String end) async {
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, start);
    await tester.enterText(find.byType(TextField).last, end);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('offers every date without a range', (tester) async {
    await pumpSection(tester);

    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Any date'), findsOneWidget);
    expect(chip(tester).selected, false);
    expect(chip(tester).onDeleted, null);
  });

  testWidgets('shows the stored range in the user\'s date format', (tester) async {
    filters.dateRange = may;
    await pumpSection(tester);

    expect(find.text('2024-05-10 – 2024-05-12'), findsOneWidget);
    expect(chip(tester).selected, true);

    settings.dateFormat = 'dd.MM.yyyy';
    await tester.pump();
    expect(find.text('10.05.2024 – 12.05.2024'), findsOneWidget);
  });

  testWidgets('shows a single day once', (tester) async {
    filters.dateRange = LocalDateRange(start: DateTime(2024, 5, 10), end: DateTime(2024, 5, 10));
    await pumpSection(tester);

    expect(find.text('2024-05-10'), findsOneWidget);
  });

  testWidgets('deleting the chip clears the range', (tester) async {
    filters.dateRange = may;
    await pumpSection(tester);

    chip(tester).onDeleted!();
    await tester.pump();

    expect(filters.dateRange, null);
    expect(find.text('Any date'), findsOneWidget);
  });

  testWidgets('a tap opens the picker and a picked range is written', (tester) async {
    await pumpSection(tester);

    await openPicker(tester);
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
    expect(find.text('Select Date Range'), findsOneWidget);

    await enterRange(tester, '05/10/2024', '05/12/2024');

    expect(find.byType(DateRangePickerDialog), findsNothing);
    expect(filters.dateRange, may);
    expect(find.text('2024-05-10 – 2024-05-12'), findsOneWidget);
  });

  testWidgets('the picker starts on the stored range and can replace it', (tester) async {
    filters.dateRange = may;
    await pumpSection(tester);

    await openPicker(tester);
    final picker = tester.widget<DateRangePickerDialog>(find.byType(DateRangePickerDialog));
    expect(picker.initialDateRange, DateTimeRange(start: DateTime(2024, 5, 10), end: DateTime(2024, 5, 12)));

    await enterRange(tester, '06/01/2024', '06/01/2024');

    expect(filters.dateRange, LocalDateRange(start: DateTime(2024, 6), end: DateTime(2024, 6)));
    expect(find.text('2024-06-01'), findsOneWidget);
  });

  testWidgets('closing the picker keeps the range', (tester) async {
    filters.dateRange = may;
    await pumpSection(tester);

    await openPicker(tester);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    expect(find.byType(DateRangePickerDialog), findsNothing);
    expect(filters.dateRange, may);
  });

  testWidgets('the picker does not offer a day after today', (tester) async {
    await pumpSection(tester);

    await openPicker(tester);
    final picker = tester.widget<DateRangePickerDialog>(find.byType(DateRangePickerDialog));

    expect(DateUtils.isSameDay(picker.lastDate, DateTime.now()), true);
  });

  group('with dated entries', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = DateTime(today.year, today.month, today.day - 100);

    setUp(() => repository.firstEntryDay = firstDay);

    RangeSlider slider(WidgetTester tester) => tester.widget(find.byType(RangeSlider));

    Future<void> release(WidgetTester tester, RangeValues values) async {
      slider(tester).onChanged!(values);
      slider(tester).onChangeEnd!(values);
      await tester.pump();
    }

    testWidgets('a slider spans the first entry to today and is open by default', (tester) async {
      await pumpSection(tester);

      expect(find.byType(FilterChip), findsNothing);
      expect(find.text('Any date'), findsOneWidget);
      expect(slider(tester).values, const RangeValues(0, 100));
      expect(slider(tester).max, 100);
    });

    testWidgets('a drag previews the days and writes them on release only', (tester) async {
      await pumpSection(tester);

      slider(tester).onChanged!(const RangeValues(10.4, 20.6));
      await tester.pump();
      final start = DateTime(firstDay.year, firstDay.month, firstDay.day + 10);
      final end = DateTime(firstDay.year, firstDay.month, firstDay.day + 21);
      final label = FilterActions.dateRangeLabel(LocalDateRange(start: start, end: end), dateFormat: 'yyyy-MM-dd')!;
      expect(find.text(label), findsOneWidget);
      expect(filters.dateRange, null);

      slider(tester).onChangeEnd!(const RangeValues(10.4, 20.6));
      await tester.pump();
      expect(filters.dateRange, LocalDateRange(start: start, end: end));
      expect(slider(tester).values, const RangeValues(10, 21));
    });

    testWidgets('an end of the slider stands for the first day or today', (tester) async {
      await pumpSection(tester);

      await release(tester, const RangeValues(0, 50));
      expect(filters.dateRange?.start, firstDay);

      await release(tester, const RangeValues(50, 100));
      expect(filters.dateRange?.end, today);

      await release(tester, const RangeValues(0, 100));
      expect(filters.dateRange, null);
      expect(find.text('Any date'), findsOneWidget);
    });

    testWidgets('a picked range beyond the track keeps its label', (tester) async {
      filters.dateRange = may;
      repository.firstEntryDay = DateTime(2025, 1, 1);
      await pumpSection(tester);

      expect(slider(tester).values.start, 0);
      expect(find.text('2024-05-10 – 2024-05-12'), findsOneWidget);
    });

    testWidgets('the calendar button opens the picker for exact days', (tester) async {
      await pumpSection(tester);

      await tester.tap(find.byTooltip('Pick exact dates'));
      await tester.pumpAndSettle();
      expect(find.byType(DateRangePickerDialog), findsOneWidget);
    });

    testWidgets('only the chip is left when every entry is from today', (tester) async {
      repository.firstEntryDay = today;
      await pumpSection(tester);

      expect(find.byType(RangeSlider), findsNothing);
      expect(find.byType(FilterChip), findsOneWidget);
    });

    for (final theme in [materialAppTheme, materialAppDarkTheme]) {
      testWidgets('fits a narrow screen with a long date format (${theme.brightness.name})', (tester) async {
        await tester.binding.setSurfaceSize(const Size(200, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        settings.dateFormat = 'EEEE, d MMMM yyyy';
        filters.dateRange = may;

        await pumpSection(tester, theme: theme);

        expect(tester.takeException(), null);
        expect(find.text('Friday, 10 May 2024 – Sunday, 12 May 2024'), findsOneWidget);
      });
    }
  });

  for (final theme in [materialAppTheme, materialAppDarkTheme]) {
    testWidgets('fits a narrow screen with a long date format (${theme.brightness.name})', (tester) async {
      await tester.binding.setSurfaceSize(const Size(200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      settings.dateFormat = 'EEEE, d MMMM yyyy';
      filters.dateRange = may;

      await pumpSection(tester, theme: theme);

      expect(tester.takeException(), null);
      expect(find.text('Friday, 10 May 2024 – Sunday, 12 May 2024'), findsOneWidget);
    });
  }
}
