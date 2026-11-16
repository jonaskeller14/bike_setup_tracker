import 'package:collection/collection.dart';

import '../../models/setup.dart';
import 'knob_effect_model.dart';
import 'session_progress.dart';
import 'strategy_knob.dart';
import 'suggestion_result.dart';
import 'test_session_strategy.dart';

/// "Fine-tune": a compass search around the best run (Hooke–Jeeves).
///
/// It polls one knob ± one step around the best run, repeats a successful move
/// (pattern move), halves the steps when no direction helps and, once every
/// step is at its smallest, asks for the best run again (A-B-A). With one knob
/// this is bracketing.
///
/// There is no stored state: the search is replayed from the runs and their
/// comparisons, so a run that deviates from a proposal counts with the values
/// actually set. A run that was not compared with the best run counts as not
/// better.
class PatternSearchStrategy extends TestSessionStrategy {
  /// The first step, as a share of a knob's range.
  static const double initialStepShare = 0.15;

  /// The first step of a knob without a finite range, in units.
  static const double initialStepUnits = 2;

  const PatternSearchStrategy();

  @override
  SuggestionResult propose(TestSessionHistory history) {
    if (TestSessionStrategy.waiting(history) case final result?) return result;
    final (:knobs, :result) = TestSessionStrategy.movableKnobs(history);
    if (result != null) return result;

    return _Search.replay(history, knobs).next();
  }

  /// Open-ended, so an estimate and no bound: the runs left if no run beats
  /// the best one any more. A better run usually adds runs, but saves one
  /// where its neighbours are ridden already (at the smallest step, at the end
  /// of a range), and "same" answers on the finer steps raise
  /// [TestSessionStrategy.minNoticeableStep] and skip them.
  @override
  SessionProgress? estimate(TestSessionHistory history) {
    final (:knobs, :result) = TestSessionStrategy.movableKnobs(history);
    if (result != null) return null;

    final search = _Search.replay(history, knobs);
    final ridden = history.runs.length;
    return switch (search.next()) {
      Converged() => SessionProgress.exact(ridden: ridden, left: 0),
      Proposal(rationale: SuggestionNote(kind: SuggestionNoteKind.rideAgainCheck)) => SessionProgress.exact(
        ridden: ridden,
        left: 1,
        confirming: true,
      ),
      _ => SessionProgress(
        ridden: ridden,
        left: search.pollsLeft() + (search.repeat == null ? 1 : 0),
        maxLeft: null,
      ),
    };
  }
}

class _Search {
  final TestSessionHistory history;
  final List<StrategyKnob> knobs;
  final Map<String, List<double>?> positions;
  final List<double> minSteps;
  late final List<double> steps;

  /// Knob indices in poll order, each with its first direction.
  late final List<(int, int)> pollOrder;

  late Setup best;
  late List<double> bestPosition;

  /// Positions that did not beat the best run of their time.
  final List<List<double>> notBetter = [];

  /// The move that just made a new best run, to try again.
  List<double>? lastMove;

  /// The latest re-ride of the best run since it became the best.
  Setup? repeat;

  _Search(this.history, this.knobs)
    : positions = TestSessionStrategy.positions(history, knobs),
      minSteps = [for (final knob in knobs) TestSessionStrategy.minNoticeableStep(knob, history)] {
    steps = [
      for (var i = 0; i < knobs.length; i++)
        knobs[i].isDiscrete
            ? knobs[i].unit
            : _atLeast(
                knobs[i].stepOf(
                  PatternSearchStrategy.initialStepShare,
                  fallbackUnits: PatternSearchStrategy.initialStepUnits,
                ),
                minSteps[i],
              ),
    ];
    // Earlier sessions tell which knobs mattered and which way helped.
    final model = KnobEffectModel.fit(knobs: knobs, history: history);
    final effects = [for (final knob in knobs) model.effects[knob.id]!];
    pollOrder = [
      for (final i in List.generate(knobs.length, (i) => i).sorted(
        (a, b) => effects[b].abs().compareTo(effects[a].abs()),
      ))
        (i, effects[i] < 0 ? -1 : 1),
    ];
    best = history.runs.first;
    // The latest run's values were checked, so a missing first position only
    // means run 1 predates a knob; it starts from the latest run then.
    bestPosition = positions[best.id] ?? positions[history.runs.last.id]!;
  }

