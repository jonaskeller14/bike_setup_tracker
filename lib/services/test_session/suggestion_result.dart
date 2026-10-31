import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../../models/adjustment/adjustment.dart';

enum SuggestionNoteKind {
  recordRunFirst,
  addFeedbackFirst,
  adjustmentGone,
  noValue,
  outOfRange,
  allLocked,
  notCompare,
  setupRemoved,
  patternStep,
  estimatedBest,
  rideAgainConfirm,
  keepGoing,
  tryFromBest,
  rideAgainCheck,
  rideAndCompare,
  levelRideAgain,
}

/// What a strategy has to say, without wording: [kind] names the sentence and
/// [args] fill it (run names, adjustment names, a move like "Rebound +2"). The
/// UI turns it into text in the app language (`enum_labels.dart`).
@immutable
class SuggestionNote {
  final SuggestionNoteKind kind;
  final List<String> args;

  const SuggestionNote(this.kind, [this.args = const []]);

  @override
  bool operator ==(Object other) =>
      other is SuggestionNote && other.kind == kind && const ListEquality<String>().equals(other.args, args);

  @override
  int get hashCode => Object.hash(kind, const ListEquality<String>().hash(args));

  @override
  String toString() => 'SuggestionNote(${kind.name}, $args)';
}

/// What a test session strategy says about the next run.
@immutable
sealed class SuggestionResult {
  const SuggestionResult();
}

/// Ride a copy of [baseSetupId] with [values] set, and compare it with
/// [referenceSetupId].
final class Proposal extends SuggestionResult {
  /// The run (or Compare candidate) the next run copies.
  final String baseSetupId;

  /// The value of every adjustment the strategy moves, changed or not.
  final Map<String, AdjustmentValue> values;

  /// The run the debrief should compare the next run with.
  final String? referenceSetupId;

  final SuggestionNote rationale;

  const Proposal({
    required this.baseSetupId,
    required this.values,
    required this.referenceSetupId,
    required this.rationale,
  });

  @override
  bool operator ==(Object other) =>
      other is Proposal &&
      other.baseSetupId == baseSetupId &&
      const MapEquality<String, AdjustmentValue>().equals(other.values, values) &&
      other.referenceSetupId == referenceSetupId &&
      other.rationale == rationale;

  @override
  int get hashCode => Object.hash(
    baseSetupId,
    const MapEquality<String, AdjustmentValue>().hash(values),
    referenceSetupId,
    rationale,
  );

  @override
  String toString() => 'Proposal($baseSetupId, $values, vs $referenceSetupId)';
}

/// Nothing left to try: [bestSetupId] is the best run (or Compare candidate).
final class Converged extends SuggestionResult {
  final String bestSetupId;

  /// The best run, ridden again, lost against a run it had beaten: the trail
  /// or the rider changed during the session.
  final bool drift;

  const Converged({required this.bestSetupId, this.drift = false});

  @override
  bool operator ==(Object other) => other is Converged && other.bestSetupId == bestSetupId && other.drift == drift;

  @override
  int get hashCode => Object.hash(bestSetupId, drift);

  @override
  String toString() => 'Converged($bestSetupId, drift: $drift)';
}

/// The strategy waits for the rider, e.g. feedback on the latest run.
final class NoSuggestion extends SuggestionResult {
  final SuggestionNote reason;

  const NoSuggestion(this.reason);

  @override
  bool operator ==(Object other) => other is NoSuggestion && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'NoSuggestion($reason)';
}

/// The session's data can't be used until the rider fixes it, e.g. an
/// adjustment that is no longer installed.
final class InvalidData extends SuggestionResult {
  final SuggestionNote error;

  const InvalidData(this.error);

  @override
  bool operator ==(Object other) => other is InvalidData && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'InvalidData($error)';
}
