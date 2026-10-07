import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/pages/forms/task_rule_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/attachment_strip.dart';
import 'package:bike_setup_tracker/widgets/task_preset_chips.dart';
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

void main() {
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;
  late bool hasStravaEntitlement;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
    appSettings.enableTaskTags = true;
    hasStravaEntitlement = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => Directory.systemTemp.path,
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      null,
    );
    // Closing the database right after dispose() races its fire-and-forget
    // subscription cancellation and can hang; wait for cancellation first.
    await appRepository.disposeAndAwaitCancellation();
    appSettings.dispose();
    await database.close();
  });

  final manual = Attachment(id: 'manual', extension: '.pdf', name: 'Fox 38 Service Manual.pdf');
  final chart = Attachment(id: 'chart', extension: '.pdf', name: 'Torque Chart.pdf');

  TaskRule rule({List<Attachment>? attachments}) => TaskRule(
    id: 'r1',
    name: 'Lower leg service',
    tags: const {'maintenance'},
    attachments: attachments ?? [manual, chart],
  );

  Object? result;

  /// Opens [page] on top of a home route, so the saved rule can be read from [result].
  Future<void> openForm(WidgetTester tester, TaskRulePage Function() page, {ThemeData? theme}) async {
    result = null;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appRepository),
          ChangeNotifierProvider<SubscriptionService>(create: (_) => MockSubscriptionService(hasStravaEntitlement: hasStravaEntitlement)),
        ],
        child: MaterialApp(
          theme: theme ?? materialAppTheme,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await Navigator.push(context, MaterialPageRoute<TaskRule>(builder: (_) => page())),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder attachChip() => find.widgetWithIcon(ActionChip, Icons.attach_file);

  group('TaskRulePage attachments', () {
    testWidgets('hides the Attach chip and the strip when attachments are disabled', (tester) async {
      await openForm(tester, () => TaskRulePage.edit(taskRule: rule()));

      expect(attachChip(), findsNothing);
      expect(find.byType(AttachmentStrip), findsNothing);
    });

    testWidgets('shows the Attach chip last in the chip row and the strip above "Linked To"', (tester) async {
      appSettings.enableAttachments = true;
      await openForm(tester, () => TaskRulePage.edit(taskRule: rule()));

      final wrap = find.ancestor(of: attachChip(), matching: find.byType(Wrap));
      expect(wrap, findsOneWidget);
      expect(
        tester.widget<Wrap>(wrap).children.last,
        isA<ActionChip>().having((c) => c.tooltip, 'tooltip', 'Add Attachment'),
      );
      expect(find.descendant(of: wrap, matching: find.byTooltip('Add Tags')), findsOneWidget);
      expect(find.byType(AttachmentStrip), findsOneWidget);
      expect(find.text('Fox 38 Service Manual.pdf'), findsOneWidget);
      expect(
        tester.getBottomLeft(find.byType(AttachmentStrip)).dy,
        lessThan(tester.getTopLeft(find.text('Linked To')).dy),
      );
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
    });

    testWidgets('shows the Attach chip alone when priority and tags are disabled', (tester) async {
      appSettings.enableAttachments = true;
      appSettings.enableTaskPriority = false;
      appSettings.enableTaskTags = false;
      await openForm(tester, () => TaskRulePage.add());

      final wrap = find.ancestor(of: attachChip(), matching: find.byType(Wrap));
      expect(tester.widget<Wrap>(wrap).children, hasLength(1));
      expect(find.byType(AttachmentStrip), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hides the Attach chip when attachments, priority and tags are disabled', (tester) async {
      appSettings.enableTaskPriority = false;
      appSettings.enableTaskTags = false;
      await openForm(tester, () => TaskRulePage.add());

      expect(attachChip(), findsNothing);
      expect(tester.takeException(), isNull);
    });

    for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
      testWidgets('the chips and a long attachment name fit a narrow screen ($label)', (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        appSettings.enableAttachments = true;
        final longName = '${'Very long service manual name ' * 6}.pdf';
        await openForm(
          tester,
          () => TaskRulePage.edit(
            taskRule: rule(
              attachments: [
                Attachment(extension: '.pdf', name: longName),
                chart,
              ],
            ),
          ),
          theme: theme,
        );

        expect(attachChip(), findsOneWidget);
        expect(find.text(longName), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('removing an attachment marks the form changed and saving returns the rest', (tester) async {
      appSettings.enableAttachments = true;
      await openForm(tester, () => TaskRulePage.edit(taskRule: rule()));

      Color? chipColor() => tester.widget<ActionChip>(attachChip()).backgroundColor;
      expect(chipColor(), isNull);

      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Fox 38 Service Manual.pdf'), findsNothing);
      final changedFill = Theme.of(tester.element(attachChip())).extension<ValueHighlightColors>()!.changedFill;
      expect(chipColor(), changedFill);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(result, isA<TaskRule>());
      final saved = result! as TaskRule;
      expect(saved.id, 'r1');
      expect(saved.attachments, [chart]);
    });

    testWidgets('saving with attachments disabled keeps the list', (tester) async {
      await openForm(tester, () => TaskRulePage.edit(taskRule: rule()));

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect((result! as TaskRule).attachments, [manual, chart]);
    });

    testWidgets('duplicate mode starts with the passed copies and saves them under a new id', (tester) async {
      appSettings.enableAttachments = true;
      await openForm(tester, () => TaskRulePage.duplicate(taskRule: rule()));

      expect(find.text('Fox 38 Service Manual.pdf'), findsOneWidget);
      expect(find.text('Torque Chart.pdf'), findsOneWidget);
      expect(tester.widget<ActionChip>(attachChip()).backgroundColor, isNull);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      final saved = result! as TaskRule;
      expect(saved.id, isNot('r1'));
      expect(saved.attachments, [manual, chart]);
    });
  });

  group('TaskRulePage presetKey', () {
    testWidgets('editing and saving a keyed rule keeps the key, even after a rename', (tester) async {
      await openForm(tester, () => TaskRulePage.edit(taskRule: rule().copyWith(presetKey: 'fork:lower_leg_service')));

      await tester.enterText(find.widgetWithText(TextFormField, 'Lower leg service'), 'Fork service');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      final saved = result! as TaskRule;
      expect(saved.name, 'Fork service');
      expect(saved.presetKey, 'fork:lower_leg_service');
    });

    testWidgets('duplicate mode keeps the key', (tester) async {
      await openForm(tester, () => TaskRulePage.duplicate(taskRule: rule().copyWith(presetKey: 'fork:lower_leg_service')));

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect((result! as TaskRule).presetKey, 'fork:lower_leg_service');
    });
  });

  group('TaskRulePage preset chips', () {
    final bike = Bike(id: 'b1', name: 'Test Bike', person: null);
    final chain = Component(
      id: 'ch1',
      name: 'Chain',
      componentType: ComponentType.chain,
      installations: [Installation.sinceBeginning(parent: 'b1')],
      adjustments: const [],
    );
    final wheel = Component(
      id: 'w1',
      name: 'Rear Wheel',
      componentType: ComponentType.wheelRear,
      installations: [Installation.sinceBeginning(parent: 'b1')],
      adjustments: const [],
    );

    void enableTaskPresets() {
      appSettings
        ..enableTask = true
        ..enableTaskInterval = true
        ..enableComponentPresets = true
        ..enableTaskPresets = true;
    }

    /// Stores the test data and reloads the repository, so it is in memory
    /// before the form opens.
    Future<void> seed(WidgetTester tester, {List<TaskRule> rules = const []}) async {
      await tester.runAsync(() async {
        await appRepository.addBikes([bike]);
        await appRepository.addComponents([chain, wheel]);
        await appRepository.addTaskRules(rules);
        await Future<void>.delayed(Duration.zero);
        await appRepository.disposeAndAwaitCancellation();
        appRepository = AppRepository(database);
        await appRepository.initialDataLoaded;
      });
    }

    Finder chip(String name) => find.widgetWithText(ActionChip, name);

    Future<void> pickAssociation(WidgetTester tester, String label) async {
      await tester.tap(find.ancestor(of: find.text('Linked To'), matching: find.byType(InkWell)).first);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text(label)).last);
      // The picker closes after a short delay that shows the selection.
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
    }

    Future<TaskRule> save(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      return result! as TaskRule;
    }

    testWidgets('a chip fills the form, hides the row and saves its presetKey', (tester) async {
      enableTaskPresets();
      hasStravaEntitlement = true;
      await seed(tester);
      await openForm(tester, () => TaskRulePage.addForComponent(componentId: 'ch1'));

      expect(chip('Check chain wear'), findsOneWidget);
      expect(chip('Replace chain'), findsOneWidget);

      await tester.tap(chip('Check chain wear'));
      await tester.pumpAndSettle();

      expect(find.byType(TaskPresetChips), findsNothing);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
      final saved = await save(tester);
      expect(saved.name, 'Check chain wear');
      expect(saved.presetKey, 'chain:wear_check');
      expect(saved.association, const ComponentTaskAssociation('ch1'));
      expect(saved.interval, const DistanceThreshold(500000));
      expect(saved.repeat, isTrue);
      expect(saved.notes, isNot(contains('Recommended interval')));
    });

    testWidgets('consumed templates get no chip', (tester) async {
      enableTaskPresets();
      hasStravaEntitlement = true;
      await seed(
        tester,
        rules: [
          TaskRule(
            name: 'Measure stretch',
            tags: const {},
            association: const ComponentTaskAssociation('ch1'),
            presetKey: 'chain:wear_check',
          ),
        ],
      );
      await openForm(tester, () => TaskRulePage.addForComponent(componentId: 'ch1'));

      expect(chip('Check chain wear'), findsNothing);
      expect(chip('Replace chain'), findsOneWidget);
    });

    testWidgets('without Strava, the fallback interval is filled and ride-only templates have no chip', (tester) async {
      enableTaskPresets();
      await seed(tester);
      await openForm(tester, () => TaskRulePage.addForComponent(componentId: 'ch1'));

      expect(chip('Replace chain'), findsNothing);
      expect(chip('Clean & lube chain'), findsNothing);

      await tester.tap(chip('Check chain wear'));
      await tester.pumpAndSettle();
      expect(find.text('month'), findsOneWidget);

      final saved = await save(tester);
      expect(saved.interval, const DurationThreshold(Duration(days: 30)));
      expect(saved.presetKey, 'chain:wear_check');
    });

    testWidgets('no chips with presets off', (tester) async {
      await seed(tester);
      await openForm(tester, () => TaskRulePage.addForComponent(componentId: 'ch1'));

      expect(find.byType(TaskPresetChips), findsNothing);
    });

    for (final (label, page) in [
      ('a bike association', () => TaskRulePage.addForBike(bikeId: 'b1')),
      ('edit mode', () => TaskRulePage.edit(taskRule: rule().copyWith(association: const ComponentTaskAssociation('ch1')))),
    ]) {
      testWidgets('no chips for $label', (tester) async {
        enableTaskPresets();
        await seed(tester);
        await openForm(tester, page);

        expect(find.byType(TaskPresetChips), findsNothing);
      });
    }

    testWidgets('picking a component later shows its chips', (tester) async {
      enableTaskPresets();
      await seed(tester);
      await openForm(tester, () => TaskRulePage.add());
      expect(find.byType(TaskPresetChips), findsNothing);

      await pickAssociation(tester, 'Rear Wheel');

      expect(chip('Spoke tension check'), findsOneWidget);
    });

    testWidgets('switching to a bike after a chip tap drops the key', (tester) async {
      enableTaskPresets();
      await seed(tester);
      await openForm(tester, () => TaskRulePage.addForComponent(componentId: 'ch1'));

      await tester.tap(chip('Check chain wear'));
      await tester.pumpAndSettle();
      await pickAssociation(tester, 'Test Bike');

      final saved = await save(tester);
      expect(saved.name, 'Check chain wear');
      expect(saved.association, const BikeTaskAssociation('b1'));
      expect(saved.presetKey, isNull);
    });

    testWidgets('switching to a component of another type drops the key and offers its chips', (tester) async {
      enableTaskPresets();
      await seed(tester);
      await openForm(tester, () => TaskRulePage.addForComponent(componentId: 'ch1'));

      await tester.tap(chip('Check chain wear'));
      await tester.pumpAndSettle();
      await pickAssociation(tester, 'Rear Wheel');

      expect(chip('Spoke tension check'), findsOneWidget);
      expect((await save(tester)).presetKey, isNull);
    });

    for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
      testWidgets('the chip row fits a narrow screen ($label)', (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        enableTaskPresets();
        hasStravaEntitlement = true;
        await seed(tester);
        await openForm(tester, () => TaskRulePage.addForComponent(componentId: 'ch1'), theme: theme);

        expect(find.byType(TaskPresetChips), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
