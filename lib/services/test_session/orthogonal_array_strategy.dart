import 'package:collection/collection.dart';

import '../../models/setup.dart';
import '../feedback_ranking_service.dart';
import 'knob_effect_model.dart';
import 'strategy_knob.dart';
import 'suggestion_result.dart';
import 'test_session_strategy.dart';

/// "Explore": run 1 is the baseline, then every run moves all knobs by a
/// large step in a two-level Hadamard pattern, so each knob's main effect can
/// be told apart in about one run per knob. Then it rides the estimated best
/// and confirms the best run (A-B-A).
///
/// The pattern is positional: run n + 1 is pattern row n, whatever was set.
/// The effects come from the values actually ridden, so deviations count.
class OrthogonalArrayStrategy extends TestSessionStrategy {
  /// The pattern's step, as a share of a knob's range.
  static const double stepShare = 0.25;

  /// The step of a knob without a finite range, in units.
  static const double stepUnits = 4;

  /// Smaller estimated effects (log-odds per step) leave a knob at the baseline.
  static const double minEffect = 0.15;

  const OrthogonalArrayStrategy();

  @override
  SuggestionResult propose(TestSessionHistory history) {
    if (TestSessionStrategy.waiting(history) case final result?) return result;
    final (:knobs, :result) = TestSessionStrategy.movableKnobs(history);
    if (result != null) return result;

    final runs = history.runs;
    final positions = TestSessionStrategy.positions(history, knobs);
    final baseline = runs.first;
    final base = positions[baseline.id] ?? positions[runs.last.id]!;
    final steps = [
      for (final knob in knobs)
        _atLeast(
          knob.stepOf(stepShare, fallbackUnits: stepUnits),
          TestSessionStrategy.minNoticeableStep(knob, history),
        ),
    ];
    final design = patternRows(knobs.length);

    List<double> row(List<int> signs) => [
      for (var k = 0; k < knobs.length; k++) _level(knobs[k], base[k], steps[k], signs[k]),
    ];

    final done = runs.length - 1;
    if (done < design.length) {
      final target = row(design[done]);
      return Proposal(
        baseSetupId: baseline.id,
        values: TestSessionStrategy.valuesAt(knobs, target),
        referenceSetupId: runs.last.id,
        rationale:
            'Pattern ${done + 1} of ${design.length}: ${TestSessionStrategy.describeMove(knobs, base, target)} '
            'from ${baseline.displayName}. Every adjustment moves, so their effects can be told apart.',
      );
    }

    bool ridden(List<double> position, Iterable<Setup> among) => among.any(
      (run) => positions[run.id] != null && TestSessionStrategy.samePosition(knobs, positions[run.id]!, position),
    );

    if (done == design.length) {
      final model = KnobEffectModel.fit(
        knobs: knobs,
        history: history,
        scales: {for (var k = 0; k < knobs.length; k++) knobs[k].id: steps[k]},
      );
      final estimate = row([
        for (final knob in knobs)
          switch (model.effects[knob.id]!) {
            final effect when effect > minEffect => 1,
            final effect when effect < -minEffect => -1,
            _ => 0,
          },
      ]);
      // An estimate that was ridden already (the baseline, when nothing made a
      // clear difference) goes straight to the confirmation.
      if (!ridden(estimate, runs)) {
        return Proposal(
          baseSetupId: baseline.id,
          values: TestSessionStrategy.valuesAt(knobs, estimate),
          referenceSetupId: runs.last.id,
          rationale:
              'Ride the estimated best: ${TestSessionStrategy.describeMove(knobs, base, estimate)} '
              'from ${baseline.displayName}.',
        );
      }
    }

    // The confirmation is the first run that repeats an earlier one after the
    // pattern; the estimate never repeats one.
    final best = _best(history, positions, knobs);
    final after = runs.skip(design.length + 1).toList();
    final confirmIndex = after.indexWhere(
      (run) => positions[run.id] != null && ridden(positions[run.id]!, runs.takeWhile((earlier) => earlier != run)),
    );
    if (confirmIndex >= 0) {
      final confirm = after[confirmIndex];
      final index = runs.indexOf(confirm);
      final original = runs
          .take(index)
          .lastWhere(
            (run) => TestSessionStrategy.samePosition(knobs, positions[run.id] ?? const [], positions[confirm.id]!),
          );
      return Converged(
        bestSetupId: best.id,
        drift: TestSessionStrategy.drifted(
          history,
          repeatId: confirm.id,
          originalId: original.id,
          previousId: runs[index - 1].id,
        ),
      );
    }

    // Riding the best right after itself says nothing, so then the baseline.
    final repeat = best.id == runs.last.id ? baseline : best;
    return Proposal(
      baseSetupId: repeat.id,
      values: TestSessionStrategy.valuesAt(knobs, positions[repeat.id] ?? base),
      referenceSetupId: runs.last.id,
      rationale: 'Ride ${repeat.displayName} again to confirm the result.',
    );
  }

  static double _atLeast(double value, double minimum) => value < minimum ? minimum : value;

  /// A step up or down from [base]; a discrete knob's "up" is the next option
  /// (or the previous one at the end), its "down" is [base].
  static double _level(StrategyKnob knob, double base, double step, int sign) {
    if (sign == 0) return base;
    if (knob.isDiscrete) {
      if (sign < 0) return base;
      return base + knob.unit <= knob.max ? base + knob.unit : base - knob.unit;
    }
    return knob.snap(base + sign * step);
  }

  /// Signs (±1) per run and knob: columns of a Sylvester Hadamard matrix of
  /// the smallest power-of-two order that fits [knobs], balanced columns
  /// first and the all-plus column last.
  static List<List<int>> patternRows(int knobs) {
    var order = 2;
    while (order < knobs) {
      order *= 2;
    }
    final columns = [for (var c = 1; c < order; c++) c, 0].take(knobs).toList();
    int sign(int row, int column) => _bitCount(row & column).isEven ? 1 : -1;
    return [
      for (var row = 0; row < order; row++) [for (final column in columns) sign(row, column)],
    ];
  }

  static int _bitCount(int value) {
    var count = 0;
    for (var v = value; v != 0; v >>= 1) {
      count += v & 1;
    }
    return count;
  }

  /// The best run of the session by Bradley-Terry; a repeat counts as the run
  /// it repeats.
  static Setup _best(TestSessionHistory history, Map<String, List<double>?> positions, List<StrategyKnob> knobs) {
    String originalOf(String id) {
      final position = positions[id];
      if (position == null) return id;
      return history.runs
              .firstWhereOrNull(
                (run) =>
                    positions[run.id] != null && TestSessionStrategy.samePosition(knobs, positions[run.id]!, position),
              )
              ?.id ??
          id;
    }

    final runIds = {for (final run in history.runs) run.id};
    final games = [
      for (final comparison in history.comparisons)
        if (runIds.contains(comparison.ratedId) && runIds.contains(comparison.referenceId))
          RankingGame(originalOf(comparison.ratedId), originalOf(comparison.referenceId), (comparison.score + 2) / 4),
    ].where((game) => game.a != game.b).toList();
    final ranks = FeedbackRankingService.rankGames(games);
    final bestId = ranks.values.sorted((a, b) => a.rank.compareTo(b.rank)).firstOrNull?.setupId;
    return history.runs.firstWhereOrNull((run) => run.id == bestId) ?? history.runs.first;
  }
}
