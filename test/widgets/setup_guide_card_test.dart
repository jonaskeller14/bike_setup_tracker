import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/setup_guide.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/component_catalog_application.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:bike_setup_tracker/utils/setup_guide_actions.dart';
import 'package:bike_setup_tracker/widgets/setup_guide_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _catalog = '''
brand: Acme
component_type: fork
guides:
  acme:
    label: Acme owner's manual (2027)
    source: https://example.com/acme
    rules:
      - target: pressure
        unit: psi
        input: rider_weight
        input_unit: kg
        rows: { 70-80: 70, 80-90: 80, 90-100: 90 }
      - { target: lsc, value: 4 }
nodes:
  - label: Guided
    level: model
    guide: acme
    adjustments:
      - { name: Pressure, type: numerical, unit: psi, min: 0, max: 120 }
      - { name: LSC, type: step, max: 10 }
''';

void main() {
  final preset = catalogProducts(parseCatalogFile(_catalog)).single;

  GuidedComponent guided({String? name}) {
    final application = buildCatalogApplication(preset);
    return GuidedComponent(
      Component(
        name: name ?? application.name,
        componentType: application.componentType,
        installations: const [],
        adjustments: application.adjustments,
        preset: application.preset,
      ),
      preset,
    );
  }

  Adjustment pressureOf(GuidedComponent guided) => guided.component.adjustments.firstWhere((a) => a.name == 'Pressure');

  Future<void> pumpCard(
    WidgetTester tester, {
    required GuidedComponent guided,
    GuideInputs inputs = const GuideInputs(riderWeight: 82),
    Map<String, AdjustmentValue> current = const {},
    void Function(GuideRecommendation)? onApply,
    VoidCallback? onApplyAll,
    ThemeData? theme,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: theme ?? materialAppTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SetupGuideCard(
              sections: [SetupGuideSection(guided, guided.evaluate(inputs, current))],
              inputs: inputs,
              onApply: onApply ?? (_) {},
              onApplyAll: onApplyAll,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows a row per recommended value with its basis', (tester) async {
    await pumpCard(tester, guided: guided());

    expect(find.text('Recommended values for 82 kg'), findsOneWidget);
    expect(find.text("Based on: Acme owner's manual (2027)"), findsOneWidget);
    expect(find.text('Pressure'), findsOneWidget);
    expect(find.text('77 psi'), findsOneWidget);
    expect(find.text('82 kg · interpolated'), findsOneWidget);
    expect(find.text('LSC'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Fixed value'), findsOneWidget);
    expect(find.text('Not set'), findsNWidgets(2));
    expect(find.text('A starting point, check your manual.'), findsOneWidget);
  });

  testWidgets('tapping a row applies that value', (tester) async {
    final component = guided();
    GuideRecommendation? applied;
    await pumpCard(tester, guided: component, onApply: (r) => applied = r);

    await tester.tap(find.text('Pressure'));

    expect(applied?.adjustment, pressureOf(component));
    expect(applied?.value, const NumericalValue(77));
  });

  testWidgets('a value already set shows on guide and does not apply again', (tester) async {
    final component = guided();
    GuideRecommendation? applied;
    await pumpCard(
      tester,
      guided: component,
      current: {pressureOf(component).id: const NumericalValue(77)},
      onApply: (r) => applied = r,
    );

    expect(find.text('On guide'), findsOneWidget);
    await tester.tap(find.text('Pressure'));
    expect(applied, isNull);
  });

  testWidgets('a deviating value shows its delta', (tester) async {
    final component = guided();
    await pumpCard(tester, guided: component, current: {pressureOf(component).id: const NumericalValue(90)});

    expect(find.text('Now 90 psi (+13)'), findsOneWidget);
  });

  testWidgets('Apply all calls back, and is disabled without a callback', (tester) async {
    var calls = 0;
    await pumpCard(tester, guided: guided(), onApplyAll: () => calls++);
    await tester.tap(find.text('Apply all'));
    expect(calls, 1);

    await pumpCard(tester, guided: guided());
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(of: find.text('Apply all'), matching: find.bySubtype<ButtonStyleButton>()),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('without a weight it hints at the rider tab and looks the pressure up in reverse', (tester) async {
    final component = guided();
    await pumpCard(
      tester,
      guided: component,
      inputs: const GuideInputs(),
      current: {pressureOf(component).id: const NumericalValue(80)},
    );

    expect(find.text('Enter a riding weight on the Rider tab for weight-based values'), findsOneWidget);
    expect(find.text('Needs your riding weight'), findsOneWidget);
    expect(find.text('80 psi ≈ 80–90 kg'), findsOneWidget);
  });

  testWidgets('a rider outside the published range gets no value', (tester) async {
    GuideRecommendation? applied;
    await pumpCard(tester, guided: guided(), inputs: const GuideInputs(riderWeight: 130), onApply: (r) => applied = r);

    expect(find.text('Outside the published range'), findsOneWidget);
    await tester.tap(find.text('Pressure'));
    expect(applied, isNull);
  });

  testWidgets('the info dialog cites the guide', (tester) async {
    await pumpCard(tester, guided: guided());

    await tester.tap(find.byTooltip('About recommended values'));
    await tester.pumpAndSettle();

    expect(find.text('Recommended values'), findsOneWidget);
    expect(find.textContaining('check your manual'), findsWidgets);
    expect(find.text('example.com/acme'), findsOneWidget);
  });

  for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
    testWidgets('long names fit a narrow screen ($label)', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final component = guided(name: 'A very long component name that will never fit on one line ' * 3);
      await pumpCard(
        tester,
        guided: component,
        theme: theme,
        current: {pressureOf(component).id: const NumericalValue(118.5)},
        onApplyAll: () {},
      );

      expect(tester.takeException(), isNull);
    });
  }
}
