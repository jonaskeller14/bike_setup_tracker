import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/pages/forms/person_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/adjustment_list_card.dart';
import 'package:bike_setup_tracker/widgets/sheets/person_add_adjustment.dart';
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
    when(() => subscriptionService.hasStravaEntitlement).thenReturn(false);
  });

  tearDown(() async {
    await repository.disposeAndAwaitCancellation();
    settings.dispose();
    await database.close();
  });

  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSettings>.value(value: settings),
          ChangeNotifierProvider<AppRepository>.value(value: repository),
          ChangeNotifierProvider<SubscriptionService>.value(value: subscriptionService),
        ],
        child: MaterialApp(theme: materialAppTheme, home: page),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openAddAttributeSheet(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Add Attribute'));
    await tester.tap(find.text('Add Attribute'));
    await tester.pumpAndSettle();
  }

  Finder appBarTitle(String text) => find.descendant(of: find.byType(AppBar), matching: find.text(text));

  group('attribute editors', () {
    testWidgets('a custom attribute opens "Add … Attribute"', (tester) async {
      await pumpPage(tester, PersonPage.add());
      await openAddAttributeSheet(tester);

      await tester.tap(find.text('Numerical Attribute'));
      await tester.pumpAndSettle();

      expect(appBarTitle('Add Numerical Attribute'), findsOneWidget);
      expect(find.text('Attribute Name'), findsOneWidget);
    });

    testWidgets('a pre-filled template opens "Add … Attribute"', (tester) async {
      await pumpPage(tester, PersonPage.add());
      await openAddAttributeSheet(tester);

      await tester.tap(find.text('Riding style'));
      await tester.pumpAndSettle();

      expect(appBarTitle('Add Categorical Attribute'), findsOneWidget);
      expect(find.text('Attribute Name'), findsOneWidget);
    });

    testWidgets('editing an attribute opens "Edit … Attribute"', (tester) async {
      final person = Person(id: 'rider', name: 'Rider', adjustments: [ridingWeightPreset.deepCopy()]);
      await pumpPage(tester, PersonPage.edit(person: person));

      final menuButton = find.descendant(
        of: find.byType(AdjustmentListCard),
        matching: find.byWidgetPredicate((widget) => widget is PopupMenuButton),
      );
      await tester.tap(menuButton.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(appBarTitle('Edit Numerical Attribute'), findsOneWidget);
      expect(find.text('Attribute Name'), findsOneWidget);
    });
  });
}
