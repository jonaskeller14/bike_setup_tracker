import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/feedback/feedback_comparison.dart';
import '../../models/feedback/feedback_key.dart';
import '../../models/feedback/ride_feedback.dart';
import '../../models/feedback/test_session.dart';
import '../../models/feedback/test_session_method.dart';
import '../../models/setup.dart';
import 'orthogonal_array_strategy.dart';
import 'pattern_search_strategy.dart';
import 'strategy_knob.dart';
import 'suggestion_result.dart';
import 'tournament_strategy.dart';

/// One answered comparison between two runs: [score] −2 … +2, positive when
/// [ratedId] was better than [referenceId].
@immutable
class RunComparison {
  final String ratedId;
  final String referenceId;
  final int score;

  const RunComparison({required this.ratedId, required this.referenceId, required this.score});

  /// The decision per step: the overall answer; on "same" (or without one) the
  /// sum of the goal-aspect answers, as one step; otherwise equal. Null when
  /// [comparisons] (all against one reference) answer neither.
  static int? scoreOf(Iterable<FeedbackComparison> comparisons, List<FeedbackAspect> goal) {
    final overall = comparisons.firstWhereOrNull((c) => c.aspect is OverallAspect && c.isValid)?.outcome;
    if (overall != null && overall != 0) return overall;
    final goalAnswers = [
      for (final comparison in comparisons)
        if (goal.contains(comparison.aspect) && comparison.isValid) comparison.outcome,
    ];
    if (goalAnswers.isNotEmpty) return goalAnswers.sum.sign;
    return overall;
  }

  @override
  bool operator ==(Object other) =>
      other is RunComparison && other.ratedId == ratedId && other.referenceId == referenceId && other.score == score;

  @override
  int get hashCode => Object.hash(ratedId, referenceId, score);

  @override
  String toString() => 'RunComparison($ratedId vs $referenceId: $score)';
}

/// What a strategy may look at: the session, its runs and the comparisons
/// between the runs of every session on the bike, so later sessions start from
/// earlier findings.
@immutable
class TestSessionHistory {
  final TestSession session;

  /// The adjustments installed on the bike and its rider, by id.
  final Map<String, Adjustment> adjustments;

  /// The session's runs, oldest first.
  final List<Setup> runs;

  /// Runs with at least one feedback, even an empty one.
  final Set<String> ratedRunIds;

  /// Runs of the bike's other sessions.
  final List<Setup> pooledRuns;

  /// Between any two runs of [runs] and [pooledRuns].
  final List<RunComparison> comparisons;

  /// Every live setup, for the candidates of a Compare session.
  final Map<String, Setup> setups;

  const TestSessionHistory({
    required this.session,
    required this.adjustments,
    required this.runs,
    required this.ratedRunIds,
    this.pooledRuns = const [],
    required this.comparisons,
    this.setups = const {},
  });

  /// Collects the history of [session] from the app's data. With [before], only
  /// the runs before that one count: what the strategy saw when it proposed it.
  factory TestSessionHistory.collect({
    required TestSession session,
    required Iterable<TestSession> sessions,
    required Map<String, Setup> setups,
    required List<RideFeedback> Function(String setupId) feedbacksForSetup,
    required Map<String, Adjustment> adjustments,
    Setup? before,
  }) {
    final sessionsById = {
      for (final other in sessions)
        if (other.bike == session.bike) other.id: other,
      session.id: session,
    };
    final allRuns = setups.values
        .where((setup) => sessionsById.containsKey(setup.testSessionId) && setup.bike == session.bike)
        .where((setup) => before == null || setup.datetime.isBefore(before.datetime))
        .sorted((a, b) => a.datetime.compareTo(b.datetime));
    final runIds = {for (final run in allRuns) run.id};

    final comparisons = <RunComparison>[];
    final rated = <String>{};
    for (final run in allRuns) {
      final feedbacks = feedbacksForSetup(run.id);
      if (feedbacks.isNotEmpty) rated.add(run.id);
      final goal = sessionsById[run.testSessionId]!.goal;
      for (final feedback in feedbacks) {
        final byReference = feedback.comparisons.groupListsBy((c) => c.referenceSetupId);
        for (final MapEntry(key: referenceId, value: answers) in byReference.entries) {
          if (referenceId == run.id || !runIds.contains(referenceId)) continue;
          final score = RunComparison.scoreOf(answers, goal);
          if (score != null) comparisons.add(RunComparison(ratedId: run.id, referenceId: referenceId, score: score));
        }
      }
    }

    return TestSessionHistory(
      session: session,
      adjustments: adjustments,
      runs: [
        for (final run in allRuns)
          if (run.testSessionId == session.id) run,
      ],
      ratedRunIds: rated,
      pooledRuns: [
        for (final run in allRuns)
          if (run.testSessionId != session.id) run,
      ],
      comparisons: comparisons,
      setups: setups,
    );
  }

