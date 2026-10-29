import 'package:flutter/foundation.dart';

import 'feedback_key.dart';

/// The feedback's resolved setup compared with [referenceSetupId]. The rated
/// side is not stored, so it follows re-resolution; the reference never moves.
@immutable
class FeedbackComparison {
  final String referenceSetupId;
  final FeedbackAspect aspect;

  /// −2 … +2 for [OverallAspect], −1 … +1 for an [EndAspect]; positive means
  /// the rated setup is better.
  final int outcome;

  const FeedbackComparison({
    required this.referenceSetupId,
    required this.aspect,
    required this.outcome,
  });

  bool get isValid => aspect.isValidOutcome(outcome);

  Map<String, dynamic> toJson() => {
    'referenceSetupId': referenceSetupId,
    'aspect': aspect.raw,
    'outcome': outcome,
  };

  factory FeedbackComparison.fromJson(Map<String, dynamic> json) {
    return FeedbackComparison(
      referenceSetupId: json['referenceSetupId'] as String,
      aspect: FeedbackAspect.parse(json['aspect'] as String),
      outcome: (json['outcome'] as num).toInt(),
    );
  }

  FeedbackComparison copyWith({
    Object? referenceSetupId = const _Sentinel(),
    Object? aspect = const _Sentinel(),
    Object? outcome = const _Sentinel(),
  }) {
    return FeedbackComparison(
      referenceSetupId: referenceSetupId is _Sentinel ? this.referenceSetupId : (referenceSetupId as String),
      aspect: aspect is _Sentinel ? this.aspect : (aspect as FeedbackAspect),
      outcome: outcome is _Sentinel ? this.outcome : (outcome as int),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FeedbackComparison &&
            referenceSetupId == other.referenceSetupId &&
            aspect == other.aspect &&
            outcome == other.outcome;
  }

  @override
  int get hashCode => Object.hash(referenceSetupId, aspect, outcome);

  @override
  String toString() => 'FeedbackComparison($referenceSetupId, $aspect, $outcome)';
}

class _Sentinel {
  const _Sentinel();
}
