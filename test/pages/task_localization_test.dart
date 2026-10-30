import 'dart:async';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/pages/details/task_rule_details_page.dart';
import 'package:bike_setup_tracker/pages/forms/task_rule_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/repositories/component_catalog_repository.dart';
import 'package:bike_setup_tracker/services/app_hint_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/task_actions.dart';
import 'package:bike_setup_tracker/widgets/items/task_rule_display_card.dart';
import 'package:bike_setup_tracker/widgets/lists/task_list.dart';
import 'package:bike_setup_tracker/widgets/sheets/copy_task_rules.dart';
import 'package:bike_setup_tracker/widgets/sheets/delete_task_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../goldens/support/localized_test_app.dart';

class _MockSubscriptionService extends Mock implements SubscriptionService {}

void main() {
  const de = Locale('de');

  late AppDatabase database;
  late AppRepository repository;
  late AppSettings settings;
  late _MockSubscriptionService subscription;
  late AppHintService hintService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    repository = AppRepository(database);
    settings = AppSettings();
    subscription = _MockSubscriptionService();
    hintService = AppHintService(appRepository: repository, appSettings: settings);
    when(() => subscription.hasStravaEntitlement).thenReturn(false);
  });

  tearDown(() async {
    await repository.disposeAndAwaitCancellation();
    settings.dispose();
    await database.close();
  });

  Widget app(Widget home, {Locale locale = de}) => MultiProvider(
    providers: [
      ChangeNotifierProvider<AppRepository>.value(value: repository),
      ChangeNotifierProvider<AppSettings>.value(value: settings),
      ChangeNotifierProvider<SubscriptionService>.value(value: subscription),
      ChangeNotifierProvider<AppHintService>.value(value: hintService),
      Provider.value(value: ComponentCatalogRepository.withCatalogs(const [])),
    ],
    child: localizedTestApp(theme: materialAppTheme, locale: locale, home: home),
  );

  Future<void> seed(WidgetTester tester, List<TaskRule> rules) async {
    await tester.runAsync(() async {
      await repository.addTaskRules(rules);
      await pumpEventQueue();
    });
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (repository.taskRules.length == rules.length) return;
    }
  }

  group('task rule form', () {
    testWidgets('is German, with a German validation error', (tester) async {
      await tester.pumpWidget(app(TaskRulePage.add()));
      await tester.pumpAndSettle();

      expect(find.text('Aufgabenregel hinzufügen'), findsOneWidget);
      expect(find.text('Name der Aufgabenregel'), findsOneWidget);
      expect(find.text('Allgemeine Aufgabe'), findsOneWidget);
      // Section titles are shown in capitals.
      expect(find.text('AUFGABENAUSLÖSER'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(find.text('Name erforderlich'), findsOneWidget);
    });

    testWidgets('keeps its English wording', (tester) async {
      await tester.pumpWidget(app(TaskRulePage.add(), locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Add Task Rule'), findsOneWidget);
      expect(find.text('General Task'), findsOneWidget);
      expect(find.text('TASK TRIGGER'), findsOneWidget);
    });

    testWidgets('names the trigger types and the plural unit of a duration in German', (tester) async {
      await tester.pumpWidget(app(TaskRulePage.add()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('taskRuleIntervalType')));
      await tester.pumpAndSettle();
      expect(find.text('ZEITBASIERT'), findsOneWidget);
      expect(find.text('AKTIVITÄTSBASIERT (STRAVA)'), findsOneWidget);
      expect(find.text('Dauer'), findsOneWidget);
      expect(find.text('Datum'), findsOneWidget);

      await tester.tap(find.text('Dauer').last);
      await tester.pumpAndSettle();
      expect(find.text('Tage'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('taskRuleIntervalValue')), '1');
      await tester.pump();
      expect(find.text('Tag'), findsOneWidget);
    });

    testWidgets('asks for a whole number in German', (tester) async {
      await tester.pumpWidget(app(TaskRulePage.add()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Ketteninspektion');
      await tester.tap(find.byKey(const Key('taskRuleIntervalType')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dauer').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('Wert eingeben'), findsOneWidget);
    });
  });

  group('task list', () {
    testWidgets('shows the German empty state and section header', (tester) async {
      await tester.pumpWidget(app(const Scaffold(body: TaskList())));
      await tester.pumpAndSettle();

      expect(find.text('Jetzt fällig (0)'), findsOneWidget);
      expect(find.text('Noch keine Aufgaben'), findsOneWidget);
      expect(find.text('Aufgabe hinzufügen'), findsWidgets);
    });

    testWidgets('names the interval and what is left in German', (tester) async {
      // The app keeps this in step with its locale; the interval text reads it.
      Intl.defaultLocale = 'de';
      addTearDown(() => Intl.defaultLocale = null);
      await seed(tester, [
        TaskRule(
          name: 'Bremsen entlüften',
          tags: const {},
          repeat: false,
          interval: DateTimeThreshold(DateTime.now().add(const Duration(days: 3))),
        ),
        TaskRule(name: 'Kette schmieren', tags: const {}, interval: const DurationThreshold(Duration(days: 30))),
      ]);
      await tester.pumpWidget(app(const Scaffold(body: TaskList())));
      await tester.pumpAndSettle();

      expect(find.text('Anstehend (1)'), findsOneWidget);
      expect(find.textContaining('Einmalig:'), findsOneWidget);
      expect(find.text('Alle 30 Tage'), findsOneWidget);
    });

    testWidgets('a task card says in German how far it is past due', (tester) async {
      Intl.defaultLocale = 'de';
      addTearDown(() => Intl.defaultLocale = null);
      final rule = TaskRule(
        name: 'Kette schmieren',
        tags: const {},
        interval: const DurationThreshold(Duration(days: 30)),
      );
      await seed(tester, [rule]);
      await tester.pumpWidget(app(Scaffold(body: TaskRuleDisplayCard(taskRule: rule, showStatus: true))));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tage überschritten'), findsOneWidget);
    });
  });

  testWidgets('the task details page says in German when the task is gone', (tester) async {
    await tester.pumpWidget(app(const TaskRuleDetailsPage(taskRuleId: 'missing')));
    await tester.pumpAndSettle();

    expect(find.text('Aufgabe nicht gefunden'), findsOneWidget);
    expect(find.text('Diese Aufgabe wurde gelöscht oder ist nicht mehr verfügbar.'), findsOneWidget);
  });

  group('sheets', () {
    final rules = [
      TaskRule(name: 'Lower leg service', tags: const {}),
      TaskRule(name: 'Check headset', tags: const {}),
    ];

    Widget opener(Future<void> Function(BuildContext context) open) => Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(onPressed: () => open(context), child: const Text('Open')),
      ),
    );

    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('the delete sheet counts tasks in German', (tester) async {
      await tester.pumpWidget(
        app(opener((context) => showDeleteTaskRulesSheet(context, taskRules: rules))),
      );
      await open(tester);

      expect(find.text('Zugehörige Aufgaben löschen?'), findsOneWidget);
      expect(find.text('Aufgaben (2 / 2)'), findsOneWidget);
      expect(find.text('2 Aufgaben löschen'), findsOneWidget);
      expect(find.text('Allgemeine Aufgabe'), findsNWidgets(2));
    });

    testWidgets('the copy sheet is German, with the singular form for one task', (tester) async {
      await tester.pumpWidget(
        app(
          opener(
            (context) => showCopyTaskRulesSheet(
              context,
              taskRules: [rules.first],
              sourceName: 'Fox 36',
              componentName: 'Fox 38',
            ),
          ),
        ),
      );
      await open(tester);

      expect(find.text('Aufgaben kopieren?'), findsOneWidget);
      expect(find.textContaining('Wähle die Aufgaben aus, die nach „Fox 38“ kopiert werden sollen.'), findsOneWidget);
      expect(find.text('1 Aufgabe kopieren'), findsOneWidget);
      expect(find.text('Weiter, ohne Aufgaben zu kopieren'), findsOneWidget);
    });
  });

  testWidgets('removing a task confirms in German, with a German undo', (tester) async {
    final bike = Bike(name: 'Enduro', person: null);
    final rule = TaskRule(name: 'Kette wechseln', tags: const {}, association: BikeTaskAssociation(bike.id));
    await seed(tester, [rule]);
    late BuildContext context;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    unawaited(TaskActions.removeTaskRules(context, taskRuleIds: [rule.id]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Aufgabe „Kette wechseln“ und zugehörige Einträge in den Papierkorb verschoben.'), findsOneWidget);
    expect(find.text('RÜCKGÄNGIG'), findsOneWidget);
  });
}
