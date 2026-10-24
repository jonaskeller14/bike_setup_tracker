import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/feedback/feedback_key.dart';
import '../models/feedback/ride_feedback.dart';
import '../models/setup.dart';

/// A setup's place among the compared setups of its bike.
@immutable
class SetupRank {
  final String setupId;

  /// 1 is the best. Setups of equal strength share a rank.
  final int rank;

  /// The number of ranked setups on the bike.
  final int of;

  /// Bradley-Terry strength; 1 is neutral (the prior's anchor).
  final double strength;

  /// The `overall` comparisons this setup takes part in, on either side.
  final int comparisonCount;

  const SetupRank({
    required this.setupId,
    required this.rank,
    required this.of,
    required this.strength,
    required this.comparisonCount,
  });

  bool get isConfident => comparisonCount >= FeedbackRankingService.minComparisons;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SetupRank &&
            setupId == other.setupId &&
            rank == other.rank &&
            of == other.of &&
            strength == other.strength &&
            comparisonCount == other.comparisonCount;
  }

  @override
  int get hashCode => Object.hash(setupId, rank, of, strength, comparisonCount);

  @override
  String toString() => 'SetupRank($setupId, #$rank of $of, $strength, $comparisonCount)';
}

class FeedbackRankingService {
  const FeedbackRankingService._();

  /// Comparisons a setup needs before its rank is shown.
  static const int minComparisons = 2;

  /// Virtual games per setup against an anchor of strength 1, half won and
  /// half lost. It keeps setups that only won or only lost finite and makes
  /// disconnected chains converge.
  static const double priorGames = 1;

  static const int _maxIterations = 1000;
  static const double _tolerance = 1e-10;

  /// Ranks the setups of every bike from the `overall` comparisons.
  ///
  /// [feedbacksBySetup] maps each setup to the feedbacks that resolve to it,
  /// which makes it the rated side of their comparisons. Setups missing from
  /// [setups] (deleted) or on another bike are ignored, as are
  /// self-comparisons. Setups without a comparison get no rank.
  static Map<String, SetupRank> rank({
    required Map<String, Setup> setups,
    required Map<String, List<RideFeedback>> feedbacksBySetup,
  }) {
    final gamesByBike = <String, List<RankingGame>>{};
    for (final MapEntry(key: ratedId, value: feedbacks) in feedbacksBySetup.entries) {
      final rated = setups[ratedId];
      if (rated == null || rated.isDeleted) continue;
      for (final feedback in feedbacks) {
        if (feedback.isDeleted) continue;
        for (final comparison in feedback.comparisons) {
          if (comparison.aspect is! OverallAspect || !comparison.isValid) continue;
          final reference = setups[comparison.referenceSetupId];
          if (reference == null || reference.isDeleted || reference.id == ratedId || reference.bike != rated.bike) {
            continue;
          }
          final ratedWins = (comparison.outcome + 2) / 4;
          (gamesByBike[rated.bike] ??= []).add(RankingGame(ratedId, reference.id, ratedWins));
        }
      }
    }

    return {
      for (final games in gamesByBike.values) ...rankGames(games),
    };
  }

  /// Fits Bradley-Terry strengths to [games] and ranks the players.
  static Map<String, SetupRank> rankGames(List<RankingGame> games) {
    // A fixed summation order, sorted ids and simultaneous updates make the
    // fit independent of input order, down to the last bit.
    games.sort((x, y) {
      final byA = x.a.compareTo(y.a);
      if (byA != 0) return byA;
      final byB = x.b.compareTo(y.b);
      return byB != 0 ? byB : x.aWins.compareTo(y.aWins);
    });
    final wins = <String, double>{};
    final counts = <String, int>{};
    final pairGames = <String, Map<String, int>>{};
    for (final game in games) {
      wins.update(game.a, (w) => w + game.aWins, ifAbsent: () => game.aWins);
      wins.update(game.b, (w) => w + 1 - game.aWins, ifAbsent: () => 1 - game.aWins);
      counts.update(game.a, (c) => c + 1, ifAbsent: () => 1);
      counts.update(game.b, (c) => c + 1, ifAbsent: () => 1);
      (pairGames[game.a] ??= {}).update(game.b, (n) => n + 1, ifAbsent: () => 1);
      (pairGames[game.b] ??= {}).update(game.a, (n) => n + 1, ifAbsent: () => 1);
    }

    final ids = wins.keys.toList()..sort();
    var strength = {for (final id in ids) id: 1.0};
    for (var iteration = 0; iteration < _maxIterations; iteration++) {
      final next = <String, double>{};
      var maxChange = 0.0;
      for (final id in ids) {
        final p = strength[id]!;
        var denominator = priorGames / (p + 1);
        for (final MapEntry(key: opponent, value: n) in pairGames[id]!.entries) {
          denominator += n / (p + strength[opponent]!);
        }
        final updated = (wins[id]! + priorGames / 2) / denominator;
        maxChange = max(maxChange, (log(updated) - log(p)).abs());
        next[id] = updated;
      }
      strength = next;
      if (maxChange < _tolerance) break;
    }

    final ordered = [...ids]
      ..sort((a, b) {
        final byStrength = strength[b]!.compareTo(strength[a]!);
        return byStrength != 0 ? byStrength : a.compareTo(b);
      });
    final result = <String, SetupRank>{};
    var rank = 0;
    for (var i = 0; i < ordered.length; i++) {
      final id = ordered[i];
      if (i == 0 || !_isTie(strength[ordered[i - 1]]!, strength[id]!)) rank = i + 1;
      result[id] = SetupRank(
        setupId: id,
        rank: rank,
        of: ordered.length,
        strength: strength[id]!,
        comparisonCount: counts[id]!,
      );
    }
    return result;
  }

  static bool _isTie(double a, double b) => (log(a) - log(b)).abs() < 1e-6;
}

/// One comparison: [a] won [aWins] of it (0 … 1), [b] the rest.
class RankingGame {
  final String a;
  final String b;
  final double aWins;

  const RankingGame(this.a, this.b, this.aWins);
}
