import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_template.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/sheets/copy_task_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAppRepository extends Mock implements AppRepository {}

TaskRule _rule(String name, {TaskPriority priority = TaskPriority.medium, bool repeat = true, String? presetKey}) =>
    TaskRule(
      name: name,
      priority: priority,
      tags: const {},
      association: const ComponentTaskAssociation('old'),
      interval: const DistanceThreshold(500000),
      repeat: repeat,
      presetKey: presetKey,
    );

TaskSuggestion _suggestion(String key, String name, {bool preselected = false, TaskThreshold? stravaInterval}) =>
    TaskSuggestion(
      key: key,
      name: name,
      priority: TaskPriority.medium,
      repeat: true,
      preselected: preselected,
      interval: stravaInterval == null ? const DistanceThreshold(500000) : const DurationThreshold(Duration(days: 30)),
      stravaInterval: stravaInterval,
    );

void main() {
  late _MockAppRepository repository;
  late Set<TaskRule> doneRules;

  setUpAll(() => registerFallbackValue(TaskRule(name: 'fallback', tags: const {})));

  setUp(() {
    repository = _MockAppRepository();
    doneRules = {};
    when(() => repository.getTaskRuleStatus(any())).thenAnswer(
      (invocation) =>
          doneRules.contains(invocation.positionalArguments.single) ? TaskStatus.completed : TaskStatus.open,
    );
  });

  Widget harness(Future<Object?> Function(BuildContext context) open, ValueChanged<Object?> onResult) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppRepository>.value(value: repository),
        ChangeNotifierProvider<AppSettings>(create: (_) => AppSettings()),
      ],
      child: MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => onResult(await open(context)),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpSheet(
    WidgetTester tester,
    Future<Object?> Function(BuildContext context) open, [
    ValueChanged<Object?>? onResult,
  ]) async {
    await tester.pumpWidget(harness(open, onResult ?? (_) {}));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  bool? rowValue(WidgetTester tester, String name) => tester
      .widget<CheckboxListTile>(find.ancestor(of: find.text(name), matching: find.byType(CheckboxListTile)))
      .value;

  double rowOpacity(WidgetTester tester, String name) =>
      tester.widget<Opacity>(find.ancestor(of: find.text(name), matching: find.byType(Opacity)).first).opacity;

  Finder headerCheckbox(String title) => find.descendant(
    of: find.ancestor(of: find.text(title), matching: find.byType(Padding)).first,
    matching: find.byType(Checkbox),
  );

  group('copy mode', () {
    testWidgets('preselects open rules and lists completed one-offs dimmed below them', (tester) async {
      final low = _rule('Clean chain', priority: TaskPriority.low);
      final high = _rule('Replace chain', priority: TaskPriority.high);
      final done = _rule('Fix creak', repeat: false);
      doneRules = {done};

      await pumpSheet(
        tester,
        (context) => showCopyTaskRulesSheet(
          context,
          taskRules: [low, done, high],
          sourceName: 'Old chain',
          componentName: 'New chain',
        ),
      );

      expect(find.text('Copy tasks?'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text(' (2 / 3)'), findsOneWidget);
      expect(find.text('Copy 2 tasks'), findsOneWidget);

      expect(rowValue(tester, 'Replace chain'), isTrue);
      expect(rowValue(tester, 'Clean chain'), isTrue);
      expect(rowValue(tester, 'Fix creak'), isFalse);
      expect(rowOpacity(tester, 'Fix creak'), 0.5);
      expect(
        tester.getTopLeft(find.text('Replace chain')).dy,
        lessThan(tester.getTopLeft(find.text('Clean chain')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Clean chain')).dy,
        lessThan(tester.getTopLeft(find.text('Fix creak')).dy),
      );

      await tester.tap(find.text('Fix creak'));
      await tester.pump();

      expect(rowOpacity(tester, 'Fix creak'), 1);
      expect(find.text(' (3 / 3)'), findsOneWidget);
      expect(find.text('Copy 3 tasks'), findsOneWidget);
    });

    testWidgets('returns the selected rules, and null when continuing without copying', (tester) async {
      final keep = _rule('Replace chain');
      final drop = _rule('Clean chain');
      Object? result;
      await pumpSheet(
        tester,
        (context) => showCopyTaskRulesSheet(context, taskRules: [keep, drop], sourceName: 'Old', componentName: 'New'),
        (value) => result = value,
      );

      await tester.tap(find.text('Clean chain'));
      await tester.pump();
      await tester.tap(find.text('Copy 1 task'));
      await tester.pumpAndSettle();
      expect(result, [keep]);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue without copying tasks'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });

    testWidgets('disables the primary button when nothing is selected', (tester) async {
      await pumpSheet(
        tester,
        (context) => showCopyTaskRulesSheet(
          context,
          taskRules: [_rule('Replace chain')],
          sourceName: 'Old',
          componentName: 'New',
        ),
      );

      await tester.tap(find.text('Replace chain'));
      await tester.pump();

      final button = find.ancestor(
        of: find.text('Copy 0 tasks'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      expect(tester.widget<ButtonStyleButton>(button).onPressed, isNull);
    });
  });

  group('recommend mode', () {
    testWidgets('preselection follows the template and each row names its interval origin', (tester) async {
      await pumpSheet(
        tester,
        (context) => showTaskRulesSheet(
          context,
          suggestions: [
            _suggestion(
              'chain:wear_check',
              'Check chain wear',
              preselected: true,
              stravaInterval: const DistanceThreshold(500000),
            ),
            _suggestion('chain:replace', 'Replace chain'),
          ],
          componentName: 'New chain',
          componentTypeLabel: 'Chain',
        ),
      );

      expect(find.text("Recommended tasks for 'New chain'"), findsOneWidget);
      expect(rowValue(tester, 'Check chain wear'), isTrue);
      expect(rowValue(tester, 'Replace chain'), isFalse);
      expect(find.text('Recommended for Chain'), findsOneWidget);
      expect(find.text('Time-based · every 500 km with Strava'), findsOneWidget);
      expect(find.text('Typical interval'), findsOneWidget);
      expect(find.text('Add 1 task'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });
  });

  group('merged mode', () {
    late TaskRule copied;
    late List<TaskSuggestion> suggestions;

    setUp(() {
      copied = _rule('Kette prüfen', presetKey: 'chain:wear_check');
      suggestions = [
        _suggestion('chain:wear_check', 'Check chain wear', preselected: true),
        _suggestion('chain:replace', 'Replace chain'),
      ];
    });

    Future<TaskRulesSheetResult?> open(BuildContext context) => showTaskRulesSheet(
      context,
      copyFrom: 'Old chain',
      copyRules: [copied],
      suggestions: suggestions,
      componentName: 'New chain',
      componentTypeLabel: 'Chain',
    );

    testWidgets('a selected copy hides the suggestion with its key; unchecking reveals it unchecked', (tester) async {
      await pumpSheet(tester, open);

      expect(find.text("Tasks for 'New chain'"), findsOneWidget);
      expect(find.text("Copy from 'Old chain'"), findsOneWidget);
      expect(find.text('Recommended for Chain'), findsOneWidget);
      expect(find.text('Check chain wear'), findsNothing);
      expect(find.text('Replace chain'), findsOneWidget);
      expect(find.text('Add 1 task'), findsOneWidget);

      await tester.tap(find.text('Kette prüfen'));
      await tester.pumpAndSettle();

      expect(find.text('Check chain wear'), findsOneWidget);
      expect(rowValue(tester, 'Check chain wear'), isFalse);
      expect(find.text('Add 0 tasks'), findsOneWidget);
    });

    testWidgets('a suggestion checked by hand comes back unchecked after its copy is re-selected', (tester) async {
      await pumpSheet(tester, open);

      await tester.tap(find.text('Kette prüfen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check chain wear'));
      await tester.pump();
      expect(rowValue(tester, 'Check chain wear'), isTrue);

      await tester.tap(find.text('Kette prüfen'));
      await tester.pumpAndSettle();
      expect(find.text('Check chain wear'), findsNothing);

      await tester.tap(find.text('Kette prüfen'));
      await tester.pumpAndSettle();
      expect(rowValue(tester, 'Check chain wear'), isFalse);
    });

    testWidgets('the panel is absent while its only suggestion is hidden, and reveals it unchecked', (tester) async {
      await pumpSheet(
        tester,
        (context) => showTaskRulesSheet(
          context,
          copyFrom: 'Old chain',
          copyRules: [copied],
          suggestions: [suggestions.first],
          componentName: 'New chain',
          componentTypeLabel: 'Chain',
        ),
      );

      expect(find.text('Recommended for Chain'), findsNothing);

      await tester.tap(find.text('Kette prüfen'));
      await tester.pumpAndSettle();

      expect(find.text('Recommended for Chain'), findsOneWidget);
      expect(rowValue(tester, 'Check chain wear'), isFalse);
    });

    testWidgets('a completed copy with the key leaves its suggestion visible but unchecked', (tester) async {
      final done = _rule('Kette prüfen', repeat: false, presetKey: 'chain:wear_check');
      doneRules = {done};
      await pumpSheet(
        tester,
        (context) => showTaskRulesSheet(
          context,
          copyFrom: 'Old chain',
          copyRules: [done],
          suggestions: suggestions,
          componentName: 'New chain',
          componentTypeLabel: 'Chain',
        ),
      );

      expect(rowValue(tester, 'Kette prüfen'), isFalse);
      expect(rowValue(tester, 'Check chain wear'), isFalse);
    });

    testWidgets('unchecking the copy section reveals keyed suggestions unchecked; others keep their preselection', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        (context) => showTaskRulesSheet(
          context,
          copyFrom: 'Old chain',
          copyRules: [copied],
          suggestions: [...suggestions, _suggestion('chain:lube', 'Clean & lube chain', preselected: true)],
          componentName: 'New chain',
          componentTypeLabel: 'Chain',
        ),
      );

      await tester.tap(headerCheckbox("Copy from 'Old chain'"));
      await tester.pumpAndSettle();

      expect(rowValue(tester, 'Kette prüfen'), isFalse);
      expect(rowValue(tester, 'Check chain wear'), isFalse);
      expect(rowValue(tester, 'Clean & lube chain'), isTrue);
    });

    testWidgets('each section header toggles only its own section', (tester) async {
      await pumpSheet(tester, open);

      await tester.tap(headerCheckbox('Recommended for Chain'));
      await tester.pump();
      expect(rowValue(tester, 'Replace chain'), isTrue);
      expect(rowValue(tester, 'Kette prüfen'), isTrue);

      await tester.tap(headerCheckbox("Copy from 'Old chain'"));
      await tester.pumpAndSettle();
      expect(rowValue(tester, 'Kette prüfen'), isFalse);
      expect(rowValue(tester, 'Replace chain'), isTrue);
      expect(rowValue(tester, 'Check chain wear'), isFalse);
    });

    group('panel animation', () {
      Future<TaskRulesSheetResult?> openWithHiddenPanel(BuildContext context) => showTaskRulesSheet(
        context,
        copyFrom: 'Old chain',
        copyRules: [copied],
        suggestions: [suggestions.first],
        componentName: 'New chain',
        componentTypeLabel: 'Chain',
      );

      double panelHeight(WidgetTester tester) => tester
          .getSize(find.ancestor(of: find.text('Recommended for Chain'), matching: find.byType(SizeTransition)).first)
          .height;

      testWidgets('grows the panel in over time', (tester) async {
        await pumpSheet(tester, openWithHiddenPanel);

        await tester.tap(find.text('Kette prüfen'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final midHeight = panelHeight(tester);

        await tester.pumpAndSettle();
        final fullHeight = panelHeight(tester);
        expect(midHeight, greaterThan(0));
        expect(midHeight, lessThan(fullHeight));
      });

      testWidgets('shows the panel at full size in one frame when animations are disabled', (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        );
        addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
        await pumpSheet(tester, openWithHiddenPanel);

        await tester.tap(find.text('Kette prüfen'));
        await tester.pump();
        final firstFrameHeight = panelHeight(tester);

        await tester.pumpAndSettle();
        expect(firstFrameHeight, greaterThan(0));
        expect(firstFrameHeight, panelHeight(tester));
      });
    });

    testWidgets('splits the result into copied rules and suggestions', (tester) async {
      Object? result;
      await pumpSheet(tester, open, (value) => result = value);

      await tester.tap(find.text('Replace chain'));
      await tester.pump();
      await tester.tap(find.text('Add 2 tasks'));
      await tester.pumpAndSettle();

      final sheetResult = result! as TaskRulesSheetResult;
      expect(sheetResult.copied, [copied]);
      expect([for (final s in sheetResult.suggested) s.key], ['chain:replace']);
    });

    testWidgets('skip returns null', (tester) async {
      Object? result = 'unset';
      await pumpSheet(tester, open, (value) => result = value);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });

    testWidgets('long names do not overflow on a narrow screen', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final longName = 'A' * 120;
      final done = _rule(longName, repeat: false);
      doneRules = {done};

      await pumpSheet(
        tester,
        (context) => showTaskRulesSheet(
          context,
          copyFrom: longName,
          copyRules: [
            _rule(longName, priority: TaskPriority.critical),
            done,
          ],
          suggestions: [_suggestion('chain:replace', longName, stravaInterval: const DistanceThreshold(2000000))],
          componentName: longName,
          componentTypeLabel: 'Chain',
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
