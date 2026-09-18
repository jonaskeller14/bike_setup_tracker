import 'dart:async';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/pages/task_rule_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/task_actions.dart';
import 'package:bike_setup_tracker/widgets/items/task_rule_list_card.dart';
import 'package:bike_setup_tracker/widgets/sheets/set_task_delay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Covers the quick delay editor reachable from TaskRuleListCard and the
/// "delay follows the trigger type" behaviour on TaskRulePage.
///
/// A delay is added on top of the trigger, so it can only ever be of the
/// trigger's own type. Both entry points must honour that, and neither may
/// turn a preselected type with an empty value into a saved delay of zero.
void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;

  final bike = Bike(name: 'Test Bike', person: null);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
    appSettings.showOnboarding = false;
    appSettings.enableTaskInterval = true;
    appSettings.enableTaskDelay = true;
  });

  tearDown(() async {
    // Closing the database right after dispose() races its fire-and-forget
    // subscription cancellation and can hang; wait for cancellation first.
    await appRepository.disposeAndAwaitCancellation();
    appSettings.dispose();
    await database.close();
  });

  Widget wrap(Widget home) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appRepository),
        ChangeNotifierProvider<SubscriptionService>(create: (_) => SubscriptionService()),
      ],
      child: MaterialApp(theme: materialAppTheme, home: home),
    );
  }

  /// Drift writes land through a stream, so the repository needs a moment
  /// before an assertion can read the persisted rule back. The wait has to run
  /// through [WidgetTester.runAsync] — real timers do not fire inside the fake
  /// async zone a widget test runs in.
  Future<void> waitForRepositoryUpdate(WidgetTester tester) async {
    final completer = Completer<void>();
    void listener() {
      if (!completer.isCompleted) completer.complete();
    }

    appRepository.addListener(listener);
    await tester.runAsync(() async {
      try {
        await completer.future.timeout(const Duration(seconds: 5));
      } catch (_) {
        // Fall back to the pumps below.
      }
    });
    appRepository.removeListener(listener);

    await tester.pumpAndSettle();
  }

  TaskRule ruleWith({TaskThreshold? interval, TaskThreshold? delay}) => TaskRule(
        name: 'Service Fork',
        tags: const {},
        association: BikeTaskAssociation(bike.id),
        interval: interval,
        delay: delay,
      );

  TaskRule? popped;

  Future<void> openEditPage(WidgetTester tester, TaskRule rule) async {
    popped = null;
    await tester.runAsync(() async {
      await appRepository.addBikes([bike]);
      await pumpEventQueue();
    });

    await tester.pumpWidget(wrap(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                popped = await Navigator.push<TaskRule>(
                  context,
                  MaterialPageRoute(builder: (_) => TaskRulePage.edit(taskRule: rule)),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// The trigger rows sit below the fold of the 800x600 test viewport.
  Future<void> tapUnit(WidgetTester tester, Finder unit) async {
    await tester.ensureVisible(unit);
    await tester.pumpAndSettle();
    await tester.tap(unit);
    await tester.pumpAndSettle();
  }

  group('canQuickEditTaskDelay', () {
    test('allows a rule whose trigger supports a delay and has none yet', () {
      final rule = ruleWith(interval: const DurationThreshold(Duration(days: 30)));
      expect(canQuickEditTaskDelay(rule, appSettings), isTrue);
    });

    test('allows a rule whose existing delay matches the trigger type', () {
      final rule = ruleWith(
        interval: const DurationThreshold(Duration(days: 30)),
        delay: const DurationThreshold(Duration(days: 5)),
      );
      expect(canQuickEditTaskDelay(rule, appSettings), isTrue);
    });

    test('rejects a rule whose delay type deviates from the trigger type', () {
      // Only the full edit page can repair such a legacy rule, so typing a
      // bare value must not be offered.
      final rule = ruleWith(
        interval: const DurationThreshold(Duration(days: 30)),
        delay: const DistanceThreshold(500000),
      );
      expect(canQuickEditTaskDelay(rule, appSettings), isFalse);
    });

    test('rejects a rule without a trigger', () {
      expect(canQuickEditTaskDelay(ruleWith(), appSettings), isFalse);
    });

    test('rejects a date deadline, which has no unit to add a delay to', () {
      final rule = ruleWith(interval: DateTimeThreshold(DateTime.utc(2026, 12, 31)));
      expect(canQuickEditTaskDelay(rule, appSettings), isFalse);
    });

    test('rejects when the delay feature is disabled', () {
      appSettings.enableTaskDelay = false;
      final rule = ruleWith(interval: const DurationThreshold(Duration(days: 30)));
      expect(canQuickEditTaskDelay(rule, appSettings), isFalse);
    });
  });

  group('TaskRuleListCard delay option', () {
    // The swipe-to-delay background behind the card renders the same label,
    // so a bare find.text() is ambiguous once the popup menu is open.
    Finder findMenuOption(String text) => find.descendant(
          of: find.byWidgetPredicate((widget) => widget is PopupMenuItem),
          matching: find.text(text),
        );

    Future<void> pumpCardMenu(WidgetTester tester, TaskRule rule) async {
      await tester.runAsync(() async {
        await appRepository.addBikes([bike]);
        await appRepository.addTaskRules([rule]);
        await pumpEventQueue();
      });
      await tester.pumpWidget(wrap(Scaffold(body: TaskRuleListCard(taskRuleId: rule.id))));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
    }

    testWidgets('replaces "Add Task Entry" with "Add Delay"', (tester) async {
      await pumpCardMenu(tester, ruleWith(interval: const DurationThreshold(Duration(days: 30))));

      expect(find.text('Add Task Entry'), findsNothing);
      expect(findMenuOption('Add Delay'), findsOneWidget);
    });

    testWidgets('labels the option "Edit Delay" once a delay exists', (tester) async {
      await pumpCardMenu(tester, ruleWith(
        interval: const DurationThreshold(Duration(days: 30)),
        delay: const DurationThreshold(Duration(days: 5)),
      ));

      expect(findMenuOption('Edit Delay'), findsOneWidget);
    });

    testWidgets('hides the option when no valid delay could be saved', (tester) async {
      await pumpCardMenu(tester, ruleWith(
        interval: const DurationThreshold(Duration(days: 30)),
        delay: const DistanceThreshold(500000),
      ));

      expect(find.text('Add Delay'), findsNothing);
      expect(find.text('Edit Delay'), findsNothing);
      // The remaining options stay reachable.
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('hides the option for a rule without a trigger', (tester) async {
      await pumpCardMenu(tester, ruleWith());

      expect(find.text('Add Delay'), findsNothing);
    });

    testWidgets('opens a sheet showing the rule alongside the value field', (tester) async {
      await pumpCardMenu(tester, ruleWith(interval: const DurationThreshold(Duration(days: 30))));

      await tester.tap(findMenuOption('Add Delay'));
      await tester.pumpAndSettle();

      expect(find.text('Delay Value'), findsOneWidget);
      expect(find.text('days'), findsOneWidget); // unit follows the trigger
      expect(find.text('Service Fork'), findsWidgets); // status card on top
    });

    testWidgets('saves a typed delay', (tester) async {
      final rule = ruleWith(interval: const DurationThreshold(Duration(days: 30)));
      await pumpCardMenu(tester, rule);

      await tester.tap(findMenuOption('Add Delay'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '5');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await waitForRepositoryUpdate(tester);

      final saved = appRepository.taskRules[rule.id]?.delay;
      expect(saved, isA<DurationThreshold>());
      expect((saved as DurationThreshold).days, const Duration(days: 5));
    });

    testWidgets('clears the delay when the value is emptied', (tester) async {
      final rule = ruleWith(
        interval: const DurationThreshold(Duration(days: 30)),
        delay: const DurationThreshold(Duration(days: 5)),
      );
      await pumpCardMenu(tester, rule);

      await tester.tap(findMenuOption('Edit Delay'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await waitForRepositoryUpdate(tester);

      expect(appRepository.taskRules[rule.id]?.delay, isNull);
    });

    testWidgets('rejects a zero when adding a delay', (tester) async {
      final rule = ruleWith(interval: const DurationThreshold(Duration(days: 30)));
      await pumpCardMenu(tester, rule);

      await tester.tap(findMenuOption('Add Delay'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '0');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Must be greater than 0'), findsOneWidget);
      expect(appRepository.taskRules[rule.id]?.delay, isNull);
    });

    testWidgets('accepts a zero when editing a delay and drops it', (tester) async {
      final rule = ruleWith(
        interval: const DurationThreshold(Duration(days: 30)),
        delay: const DurationThreshold(Duration(days: 5)),
      );
      await pumpCardMenu(tester, rule);

      await tester.tap(findMenuOption('Edit Delay'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '0');
      await tester.pump();

      expect(find.text('Must be greater than 0'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await waitForRepositoryUpdate(tester);

      expect(appRepository.taskRules[rule.id]?.delay, isNull);
    });

    testWidgets('clears the value through the suffix icon', (tester) async {
      final rule = ruleWith(
        interval: const DurationThreshold(Duration(days: 30)),
        delay: const DurationThreshold(Duration(days: 5)),
      );
      await pumpCardMenu(tester, rule);

      await tester.tap(findMenuOption('Edit Delay'));
      await tester.pumpAndSettle();

      // The icon shows only while the field holds a value.
      expect(find.byIcon(Icons.clear), findsOneWidget);
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.clear), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await waitForRepositoryUpdate(tester);

      expect(appRepository.taskRules[rule.id]?.delay, isNull);
    });
  });

  group('completing a task consumes its delay', () {
    testWidgets('bulk completion skips already completed rules', (tester) async {
      final openRule = TaskRule(name: 'Open', tags: const {});
      final completedRule = TaskRule(name: 'Completed', tags: const {});
      final completedEntry = TaskEntry(
        name: completedRule.name,
        dateTimeUTC: DateTime.now().toUtc(),
        dateTimeLocal: DateTime.now(),
        taskRule: completedRule.id,
      );
      await tester.runAsync(() async {
        await appRepository.addTaskRules([openRule, completedRule]);
        await appRepository.addTaskEntries([completedEntry]);
        await pumpEventQueue();
      });

      await tester.pumpWidget(wrap(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => TaskActions.addDefaultTaskEntries(
                context,
                taskRuleIds: [openRule.id, completedRule.id],
              ),
              child: const Text('Complete selected'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Complete selected'));
      await waitForRepositoryUpdate(tester);

      expect(appRepository.taskEntries.values.where((entry) => entry.taskRule == openRule.id), hasLength(1));
      expect(appRepository.taskEntries.values.where((entry) => entry.taskRule == completedRule.id), hasLength(1));
    });

    test('adding a task entry drops the delay', () async {
      final rule = ruleWith(
        interval: const DurationThreshold(Duration(days: 30)),
        delay: const DurationThreshold(Duration(days: 5)),
      );
      await appRepository.addBikes([bike]);
      await appRepository.addTaskRules([rule]);
      await pumpEventQueue();

      expect(appRepository.taskRules[rule.id]?.delay, isNotNull);

      await appRepository.addTaskEntries([TaskEntry(
        name: 'Done',
        dateTimeUTC: DateTime.now().toUtc(),
        dateTimeLocal: DateTime.now(),
        taskRule: rule.id,
        association: BikeTaskAssociation(bike.id),
      )]);
      await pumpEventQueue();

      expect(appRepository.taskRules[rule.id]?.delay, isNull);
      // Only the delay is dropped — the trigger itself must survive.
      expect(appRepository.taskRules[rule.id]?.interval, isA<DurationThreshold>());
    });

    test('leaves a rule without a delay untouched', () async {
      final rule = ruleWith(interval: const DurationThreshold(Duration(days: 30)));
      await appRepository.addBikes([bike]);
      await appRepository.addTaskRules([rule]);
      await pumpEventQueue();

      final before = appRepository.taskRules[rule.id]!.lastModified;

      await appRepository.addTaskEntries([TaskEntry(
        name: 'Done',
        dateTimeUTC: DateTime.now().toUtc(),
        dateTimeLocal: DateTime.now(),
        taskRule: rule.id,
        association: BikeTaskAssociation(bike.id),
      )]);
      await pumpEventQueue();

      expect(appRepository.taskRules[rule.id]?.delay, isNull);
      expect(appRepository.taskRules[rule.id]?.lastModified, before);
    });

    testWidgets('ticking the card checkbox drops the delay', (tester) async {
      final rule = ruleWith(
        interval: const DurationThreshold(Duration(days: 30)),
        delay: const DurationThreshold(Duration(days: 5)),
      );
      await tester.runAsync(() async {
        await appRepository.addBikes([bike]);
        await appRepository.addTaskRules([rule]);
        await pumpEventQueue();
      });
      await tester.pumpWidget(wrap(Scaffold(body: TaskRuleListCard(taskRuleId: rule.id))));
      await tester.pumpAndSettle();

      // The checkbox routes through TaskEntryPage, which every completion path
      // in the UI shares.
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check));
      // TaskEntryPage saves behind a real async stats lookup, which only makes
      // progress outside the fake async zone a widget test runs in.
      await tester.pump();
      await tester.runAsync(() => pumpEventQueue());
      await tester.pumpAndSettle();
      await waitForRepositoryUpdate(tester);

      // Guards the assertion below: without an entry there is nothing to
      // consume the delay, and the test would pass for the wrong reason.
      expect(appRepository.taskEntries.values.where((e) => e.taskRule == rule.id), hasLength(1));
      expect(appRepository.taskRules[rule.id]?.delay, isNull);
    });
  });

  group('TaskRulePage delay follows the trigger type', () {
    Finder delayValueField() => find.byKey(const Key('taskRuleDelayValue'));

    testWidgets('offers a bare value field carrying the trigger unit', (tester) async {
      await openEditPage(tester, ruleWith(interval: const ElevationThreshold(1000)));

      // Nothing left to pick: a delay can only ever be of the trigger's type.
      expect(find.byKey(const Key('taskRuleDelayType')), findsNothing);
      expect(find.text('m'), findsNWidgets(2)); // trigger value + delay value

      await tester.enterText(delayValueField(), '200');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect(popped!.delay, isA<ElevationThreshold>());
      expect((popped!.delay as ElevationThreshold).meters, 200);
    });

    testWidgets('an empty delay value neither blocks saving nor becomes zero', (tester) async {
      await openEditPage(tester, ruleWith(interval: const DurationThreshold(Duration(days: 30))));

      expect(delayValueField(), findsOneWidget);
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.byType(TaskRulePage), findsNothing); // saved and popped
      expect(popped, isNotNull);
      expect(popped!.delay, isNull);
    });

    testWidgets('saves a delay typed into the trigger type', (tester) async {
      await openEditPage(tester, ruleWith(interval: const DurationThreshold(Duration(days: 30))));

      await tester.enterText(delayValueField(), '7');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect(popped!.delay, isA<DurationThreshold>());
      expect((popped!.delay as DurationThreshold).days, const Duration(days: 7));
    });

    testWidgets('keeps an existing delay of the trigger type', (tester) async {
      await openEditPage(tester, ruleWith(
        interval: const DurationThreshold(Duration(days: 30)),
        delay: const DurationThreshold(Duration(days: 5)),
      ));

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect((popped!.delay as DurationThreshold).days, const Duration(days: 5));
    });

    testWidgets('rejects a zero when adding a delay', (tester) async {
      await openEditPage(tester, ruleWith(interval: const DurationThreshold(Duration(days: 30))));

      await tester.enterText(delayValueField(), '0');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('Must be greater than 0'), findsOneWidget);
      expect(find.byType(TaskRulePage), findsOneWidget); // save blocked
    });

    testWidgets('accepts a zero when editing a delay and drops it', (tester) async {
      await openEditPage(tester, ruleWith(
        interval: const DurationThreshold(Duration(days: 30)),
        delay: const DurationThreshold(Duration(days: 5)),
      ));

      await tester.enterText(delayValueField(), '0');
      await tester.pump();
      expect(find.text('Must be greater than 0'), findsNothing);

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect(popped!.delay, isNull);
    });

    testWidgets('carries a unit of its own, independent of the trigger', (tester) async {
      await openEditPage(tester, ruleWith(interval: const DurationThreshold(Duration(days: 365))));

      await tester.enterText(delayValueField(), '2');
      await tester.pump();
      await tapUnit(tester, find.descendant(of: delayValueField(), matching: find.text('days')));

      // The trigger keeps its own unit while the delay moves on to weeks.
      expect(find.descendant(of: delayValueField(), matching: find.text('weeks')), findsOneWidget);
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect((popped!.interval as DurationThreshold).days, const Duration(days: 365));
      expect((popped!.delay as DurationThreshold).days, const Duration(days: 14));
    });
  });

  group('TaskRulePage duration unit', () {
    Finder intervalValueField() => find.byKey(const Key('taskRuleIntervalValue'));

    Finder unitButton(String label) =>
        find.descendant(of: intervalValueField(), matching: find.text(label));

    testWidgets('opens a saved duration in the largest unit it divides into', (tester) async {
      await openEditPage(tester, ruleWith(interval: const DurationThreshold(Duration(days: 90))));

      expect(unitButton('months'), findsOneWidget);
      final editableText = tester.widget<EditableText>(
        find.descendant(of: intervalValueField(), matching: find.byType(EditableText)),
      );
      expect(editableText.controller.text, '3');
    });

    testWidgets('cycles days → weeks → months → years on tap', (tester) async {
      await openEditPage(tester, ruleWith(interval: const DurationThreshold(Duration(days: 100))));

      var current = 'days';
      for (final next in ['weeks', 'months', 'years', 'days']) {
        await tapUnit(tester, unitButton(current));
        expect(unitButton(next), findsOneWidget);
        current = next;
      }
    });

    testWidgets('keeps the typed number and saves it in the picked unit', (tester) async {
      await openEditPage(tester, ruleWith(interval: const DurationThreshold(Duration(days: 100))));

      await tester.enterText(intervalValueField(), '3');
      await tester.pump();
      await tapUnit(tester, unitButton('days'));

      // The number stays as typed: "3 days" becomes "3 weeks", not "0.4 weeks".
      expect(unitButton('weeks'), findsOneWidget);
      final editableText = tester.widget<EditableText>(
        find.descendant(of: intervalValueField(), matching: find.byType(EditableText)),
      );
      expect(editableText.controller.text, '3');

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect((popped!.interval as DurationThreshold).days, const Duration(days: 21));
    });

    testWidgets('labels a single unit in the singular', (tester) async {
      await openEditPage(tester, ruleWith(interval: const DurationThreshold(Duration(days: 7))));

      expect(unitButton('week'), findsOneWidget);
    });
  });

  group('TaskRulePage interval value focus', () {
    Future<void> selectDurationAndExpectSelection(
      WidgetTester tester,
      TaskRulePage page,
      String expectedValue,
    ) async {
      await tester.pumpWidget(wrap(page));
      await tester.pumpAndSettle();

      final typeDropdown = find.byKey(const Key('taskRuleIntervalType'));
      await tester.ensureVisible(typeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(typeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duration').last);
      await tester.pumpAndSettle();

      final valueField = find.byKey(const Key('taskRuleIntervalValue'));
      final editableText = tester.widget<EditableText>(
        find.descendant(of: valueField, matching: find.byType(EditableText)),
      );

      expect(editableText.focusNode.hasFocus, isTrue);
      expect(editableText.controller.text, expectedValue);
      expect(
        editableText.controller.selection,
        TextSelection(baseOffset: 0, extentOffset: expectedValue.length),
      );
    }

    testWidgets('focuses an empty value in add mode', (tester) async {
      await selectDurationAndExpectSelection(tester, TaskRulePage.add(), '');
    });

    // 100 days divides into no larger unit, so the field stays in days.
    testWidgets('selects the existing value in edit mode', (tester) async {
      final rule = ruleWith(interval: const DurationThreshold(Duration(days: 100)));
      await selectDurationAndExpectSelection(tester, TaskRulePage.edit(taskRule: rule), '100');
    });

    testWidgets('selects the existing value in duplicate mode', (tester) async {
      final rule = ruleWith(interval: const DurationThreshold(Duration(days: 100)));
      await selectDurationAndExpectSelection(tester, TaskRulePage.duplicate(taskRule: rule), '100');
    });
  });
}
