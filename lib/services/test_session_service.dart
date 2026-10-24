import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData;

import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/feedback/feedback_key.dart';
import '../models/feedback/ride_feedback.dart';
import '../models/feedback/test_session.dart';
import '../models/feedback/test_session_method.dart';
import '../models/person.dart';
import '../models/setup.dart';
import '../models/timeline_entry.dart';

/// An adjustment a test session can tune, with the component or rider it
/// belongs to.
@immutable
class TestSessionKnob {
  final Adjustment adjustment;
  final String ownerId;
  final String ownerName;
  final IconData ownerIcon;
  final bool isRider;

  const TestSessionKnob({
    required this.adjustment,
    required this.ownerId,
    required this.ownerName,
    required this.ownerIcon,
    required this.isRider,
  });
}

/// Pure rules of test sessions: which adjustments are knobs, what a run copies
/// from the run before it, and what the method picker tells the rider.
class TestSessionService {
  static const int minCompareSetups = 2;

  /// Every pair of candidates is compared at least once, so more setups mean
  /// many more runs.
  static const int recommendedMaxCompareSetups = 4;

  /// More adjustments at once make it hard to tell which one helped.
  static const int recommendedMaxAdjustments = 5;

  /// A text has no direction to move in, so it can't be tuned.
  static bool isTunable(Adjustment adjustment) =>
      adjustment is! TextAdjustment && adjustment is! DurationAdjustment;

  /// The tunable adjustments of the bike's components and its rider.
  static List<TestSessionKnob> knobsFor({required Iterable<Component> bikeComponents, Person? rider}) {
    return [
      for (final component in bikeComponents)
        for (final adjustment in component.adjustments.where(isTunable))
          TestSessionKnob(
            adjustment: adjustment,
            ownerId: component.id,
            ownerName: component.name,
            ownerIcon: component.componentType.getIconData(),
            isRider: false,
          ),
      if (rider != null)
        for (final adjustment in rider.adjustments.where(isTunable))
          TestSessionKnob(
            adjustment: adjustment,
            ownerId: rider.id,
            ownerName: rider.name,
            ownerIcon: Person.iconData,
            isRider: true,
          ),
    ];
  }

  /// Adjustments whose value is not the same in every one of [setups].
  static List<String> differingAdjustmentIds(Iterable<Setup> setups) {
    final values = [for (final setup in setups) {...setup.bikeAdjustmentValues, ...setup.personAdjustmentValues}];
    final ids = {for (final map in values) ...map.keys};
    return [
      for (final id in ids.toList()..sort())
        if (values.any((map) => map[id] != values.first[id])) id,
    ];
  }

  /// The knobs a run may change: the session's, minus the locked ones, and
  /// none once the session has ended.
  static Set<String> editableIds(TestSession session) {
    if (!session.isRunning) return const {};
    return session.adjustmentIds.toSet().difference(session.locks.keys.toSet());
  }

  /// Run 1 or a later run: a copy of [source] stamped [now], with the session's
  /// locked values on top, so a lock holds even when [source] is an older run.
  static Setup run({required Setup source, required TestSession session, required int number, DateTime? now}) {
    final stamp = now ?? DateTime.now();
    Map<String, AdjustmentValue> locked(Map<String, AdjustmentValue> values) => {
      ...values,
      for (final MapEntry(:key, :value) in session.locks.entries)
        if (values.containsKey(key)) key: value,
    };
    return Setup(
      name: 'Run $number',
      datetime: stamp.toUtc(),
      datetimeLocal: stamp,
      tags: const {},
      bike: source.bike,
      person: source.person,
      bikeAdjustmentValues: locked(source.bikeAdjustmentValues),
      personAdjustmentValues: locked(source.personAdjustmentValues),
      testSessionId: session.id,
    );
  }

  /// Each run followed by the feedbacks on it, oldest first, or the whole
  /// list newest first to match a descending timeline.
  static List<TimelineEntry> runsAndFeedbacks(
    List<Setup> runs,
    List<RideFeedback> Function(Setup run) feedbacksOf, {
    required bool ascending,
  }) {
    final ordered = [
      for (final run in [...runs]..sort((a, b) => a.datetime.compareTo(b.datetime))) ...[
        SetupEntry(run),
        for (final feedback in feedbacksOf(run).toList()..sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC)))
          FeedbackTimelineEntry(feedback),
      ],
    ];
    return ascending ? ordered : ordered.reversed.toList();
  }

  /// "Front · Calm".
  static String goalLabel(FeedbackAspect aspect, String Function(String slug) customLabel) => switch (aspect) {
    EndAspect(:final end, :final attribute) => '${end.label} · ${attribute.qualityLabel}',
    CustomAspect(:final slug) => customLabel(slug),
    _ => aspect.raw,
  };

  static String methodLabel(TestSessionMethod? method) => switch (method) {
    PatternSearch() => 'Fine-tune',
    OrthogonalArray() => 'Explore',
    Tournament() => 'Compare',
    null => 'Free',
  };

  static String methodDescription(TestSessionMethod? method) => switch (method) {
    PatternSearch() => 'Move one knob at a time around your best run, in smaller and smaller steps.',
    OrthogonalArray() => 'Change all knobs together in a planned pattern to learn what each one does.',
    Tournament() => 'Ride 2–4 setups you already have against each other to find the best.',
    null => 'Record the runs and compare them yourself. Nothing is proposed.',
  };

  /// A rough run count for [knobCount] knobs, or the number of candidates for a
  /// Compare session.
  static String? expectedRuns(TestSessionMethod? method, int knobCount) {
    return switch (method) {
      _ when knobCount <= 0 => null,
      PatternSearch() => 'about ${knobCount * 4} runs',
      OrthogonalArray() => 'about ${knobCount + 2} runs',
      Tournament(:final candidateSetupIds) => 'about ${candidateSetupIds.length + 1} runs',
      null => null,
    };
  }
}
