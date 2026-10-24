import 'package:bike_setup_tracker/models/feedback/custom_issue.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_comparison.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_observation.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/services/custom_issue_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const wetRoots = CustomIssue('wet roots', 'Wet roots');
  const loose = CustomIssue('loose', 'Loose');
  const frontGrip = IssueKey(FeedbackEnd.front, FeedbackAttribute.grip);

  RideFeedback feedback(
    int day, {
    List<CustomIssue> issues = const [],
    Set<FeedbackComparison> comparisons = const {},
    bool isDeleted = false,
  }) {
    final at = DateTime.utc(2026, 6, day);
    return RideFeedback(
      bike: 'bike',
      setupId: 'setup',
      isDeleted: isDeleted,
      dateTimeUTC: at,
      dateTimeLocal: at,
      observations: {for (final issue in issues) issue.toObservation(), const FeedbackObservation.flag(frontGrip)},
      comparisons: comparisons,
    );
  }

  FeedbackComparison comparison(CustomIssue issue, int outcome, {String reference = 's0'}) =>
      FeedbackComparison(referenceSetupId: reference, aspect: issue.aspect, outcome: outcome);

  group('CustomIssueService.index', () {
    test('the latest feedback decides the label', () {
      final index = CustomIssueService.index([
        feedback(1, issues: [const CustomIssue('wet roots', 'wet roots')]),
        feedback(9, issues: [wetRoots]),
        feedback(5, issues: [const CustomIssue('wet roots', 'WET ROOTS')]),
      ]);

      expect(index.labelOf('wet roots'), 'Wet roots');
      expect(index.usages.single.useCount, 3);
      expect(index.usages.single.lastUsedUTC, DateTime.utc(2026, 6, 9));
    });

    test('most used first, then most recently used', () {
      final index = CustomIssueService.index([
        feedback(1, issues: [wetRoots]),
        feedback(2, issues: [loose]),
        feedback(3, issues: [loose]),
        feedback(4, issues: [const CustomIssue('a', 'Apex')]),
      ]);

      expect(index.usages.map((u) => u.slug), ['loose', 'a', 'wet roots']);
    });

    test('a feedback in the trash does not keep an issue alive', () {
      final index = CustomIssueService.index([
        feedback(1, issues: [wetRoots], isDeleted: true),
        feedback(2, issues: [loose]),
      ]);

      expect(index.contains('wet roots'), isFalse);
      expect(index.labelOf('wet roots'), 'wet roots');
      expect(index.usages.map((u) => u.slug), ['loose']);
    });

    test('matching filters by the typed text and keeps the usage order', () {
      final index = CustomIssueService.index([
        feedback(1, issues: [wetRoots, loose]),
        feedback(2, issues: [loose]),
      ]);

      expect(index.matching('  ROO').map((u) => u.slug), ['wet roots']);
      expect(index.matching('').map((u) => u.slug), ['loose', 'wet roots']);
      expect(index.matching('zzz'), isEmpty);
    });

    test('built-in flags and unknown keys are ignored', () {
      final f = feedback(1).copyWith(
        observations: {
          const FeedbackObservation.flag(frontGrip),
          const FeedbackObservation.flag(UnknownFeedbackKey('issue.custom')),
        },
      );
      expect(CustomIssueService.index([f]).usages, isEmpty);
    });
  });

  group('CustomIssueService.rename', () {
    test('rewrites key, label and comparison aspects', () {
      final f = feedback(1, issues: [wetRoots], comparisons: {comparison(wetRoots, 1)});

      final renamed = CustomIssueService.rename(f, 'wet roots', const CustomIssue('slippery', 'Slippery'))!;

      expect(renamed.customIssues, [const CustomIssue('slippery', 'Slippery')]);
      expect(renamed.issues, {frontGrip});
      expect(renamed.comparisons, {
        const FeedbackComparison(referenceSetupId: 's0', aspect: CustomAspect('slippery'), outcome: 1),
      });
    });

    test('a new label for the same slug only changes the label', () {
      final f = feedback(1, issues: [wetRoots], comparisons: {comparison(wetRoots, -1)});

      final renamed = CustomIssueService.rename(f, 'wet roots', const CustomIssue('wet roots', 'WET ROOTS'))!;

      expect(renamed.customIssues.single.label, 'WET ROOTS');
      expect(renamed.comparisons, f.comparisons);
    });

    test('merging into an existing issue keeps one flag and the existing answer', () {
      final f = feedback(
        1,
        issues: [wetRoots, loose],
        comparisons: {
          comparison(wetRoots, 1),
          comparison(loose, -1),
          comparison(wetRoots, 1, reference: 's9'),
        },
      );

      final merged = CustomIssueService.rename(f, 'wet roots', loose)!;

      expect(merged.customIssues, [loose]);
      expect(merged.comparisons, {comparison(loose, -1), comparison(loose, 1, reference: 's9')});
    });

    test('feedbacks without the issue are left alone', () {
      expect(CustomIssueService.rename(feedback(1, issues: [loose]), 'wet roots', const CustomIssue('x', 'X')), isNull);
      expect(CustomIssueService.rename(feedback(1, issues: [wetRoots]), 'wet roots', wetRoots), isNull);
    });

    test('other answers are kept', () {
      final f = feedback(
        1,
        issues: [wetRoots],
        comparisons: {
          const FeedbackComparison(referenceSetupId: 's0', aspect: OverallAspect(), outcome: 2),
          const FeedbackComparison(referenceSetupId: 's0', aspect: UnknownAspect('future'), outcome: 1),
        },
      );

      final renamed = CustomIssueService.rename(f, 'wet roots', loose)!;

      expect(renamed.comparisons, containsAll(f.comparisons));
    });
  });

  group('CustomIssueService.remove', () {
    test('strips the flag and its comparisons only', () {
      final f = feedback(
        1,
        issues: [wetRoots, loose],
        comparisons: {
          comparison(wetRoots, 1),
          comparison(loose, 1),
          const FeedbackComparison(referenceSetupId: 's0', aspect: OverallAspect(), outcome: 1),
        },
      );

      final removed = CustomIssueService.remove(f, 'wet roots')!;

      expect(removed.customIssues, [loose]);
      expect(removed.issues, {frontGrip});
      expect(removed.comparisons.map((c) => c.aspect), unorderedEquals([loose.aspect, const OverallAspect()]));
    });

    test('is null when the feedback does not use the issue', () {
      expect(CustomIssueService.remove(feedback(1, issues: [loose]), 'wet roots'), isNull);
    });
  });

  group('session goals', () {
    TestSession session(List<FeedbackAspect> goal) => TestSession(
      bike: 'bike',
      adjustmentIds: const ['a'],
      goal: goal,
      startedAtUTC: DateTime.utc(2026, 6, 1),
      startedAtLocal: DateTime(2026, 6, 1),
    );
    const frontCalm = EndAspect(FeedbackEnd.front, FeedbackAttribute.calm);

    test('rename rewrites the goal and does not double an existing one', () {
      expect(CustomIssueService.renameGoal(session([frontCalm, wetRoots.aspect]), 'wet roots', loose)!.goal, [
        frontCalm,
        loose.aspect,
      ]);
      expect(CustomIssueService.renameGoal(session([wetRoots.aspect, loose.aspect]), 'wet roots', loose)!.goal, [
        loose.aspect,
      ]);
    });

    test('remove drops the goal', () {
      expect(CustomIssueService.removeGoal(session([wetRoots.aspect, frontCalm]), 'wet roots')!.goal, [frontCalm]);
    });

    test('sessions without the goal are left alone', () {
      expect(CustomIssueService.renameGoal(session([frontCalm]), 'wet roots', loose), isNull);
      expect(CustomIssueService.removeGoal(session([frontCalm]), 'wet roots'), isNull);
    });
  });
}
