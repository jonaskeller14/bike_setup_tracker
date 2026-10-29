import 'dart:math' as math;

import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/feedback/test_session_method.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/services/test_session/suggestion_result.dart';
import 'package:bike_setup_tracker/services/test_session/test_session_strategy.dart';

StepAdjustment stepKnob(String id, {int min = 0, int max = 20, int step = 1}) => StepAdjustment(
  id: id,
  name: id,
  notes: null,
  unit: null,
  min: min,
  max: max,
  step: step,
  visualization: StepAdjustmentVisualization.slider,
);

final DateTime _start = DateTime(2026, 5, 2, 9);

Setup run(String id, Map<String, AdjustmentValue> values, {int index = 0, String sessionId = 'ts', String? name}) {
  final local = _start.add(Duration(minutes: 10 * index));
  return Setup(
    id: id,
    name: name ?? 'Run ${index + 1}',
    datetime: local.toUtc(),
    datetimeLocal: local,
    tags: const {},
    bike: 'bike',
    person: 'rider',
    bikeAdjustmentValues: values,
    personAdjustmentValues: const {},
    testSessionId: sessionId,
  );
}

TestSession testSession({
  required TestSessionMethod? method,
  required List<String> knobs,
  Map<String, AdjustmentValue> locks = const {},
  bool ended = false,
  String id = 'ts',
}) {
  return TestSession(
    id: id,
    bike: 'bike',
    method: method,
    adjustmentIds: knobs,
    locks: locks,
    startedAtUTC: _start.toUtc(),
    startedAtLocal: _start,
    endedAtUTC: ended ? _start.toUtc() : null,
    endedAtLocal: ended ? _start : null,
  );
}

/// A rider whose preference is [preference]; each run is compared with the
/// proposal's reference, the difference rounded to the 5-step scale.
class Simulation {
  final TestSessionStrategy strategy;
  final TestSession session;
  final Map<String, Adjustment> adjustments;
  final double Function(Map<String, AdjustmentValue> values) preference;

  /// Uniform noise added to each preference difference, ± this much.
  final double noise;
  final math.Random random;

  final List<Setup> runs = [];
  final List<RunComparison> comparisons = [];
  final List<SuggestionResult> results = [];
  final Map<String, Setup> setups;

  Simulation({
    required this.strategy,
    required this.session,
    required List<Adjustment> knobs,
    required this.preference,
    required Map<String, AdjustmentValue> start,
    this.noise = 0,
    int seed = 1,
    this.setups = const {},
  }) : adjustments = {for (final knob in knobs) knob.id: knob},
       random = math.Random(seed) {
    runs.add(run('r0', start));
  }

  TestSessionHistory get history => TestSessionHistory(
    session: session,
    adjustments: adjustments,
    runs: runs,
    ratedRunIds: {for (final r in runs) r.id},
    comparisons: comparisons,
    setups: setups,
  );

  int score(Setup rated, Setup reference) {
    final difference = preference(rated.bikeAdjustmentValues) - preference(reference.bikeAdjustmentValues);
    final noisy = difference + (noise == 0 ? 0 : (random.nextDouble() * 2 - 1) * noise);
    return noisy.round().clamp(-2, 2);
  }

  /// Rides proposals until the strategy stops proposing or [maxRuns] runs.
  SuggestionResult play({int maxRuns = 40, Map<String, AdjustmentValue> Function(Proposal)? deviate}) {
    while (true) {
      final result = strategy.propose(history);
      results.add(result);
      if (result is! Proposal || runs.length >= maxRuns) return result;
      final base = setups[result.baseSetupId] ?? runs.firstWhere((r) => r.id == result.baseSetupId);
      final values = {...base.bikeAdjustmentValues, ...result.values, ...?deviate?.call(result)};
      final next = run('r${runs.length}', values, index: runs.length);
      final reference = runs.firstWhere((r) => r.id == result.referenceSetupId);
      runs.add(next);
      comparisons.add(RunComparison(ratedId: next.id, referenceId: reference.id, score: score(next, reference)));
    }
  }

  Map<String, AdjustmentValue> valuesOf(String setupId) =>
      (setups[setupId] ?? runs.firstWhere((r) => r.id == setupId)).bikeAdjustmentValues;
}

int stepOf(Map<String, AdjustmentValue> values, String id) => (values[id] as StepValue).value;
