import 'dart:math' as math;

import 'package:collection/collection.dart';

import '../../models/feedback/test_session_method.dart';
import '../../models/setup.dart';
import '../feedback_ranking_service.dart';
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
    if (method is! Tournament) return const InvalidData('This session does not compare setups.');
    final candidates = [for (final id in method.candidateSetupIds) history.setups[id]];
    if (candidates.contains(null) || candidates.length < 2) {
      return const InvalidData('A setup to compare was removed. End the session or compare the rest in a new one.');
    }
    final field = candidates.cast<Setup>();

    final ids = history.session.adjustmentIds;
    Setup? candidateOf(Setup run) => field.firstWhereOrNull(
      (candidate) =>
          ids.every((id) => TestSessionHistory.valueOf(run, id) == TestSessionHistory.valueOf(candidate, id)),
    );
    final candidateByRun = {for (final run in history.runs) run.id: ?candidateOf(run)?.id};

    final games = <RankingGame>[];
    final pairGames = <String, int>{};
    final gameCount = <String, int>{};
    for (final comparison in history.comparisons) {
      final a = candidateByRun[comparison.ratedId];
      final b = candidateByRun[comparison.referenceId];
      if (a == null || b == null || a == b) continue;
      games.add(RankingGame(a, b, (comparison.score + 2) / 4));
      pairGames.update(_pair(a, b), (n) => n + 1, ifAbsent: () => 1);
      gameCount.update(a, (n) => n + 1, ifAbsent: () => 1);
      gameCount.update(b, (n) => n + 1, ifAbsent: () => 1);
    }
    int pairCount(String a, String b) => pairGames[_pair(a, b)] ?? 0;
    int count(String id) => gameCount[id] ?? 0;

    final last = history.runs.last;
    final current = candidateByRun[last.id];
    final largeField = field.length > roundRobinMax;
    final requiredGames = math.min(minGamesInLargeFields, field.length - 1);
    bool needsMore(Setup candidate) => largeField
        ? count(candidate.id) < requiredGames
        : field.any((other) => other != candidate && pairCount(candidate.id, other.id) == 0);

    if (field.any(needsMore)) {
      // A pair not compared yet with the run just ridden first, then whoever
      // still needs comparisons, then whoever has the fewest.
      int priority(Setup candidate) {
        final fresh = current == null || pairCount(current, candidate.id) == 0;
        final needs = needsMore(candidate);
        return (fresh && needs ? 4 : 0) + (needs ? 2 : 0) + (fresh ? 1 : 0);
      }

      final next = field.where((c) => c.id != current).sorted((a, b) {
        final byPriority = priority(b).compareTo(priority(a));
        if (byPriority != 0) return byPriority;
        final byCount = count(a.id).compareTo(count(b.id));
        return byCount != 0 ? byCount : field.indexOf(a).compareTo(field.indexOf(b));
      }).first;
      return _ride(next, ids, last, 'Ride ${next.displayName} and compare it with ${last.displayName}.');
    }

    Setup candidate(String id) => field.firstWhere((c) => c.id == id);
    final ranks = FeedbackRankingService.rankGames(games).values.sorted((a, b) {
      final byRank = a.rank.compareTo(b.rank);
      return byRank != 0 ? byRank : field.indexOf(candidate(a.setupId)).compareTo(field.indexOf(candidate(b.setupId)));
    });
    final top = ranks[0];
    final second = ranks[1];
    final level = (math.log(top.strength) - math.log(second.strength)).abs() < tieThreshold;
    if (level && pairCount(top.setupId, second.setupId) < tieBreakGames) {
      final next = candidate(current == top.setupId ? second.setupId : top.setupId);
      final other = candidate(next.id == top.setupId ? second.setupId : top.setupId);
      return _ride(
        next,
        ids,
        last,
        '${next.displayName} and ${other.displayName} are level. Ride ${next.displayName} again to decide.',
      );
    }
    return Converged(bestSetupId: top.setupId);
  }

  static Proposal _ride(Setup next, List<String> ids, Setup last, String rationale) => Proposal(
    baseSetupId: next.id,
    values: {for (final id in ids) id: ?TestSessionHistory.valueOf(next, id)},
    referenceSetupId: last.id,
    rationale: rationale,
  );

  static String _pair(String a, String b) => a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';
}
