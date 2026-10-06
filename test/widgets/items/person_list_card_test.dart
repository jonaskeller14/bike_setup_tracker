import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/pages/details/person_details_page.dart';
import 'package:bike_setup_tracker/pages/forms/person_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/person_list_card.dart';
import 'package:bike_setup_tracker/widgets/sheets/bike_link_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSubscriptionService extends Mock implements SubscriptionService {}

void main() {
  late AppDatabase database;
  late AppRepository repository;
  late AppSettings settings;
  late SubscriptionService subscriptionService;

  final person = Person(id: 'rider', name: 'Rider');

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    repository = AppRepository(database);
    await repository.initialDataLoaded;
    settings = AppSettings()
      ..showOnboarding = false
      ..enablePerson = true;
    subscriptionService = _MockSubscriptionService();
    when(() => subscriptionService.hasStravaEntitlement).thenReturn(true);
  });

  tearDown(() async {
    await repository.disposeAndAwaitCancellation();
    settings.dispose();
    await database.close();
  });

  Future<void> pumpCard(WidgetTester tester, Widget body) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSettings>.value(value: settings),
          ChangeNotifierProvider<AppRepository>.value(value: repository),
          ChangeNotifierProvider<SubscriptionService>.value(value: subscriptionService),
        ],
        child: MaterialApp(
          theme: materialAppTheme,
          home: Scaffold(body: body),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<List<String>> openMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();
    final labels = [
      for (final label in ['Edit', 'Link bikes', 'Duplicate', 'Remove'])
        if (find.text(label).evaluate().isNotEmpty) label,
    ];
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    return labels;
  }

  Widget reorderable() => ReorderableListView(
    onReorderItem: (_, _) {},
    children: [PersonListCard(key: const ValueKey('card'), person: person, index: 0)],
  );

  group('simple layout', () {
    testWidgets('has no handle, Duplicate or Strava badge', (tester) async {
      await pumpCard(tester, PersonListCard(person: person));

      expect(find.byIcon(Icons.drag_handle), findsNothing);
      expect(find.byIcon(Icons.link_off), findsNothing);
      expect(await openMenu(tester), ['Edit', 'Link bikes', 'Remove']);
    });

    testWidgets('tap opens edit', (tester) async {
      await pumpCard(tester, PersonListCard(person: person));

      await tester.tap(find.text('Rider'));
      await tester.pumpAndSettle();

      expect(find.byType(PersonPage), findsOneWidget);
      expect(find.byType(PersonDetailsPage), findsNothing);
    });

    testWidgets('Link bikes opens the bike link sheet', (tester) async {
      await pumpCard(tester, PersonListCard(person: person));

      await tester.tap(find.byTooltip('Show menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Link bikes'));
      await tester.pumpAndSettle();

      expect(find.byType(BikeLinkSheetContent), findsOneWidget);
    });
  });

  group('advanced layout', () {
    setUp(() => settings.enablePersonAdvanced = true);

    testWidgets('shows handle, Duplicate and Strava badge', (tester) async {
      await pumpCard(tester, reorderable());

      expect(find.byIcon(Icons.drag_handle), findsOneWidget);
      expect(find.byIcon(Icons.link_off), findsOneWidget);
      expect(await openMenu(tester), ['Edit', 'Link bikes', 'Duplicate', 'Remove']);
    });

    testWidgets('tap opens the details page', (tester) async {
      await pumpCard(tester, reorderable());

      await tester.tap(find.text('Rider'));
      await tester.pumpAndSettle();

      expect(find.byType(PersonDetailsPage), findsOneWidget);
    });

    testWidgets('no index outside a reorderable list draws no handle', (tester) async {
      await pumpCard(tester, PersonListCard(person: person));

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.drag_handle), findsNothing);
    });
  });
}
