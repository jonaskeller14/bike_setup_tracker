import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/services/dangling_adjustment_service.dart';
import 'package:bike_setup_tracker/services/setup_resolution_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/lists/adjustment_compact_display_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fixed scheme so we can assert against the exact themed error colour.
final ColorScheme _scheme = ColorScheme.fromSeed(seedColor: Colors.blue);
final ValueHighlightColors _highlights = ValueHighlightColors.light;

void main() {
  // --- Fixture -------------------------------------------------------------
  // A bike ("myBike") with a fork whose three adjustments we drive through the
  // changed / initial / unchanged states, plus a shock that lives on a *second*
  // bike so any of its values are "dangling" (not installed at setup time), and
  // a person attribute. `deletedAdjId` is an adjustment id that belongs to no
  // component/person at all (its definition was deleted).
  const deletedAdjId = 'adj_deleted';

  late TextAdjustment pressure;
  late TextAdjustment rebound;
  late TextAdjustment compression;
  late TextAdjustment sag;
  late TextAdjustment weight;

  late Bike myBike;
  late Bike otherBike;
  late Person me;
  late Component fork; // installed on myBike -> normal
  late Component shock; // installed on otherBike -> dangling for myBike

  setUp(() {
    pressure = TextAdjustment(id: 'adj_pressure', name: 'Pressure', notes: null, unit: 'psi');
    rebound = TextAdjustment(id: 'adj_rebound', name: 'Rebound', notes: null, unit: 'clicks');
    compression = TextAdjustment(id: 'adj_compression', name: 'Compression', notes: null, unit: 'clicks');
    sag = TextAdjustment(id: 'adj_sag', name: 'Sag', notes: null, unit: '%');
    weight = TextAdjustment(id: 'adj_weight', name: 'Weight', notes: null, unit: 'kg');

    myBike = Bike(id: 'bike_1', name: 'Enduro', person: 'person_1');
    otherBike = Bike(id: 'bike_2', name: 'Trail', person: 'person_1');
    me = Person(id: 'person_1', name: 'Me', adjustments: [weight]);

    fork = Component(
      id: 'comp_fork',
      name: 'Fork',
      componentType: ComponentType.fork,
      adjustments: [pressure, rebound, compression],
      installations: [Installation.sinceBeginning(parent: myBike.id)],
    );
    shock = Component(
      id: 'comp_shock',
      name: 'Shock',
      componentType: ComponentType.shock,
      adjustments: [sag],
      installations: [Installation.sinceBeginning(parent: otherBike.id)], // never on myBike
    );
  });

  // --- Helpers -------------------------------------------------------------
  Widget harness(Widget child) => MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: _scheme,
          textTheme: const TextTheme(
            headlineLarge: TextStyle(fontWeight: FontWeight.bold),
            titleLarge: TextStyle(fontWeight: FontWeight.bold),
          ),
          extensions: const [ValueHighlightColors.light],
        ),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  Setup makeSetup({
    required Map<String, dynamic> bikeValues,
    Map<String, dynamic> personValues = const {},
    Map<String, dynamic> previousBikeValues = const {},
    Map<String, dynamic> previousPersonValues = const {},
  }) {
    final t = DateTime(2025, 6, 1).toUtc();
    return Setup(
      id: 'setup_1',
      name: 'Test',
      datetime: t,
      datetimeLocal: t.toLocal(),
      bike: myBike.id,
      person: me.id,
      tags: {},
      bikeAdjustmentValues: bikeValues,
      personAdjustmentValues: personValues,
    )
      ..previousBikeAdjustmentValues = Map.from(previousBikeValues)
      ..previousPersonAdjustmentValues = Map.from(previousPersonValues);
  }

  /// Builds the widget exactly the way SetupListCard does: run the setup through
  /// [DanglingAdjustmentService.analyzeSetup] and feed the resulting normal /
  /// dangling groups into the provider-free list.
  Widget compactFor(Setup setup, {required bool displayOnlyChanges, bool displayPerson = true}) {
    final breakdown = DanglingAdjustmentService.analyzeSetup(
      setup: setup,
      components: [fork, shock],
      persons: [me],
    );
    return harness(AdjustmentCompactDisplayList(
      components: breakdown.components,
      persons: breakdown.person != null ? [breakdown.person!] : const [],
      danglingComponents: breakdown.danglingComponents,
      danglingPersons: breakdown.danglingPersons,
      adjustmentValues: {...setup.bikeAdjustmentValues, ...setup.personAdjustmentValues},
      previousAdjustmentValues: {...setup.previousBikeAdjustmentValues, ...setup.previousPersonAdjustmentValues},
      showRowIcons: true,
      highlightInitialValues: true,
      displayOnlyChanges: displayOnlyChanges,
      displayBikeAdjustmentValues: true,
      displayPersonAdjustmentValues: displayPerson,
    ));
  }

  Color? valueColor(WidgetTester tester, String value) {
    final finder = find.text(value);
    expect(finder, findsOneWidget, reason: 'expected value "$value" exactly once');
    return tester.widget<Text>(finder).style?.color;
  }

  /// A single setup exercising every state at once:
  ///  - pressure    : 85 -> 80   changed    (orange)
  ///  - rebound     : (no prev)  initial    (green)
  ///  - compression : 3  -> 3    unchanged  (default/null)
  ///  - sag         : on shock   dangling   (red, not installed here)
  ///  - deletedAdj  : orphan     deleted    (hidden)
  ///  - weight      : 72 -> 70   changed    (orange, person)
  Setup mixedSetup() => makeSetup(
        bikeValues: {
          pressure.id: '80',
          rebound.id: '5',
          compression.id: '3',
          sag.id: '30',
          deletedAdjId: '999',
        },
        personValues: {weight.id: '70'},
        previousBikeValues: {pressure.id: '85', compression.id: '3'},
        previousPersonValues: {weight.id: '72'},
      );

  // --- Widget: expanded ----------------------------------------------------
  group('AdjustmentCompactDisplayList expanded', () {
    testWidgets('shows every existing value, hides deleted, with correct colours', (tester) async {
      await tester.pumpWidget(compactFor(mixedSetup(), displayOnlyChanges: false));

      // Existing values are all visible.
      expect(find.text('80'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('70'), findsOneWidget);
      // Value of a deleted adjustment is never rendered.
      expect(find.text('999'), findsNothing);

      // Highlight colours.
      expect(valueColor(tester, '80'), _highlights.changed, reason: 'changed');
      expect(valueColor(tester, '5'), _highlights.initial, reason: 'initial');
      expect(valueColor(tester, '3'), isNull, reason: 'unchanged -> default');
      expect(valueColor(tester, '30'), _scheme.error, reason: 'dangling');
      expect(valueColor(tester, '70'), _highlights.changed, reason: 'person changed');
    });

    testWidgets('dangling component icon is red, normal component icon is not', (tester) async {
      await tester.pumpWidget(compactFor(mixedSetup(), displayOnlyChanges: false));

      final forkIcon = tester.widget<Icon>(find.byIcon(ComponentType.fork.getIconData()));
      final shockIcon = tester.widget<Icon>(find.byIcon(ComponentType.shock.getIconData()));

      expect(forkIcon.color, isNull);
      expect(shockIcon.color, _scheme.error);
    });

    testWidgets('person values are omitted when disabled', (tester) async {
      await tester.pumpWidget(compactFor(mixedSetup(), displayOnlyChanges: false, displayPerson: false));

      expect(find.text('80'), findsOneWidget);
      expect(find.text('70'), findsNothing);
    });
  });

  // --- Widget: collapsed ---------------------------------------------------
  group('AdjustmentCompactDisplayList collapsed (displayOnlyChanges)', () {
    testWidgets('keeps only changed/initial values and hides unchanged + dangling', (tester) async {
      await tester.pumpWidget(compactFor(mixedSetup(), displayOnlyChanges: true));

      // Changed / initial remain.
      expect(find.text('80'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('70'), findsOneWidget);
      // Unchanged is hidden.
      expect(find.text('3'), findsNothing);
      // Dangling is hidden while collapsed.
      expect(find.text('30'), findsNothing);
      // Deleted stays hidden.
      expect(find.text('999'), findsNothing);

      // Colours of surviving values are unchanged.
      expect(valueColor(tester, '80'), _highlights.changed);
      expect(valueColor(tester, '5'), _highlights.initial);
    });
  });

  // --- Multiple setups with changing values --------------------------------
  group('multiple setups with changing values', () {
    testWidgets('highlight of a value reflects the previous setup on the timeline', (tester) async {
      final t1 = DateTime(2025, 1, 1).toUtc();
      final t2 = DateTime(2025, 1, 2).toUtc();
      final t3 = DateTime(2025, 1, 3).toUtc();

      Setup mk(String id, DateTime t, String pressureVal) => Setup(
            id: id,
            name: id,
            datetime: t,
            datetimeLocal: t.toLocal(),
            bike: myBike.id,
            person: me.id,
            tags: {},
            personAdjustmentValues: {},
            bikeAdjustmentValues: {pressure.id: pressureVal},
          );

      final resolved = SetupResolutionService.resolveSetups(
        setups: {
          's1': mk('s1', t1, '80'), // first ever -> initial
          's2': mk('s2', t2, '85'), // 80 -> 85 -> changed
          's3': mk('s3', t3, '85'), // 85 -> 85 -> unchanged
        },
        bikes: {myBike.id: myBike},
        persons: {me.id: me},
        components: {fork.id: fork},
        ratings: {},
      ).setups;

      await tester.pumpWidget(compactFor(resolved['s1']!, displayOnlyChanges: false));
      expect(valueColor(tester, '80'), _highlights.initial, reason: 's1 has no previous -> initial');

      await tester.pumpWidget(compactFor(resolved['s2']!, displayOnlyChanges: false));
      expect(valueColor(tester, '85'), _highlights.changed, reason: 's2 changed from 80');

      await tester.pumpWidget(compactFor(resolved['s3']!, displayOnlyChanges: false));
      expect(valueColor(tester, '85'), isNull, reason: 's3 unchanged from s2');
    });
  });

  // --- Classification (analyzeSetup) --------------------------------------
  group('DanglingAdjustmentService.analyzeSetup', () {
    test('installed component is normal, not dangling', () {
      final breakdown = DanglingAdjustmentService.analyzeSetup(
        setup: makeSetup(bikeValues: {pressure.id: '80'}),
        components: [fork, shock],
        persons: [me],
      );
      expect(breakdown.components.map((c) => c.id), contains('comp_fork'));
      expect(breakdown.danglingComponents, isEmpty);
      expect(breakdown.componentSplit.deletedValues, isEmpty);
    });

    test('value on a not-installed component becomes a dangling group', () {
      final breakdown = DanglingAdjustmentService.analyzeSetup(
        setup: makeSetup(bikeValues: {sag.id: '30'}),
        components: [fork, shock],
        persons: [me],
      );
      expect(breakdown.danglingComponents.map((c) => c.id), ['comp_shock']);
      expect(breakdown.componentSplit.deletedValues, isEmpty);
    });

    test('value for an unknown adjustment id becomes a deleted value', () {
      final breakdown = DanglingAdjustmentService.analyzeSetup(
        setup: makeSetup(bikeValues: {deletedAdjId: '999'}),
        components: [fork, shock],
        persons: [me],
      );
      expect(breakdown.danglingComponents, isEmpty);
      expect(breakdown.componentSplit.deletedValues.keys, contains(deletedAdjId));
    });
  });

  // --- Summary (drives the expand/collapse toggle in the card) -------------
  group('AdjustmentCompactDisplayList.summarize', () {
    test('no values -> no content, nothing hidden', () {
      final summary = AdjustmentCompactDisplayList.summarize(adjustmentValues: {});
      expect(summary.hasContent, isFalse);
      expect(summary.collapsedHidesSomething, isFalse);
    });

    test('only unchanged values -> has content, collapsing hides them', () {
      final summary = AdjustmentCompactDisplayList.summarize(
        components: [fork],
        adjustmentValues: {pressure.id: '80'},
        previousAdjustmentValues: {pressure.id: '80'},
      );
      expect(summary.hasContent, isTrue);
      expect(summary.collapsedHidesSomething, isTrue);
    });

    test('only changed values -> has content, collapsing hides nothing', () {
      final summary = AdjustmentCompactDisplayList.summarize(
        components: [fork],
        adjustmentValues: {pressure.id: '80'},
        previousAdjustmentValues: {pressure.id: '85'},
      );
      expect(summary.hasContent, isTrue);
      expect(summary.collapsedHidesSomething, isFalse);
    });

    test('only dangling values -> has content, collapsing hides them', () {
      final summary = AdjustmentCompactDisplayList.summarize(
        danglingComponents: [shock],
        adjustmentValues: {sag.id: '30'},
      );
      expect(summary.hasContent, isTrue);
      expect(summary.collapsedHidesSomething, isTrue);
    });
  });
}