  static AdjustmentValue? valueOf(Setup setup, String adjustmentId) =>
      setup.bikeAdjustmentValues[adjustmentId] ?? setup.personAdjustmentValues[adjustmentId];

  /// The adjustments whose value is not the same in [a] and [b].
  static Set<String> differingIds(Setup a, Setup b) {
    final valuesA = {...a.bikeAdjustmentValues, ...a.personAdjustmentValues};
    final valuesB = {...b.bikeAdjustmentValues, ...b.personAdjustmentValues};
    return {
      for (final id in {...valuesA.keys, ...valuesB.keys})
        if (valuesA[id] != valuesB[id]) id,
    };
  }

  /// The summed scores of [a] against [b] (either side rated), or null when
  /// they were never compared.
  int? verdict(String a, String b) => verdictWhere((id) => id == a, (id) => id == b);

  /// Like [verdict], for every pair of runs that pass [isA] and [isB].
  int? verdictWhere(bool Function(String id) isA, bool Function(String id) isB) {
    int? total;
    for (final comparison in comparisons) {
      if (isA(comparison.ratedId) && isB(comparison.referenceId)) {
        total = (total ?? 0) + comparison.score;
      } else if (isB(comparison.ratedId) && isA(comparison.referenceId)) {
        total = (total ?? 0) - comparison.score;
      }
    }
    return total;
  }
}

/// A pure proposal strategy for one [TestSessionMethod]. Strategies are black
/// boxes: they know a knob's type, range and step, never what it does.
abstract class TestSessionStrategy {
  const TestSessionStrategy();

  SuggestionResult propose(TestSessionHistory history);

  /// Null for a free session: nothing is proposed.
  static TestSessionStrategy? of(TestSessionMethod? method) => switch (method) {
    PatternSearch() => const PatternSearchStrategy(),
    OrthogonalArray() => const OrthogonalArrayStrategy(),
    Tournament() => const TournamentStrategy(),
    null => null,
  };

  /// Why nothing can be proposed for any method yet, or null.
  static SuggestionResult? waiting(TestSessionHistory history) {
    if (!history.session.isRunning) return const NoSuggestion('The session has ended.');
    final latest = history.runs.lastOrNull;
    if (latest == null) return const NoSuggestion('Record a run first.');
    if (!history.ratedRunIds.contains(latest.id)) return NoSuggestion('Add feedback on ${latest.displayName} first.');
    return null;
  }

  /// The knobs a strategy may move: the session's, minus the locked ones and
  /// those it can't move (see [StrategyKnob.of]). Problems with the data come
  /// back as [InvalidData], and [NoSuggestion] when every knob is locked.
  static ({List<StrategyKnob> knobs, SuggestionResult? result}) movableKnobs(TestSessionHistory history) {
    final latest = history.runs.last;
    final knobs = <StrategyKnob>[];
    for (final id in history.session.adjustmentIds) {
      if (history.session.locks.containsKey(id)) continue;
      final adjustment = history.adjustments[id];
      if (adjustment == null) {
        return (
          knobs: const [],
          result: const InvalidData('An adjustment of this session is no longer on the bike. Lock it to go on.'),
        );
      }
      if (adjustment is StepAdjustment && (adjustment.notes?.contains(StepAdjustment.unknownMaxWarning) ?? false)) {
        return (
          knobs: const [],
          result: InvalidData("The range of '${adjustment.name}' is a placeholder. Set its real max first."),
        );
      }
      final value = TestSessionHistory.valueOf(latest, id);
      if (value == null) {
        return (knobs: const [], result: InvalidData("${latest.displayName} has no value for '${adjustment.name}'."));
      }
      if (!adjustment.isValidValue(value)) {
        return (
          knobs: const [],
          result: InvalidData("'${adjustment.name}' in ${latest.displayName} is outside its range."),
        );
      }
      if (StrategyKnob.of(adjustment, reference: value) case final knob?) knobs.add(knob);
    }
    if (knobs.isEmpty) return (knobs: knobs, result: const NoSuggestion('Every adjustment is locked.'));
    return (knobs: knobs, result: null);
  }

