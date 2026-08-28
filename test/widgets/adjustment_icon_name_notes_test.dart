import 'dart:async';

import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/adjustment_activity_histogram.dart';
import 'package:bike_setup_tracker/services/setup_activity_analysis_service.dart';
import 'package:bike_setup_tracker/widgets/display_adjustment/adjustment_icon_name_notes.dart';
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
      AdjustmentActivityHistogramBar.exact(label: '4 clicks', activityCount: 3, exactValue: 4),
    ],
    isBinned: false,
  );

  Widget harness({SetupActivityAnalysisService? service}) {
    final child = MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: AdjustmentIconNameNotes(adjustment: adjustment),
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
}
