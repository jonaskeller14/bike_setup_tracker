import 'dart:math' as math;

import 'package:collection/collection.dart';

import '../../models/feedback/test_session_method.dart';
import '../../models/setup.dart';
import '../feedback_ranking_service.dart';
import 'session_progress.dart';
import 'suggestion_result.dart';
import 'test_session_strategy.dart';

/// "Compare": rides the candidate setups against each other. Each run is
/// compared with the run before it, so the schedule is a walk through the
/// pairs: a full round robin for up to [roundRobinMax] candidates, otherwise
/// until every candidate has [minGamesInLargeFields] comparisons. Bradley-Terry
/// ranks the candidates; when the top two are level, they are ridden against
/// each other again.
class TournamentStrategy extends TestSessionStrategy {
  static const int roundRobinMax = 4;
  static const int minGamesInLargeFields = 2;

  /// Direct comparisons of a level top two before the leader is taken as is.
  static const int tieBreakGames = 2;

  /// Strengths closer than this (in log) are level.
  static const double tieThreshold = 0.25;

  const TournamentStrategy();

  @override
  SuggestionResult propose(TestSessionHistory history) {
    if (TestSessionStrategy.waiting(history) case final result?) return result;
    final method = history.session.method;
    if (method is! Tournament) return const InvalidData(SuggestionNote(SuggestionNoteKind.notCompare));
    final field = _Field.of(method, history);
    if (field == null) return const InvalidData(SuggestionNote(SuggestionNoteKind.setupRemoved));

    final ids = history.session.adjustmentIds;
    final last = history.runs.last;
    if (field.nextInWalk() case final next?) {
      return _ride(
        next,
        ids,
        last,
        SuggestionNote(SuggestionNoteKind.rideAndCompare, [SetupArg(next.name), SetupArg(last.name)]),
      );
    }

    final (:top, :second, :gamesLeft) = field.leaders();
    if (gamesLeft > 0) {
      final next = field.current == top.id ? second : top;
      final other = next.id == top.id ? second : top;
      return _ride(
        next,
        ids,
        last,
        SuggestionNote(SuggestionNoteKind.levelRideAgain, [SetupArg(next.name), SetupArg(other.name)]),
      );
    }
    return Converged(bestSetupId: top.id);
  }

  /// The walk is fixed, whatever the answers; only a level top two adds runs.
  /// A tie-break counts once: the rare case that it levels another pair is
  /// left out of the upper end.
  @override
  SessionProgress? estimate(TestSessionHistory history) {
    final method = history.session.method;
    final field = method is Tournament ? _Field.of(method, history) : null;
    if (field == null) return null;
    final ridden = history.runs.length;

    var walk = 0;
    for (var next = field.nextInWalk(); next != null; next = field.nextInWalk()) {
      field.ride(next);
      walk++;
    }
    if (walk > 0) {
      return SessionProgress(ridden: ridden, left: walk, maxLeft: walk + field.maxTieBreakRuns);
    }

    final (:top, :second, :gamesLeft) = field.leaders();
    if (gamesLeft == 0) return SessionProgress.exact(ridden: ridden, left: 0);
    // A clear answer ends it after one run. When neither of the two was ridden
    // last, the first run only brings one of them up.
    final onPair = field.current == top.id || field.current == second.id;
    return SessionProgress(ridden: ridden, left: 1, maxLeft: gamesLeft + (onPair ? 0 : 1));
  }

  static Proposal _ride(Setup next, List<String> ids, Setup last, SuggestionNote rationale) => Proposal(
    baseSetupId: next.id,
    values: {for (final id in ids) id: ?TestSessionHistory.valueOf(next, id)},
    referenceSetupId: last.id,
    rationale: rationale,
  );
}

/// The candidates of a Compare session and the comparisons between them.
class _Field {
  final List<Setup> candidates;
  final List<RankingGame> _games = [];
  final Map<String, int> _pairGames = {};
  final Map<String, int> _gameCount = {};

  /// The candidate ridden last, which the next run is compared with.
  String? current;

  _Field._(this.candidates);

