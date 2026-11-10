import 'package:bike_setup_tracker/models/feedback/custom_issue.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_observation.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/services/custom_issue_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const wetRoots = CustomIssue('wet roots', 'Wet roots');
  const loose = CustomIssue('loose', 'Loose');
  const frontGrip = IssueKey(FeedbackEnd.front, FeedbackAttribute.grip);

  RideFeedback feedback(
    int day, {
    List<CustomIssue> issues = const [],
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
    );
  }

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
}
