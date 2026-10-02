import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/pages/details/bike_details_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/setup_activity_analysis_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/attachment_row.dart';
import 'package:bike_setup_tracker/widgets/display_data/setup_histogram_chart.dart';
import 'package:bike_setup_tracker/widgets/display_data/setup_line_chart.dart';
import 'package:bike_setup_tracker/widgets/display_data/setup_radial_chart.dart';
import 'package:bike_setup_tracker/widgets/display_data/setup_table.dart';
import 'package:bike_setup_tracker/widgets/initial_changed_value_legend.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSubscriptionService extends Mock implements SubscriptionService {
  MockSubscriptionService({this.hasStravaEntitlement = false});

  @override
  final bool hasStravaEntitlement;
}

class MockSetupActivityAnalysisService extends Mock implements SetupActivityAnalysisService {}

void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;
  late SetupActivityAnalysisService setupActivityAnalysisService;
  late bool hasStravaEntitlement;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
    setupActivityAnalysisService = SetupActivityAnalysisService(database);
    hasStravaEntitlement = false;
  });

  tearDown(() async {
    // Closing the database right after dispose() races its fire-and-forget
    // subscription cancellation and can hang; wait for cancellation first.
    await appRepository.disposeAndAwaitCancellation();
    appSettings.dispose();
    setupActivityAnalysisService.dispose();
    await database.close();
  });

  Widget createWidgetUnderTest(String bikeId) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appRepository),
        ChangeNotifierProvider.value(value: setupActivityAnalysisService),
        ChangeNotifierProvider<SubscriptionService>.value(
          value: MockSubscriptionService(hasStravaEntitlement: hasStravaEntitlement),
        ),
      ],
      child: MaterialApp(
        theme: materialAppTheme,
        home: BikeDetailsPage(bikeId: bikeId),
      ),
    );
  }

  Setup setup(String id, String name, String bike) => Setup(
    id: id,
    name: name,
    datetime: DateTime(2024).toUtc(),
    datetimeLocal: DateTime(2024),
    tags: {},
    bike: bike,
    person: null,
    bikeAdjustmentValues: {},
    personAdjustmentValues: {},
  );

  /// Seeds the database, then rebuilds the repository so it loads the rows into
  /// its caches, and pumps the page once the bike has arrived.
  Future<void> pumpPageWith(WidgetTester tester, Future<void> Function() writes) async {
    await tester.runAsync(() async {
      await writes();
      await Future<void>.delayed(Duration.zero);
    });

    appRepository.dispose();
    appRepository = AppRepository(database);

    await tester.pumpWidget(createWidgetUnderTest('bike1'));
    await tester.runAsync(() async {
      for (var attempts = 0; appRepository.bikes['bike1'] == null && attempts < 10; attempts++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets('lists only the setups of this bike, without a bike column', (WidgetTester tester) async {
    await pumpPageWith(tester, () async {
      await appRepository.addBikes([
        Bike(id: 'bike1', name: 'Test Bike', person: null),
        Bike(id: 'bike2', name: 'Other Bike', person: null),
      ]);
      await appRepository.addSetups([
        setup('s1', 'Alpha Setup', 'bike1'),
        setup('s2', 'Beta Setup', 'bike2'),
      ]);
    });

    expect(find.text('SETUP HISTORY'), findsOneWidget);
    expect(find.byType(SetupTable), findsOneWidget);
    expect(find.text('Alpha Setup'), findsOneWidget);
    expect(find.text('Beta Setup'), findsNothing);

    expect(find.descendant(of: find.byType(SetupTable), matching: find.byType(Checkbox)), findsWidgets);

    await tester.tap(find.widgetWithText(FilterChip, 'Columns'));
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byType(Wrap), matching: find.text('Bike')), findsNothing);
    expect(find.text('Component Adjustments'), findsNothing);
    expect(find.descendant(of: find.byType(Wrap), matching: find.text('Temperature')), findsOneWidget);
  });

  testWidgets('keeps the setups of this bike when another bike is selected', (WidgetTester tester) async {
    await pumpPageWith(tester, () async {
      await appRepository.addBikes([
        Bike(id: 'bike1', name: 'Test Bike', person: null),
        Bike(id: 'bike2', name: 'Other Bike', person: null),
      ]);
      await appRepository.addSetups([setup('s1', 'Alpha Setup', 'bike1')]);
    });

    appRepository.filters.toggleBike('bike2');
    await tester.pumpAndSettle();

    expect(find.text('Alpha Setup'), findsOneWidget);
  });

  testWidgets('shows a placeholder when no setup references the bike', (WidgetTester tester) async {
    await pumpPageWith(tester, () async {
      await appRepository.addBikes([Bike(id: 'bike1', name: 'Test Bike', person: null)]);
      await appRepository.addSetups([setup('s2', 'Beta Setup', 'bike2')]);
    });

    expect(find.byType(SetupTable), findsNothing);
    expect(find.text('No setups reference this bike'), findsOneWidget);
  });

  testWidgets('shows the bike attachments only when attachments are enabled', (WidgetTester tester) async {
    const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => Directory.systemTemp.path,
    );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pathProviderChannel, null),
    );
    await pumpPageWith(tester, () async {
      await appRepository.addBikes([
        Bike(
          id: 'bike1',
          name: 'Test Bike',
          person: null,
          attachments: [Attachment(extension: '.pdf', name: 'Frame Manual.pdf')],
        ),
      ]);
    });

    expect(find.byType(AttachmentRow), findsNothing);

    appSettings.enableAttachments = true;
    await tester.pumpAndSettle();

    expect(find.byType(AttachmentRow), findsOneWidget);
    expect(find.text('Frame Manual.pdf'), findsOneWidget);
  });

  group('bike adjustment columns', () {
    const columnLabel = 'Pressure · Tire (Front Wheel)';

    Installation onBike(int day) => BikeInstallation(
      bikeId: 'bike1',
      dateTimeUTC: DateTime.utc(2026, 1, day),
      dateTimeLocal: DateTime(2026, 1, day),
    );

    Installation onWheel(int day) => ComponentInstallation(
      parentComponentId: 'wheel',
      dateTimeUTC: DateTime.utc(2026, 1, day),
      dateTimeLocal: DateTime(2026, 1, day),
    );

    Setup setupOn(String id, int day, Map<String, AdjustmentValue> values) => Setup(
      id: id,
      name: id,
      datetime: DateTime.utc(2026, 1, day, 12),
      datetimeLocal: DateTime.utc(2026, 1, day, 12).toLocal(),
      tags: {},
      bike: 'bike1',
      person: null,
      bikeAdjustmentValues: values,
      personAdjustmentValues: {},
    );

    /// Tire A is replaced by tire B on the front wheel on day 5.
    Future<void> seedTireReplacement({String tireName = 'Tire'}) async {
      await appRepository.addBikes([Bike(id: 'bike1', name: 'Test Bike', person: null)]);
      await appRepository.addComponents([
        Component(
          id: 'wheel',
          name: 'Front Wheel',
          componentType: ComponentType.wheelFront,
          installations: [onBike(1)],
        ),
        Component(
          id: 'tire-a',
          name: '$tireName A',
          componentType: ComponentType.tire,
          installations: [
            onWheel(1),
            Uninstallation(dateTimeUTC: DateTime.utc(2026, 1, 5), dateTimeLocal: DateTime(2026, 1, 5)),
          ],
          adjustments: [NumericalAdjustment(id: 'pa', name: 'Pressure', notes: null, unit: null)],
        ),
        Component(
          id: 'tire-b',
          name: '$tireName B',
          componentType: ComponentType.tire,
          installations: [onWheel(5)],
          adjustments: [NumericalAdjustment(id: 'pb', name: 'Pressure', notes: null, unit: null)],
        ),
      ]);
      await appRepository.addSetups([
        setupOn('s1', 2, {'pa': const NumericalValue(25.0)}),
        setupOn('s2', 6, {'pb': const NumericalValue(22.0)}),
      ]);
    }

    Finder inTable(String text) => find.descendant(of: find.byType(SetupTable), matching: find.text(text));

    testWidgets('merges a replaced tire into one column', (WidgetTester tester) async {
      await pumpPageWith(tester, seedTireReplacement);

      expect(inTable(columnLabel), findsOneWidget);
      expect(inTable('25'), findsOneWidget);
      expect(inTable('22'), findsOneWidget);
      // The replacement has no previous value of its own, so its first value is "initial".
      final initial = materialAppTheme.extension<ValueHighlightColors>()!.initial;
      expect(tester.widget<Text>(inTable('22')).style?.color, initial);
      expect(find.byType(InitialChangedValueLegend), findsOneWidget);
    });

    testWidgets('charts the merged column for the newest setups', (WidgetTester tester) async {
      await pumpPageWith(tester, seedTireReplacement);

      final lineChart = find.byType(SetupLineChart);
      expect(find.descendant(of: find.byType(SetupTable), matching: find.byType(Checkbox)), findsWidgets);
      expect(find.descendant(of: lineChart, matching: find.byType(LineChart)), findsOneWidget);
      expect(find.descendant(of: lineChart, matching: find.text(columnLabel)), findsOneWidget);
      expect(find.byType(SetupRadialChart), findsOneWidget);
    });

    testWidgets('long-pressing a line chart legend entry deactivates its column', (WidgetTester tester) async {
      await pumpPageWith(tester, seedTireReplacement);

      final legendEntry = find.descendant(of: find.byType(SetupLineChart), matching: find.text(columnLabel));
      await tester.ensureVisible(legendEntry);
      await tester.longPress(legendEntry);
      await tester.pumpAndSettle();

      expect(inTable(columnLabel), findsNothing);
      expect(find.text('No adjustments selected'), findsNWidgets(2));
    });

    testWidgets('counts the activities of a replaced tire in one histogram', (WidgetTester tester) async {
      const counts = {'s1': 3, 's2': 2};
      setupActivityAnalysisService.dispose();
      final service = MockSetupActivityAnalysisService();
      when(() => service.hasAnyActivity).thenReturn(true);
      when(() => service.setupActivityCounts).thenReturn(counts);
      when(() => service.setupActivityCountsLoaded).thenReturn(true);
      when(() => service.setupActivityCountsFailed).thenReturn(false);
      when(service.getSetupActivityCounts).thenAnswer((_) async => counts);
      setupActivityAnalysisService = service;
      hasStravaEntitlement = true;

      await pumpPageWith(tester, seedTireReplacement);

      final histogram = find.byType(SetupHistogramChart);
      final barChart = tester.widget<BarChart>(find.descendant(of: histogram, matching: find.byType(BarChart)));
      // 22: tire B at s2, 25: tire A at s1.
      expect(barChart.data.barGroups.map((group) => group.barRods.single.toY), [2, 3]);
      expect(find.descendant(of: histogram, matching: find.text(columnLabel)), findsOneWidget);
    });

    testWidgets('does not overflow with long component names on a narrow screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpPageWith(tester, () => seedTireReplacement(tireName: 'Extraordinarily Long Tubeless Tire Name ' * 3));
      expect(inTable(columnLabel), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Columns'));
      await tester.pumpAndSettle();

      expect(find.text('Component Adjustments'), findsOneWidget);
      expect(find.text('Tire (Front Wheel)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
