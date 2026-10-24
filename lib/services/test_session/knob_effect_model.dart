import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'strategy_knob.dart';
import 'test_session_strategy.dart';

/// Which knob moved the rider's preference, and in which direction:
/// Bradley-Terry with knob values as features. The chance that run A beats
/// run B is `σ(Σ effect · (a − b) / scale)`, fitted by logistic regression on
/// the answered comparisons with a ridge prior towards "no effect".
///
/// It works with any pair of runs and pools every session on the bike.
/// Comparisons of runs that also differ in an adjustment outside [knobs] are
/// left out, since that change could explain the answer.
@immutable
class KnobEffectModel {
  /// Log-odds of "better" per [scales] step up, by knob id.
  final Map<String, double> effects;

  /// The step each effect is measured in, by knob id.
  final Map<String, double> scales;

  /// Comparisons in which the knob differed, by knob id.
  final Map<String, int> evidence;

  const KnobEffectModel({required this.effects, required this.scales, required this.evidence});

  /// The ridge prior's weight, as virtual comparisons per knob at no effect.
  /// Light, because a session gives only about one comparison per knob.
  static const double ridge = 0.25;

  static const int _maxIterations = 50;
  static const double _tolerance = 1e-9;

  /// [scales] default to one unit of each knob.
  static KnobEffectModel fit({
    required List<StrategyKnob> knobs,
    required TestSessionHistory history,
    Map<String, double>? scales,
  }) {
    final scaleOf = {for (final knob in knobs) knob.id: scales?[knob.id] ?? knob.unit};
    final runs = {
      for (final run in [...history.pooledRuns, ...history.runs]) run.id: run,
    };
    final knobIds = {for (final knob in knobs) knob.id};

    final rows = <List<double>>[];
    final targets = <double>[];
    final evidence = {for (final knob in knobs) knob.id: 0};
    for (final comparison in history.comparisons) {
      final a = runs[comparison.ratedId];
      final b = runs[comparison.referenceId];
      if (a == null || b == null || !knobIds.containsAll(TestSessionHistory.differingIds(a, b))) continue;
      final row = <double>[];
      for (final knob in knobs) {
        final x = knob.coordinateOf(TestSessionHistory.valueOf(a, knob.id));
        final y = knob.coordinateOf(TestSessionHistory.valueOf(b, knob.id));
        final difference = x == null || y == null ? 0.0 : (x - y) / scaleOf[knob.id]!;
        if (difference != 0) evidence.update(knob.id, (n) => n + 1);
        row.add(difference);
      }
      if (row.every((z) => z == 0)) continue;
      rows.add(row);
      targets.add((comparison.score + 2) / 4);
    }

    final beta = _fit(rows, targets, knobs.length);
    return KnobEffectModel(
      effects: {for (var i = 0; i < knobs.length; i++) knobs[i].id: beta[i]},
      scales: scaleOf,
      evidence: evidence,
    );
  }

  /// Newton's method on the penalized log-likelihood; soft targets (0 … 1)
  /// carry the 5-step answer.
  static List<double> _fit(List<List<double>> rows, List<double> targets, int dimensions) {
    var beta = List<double>.filled(dimensions, 0);
    if (rows.isEmpty) return beta;
    for (var iteration = 0; iteration < _maxIterations; iteration++) {
      final gradient = [for (var j = 0; j < dimensions; j++) -ridge * beta[j]];
      final hessian = [
        for (var j = 0; j < dimensions; j++) [for (var k = 0; k < dimensions; k++) j == k ? ridge : 0.0],
      ];
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        var logit = 0.0;
        for (var j = 0; j < dimensions; j++) {
          logit += beta[j] * row[j];
        }
        final p = 1 / (1 + math.exp(-logit));
        final weight = p * (1 - p);
        for (var j = 0; j < dimensions; j++) {
          gradient[j] += (targets[i] - p) * row[j];
          for (var k = 0; k < dimensions; k++) {
            hessian[j][k] += weight * row[j] * row[k];
          }
        }
      }
      final step = _solve(hessian, gradient);
      beta = [for (var j = 0; j < dimensions; j++) beta[j] + step[j]];
      if (step.every((s) => s.abs() < _tolerance)) break;
    }
    return beta;
  }

  /// Gaussian elimination with partial pivoting; [a] is positive definite
  /// thanks to the ridge.
  static List<double> _solve(List<List<double>> a, List<double> b) {
    final n = b.length;
    final m = [
      for (var i = 0; i < n; i++) [...a[i], b[i]],
    ];
    for (var col = 0; col < n; col++) {
      var pivot = col;
      for (var row = col + 1; row < n; row++) {
        if (m[row][col].abs() > m[pivot][col].abs()) pivot = row;
      }
      final swap = m[col];
      m[col] = m[pivot];
      m[pivot] = swap;
      for (var row = col + 1; row < n; row++) {
        final factor = m[row][col] / m[col][col];
        for (var k = col; k <= n; k++) {
          m[row][k] -= factor * m[col][k];
        }
      }
    }
    final x = List<double>.filled(n, 0);
    for (var row = n - 1; row >= 0; row--) {
      var sum = m[row][n];
      for (var k = row + 1; k < n; k++) {
        sum -= m[row][k] * x[k];
      }
      x[row] = sum / m[row][row];
    }
    return x;
  }
}
