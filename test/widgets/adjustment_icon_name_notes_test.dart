import 'dart:async';

import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/adjustment_activity_histogram.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/setup_guide.dart';
import 'package:bike_setup_tracker/services/setup_activity_analysis_service.dart';
import 'package:bike_setup_tracker/utils/component_catalog_application.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:bike_setup_tracker/utils/setup_guide_actions.dart';
import 'package:bike_setup_tracker/widgets/display_adjustment/adjustment_icon_name_notes.dart';
import 'package:bike_setup_tracker/widgets/display_data/adjustment_activity_histogram_chart.dart';
import 'package:bike_setup_tracker/widgets/setup_guide_card.dart';
import 'package:bike_setup_tracker/widgets/setup_guide_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockSetupActivityAnalysisService extends Mock implements SetupActivityAnalysisService {}

void main() {
  final adjustment = StepAdjustment(
    id: 'rebound',
    name: 'Rebound',
    notes: 'Start from fully closed',
    unit: AdjustmentUnit.fromLegacy('clicks'),
    step: 1,
    min: 0,
    max: 20,
    visualization: StepAdjustmentVisualization.slider,
  );
  final populated = AdjustmentActivityHistogram(
    adjustmentId: adjustment.id,
    bars: const [
      AdjustmentActivityHistogramBar.exact(label: '4 clicks', activityCount: 3, exactValue: StepValue(4)),
    ],
    isBinned: false,
  );

  Widget harness({SetupActivityAnalysisService? service}) {
    final child = MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: AdjustmentIconNameNotes(adjustment: adjustment, value: const StepValue(4)),
        ),
      ),
    );
    return service == null
        ? child
        : ListenableProvider<SetupActivityAnalysisService>.value(value: service, child: child);
  }

  MockSetupActivityAnalysisService serviceWith({
    required bool gate,
    required Future<AdjustmentActivityHistogram> Function() load,
  }) {
    final service = MockSetupActivityAnalysisService();
    when(() => service.hasAnyActivity).thenReturn(gate);
    when(() => service.getAdjustmentHistogram(any())).thenAnswer((_) => load());
    when(() => service.addListener(any())).thenAnswer((_) {});
    when(() => service.removeListener(any())).thenAnswer((_) {});
    return service;
  }

  testWidgets('loads lazily, shows loading below existing content, then renders data', (tester) async {
    final completer = Completer<AdjustmentActivityHistogram>();
    final service = serviceWith(gate: true, load: () => completer.future);
    await tester.pumpWidget(harness(service: service));

    verifyNever(() => service.getAdjustmentHistogram(any()));
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byType(Tooltip));
    await tester.pump();
    verify(() => service.getAdjustmentHistogram('rebound')).called(1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Start from fully closed'), findsOneWidget);

    completer.complete(populated);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const ValueKey('adjustment-activity-histogram')), findsOneWidget);
    expect(
      tester.widget<AdjustmentActivityHistogramChart>(find.byType(AdjustmentActivityHistogramChart)).currentValue,
      const StepValue(4),
    );
    expect(find.text('Start from fully closed'), findsOneWidget);
  });

  testWidgets('omits analysis for an empty result, error, closed gate, or absent provider', (tester) async {
    final emptyService = serviceWith(
      gate: true,
      load: () async => AdjustmentActivityHistogram.empty(adjustment.id),
    );
    await tester.pumpWidget(harness(service: emptyService));
    await tester.tap(find.byType(Tooltip));
    await tester.pump();
    expect(find.byKey(const ValueKey('adjustment-activity-histogram')), findsNothing);
    expect(find.text('Start from fully closed'), findsOneWidget);

    final previousDebugPrint = debugPrint;
    final messages = <String>[];
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    final errorService = serviceWith(gate: true, load: () => Future.error(StateError('failed')));
    await tester.pumpWidget(harness(service: errorService));
    await tester.tap(find.byType(Tooltip));
    await tester.pump();
    debugPrint = previousDebugPrint;
    expect(messages.join(), contains('Failed to load adjustment activity histogram'));
    expect(tester.takeException(), isNull);

    final closedService = serviceWith(gate: false, load: () async => populated);
    await tester.pumpWidget(harness(service: closedService));
    await tester.tap(find.byType(Tooltip));
    await tester.pump();
    verifyNever(() => closedService.getAdjustmentHistogram(any()));

    await tester.pumpWidget(harness());
    await tester.tap(find.byType(Tooltip));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Start from fully closed'), findsOneWidget);
  });

  testWidgets('reuses service futures on repeat and ignores completion after disposal', (tester) async {
    final cachedFuture = Future.value(populated);
    final cachedService = serviceWith(gate: true, load: () => cachedFuture);
    await tester.pumpWidget(harness(service: cachedService));
    await tester.tap(find.byType(Tooltip));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.tap(find.byType(Tooltip));
    await tester.pump();
    verify(() => cachedService.getAdjustmentHistogram('rebound')).called(2);
    expect(find.byKey(const ValueKey('adjustment-activity-histogram')), findsOneWidget);

    final completer = Completer<AdjustmentActivityHistogram>();
    final pendingService = serviceWith(gate: true, load: () => completer.future);
    await tester.pumpWidget(harness(service: pendingService));
    await tester.tap(find.byType(Tooltip));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    completer.complete(populated);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  group('with a setup guide scope', () {
    final preset = catalogProducts(parseCatalogFile(_guideCatalog)).single;
    final application = buildCatalogApplication(preset);
    final guided = GuidedComponent(
      Component(
        name: application.name,
        componentType: application.componentType,
        installations: const [],
        adjustments: application.adjustments,
        preset: application.preset,
      ),
      preset,
    );
    final pressure = guided.component.adjustments.firstWhere((a) => a.name == 'Pressure');

    Widget scoped({
      AdjustmentValue? current,
      GuideInputs inputs = const GuideInputs(riderWeight: 82),
      SetupActivityAnalysisService? service,
    }) {
      final child = MaterialApp(
        home: Scaffold(
          body: SetupGuideScope(
            sections: [
              SetupGuideSection(guided, guided.evaluate(inputs, {pressure.id: ?current})),
            ],
            child: SizedBox(
              width: 400,
              child: AdjustmentIconNameNotes(adjustment: pressure, value: current),
            ),
          ),
        ),
      );
      return service == null
          ? child
          : ListenableProvider<SetupActivityAnalysisService>.value(value: service, child: child);
    }

    Future<void> openTooltip(WidgetTester tester, Widget widget) async {
      await tester.pumpWidget(widget);
      await tester.tap(find.byType(Tooltip));
      await tester.pump();
    }

    testWidgets('shows the recommended value without a histogram', (tester) async {
      await openTooltip(tester, scoped());
      expect(find.text('Recommended: 77 psi'), findsOneWidget);

      await openTooltip(tester, scoped(current: const NumericalValue(77)));
      expect(find.text('Recommended: 77 psi'), findsOneWidget);
      expect(find.text('Matches'), findsOneWidget);

      await openTooltip(tester, scoped(current: const NumericalValue(80)));
      expect(find.text('In range'), findsOneWidget);
      expect(find.textContaining('In range:'), findsNothing);

      await openTooltip(tester, scoped(current: const NumericalValue(90)));
      expect(find.text('+13 psi'), findsOneWidget);
      expect(find.text('In range: 72–82 psi'), findsOneWidget);
    });

    testWidgets('shows why there is no value', (tester) async {
      await openTooltip(tester, scoped(inputs: const GuideInputs()));
      expect(find.text('Recommended: – · Needs your riding weight'), findsOneWidget);
    });

    testWidgets('passes the recommended value to the histogram', (tester) async {
      final histogram = AdjustmentActivityHistogram(
        adjustmentId: pressure.id,
        bars: const [
          AdjustmentActivityHistogramBar.exact(label: '77 psi', activityCount: 2, exactValue: NumericalValue(77)),
        ],
        isBinned: false,
      );
      final service = serviceWith(gate: true, load: () async => histogram);
      await openTooltip(tester, scoped(current: const NumericalValue(77), service: service));
      await tester.pump();

      expect(
        tester.widget<AdjustmentActivityHistogramChart>(find.byType(AdjustmentActivityHistogramChart)).guideValue,
        const NumericalValue(77),
      );
    });

    testWidgets('an adjuster without a guide rule shows no line', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupGuideScope(
              sections: [SetupGuideSection(guided, guided.evaluate(const GuideInputs(riderWeight: 82), const {}))],
              child: SizedBox(width: 400, child: AdjustmentIconNameNotes(adjustment: adjustment)),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(Tooltip));
      await tester.pump();
      expect(find.textContaining('Recommended'), findsNothing);
    });
  });

  testWidgets('shows no recommendation without a scope', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.byType(Tooltip));
    await tester.pump();
    expect(find.textContaining('Recommended'), findsNothing);
  });
}

const _guideCatalog = '''
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
nodes:
  - label: Guided
    level: model
    guide: acme
    adjustments:
      - { name: Pressure, type: numerical, unit: psi, min: 0, max: 120 }
''';
