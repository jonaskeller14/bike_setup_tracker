import 'package:bike_setup_tracker/models/app_hint.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/setup_comparison.dart' as comparison;
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/compare_setups/setup_comparison_header.dart';
import 'package:bike_setup_tracker/widgets/compare_setups/setup_comparison_owner_card.dart';
import 'package:bike_setup_tracker/widgets/current_setup_badge.dart';
import 'package:bike_setup_tracker/widgets/current_setup_highlight.dart';
import 'package:bike_setup_tracker/widgets/display_adjustment/display_adjustment_diff.dart';
import 'package:bike_setup_tracker/widgets/sheets/compare_setups.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'compare_setups_harness.dart';

void main() {
  late CompareSetupsHarness harness;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    harness = await CompareSetupsHarness.create();
  });

  tearDown(() => harness.dispose());

  Future<(String, String)> seedPair(
    WidgetTester tester, {
    String? name,
    bool extraDifferences = false,
  }) async {
    final older = harness.setup(
      id: 'older',
      name: name ?? 'Baseline',
      local: DateTime(2026, 8, 1, 10),
      values: {
        CompareSetupsHarness.changedAdjustmentId: 2,
        CompareSetupsHarness.unchangedAdjustmentId: 80,
        if (extraDifferences)
          for (var index = 0; index < 12; index++) 'extra-$index': index,
      },
    );
    final newer = harness.setup(
      id: 'newer',
      name: name ?? 'Candidate',
      local: DateTime(2026, 8, 2, 10),
      values: {
        CompareSetupsHarness.changedAdjustmentId: 4,
        CompareSetupsHarness.unchangedAdjustmentId: 80,
        if (extraDifferences)
          for (var index = 0; index < 12; index++) 'extra-$index': index + 1,
      },
    );
    await harness.addSetups(tester, [older, newer]);
    await harness.reload(tester);
    return (older.id, newer.id);
  }

  Future<void> pumpComparison(
    WidgetTester tester,
    String setupAId,
    String setupBId, {
    double width = 390,
    double? height,
    bool dark = false,
  }) async {
    await tester.pumpWidget(
      harness.wrap(
        CompareSetups(setupAId: setupAId, setupBId: setupBId),
        width: width,
        height: height,
        dark: dark,
      ),
    );
    await settle(tester);
  }

  testWidgets('Values filter starts in Differences and All reveals unchanged rows', (tester) async {
    final (setupAId, setupBId) = await seedPair(tester);
    await pumpComparison(tester, setupAId, setupBId);

    expect(find.text('Differences (1)'), findsOneWidget);
    expect(find.text('VALUES'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(const Key('compare-filter-control')),
        matching: find.byType(PinnedHeaderSliver),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('compare-owner-component-fork')), findsOneWidget);
    expect(find.textContaining('1/2 values differs'), findsOneWidget);
    expect(find.textContaining('A: Present'), findsNothing);
    expect(find.byKey(const Key('compare-row-fork-pressure')), findsNothing);
    expect(find.textContaining('Δ'), findsNothing);

    await tester.tap(find.text('All'));
    await settle(tester);

    expect(find.byKey(const Key('compare-row-fork-pressure')), findsOneWidget);
  });

  testWidgets('shows and dismisses the comparison hint above Context', (tester) async {
    final (setupAId, setupBId) = await seedPair(tester);
    await harness.hintService.resetAll();
    await pumpComparison(tester, setupAId, setupBId);

    expect(find.byKey(const Key('compare-setups-hint')), findsOneWidget);
    expect(find.text('Compare two setups'), findsOneWidget);
    expect(find.text('CONTEXT'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const Key('compare-setups-hint'))).bottom,
      lessThan(tester.getRect(find.text('CONTEXT')).top),
    );

    await tester.tap(find.byTooltip('Dismiss'));
    await settle(tester);
    expect(find.byKey(const Key('compare-setups-hint')), findsNothing);
    expect(harness.hintService.statusOf(AppHint.setupComparisonV1), AppHintStatus.dismissed);
  });

  testWidgets('keeps equal explicit and inherited values out of Differences without showing provenance', (
    tester,
  ) async {
    final explicit = harness.setup(
      id: 'explicit',
      name: 'Explicit',
      local: DateTime(2026, 8, 1, 10),
      values: {CompareSetupsHarness.changedAdjustmentId: 4},
    );
    final inherited = harness.setup(
      id: 'inherited',
      name: 'Inherited',
      local: DateTime(2026, 8, 2, 10),
    )..previousBikeAdjustmentValues = {CompareSetupsHarness.changedAdjustmentId: 4};
    await harness.addSetups(tester, [explicit, inherited]);
    await harness.reload(tester);
    await pumpComparison(tester, explicit.id, inherited.id);

    expect(find.byKey(const Key('compare-row-fork-rebound')), findsNothing);
    await tester.tap(find.text('These setups have no value differences'));
    await settle(tester);

    expect(find.byKey(const Key('compare-row-fork-rebound')), findsOneWidget);
    expect(find.text('Inherited'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('compare-panel-b-fork-rebound')),
        matching: find.text('Inherited'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('compare-panel-b-fork-rebound')),
        matching: find.text('4'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('uses a dash for cleared and unrecorded values', (tester) async {
    final cleared = harness.setup(
      id: 'cleared',
      name: 'Cleared',
      local: DateTime(2026, 8, 2, 10),
      values: {CompareSetupsHarness.changedAdjustmentId: null},
    );
    final missing = harness.setup(
      id: 'missing',
      name: 'Missing',
      local: DateTime(2026, 8, 1, 10),
    );
    await harness.addSetups(tester, [cleared, missing]);
    await harness.reload(tester);
    await pumpComparison(tester, cleared.id, missing.id);

    expect(find.text('Cleared'), findsOneWidget);
    expect(find.text('Not recorded'), findsNothing);
    expect(find.text('-'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('identical values show a Values empty hint and Show all works', (tester) async {
    final a = harness.setup(
      id: 'same-a',
      name: 'Same A',
      local: DateTime(2026, 8, 1, 10),
      values: {CompareSetupsHarness.changedAdjustmentId: 4},
    );
    final b = harness.setup(
      id: 'same-b',
      name: 'Same B',
      local: DateTime(2026, 8, 2, 10),
      values: {CompareSetupsHarness.changedAdjustmentId: 4},
    );
    await harness.addSetups(tester, [a, b]);
    await harness.reload(tester);
    await pumpComparison(tester, a.id, b.id);

    expect(find.text('These setups have no value differences'), findsOneWidget);
    expect(find.byKey(const Key('compare-context-changed-badge')), findsNothing);
    await tester.tap(find.text('These setups have no value differences'));
    await settle(tester);
    expect(find.byKey(const Key('compare-row-fork-rebound')), findsOneWidget);
  });

  testWidgets('empty comparison sheet wraps its content', (tester) async {
    final a = harness.setup(
      id: 'same-sheet-a',
      name: 'Same A',
      local: DateTime(2026, 8, 1, 10),
      values: {CompareSetupsHarness.changedAdjustmentId: 4},
    );
    final b = harness.setup(
      id: 'same-sheet-b',
      name: 'Same B',
      local: DateTime(2026, 8, 2, 10),
      values: {CompareSetupsHarness.changedAdjustmentId: 4},
    );
    await harness.addSetups(tester, [a, b]);
    await harness.reload(tester);
    await tester.pumpWidget(
      harness.wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showCompareSetupsSheet(context, setupA: a, setupB: b),
            child: const Text('Compare'),
          ),
        ),
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Compare'));
    await settle(tester);

    final sheetHeight = tester.getSize(find.byType(BottomSheet)).height;
    final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(sheetHeight, lessThan(screenHeight));
    expect(find.text('These setups have no value differences'), findsOneWidget);
  });

  testWidgets('bike comparison resolves names and missing-bike errors from setups', (tester) async {
    final valid = harness.setup(id: 'valid-bike', name: 'Valid', local: DateTime(2026, 8, 1, 10));
    final missing = harness.setup(
      id: 'missing-bike',
      name: 'Missing',
      local: DateTime(2026, 8, 2, 10),
      bike: 'deleted-bike',
    );
    await harness.addSetups(tester, [valid, missing]);
    await harness.reload(tester);
    await pumpComparison(tester, valid.id, missing.id);

    expect(find.text('Bike A'), findsOneWidget);
    expect(find.text('BIKE NOT FOUND'), findsOneWidget);
    final missingBike = tester.widget<SelectableText>(find.widgetWithText(SelectableText, 'BIKE NOT FOUND'));
    expect(missingBike.style?.color, Theme.of(tester.element(find.text('BIKE NOT FOUND'))).colorScheme.error);
  });

  testWidgets('keeps long identities pinned in narrow and short landscape layouts', (tester) async {
    await harness.addExtraAdjustments(tester);
    final (setupAId, setupBId) = await seedPair(
      tester,
      name: 'Long setup name ' * 20,
      extraDifferences: true,
    );

    for (final dimensions in [(320.0, null), (700.0, 320.0)]) {
      harness.repository.setups[setupAId]!.isCurrent = dimensions.$2 == null;
      harness.repository.setups[setupBId]!.isCurrent = dimensions.$2 != null;
      await pumpComparison(
        tester,
        setupAId,
        setupBId,
        width: dimensions.$1,
        height: dimensions.$2,
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
      await settle(tester);

      expect(find.byKey(const Key('compare-identity-a')).hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('compare-identity-b')).hitTestable(), findsOneWidget);
      expect(find.byType(DisplayAdjustmentDiff), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('changed rows expose a semantic difference and themed text', (tester) async {
    final (setupAId, setupBId) = await seedPair(tester);
    await pumpComparison(tester, setupAId, setupBId, dark: true);

    final row = tester.widget<Container>(find.byKey(const Key('compare-row-fork-rebound')));
    final value = tester.widget<SelectableText>(
      find.descendant(
        of: find.byKey(const Key('compare-panel-a-fork-rebound')),
        matching: find.byType(SelectableText),
      ),
    );
    expect(row.color, isNull);
    expect(value.style?.color, materialAppDarkTheme.extension<ValueHighlightColors>()!.changed);
    expect(find.bySemanticsLabel(RegExp('Different Rebound')), findsOneWidget);
  });

  testWidgets('shows changed Context badge without coloring context values', (tester) async {
    harness.settings.enableSetupTags = true;
    final a = harness.setup(
      id: 'notes-a',
      name: 'A',
      local: DateTime(2026, 8, 1, 10),
      notes: 'A long note that remains visible without opening another control. ' * 4,
      tags: {'dry', 'fast'},
    );
    final b = harness.setup(
      id: 'notes-b',
      name: 'B',
      local: DateTime(2026, 8, 2, 10),
      notes: 'Different note',
      tags: {'wet'},
    );
    await harness.addSetups(tester, [a, b]);
    await harness.reload(tester);
    await pumpComparison(tester, a.id, b.id, width: 320);

    expect(find.byIcon(Icons.notes), findsOneWidget);
    expect(find.byIcon(Icons.tag), findsOneWidget);
    expect(find.textContaining('A long note'), findsOneWidget);
    expect(find.textContaining('dry'), findsOneWidget);
    expect(find.textContaining('wet'), findsOneWidget);
    expect(find.text('Differences (0)'), findsOneWidget);
    expect(find.byKey(const Key('compare-context-changed-badge')), findsOneWidget);
    expect(find.bySemanticsLabel('Context varies'), findsOneWidget);
    expect(tester.widget<Icon>(find.byIcon(Icons.notes)).color, isNull);
    expect(tester.widget<Text>(find.textContaining('dry')).style?.color, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('explicit cross-bike inputs open and invalid implicit/equal calls do not', (tester) async {
    final setupA = harness.setup(id: 'a', name: 'A', local: DateTime(2026, 8, 1, 10));
    final setupB = harness.setup(
      id: 'b',
      name: 'B',
      local: DateTime(2026, 8, 2, 10),
      bike: CompareSetupsHarness.secondBikeId,
    );
    await harness.addSetups(tester, [setupA, setupB]);
    await harness.reload(tester);
    await tester.pumpWidget(
      harness.wrap(
        Builder(
          builder: (context) => Column(
            children: [
              TextButton(
                onPressed: () => showCompareSetupsSheet(context, setupA: setupA, setupB: setupB),
                child: const Text('Cross bike'),
              ),
              TextButton(
                onPressed: () => showCompareSetupsSheet(context, setupA: null, setupB: setupB),
                child: const Text('Implicit'),
              ),
              TextButton(
                onPressed: () => showCompareSetupsSheet(context, setupA: setupB, setupB: setupB),
                child: const Text('Equal'),
              ),
            ],
          ),
        ),
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Cross bike'));
    await settle(tester);
    expect(find.byType(CompareSetups), findsOneWidget);
    expect(find.textContaining('A: Present'), findsNothing);
    expect(find.textContaining('B: Present'), findsNothing);
    await tester.tap(find.byIcon(Icons.close));
    await settle(tester);

    await tester.tap(find.text('Implicit'));
    await settle(tester);
    expect(find.byType(CompareSetups), findsNothing);
    expect(find.text('No current setup is available to compare.'), findsOneWidget);

    await tester.tap(find.text('Equal'));
    await settle(tester);
    expect(find.byType(CompareSetups), findsNothing);
    expect(find.text('Choose two different setups to compare.'), findsOneWidget);
  });

  testWidgets('one-sided component cards occupy only their matching setup column', (tester) async {
    final setupOnBikeA = harness.setup(
      id: 'bike-a-setup',
      name: 'Bike A setup',
      local: DateTime(2026, 8, 1, 10),
      values: {CompareSetupsHarness.changedAdjustmentId: 4},
    );
    final setupOnBikeB = harness.setup(
      id: 'bike-b-setup',
      name: 'Bike B setup',
      local: DateTime(2026, 8, 2, 10),
      bike: CompareSetupsHarness.secondBikeId,
    );
    await harness.addSetups(tester, [setupOnBikeA, setupOnBikeB]);
    await harness.reload(tester);

    await pumpComparison(tester, setupOnBikeA.id, setupOnBikeB.id);

    final forkOwner = find.byKey(const Key('compare-owner-component-fork'));
    final cardA = find.descendant(of: forkOwner, matching: find.byType(Card));
    final cardARect = tester.getRect(cardA);
    final identityARect = tester.getRect(find.byKey(const Key('compare-identity-a')));
    expect(cardARect.left, moreOrLessEquals(identityARect.left));
    expect(cardARect.width, moreOrLessEquals(identityARect.width));
    expect(find.byKey(const Key('compare-panel-a-fork-rebound')), findsOneWidget);
    expect(find.byKey(const Key('compare-panel-b-fork-rebound')), findsNothing);
    final notInstalledB = find.byKey(const Key('compare-not-installed-fork-b'));
    expect(notInstalledB, findsOneWidget);
    expect(tester.getCenter(notInstalledB).dy, moreOrLessEquals(cardARect.center.dy));
    expect(find.text('Not installed'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpComparison(tester, setupOnBikeB.id, setupOnBikeA.id);

    final cardB = find.descendant(
      of: find.byKey(const Key('compare-owner-component-fork')),
      matching: find.byType(Card),
    );
    final cardBRect = tester.getRect(cardB);
    final identityBRect = tester.getRect(find.byKey(const Key('compare-identity-b')));
    expect(cardBRect.left, moreOrLessEquals(identityBRect.left));
    expect(cardBRect.width, moreOrLessEquals(identityBRect.width));
    expect(find.byKey(const Key('compare-panel-a-fork-rebound')), findsNothing);
    expect(find.byKey(const Key('compare-panel-b-fork-rebound')), findsOneWidget);
    final notInstalledA = find.byKey(const Key('compare-not-installed-fork-a'));
    expect(notInstalledA, findsOneWidget);
    expect(tester.getCenter(notInstalledA).dy, moreOrLessEquals(cardBRect.center.dy));
    expect(find.textContaining('Present'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an adjustmentless one-sided component only in All', (tester) async {
    await tester.runAsync(
      () => harness.repository.addComponent(
        Component(
          id: 'frame',
          name: 'Frame',
          componentType: ComponentType.frame,
          installations: [Installation.sinceBeginning(parent: CompareSetupsHarness.bikeId)],
          adjustments: const [],
        ),
      ),
    );
    final setupA = harness.setup(
      id: 'bike-a-setup',
      name: 'Bike A setup',
      local: DateTime(2026, 8, 1, 10),
      values: {CompareSetupsHarness.changedAdjustmentId: 4},
    );
    final setupB = harness.setup(
      id: 'bike-b-setup',
      name: 'Bike B setup',
      local: DateTime(2026, 8, 2, 10),
      bike: CompareSetupsHarness.secondBikeId,
    );
    await harness.addSetups(tester, [setupA, setupB]);
    await harness.reload(tester);
    await pumpComparison(tester, setupA.id, setupB.id);

    expect(find.byKey(const Key('compare-owner-component-frame')), findsNothing);
    expect(find.text('No adjustments'), findsNothing);

    await tester.tap(find.text('All'));
    await settle(tester);

    final frameCard = find.byKey(const Key('compare-owner-component-frame'));
    final verticalScrollables = find.byWidgetPredicate(
      (widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    final scrollPosition = tester
        .stateList<ScrollableState>(verticalScrollables)
        .firstWhere((state) => state.position.maxScrollExtent > 0)
        .position;
    scrollPosition.jumpTo(scrollPosition.maxScrollExtent);
    await settle(tester);
    expect(frameCard, findsOneWidget);
    final subtitle = tester.widget<Text>(
      find.descendant(of: frameCard, matching: find.text('No adjustments')),
    );
    expect(subtitle.style?.color, isNull);
  });

  testWidgets('one-sided structural component title stays neutral', (tester) async {
    final group = comparison.SetupComparisonGroup(
      kind: comparison.SetupComparisonGroupKind.component,
      ownerId: 'frame',
      ownerStateA: comparison.SetupComparisonOwnerState.installedOrLinked,
      ownerStateB: comparison.SetupComparisonOwnerState.absent,
      label: 'Frame',
      componentA: Component(
        id: 'frame',
        name: 'Frame',
        componentType: ComponentType.frame,
        installations: const [],
      ),
      rows: const [],
    );
    await tester.pumpWidget(
      harness.wrap(
        SetupComparisonOwnerCard(group: group, differencesOnly: true),
      ),
    );
    await settle(tester);

    final title = tester.widget<Text>(find.text('Frame'));
    expect(title.style?.color, isNull);
    expect(find.textContaining('Present'), findsNothing);
    expect(find.text('-'), findsNothing);
    expect(find.text('Not installed'), findsOneWidget);
  });

  testWidgets('scrolls actions away while keeping labeled setup identities pinned', (tester) async {
    await harness.addExtraAdjustments(tester);
    final (setupAId, setupBId) = await seedPair(tester, extraDifferences: true);
    await pumpComparison(tester, setupAId, setupBId);

    expect(find.text('Setup comparison').hitTestable(), findsOneWidget);
    expect(find.byIcon(Icons.close).hitTestable(), findsOneWidget);
    expect(find.text('Restore B'), findsNothing);

    final verticalScrollables = find.byWidgetPredicate(
      (widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    final scrollPosition = tester
        .stateList<ScrollableState>(verticalScrollables)
        .firstWhere((state) => state.position.maxScrollExtent > 0)
        .position;
    scrollPosition.jumpTo(scrollPosition.maxScrollExtent);
    await settle(tester);

    expect(find.text('Setup comparison').hitTestable(), findsNothing);
    expect(find.byIcon(Icons.close).hitTestable(), findsNothing);
    expect(find.text('Restore B'), findsNothing);
    for (final side in ['a', 'b']) {
      final identity = find.byKey(Key('compare-identity-$side'));
      expect(identity.hitTestable(), findsOneWidget);
      expect(
        find.descendant(of: identity, matching: find.text(side.toUpperCase())).hitTestable(),
        findsOneWidget,
      );
    }
  });

  testWidgets('shows both identity lines and highlights only the current setup', (tester) async {
    final (setupAId, setupBId) = await seedPair(tester);
    harness.repository.setups[setupAId]!.isCurrent = true;
    harness.repository.setups[setupBId]!.isCurrent = false;
    await pumpComparison(tester, setupAId, setupBId);

    final identityA = find.byKey(const Key('compare-identity-a'));
    final identityB = find.byKey(const Key('compare-identity-b'));
    expect(find.descendant(of: identityA, matching: find.text('Baseline')), findsOneWidget);
    expect(find.descendant(of: identityA, matching: find.text('2026-08-01 • 10:00')), findsOneWidget);
    expect(find.descendant(of: identityA, matching: find.text('A')), findsOneWidget);
    expect(find.descendant(of: identityB, matching: find.text('Candidate')), findsOneWidget);
    expect(find.descendant(of: identityB, matching: find.text('2026-08-02 • 10:00')), findsOneWidget);
    expect(find.descendant(of: identityB, matching: find.text('B')), findsOneWidget);
    expect(find.descendant(of: identityA, matching: find.byType(CurrentSetupHighlight)), findsOneWidget);
    expect(find.descendant(of: identityB, matching: find.byType(CurrentSetupHighlight)), findsNothing);
    expect(
      find.descendant(of: find.byKey(const Key('compare-identity-band')), matching: find.byType(CurrentSetupBadge)),
      findsNothing,
    );
    expect(
      find.descendant(of: find.byKey(const Key('compare-identity-band')), matching: find.byType(Divider)),
      findsNothing,
    );
  });

  testWidgets('stacks the pinned Values header below identities and keeps its filter operable', (tester) async {
    await harness.addExtraAdjustments(tester);
    final (setupAId, setupBId) = await seedPair(tester, extraDifferences: true);
    await pumpComparison(tester, setupAId, setupBId, width: 700, height: 320);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await settle(tester);

    final identityRect = tester.getRect(find.byKey(const Key('compare-identity-band')));
    final valuesHeader = find.ancestor(
      of: find.byKey(const Key('compare-filter-control')),
      matching: find.byType(PinnedHeaderSliver),
    );
    final valuesHeaderSurface = find
        .ancestor(
          of: find.byKey(const Key('compare-filter-control')),
          matching: find.byType(ColoredBox),
        )
        .first;
    final valuesRect = tester.getRect(valuesHeaderSurface);
    final viewportRect = tester.getRect(find.byType(CustomScrollView));
    expect(identityRect.bottom, lessThanOrEqualTo(valuesRect.top));
    expect(identityRect.top, greaterThanOrEqualTo(viewportRect.top));
    expect(valuesRect.bottom, lessThanOrEqualTo(viewportRect.bottom));
    expect(valuesHeader, findsOneWidget);

    await tester.tap(find.text('All').hitTestable());
    await settle(tester);
    expect(
      tester.widget<SegmentedButton<bool>>(find.byKey(const Key('compare-filter-control'))).selected,
      {false},
    );
    expect(
      tester.getRect(find.byKey(const Key('compare-identity-band'))).bottom,
      lessThanOrEqualTo(tester.getRect(valuesHeaderSurface).top),
    );
    await tester.tap(find.textContaining('Differences'));
    await settle(tester);
    expect(
      tester.widget<SegmentedButton<bool>>(find.byKey(const Key('compare-filter-control'))).selected,
      {true},
    );
  });

  testWidgets('identities without setup selection are not tappable', (tester) async {
    final setupA = harness.setup(id: 'callback-a', name: 'Callback A', local: DateTime(2026, 8, 1, 10));
    final setupB = harness.setup(id: 'callback-b', name: 'Callback B', local: DateTime(2026, 8, 2, 10));
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      harness.wrap(
        CustomScrollView(
          slivers: [SetupComparisonIdentities(setupA: setupA, setupB: setupB)],
        ),
      ),
    );
    await settle(tester);
    for (final side in ['a', 'b']) {
      final data = tester.getSemantics(find.byKey(Key('compare-identity-$side'))).getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.flagsCollection.isButton, isFalse);
    }

    semantics.dispose();
  });

  testWidgets('identities select another setup and highlight the opposite selection', (tester) async {
    final (setupAId, setupBId) = await seedPair(tester);
    final third = harness.setup(
      id: 'third',
      name: 'Third setup',
      local: DateTime(2026, 8, 3, 10),
    );
    await harness.addSetups(tester, [third]);
    await pumpComparison(tester, setupAId, setupBId);

    expect(
      tester.widget<PopupMenuButton<Setup>>(find.byType(PopupMenuButton<Setup>).first).initialValue,
      harness.repository.setups[setupAId],
    );
    await tester.tap(find.byType(PopupMenuButton<Setup>).first);
    await settle(tester);

    final highlightedOption = tester.widget<Container>(find.byKey(const Key('compare-setup-option-newer')));
    expect(
      highlightedOption.color,
      Theme.of(tester.element(find.byType(CompareSetups))).colorScheme.secondaryContainer,
    );
    expect(find.byType(CheckedPopupMenuItem<Setup>), findsNothing);
    expect(find.byType(CurrentSetupBadge), findsOneWidget);
    expect(find.text('2026-08-03 • 10:00'), findsOneWidget);

    await tester.tap(find.text('Third setup'));
    await settle(tester);

    expect(
      find.descendant(of: find.byKey(const Key('compare-identity-a')), matching: find.text('Third setup')),
      findsOneWidget,
    );
  });

  testWidgets('same-bike comparisons only offer setups from that bike', (tester) async {
    final setupA = harness.setup(id: 'same-bike-a', name: 'Same bike A', local: DateTime(2026, 8, 1, 10));
    final setupB = harness.setup(id: 'same-bike-b', name: 'Same bike B', local: DateTime(2026, 8, 2, 10));
    final otherBikeSetup = harness.setup(
      id: 'other-bike',
      name: 'Other bike setup',
      bike: CompareSetupsHarness.secondBikeId,
      local: DateTime(2026, 8, 3, 10),
    );
    await harness.addSetups(tester, [setupA, setupB, otherBikeSetup]);
    await harness.reload(tester);
    await pumpComparison(tester, setupA.id, setupB.id);

    await tester.tap(find.byType(PopupMenuButton<Setup>).first);
    await settle(tester);

    expect(find.byKey(const Key('compare-setup-option-same-bike-a')), findsOneWidget);
    expect(find.byKey(const Key('compare-setup-option-same-bike-b')), findsOneWidget);
    expect(find.byKey(const Key('compare-setup-option-other-bike')), findsNothing);
  });

  testWidgets('cross-bike comparisons offer all setups and show bike names', (tester) async {
    final setupA = harness.setup(id: 'bike-a-setup', name: 'Bike A setup', local: DateTime(2026, 8, 1, 10));
    final setupB = harness.setup(
      id: 'bike-b-setup',
      name: 'Bike B setup',
      bike: CompareSetupsHarness.secondBikeId,
      local: DateTime(2026, 8, 2, 10),
    );
    await harness.addSetups(tester, [setupA, setupB]);
    await harness.reload(tester);
    await pumpComparison(tester, setupA.id, setupB.id);

    await tester.tap(find.byType(PopupMenuButton<Setup>).first);
    await settle(tester);

    expect(
      find.descendant(
        of: find.byKey(const Key('compare-setup-option-bike-a-setup')),
        matching: find.text('Bike A'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('compare-setup-option-bike-b-setup')),
        matching: find.text('Bike B'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('identity dates remain visible at a larger text scale', (tester) async {
    final (setupAId, setupBId) = await seedPair(tester, name: 'Long identity name ' * 10);
    final setupA = harness.repository.setups[setupAId]!;
    final setupB = harness.repository.setups[setupBId]!;
    await tester.pumpWidget(
      harness.wrap(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: CustomScrollView(
            slivers: [SetupComparisonIdentities(setupA: setupA, setupB: setupB)],
          ),
        ),
        width: 320,
      ),
    );
    await settle(tester);

    expect(find.text('2026-08-01 • 10:00'), findsOneWidget);
    expect(find.text('2026-08-02 • 10:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing setup keeps actions without rendering identities', (tester) async {
    await pumpComparison(tester, 'missing-a', 'missing-b');

    expect(find.text('Setup comparison'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byKey(const Key('compare-identity-band')), findsNothing);
    expect(find.text('A setup is no longer available'), findsOneWidget);
  });

  testWidgets('Ratings is shown in Differences and All when enabled', (tester) async {
    harness.settings.enableRating = true;
    final (setupAId, setupBId) = await seedPair(tester);
    await pumpComparison(tester, setupAId, setupBId);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await settle(tester);
    expect(find.text('RATINGS'), findsOneWidget);
    expect(find.text('No ratings yet'), findsNWidgets(2));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 2000));
    await settle(tester);
    await tester.tap(find.text('All'));
    await settle(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await settle(tester);
    expect(find.text('RATINGS'), findsOneWidget);
    expect(find.byType(PinnedHeaderSliver), findsNWidgets(4));
    expect(find.text('No ratings yet'), findsNWidgets(2));

    harness.settings.enableRating = false;
    await tester.pump();
    await settle(tester);
    expect(find.text('Ratings'), findsNothing);
  });
}