  /// Null when a candidate is gone.
  static _Field? of(Tournament method, TestSessionHistory history) {
    final candidates = [for (final id in method.candidateSetupIds) history.setups[id]];
    if (candidates.contains(null) || candidates.length < 2) return null;
    final field = _Field._(candidates.cast<Setup>());

    final ids = history.session.adjustmentIds;
    // A run copied from another run, or recorded before runs knew their source,
    // is matched by its values.
    Setup? candidateOf(Setup run) =>
        field.candidates.firstWhereOrNull((candidate) => candidate.id == run.sourceSetupId) ??
        field.candidates.firstWhereOrNull(
          (candidate) =>
              ids.every((id) => TestSessionHistory.valueOf(run, id) == TestSessionHistory.valueOf(candidate, id)),
        );
    final candidateByRun = {for (final run in history.runs) run.id: ?candidateOf(run)?.id};

    for (final comparison in history.comparisons) {
      final a = candidateByRun[comparison.ratedId];
      final b = candidateByRun[comparison.referenceId];
      if (a == null || b == null || a == b) continue;
      field._games.add(RankingGame(a, b, (comparison.score + 2) / 4));
      field._count(a, b);
    }
    field.current = candidateByRun[history.runs.last.id];
    return field;
  }

  void _count(String a, String b) {
    _pairGames.update(_pair(a, b), (n) => n + 1, ifAbsent: () => 1);
    _gameCount.update(a, (n) => n + 1, ifAbsent: () => 1);
    _gameCount.update(b, (n) => n + 1, ifAbsent: () => 1);
  }

  static String _pair(String a, String b) => a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';

  int _pairCount(String a, String b) => _pairGames[_pair(a, b)] ?? 0;
  int _countOf(String id) => _gameCount[id] ?? 0;

  bool get _isLarge => candidates.length > TournamentStrategy.roundRobinMax;

  bool _needsMore(Setup candidate) => _isLarge
      ? _countOf(candidate.id) < math.min(TournamentStrategy.minGamesInLargeFields, candidates.length - 1)
      : candidates.any((other) => other != candidate && _pairCount(candidate.id, other.id) == 0);

  /// The candidate the walk rides next, or null once it is complete.
  Setup? nextInWalk() {
    if (!candidates.any(_needsMore)) return null;
    final current = this.current;
    // A pair not compared yet with the run just ridden first, then whoever
    // still needs comparisons, then whoever has the fewest.
    int priority(Setup candidate) {
      final fresh = current == null || _pairCount(current, candidate.id) == 0;
      final needs = _needsMore(candidate);
      return (fresh && needs ? 4 : 0) + (needs ? 2 : 0) + (fresh ? 1 : 0);
    }

    return candidates.where((c) => c.id != current).sorted((a, b) {
      final byPriority = priority(b).compareTo(priority(a));
      if (byPriority != 0) return byPriority;
      final byCount = _countOf(a.id).compareTo(_countOf(b.id));
      return byCount != 0 ? byCount : candidates.indexOf(a).compareTo(candidates.indexOf(b));
    }).first;
  }

  /// Counts [next] as ridden and compared with [current], without an answer:
  /// enough for the walk, not for [leaders].
  void ride(Setup next) {
    if (current case final current?) _count(current, next.id);
    current = next.id;
  }

  /// The two strongest candidates and the direct comparisons they still owe:
  /// none unless they are level.
  ({Setup top, Setup second, int gamesLeft}) leaders() {
    Setup candidate(String id) => candidates.firstWhere((c) => c.id == id);
    final ranks = FeedbackRankingService.rankGames(_games).values.sorted((a, b) {
      final byRank = a.rank.compareTo(b.rank);
      return byRank != 0
          ? byRank
          : candidates.indexOf(candidate(a.setupId)).compareTo(candidates.indexOf(candidate(b.setupId)));
    });
    final top = ranks[0];
    final second = ranks[1];
    final level = (math.log(top.strength) - math.log(second.strength)).abs() < TournamentStrategy.tieThreshold;
    return (
      top: candidate(top.setupId),
      second: candidate(second.setupId),
      gamesLeft: level ? math.max(0, TournamentStrategy.tieBreakGames - _pairCount(top.setupId, second.setupId)) : 0,
    );
  }

  /// The most runs one tie-break takes, whichever two end up level: their
  /// missing direct comparisons, plus one run to bring one of them up when
  /// neither was ridden last.
  int get maxTieBreakRuns {
    var fewest = TournamentStrategy.tieBreakGames;
    for (final (i, a) in candidates.indexed) {
      for (final b in candidates.skip(i + 1)) {
        fewest = math.min(fewest, _pairCount(a.id, b.id));
      }
    }
    final games = TournamentStrategy.tieBreakGames - fewest;
    return games == 0 ? 0 : games + (candidates.length > 2 ? 1 : 0);
  }
}
