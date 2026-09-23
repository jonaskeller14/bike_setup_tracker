import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/map_empty_state.dart';
import 'package:bike_setup_tracker/widgets/map_empty_state_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MockAppRepository repository;
  late AppSettings settings;
  late MockSubscriptionService subscriptionService;
  late int retries;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = MockAppRepository();
    when(() => repository.bikes).thenReturn(<String, Bike>{});
    when(() => repository.onBikeTap(any())).thenAnswer((_) {});
    settings = AppSettings();
    subscriptionService = MockSubscriptionService();
    when(() => subscriptionService.hasStravaEntitlement).thenReturn(false);
    retries = 0;
  });

  tearDown(() {
    settings.dispose();
  });

  Future<void> pumpCard(
    WidgetTester tester, {
    required MapPinState state,
    bool collapsed = false,
    VoidCallback? onToggleCollapsed,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ListenableProvider<AppRepository>.value(value: repository),
          ListenableProvider<SubscriptionService>.value(value: subscriptionService),
        ],
        child: MaterialApp(
          theme: theme,
          home: Scaffold(
            // Mirrors the map's chrome column: full width offered, the card
            // takes only what it needs and stays left-aligned.
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                MapEmptyStateCard(
                  state: state,
                  collapsed: collapsed,
                  onToggleCollapsed: onToggleCollapsed ?? () {},
                  onRetry: () => retries++,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('offers adding a setup when nothing is positioned yet', (tester) async {
    await pumpCard(tester, state: MapPinState.none);

    expect(find.byKey(const Key('map-empty-none')), findsOneWidget);
    expect(find.text('No locations yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Add setup'));
    await tester.pump();

    // The add flow ran and stopped on its own precondition: no bike exists.
    expect(find.text('A bike is required to create a setup'), findsOneWidget);
  });

  testWidgets('names other pin sources only while they are enabled', (tester) async {
    await pumpCard(tester, state: MapPinState.none);
    expect(find.textContaining('Same for'), findsNothing);

    settings.enableRating = true;
    when(() => subscriptionService.hasStravaEntitlement).thenReturn(true);
    await pumpCard(tester, state: MapPinState.none);

    expect(find.textContaining('Same for Strava activities and rating entries.'), findsOneWidget);
  });

  testWidgets('clears the filters from the filtered state', (tester) async {
    await pumpCard(tester, state: MapPinState.filtered);

    expect(find.byKey(const Key('map-empty-filtered')), findsOneWidget);
    expect(find.text('Nothing on the map in this view'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Clear filters'));
    await tester.pump();

    verify(() => repository.onBikeTap(null)).called(1);
  });

  testWidgets('retries the activity query from the error state', (tester) async {
    await pumpCard(tester, state: MapPinState.error);

    expect(find.byKey(const Key('map-empty-error')), findsOneWidget);
    expect(find.text("Couldn't load activities"), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pump();

    expect(retries, 1);
  });

  testWidgets('swaps between the card and the pill', (tester) async {
    var toggles = 0;
    await pumpCard(tester, state: MapPinState.none, onToggleCollapsed: () => toggles++);

    await tester.tap(find.byKey(const Key('map-empty-collapse')));
    expect(toggles, 1);

    await pumpCard(tester, state: MapPinState.none, collapsed: true);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('map-empty-pill')), findsOneWidget);
    expect(find.byKey(const Key('map-empty-none')), findsNothing);
    expect(find.text('No pins'), findsOneWidget);
  });

  testWidgets('keeps the collapse button in the top-right corner', (tester) async {
    await pumpCard(tester, state: MapPinState.filtered);

    final card = tester.getRect(find.byKey(const Key('map-empty-filtered')));
    final close = tester.getRect(find.byKey(const Key('map-empty-collapse')));
    final glyph = tester.getCenter(
      find.descendant(
        of: find.byKey(const Key('map-empty-collapse')),
        matching: find.byIcon(Icons.close),
      ),
    );

    // The text column has to take the slack, or the button floats mid-card.
    expect(card.right - close.right, lessThan(12));
    // The glyph, not just its tap target: centring it in the Row dropped it
    // level with the subtitle.
    expect(glyph.dy - card.top, lessThan(24));
    expect(card.right - glyph.dx, lessThan(24));
  });

  testWidgets('stays only as wide as its copy', (tester) async {
    await pumpCard(tester, state: MapPinState.filtered);

    final card = tester.getRect(find.byKey(const Key('map-empty-filtered')));
    final available = tester.getSize(find.byType(Scaffold)).width;

    expect(card.width, lessThan(available));
    expect(card.left, 0);
  });

  testWidgets('stays only as wide as its copy', (tester) async {
    await pumpCard(tester, state: MapPinState.filtered);

    final card = tester.getRect(find.byKey(const Key('map-empty-filtered')));

    expect(card.left, 0);
    expect(card.width, lessThan(tester.getSize(find.byType(Scaffold)).width));
  });

  testWidgets('survives a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    settings.enableRating = true;
    when(() => subscriptionService.hasStravaEntitlement).thenReturn(true);
    await pumpCard(tester, state: MapPinState.filtered);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('map-empty-filtered')), findsOneWidget);
  });

  testWidgets('renders in light and dark', (tester) async {
    for (final theme in [materialAppTheme, materialAppDarkTheme]) {
      await pumpCard(tester, state: MapPinState.error, theme: theme);
      expect(find.byKey(const Key('map-empty-error')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

class MockSubscriptionService extends Mock implements SubscriptionService {}

class MockAppRepository extends Mock implements AppRepository {}
