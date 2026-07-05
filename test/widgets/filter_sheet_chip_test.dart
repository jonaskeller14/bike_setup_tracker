import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/chips/filter_sheet_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAppRepository extends Mock implements AppRepository {}

class MockSubscriptionService extends Mock implements SubscriptionService {}

void main() {
  late MockAppRepository mockRepository;
  late MockSubscriptionService mockSubscription;
  late AppSettings appSettings;
  late Bike bike1;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepository = MockAppRepository();
    mockSubscription = MockSubscriptionService();
    appSettings = AppSettings();
    bike1 = Bike(id: 'b1', name: 'Bike 1', person: 'P1');

    // Defaults: no bike selected, no tags. Individual tests override as needed.
    when(() => mockRepository.selectedBike).thenReturn(null);
    when(() => mockRepository.selectedSetupTags).thenReturn(<String>{});
    when(() => mockRepository.bikes).thenReturn({'b1': bike1});
    when(() => mockSubscription.hasStravaEntitlement).thenReturn(false);
  });

  void selectBike() {
    when(() => mockRepository.selectedBike).thenReturn('b1');
  }

  void selectTags(Set<String> tags) {
    when(() => mockRepository.selectedSetupTags).thenReturn(tags);
  }

  Widget createWidgetUnderTest(FilterSheetChip chip) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider<AppRepository>.value(value: mockRepository),
        ChangeNotifierProvider<SubscriptionService>.value(value: mockSubscription),
      ],
      child: MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(body: chip),
      ),
    );
  }

  group('FilterSheetChip label — bike-only sheet', () {
    // A pure bike picker: no tag filter and no folded-in display sections.
    const bikeOnlyChip = FilterSheetChip(enableSetupTagFilter: false);

    testWidgets('shows "All Bikes" when no bike is selected', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(bikeOnlyChip));

      expect(find.text('All Bikes'), findsOneWidget);
      expect(find.text('Filter'), findsNothing);
      expect(find.byIcon(Bike.iconData), findsOneWidget);
    });

    testWidgets('shows the bike name when a bike is selected', (tester) async {
      selectBike();
      await tester.pumpWidget(createWidgetUnderTest(bikeOnlyChip));

      expect(find.text('Bike 1'), findsOneWidget);
      expect(find.text('All Bikes'), findsNothing);
    });
  });

  group('FilterSheetChip label — sheet with extra sections (map case)', () {
    // showMapVisibility folds activity/setup visibility toggles into the sheet,
    // so it is no longer a pure bike picker → must NOT say "All Bikes".
    const mapChip = FilterSheetChip(
      enableSetupTagFilter: false,
      showMapVisibility: true,
    );

    testWidgets('shows "Filter" instead of "All Bikes" when no bike selected', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(mapChip));

      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('All Bikes'), findsNothing);
      expect(find.byIcon(Icons.filter_alt_outlined), findsOneWidget);
      expect(find.byIcon(Bike.iconData), findsNothing);
    });

    testWidgets('shows the bike name when a bike is selected', (tester) async {
      selectBike();
      await tester.pumpWidget(createWidgetUnderTest(mapChip));

      expect(find.text('Bike 1'), findsOneWidget);
      expect(find.text('All Bikes'), findsNothing);
    });
  });

  group('FilterSheetChip label — setup tag filter', () {
    const tagChip = FilterSheetChip(enableSetupTagFilter: true);

    testWidgets('shows "Filter" when nothing is selected', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(tagChip));

      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('All Bikes'), findsNothing);
      expect(find.byIcon(Icons.filter_alt_outlined), findsOneWidget);
    });

    testWidgets('shows tag count only when tags but no bike are selected', (tester) async {
      selectTags({'t1', 't2'});
      await tester.pumpWidget(createWidgetUnderTest(tagChip));

      expect(find.text('2 Tags'), findsOneWidget);
    });

    testWidgets('shows singular "Tag" for a single tag', (tester) async {
      selectTags({'t1'});
      await tester.pumpWidget(createWidgetUnderTest(tagChip));

      expect(find.text('1 Tag'), findsOneWidget);
    });

    testWidgets('combines bike name and tag count', (tester) async {
      selectBike();
      selectTags({'t1', 't2'});
      await tester.pumpWidget(createWidgetUnderTest(tagChip));

      expect(find.text('Bike 1 + 2 Tags'), findsOneWidget);
    });

    testWidgets('shows the bike name alone when only a bike is selected', (tester) async {
      selectBike();
      await tester.pumpWidget(createWidgetUnderTest(tagChip));

      expect(find.text('Bike 1'), findsOneWidget);
    });
  });
}