  /// The search after every run of [history].
  factory _Search.replay(TestSessionHistory history, List<StrategyKnob> knobs) {
    final search = _Search(history, knobs);
    for (final run in history.runs.skip(1)) {
      search.add(run);
    }
    return search;
  }

  static double _atLeast(double value, double minimum) => value < minimum ? minimum : value;

  bool _same(List<double> a, List<double> b) => TestSessionStrategy.samePosition(knobs, a, b);

  void add(Setup run) {
    final position = positions[run.id];
    if (position == null) return;
    // The run was proposed after the steps shrank, so shrink them first.
    if (_patternTarget() == null) {
      while (_nextPoll() == null && _halveSteps()) {}
    }
    if (_same(position, bestPosition)) {
      repeat = run;
      return;
    }
    final verdict = history.verdictWhere(
      (id) => id == run.id,
      (id) => positions[id] != null && _same(positions[id]!, bestPosition),
    );
    if (verdict != null && verdict > 0) {
      notBetter.add(bestPosition);
      lastMove = [for (var i = 0; i < knobs.length; i++) position[i] - bestPosition[i]];
      best = run;
      bestPosition = position;
      repeat = null;
    } else {
      notBetter.add(position);
      lastMove = null;
    }
  }

  bool _tried(List<double> position) => notBetter.any((tried) => _same(tried, position));

  SuggestionResult next() {
    if (_patternTarget() case final target?) {
      return _proposal(target, SuggestionNote(SuggestionNoteKind.keepGoing, [SetupArg(best.name), _describe(target)]));
    }

    while (true) {
      if (_nextPoll() case final target?) {
        return _proposal(
          target,
          SuggestionNote(SuggestionNoteKind.tryFromBest, [_describe(target), SetupArg(best.name)]),
        );
      }
      if (!_halveSteps()) break;
    }

    final repeated = repeat;
    if (repeated == null) {
      return Proposal(
        baseSetupId: best.id,
        values: TestSessionStrategy.valuesAt(knobs, bestPosition),
        referenceSetupId: history.runs.last.id,
        rationale: SuggestionNote(SuggestionNoteKind.rideAgainCheck, [SetupArg(best.name)]),
      );
    }
    final index = history.runs.indexOf(repeated);
    return Converged(
      bestSetupId: best.id,
      drift:
          index > 0 &&
          TestSessionStrategy.drifted(
            history,
            repeatId: repeated.id,
            originalId: best.id,
            previousId: history.runs[index - 1].id,
          ),
    );
  }

  /// The runs [next] goes on to propose before the confirmation when none of
  /// them beats the best run: the pattern move, then every poll down to the
  /// smallest steps. Uses up the search.
  int pollsLeft() {
    var count = 0;
    if (_patternTarget() case final target?) {
      notBetter.add(target);
      count++;
    }
    while (true) {
      for (var target = _nextPoll(); target != null; target = _nextPoll()) {
        notBetter.add(target);
        count++;
      }
      if (!_halveSteps()) return count;
    }
  }

  /// The move that made the best run, once more, if not tried yet.
  List<double>? _patternTarget() {
    final move = lastMove;
    if (move == null) return null;
    final target = [for (var i = 0; i < knobs.length; i++) knobs[i].snap(bestPosition[i] + move[i])];
    return _same(target, bestPosition) || _tried(target) ? null : target;
  }

  /// One knob one step away from the best run, not tried yet.
  List<double>? _nextPoll() {
    for (final (i, firstDirection) in pollOrder) {
      for (final direction in [firstDirection, -firstDirection]) {
        final target = [...bestPosition];
        target[i] = knobs[i].snap(bestPosition[i] + direction * steps[i]);
        if (!_same(target, bestPosition) && !_tried(target)) return target;
      }
    }
    return null;
  }

  /// False once every step is at its smallest.
  bool _halveSteps() {
    var changed = false;
    for (var i = 0; i < knobs.length; i++) {
      if (knobs[i].isDiscrete) continue;
      final halved = _atLeast(knobs[i].roundToUnits(steps[i] / 2), minSteps[i]);
      if (halved < steps[i]) {
        steps[i] = halved;
        changed = true;
      }
    }
    return changed;
  }

  MoveArg _describe(List<double> target) => TestSessionStrategy.describeMove(knobs, bestPosition, target);

  Proposal _proposal(List<double> target, SuggestionNote rationale) => Proposal(
    baseSetupId: best.id,
    values: TestSessionStrategy.valuesAt(knobs, target),
    referenceSetupId: best.id,
    rationale: rationale,
  );
}
