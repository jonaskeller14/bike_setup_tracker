import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/pages/forms/bike_page.dart';
import 'package:bike_setup_tracker/pages/forms/component_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/repositories/component_catalog_repository.dart';
import 'package:bike_setup_tracker/services/app_hint_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/set_installation_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../goldens/support/localized_test_app.dart';

void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
    appSettings.showOnboarding = false;
  });

  tearDown(() async {
    await appRepository.disposeAndAwaitCancellation();
    appSettings.dispose();
    await database.close();
  });

  Widget app(Widget home, {required Locale locale}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appRepository),
        ChangeNotifierProvider<SubscriptionService>(create: (_) => SubscriptionService()),
        Provider<ComponentCatalogRepository>(create: (_) => ComponentCatalogRepository.withCatalogs(const [])),
        ChangeNotifierProvider(
          create: (_) => AppHintService(appRepository: appRepository, appSettings: appSettings),
        ),
      ],
      child: localizedTestApp(theme: materialAppTheme, locale: locale, home: home),
    );
  }

  const de = Locale('de');

  testWidgets('the bike form is German', (tester) async {
    await tester.pumpWidget(app(BikePage.add(), locale: de));

    expect(find.text('Bike hinzufügen'), findsOneWidget);
    expect(find.text('Bike-Name'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.text('Bitte gib einen Namen für das Bike ein'), findsOneWidget);
  });

  testWidgets('the bike form keeps its English wording', (tester) async {
    await tester.pumpWidget(
      app(
        BikePage.edit(bike: Bike(name: 'Trail', person: null)),
        locale: const Locale('en'),
      ),
    );

    expect(find.text('Edit Bike'), findsOneWidget);
    expect(find.text('Bike Name'), findsOneWidget);
  });

  testWidgets('the component form is German', (tester) async {
    await tester.pumpWidget(app(ComponentPage.add(), locale: de));
    await tester.pumpAndSettle();

    expect(find.text('Komponente hinzufügen'), findsOneWidget);
    expect(find.text('Typ'), findsOneWidget);
    expect(find.text('EINSTELLUNGEN'), findsOneWidget);
    expect(find.text('Einstellung hinzufügen'), findsOneWidget);
  });

  testWidgets('the installation timeline is German, with a German error', (tester) async {
    final beginning = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final entries = [
      Installation.sinceBeginning(parent: null),
      Uninstallation(dateTimeUTC: DateTime.utc(2026, 1, 1), dateTimeLocal: DateTime(2026, 1, 1)),
      Uninstallation(dateTimeUTC: DateTime.utc(2026, 1, 2), dateTimeLocal: DateTime(2026, 1, 2)),
    ];
    expect(entries.first.dateTimeUTC, beginning);

    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      app(
        Scaffold(
          body: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: SetInstallationTimeline(
                componentType: ComponentType.fork,
                initialInstallations: entries,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
        locale: de,
      ),
    );

    expect(find.text('EINBAUHISTORIE'), findsOneWidget);
    expect(find.text('Von Beginn an'), findsOneWidget);

    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('Zwei Ausbauten dürfen nicht direkt aufeinander folgen'), findsOneWidget);
  });
}
