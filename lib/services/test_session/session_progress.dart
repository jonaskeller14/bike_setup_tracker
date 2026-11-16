import 'dart:math' as math;

import 'package:flutter/foundation.dart';

@immutable
class SessionProgress {
  /// The session's runs so far, including one that waits for its feedback.
  final int ridden;

  /// The latest run has no feedback yet.
  final bool pending;

  /// The runs still to record after the [ridden] ones, as things stand.
  final int left;

  /// The most runs still to record; null when there is no upper end.
  final int? maxLeft;

  /// The run now due (the [pending] one, otherwise the next) rides the best
  /// run again to confirm it, and ends the session.
  final bool confirming;

  const SessionProgress({
    required this.ridden,
    this.pending = false,
    required this.left,
    required this.maxLeft,
    this.confirming = false,
  }) : assert(ridden > 0 && left >= 0 && (maxLeft == null || maxLeft >= left));

  /// Exactly [left] more runs.
  const SessionProgress.exact({required int ridden, required int left, bool confirming = false})
    : this(ridden: ridden, left: left, maxLeft: left, confirming: confirming);

  bool get isDone => !pending && maxLeft == 0;
  bool get isExact => maxLeft == left;
  bool get isOpenEnded => maxLeft == null;

  /// This estimate once the next run is ridden and waits for its feedback: the
  /// answer is not in yet, so the run only moves from "left" to "ridden".
  SessionProgress get awaitingFeedback => SessionProgress(
    ridden: ridden + 1,
    pending: true,
    left: math.max(0, left - 1),
    maxLeft: maxLeft == null ? null : math.max(0, maxLeft! - 1),
    confirming: confirming,
  );

  /// This estimate while the latest of the [ridden] runs waits for its feedback.
  SessionProgress get asPending =>
      SessionProgress(ridden: ridden, pending: true, left: left, maxLeft: maxLeft, confirming: confirming);

  @override
  bool operator ==(Object other) =>
      other is SessionProgress &&
      other.ridden == ridden &&
      other.pending == pending &&
      other.left == left &&
      other.maxLeft == maxLeft &&
      other.confirming == confirming;

  @override
  int get hashCode => Object.hash(ridden, pending, left, maxLeft, confirming);

  @override
  String toString() =>
      'SessionProgress($ridden ridden${pending ? ', pending' : ''}, '
      '$left–${maxLeft ?? '∞'} left${confirming ? ', confirming' : ''})';
}