  /// Each run's position on [knobs], or null where a value is missing.
  static Map<String, List<double>?> positions(TestSessionHistory history, List<StrategyKnob> knobs) {
    List<double>? positionOf(Setup run) {
      final position = [for (final knob in knobs) knob.coordinateOf(TestSessionHistory.valueOf(run, knob.id))];
      return position.contains(null) ? null : position.cast<double>();
    }

    return {
      for (final run in [...history.pooledRuns, ...history.runs]) run.id: positionOf(run),
    };
  }

  static bool samePosition(List<StrategyKnob> knobs, List<double> a, List<double> b) {
    for (var i = 0; i < knobs.length; i++) {
      if (!knobs[i].isSame(a[i], b[i])) return false;
    }
    return true;
  }

  static Map<String, AdjustmentValue> valuesAt(List<StrategyKnob> knobs, List<double> position) => {
    for (var i = 0; i < knobs.length; i++) knobs[i].id: knobs[i].valueAt(position[i]),
  };

  /// "Rebound +2, Lockout On": what changes from [from] to [to].
  static String describeMove(List<StrategyKnob> knobs, List<double> from, List<double> to) => [
    for (var i = 0; i < knobs.length; i++)
      if (!knobs[i].isSame(from[i], to[i])) knobs[i].describe(from[i], to[i]),
  ].join(', ');

  /// The A-B-A check: [repeatId] (a re-ride of [originalId]) lost against
  /// [previousId], which [originalId] had beaten.
  static bool drifted(
    TestSessionHistory history, {
    required String repeatId,
    required String originalId,
    required String previousId,
  }) {
    final before = history.verdict(originalId, previousId);
    final after = history.verdict(repeatId, previousId);
    return before != null && after != null && before > 0 && after < 0;
  }

  /// The smallest change of [knob] the rider notices. It starts at one unit;
  /// a change size answered "same" at least [repeatsToRaise] times, and never
  /// otherwise, raises it above that size. Only comparisons of runs (of any of
  /// the bike's sessions) that differ in this knob alone count.
  static const int repeatsToRaise = 2;

  static double minNoticeableStep(StrategyKnob knob, TestSessionHistory history) {
    if (knob.isDiscrete) return knob.unit;
    final runs = {
      for (final run in [...history.pooledRuns, ...history.runs]) run.id: run,
    };
    final sames = <int, int>{};
    final differents = <int, int>{};
    for (final comparison in history.comparisons) {
      final a = runs[comparison.ratedId];
      final b = runs[comparison.referenceId];
      if (a == null || b == null || !setEquals(TestSessionHistory.differingIds(a, b), {knob.id})) continue;
      final from = knob.coordinateOf(TestSessionHistory.valueOf(b, knob.id));
      final to = knob.coordinateOf(TestSessionHistory.valueOf(a, knob.id));
      if (from == null || to == null) continue;
      final units = ((to - from).abs() / knob.unit).round();
      if (units == 0) continue;
      final counts = comparison.score == 0 ? sames : differents;
      counts.update(units, (n) => n + 1, ifAbsent: () => 1);
    }

    var minUnits = 1;
    for (final units in {...sames.keys, ...differents.keys}.sorted((a, b) => a.compareTo(b))) {
      if ((differents[units] ?? 0) > 0) break;
      if ((sames[units] ?? 0) >= repeatsToRaise) minUnits = units + 1;
    }
    return minUnits * knob.unit;
  }
}
