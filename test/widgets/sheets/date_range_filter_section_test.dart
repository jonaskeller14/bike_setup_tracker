import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/filters/local_date_range.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/repositories/filter_controller.dart';
import 'package:bike_setup_tracker/theme.dart';
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
