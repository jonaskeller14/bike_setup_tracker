import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData;
import 'package:intl/intl.dart';

import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/feedback/feedback_key.dart';
import '../models/feedback/ride_feedback.dart';
import '../models/feedback/test_session.dart';
import '../models/feedback/test_session_method.dart';
import '../models/person.dart';
import '../models/setup.dart';
import '../models/timeline_entry.dart';
import 'bike_adjustment_column_service.dart';
import 'setup_carry_over.dart';

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

  /// What [setups] differ in. Component adjustments are compared by column of
  /// the bike details table, so a replaced component's adjustment and its
  /// successor count once. [adjustmentIds] holds every adjustment of the
  /// differing columns, [count] the differing columns and rider attributes.
  static ({List<String> adjustmentIds, int count}) differencesBetween(
    Iterable<Setup> setups,
    BikeAdjustmentProjection projection,
  ) {
    final all = setups.toList();
    if (all.isEmpty) return (adjustmentIds: const [], count: 0);
    bool differ(AdjustmentValue? Function(Setup setup) valueIn) =>
        all.any((setup) => valueIn(setup) != valueIn(all.first));

    final ids = <String>[];
    var count = 0;
    for (final column in projection.columns) {
      if (!differ((setup) => projection.valueFor(setup, column))) continue;
      count++;
      for (final member in projection.laneOf(column)?.members ?? const <SlotLaneMember>[]) {
        ids.addAll([
          for (final adjustment in member.component.adjustments)
            if (laneAdjustmentKey(adjustment) == column.adjustment) adjustment.id,
        ]);
      }
    }
    final personIds = {for (final setup in all) ...setup.personAdjustmentValues.keys}.toList()..sort();
    for (final id in personIds) {
      if (!differ((setup) => setup.personAdjustmentValues[id])) continue;
      count++;
      ids.add(id);
    }
    return (adjustmentIds: ids, count: count);
  }

  /// The columns of [projection] that hold any of [adjustmentIds].
  static List<BikeAdjustmentColumnKey> columnsOf(Iterable<String> adjustmentIds, BikeAdjustmentProjection projection) {
    final ids = adjustmentIds.toSet();
    return [
      for (final column in projection.columns)
        if (projection
                .laneOf(column)
                ?.members
                .any(
                  (member) => member.component.adjustments.any(
                    (adjustment) => ids.contains(adjustment.id) && laneAdjustmentKey(adjustment) == column.adjustment,
                  ),
                ) ??
            false)
          column,
    ];
  }

  /// The knobs a run may change: the session's, minus the locked ones, and
  /// none once the session has ended.
  static Set<String> editableIds(TestSession session) {
    if (!session.isRunning) return const {};
    return session.adjustmentIds.toSet().difference(session.locks.keys.toSet());
  }

  /// "Copy of 'Run 2' (1.10.2026)" below the notes of [source]. The notes of an
  /// earlier run describe that ride, so only a source from outside the session
  /// passes its notes on, and the copy lines don't pile up run after run.
  static String runNotes({required Setup source, required TestSession session, required String dateFormat}) {
    final copyLine = "Copy of '${source.displayName}' (${DateFormat(dateFormat).format(source.datetimeLocal)})";
    final notes = source.testSessionId == session.id ? null : source.notes?.trim();
    return notes == null || notes.isEmpty ? copyLine : '$notes\n\n$copyLine';
  }

  /// Run 1 or a later run: a copy of [source] stamped [now] with [values] (a
  /// proposal) set, and the session's locked values on top, so a lock holds
  /// even when [source] is an older run. A Compare run ignores locks: a locked
  /// value would turn the candidate into a different setup. A [carryOver]
  /// moves the values of replaced components to their successors first.
  static Setup run({
    required Setup source,
    required TestSession session,
    required int number,
    Map<String, AdjustmentValue> values = const {},
    SetupCarryOver? carryOver,
    String? notes,
    DateTime? now,
  }) {
    final stamp = now ?? DateTime.now();
    final locks = session.method is Tournament ? const <String, AdjustmentValue>{} : session.locks;
    Map<String, AdjustmentValue> locked(Map<String, AdjustmentValue> current) => {
      ...current,
      for (final MapEntry(:key, :value) in values.entries)
        if (current.containsKey(key)) key: value,
      for (final MapEntry(:key, :value) in locks.entries)
        if (current.containsKey(key)) key: value,
    };
    return Setup(
      name: 'Run $number',
      notes: notes,
      datetime: stamp.toUtc(),
      datetimeLocal: stamp,
      tags: const {},
      bike: source.bike,
      person: source.person,
      bikeAdjustmentValues: locked(carryOver?.applyTo(source.bikeAdjustmentValues) ?? source.bikeAdjustmentValues),
      personAdjustmentValues: locked(source.personAdjustmentValues),
      testSessionId: session.id,
      sourceSetupId: source.id,
      sourceKind: SetupSourceKind.testSessionRun,
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
