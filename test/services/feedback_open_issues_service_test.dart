import 'package:bike_setup_tracker/models/feedback/custom_issue.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_observation.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/services/feedback_open_issues_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const frontHarsh = IssueKey(FeedbackEnd.front, FeedbackAttribute.comfort);
  const frontGrip = IssueKey(FeedbackEnd.front, FeedbackAttribute.grip);
  const rearCalm = IssueKey(FeedbackEnd.rear, FeedbackAttribute.calm);

  const wetRoots = CustomIssue('wet roots', 'Wet roots');

  List<FeedbackAspect>? aspects(OpenIssues? openIssues) => openIssues?.issues.map((i) => i.aspect).toList();

  RideFeedback feedback(int day, Set<FeedbackKey> flags, {String? notes, List<CustomIssue> custom = const []}) {
    final at = DateTime.utc(2026, 6, day);
    return RideFeedback(
      bike: 'bike',
      setupId: 'setup',
      dateTimeUTC: at,
      dateTimeLocal: at,
      notes: notes,
      observations: {
        for (final key in flags) FeedbackObservation.flag(key),
        for (final issue in custom) issue.toObservation(),
      },
    );
  }

  group('FeedbackOpenIssuesService.openIssues', () {
    test('the latest feedback wins', () {
      final older = feedback(1, {frontHarsh});
      final newer = feedback(5, {rearCalm});

      final result = FeedbackOpenIssuesService.openIssues([older, newer]);

      expect(aspects(result), [rearCalm.aspect]);
      expect(result?.feedbackId, newer.id);
      expect(result?.isDialledIn, false);
    });

    test('a later feedback without flags does not clear the issues', () {
      final flagged = feedback(1, {frontHarsh});
      final unanswered = feedback(5, {}, notes: 'Rode it again');

      final result = FeedbackOpenIssuesService.openIssues([unanswered, flagged]);

      expect(aspects(result), [frontHarsh.aspect]);
      expect(result?.feedbackId, flagged.id);
    });

    test('"Nothing stood out" means dialled in', () {
      final result = FeedbackOpenIssuesService.openIssues([
        feedback(1, {frontHarsh}),
        feedback(5, {const NoIssueKey()}),
      ]);

      expect(result?.isDialledIn, true);
      expect(result?.issues, isEmpty);
    });

    test('no answers give no state', () {
      expect(FeedbackOpenIssuesService.openIssues([]), isNull);
      expect(FeedbackOpenIssuesService.openIssues([feedback(1, {}), feedback(2, {})]), isNull);
    });

    test('issues are ordered front before rear, in vocabulary order', () {
      final result = FeedbackOpenIssuesService.openIssues([
        feedback(1, {rearCalm, frontHarsh, frontGrip}),
      ]);

      expect(aspects(result), [frontGrip.aspect, frontHarsh.aspect, rearCalm.aspect]);
    });

    test('custom issues follow the built-in ones, by label', () {
      final result = FeedbackOpenIssuesService.openIssues([
        feedback(1, {rearCalm}, custom: [const CustomIssue('b', 'Bumpy'), wetRoots, const CustomIssue('a', 'apex')]),
      ]);

      expect(aspects(result), [rearCalm.aspect, const CustomAspect('a'), const CustomAspect('b'), wetRoots.aspect]);
      expect(result?.issues.map((i) => i.label), ['Rear: Unsettled', 'apex', 'Bumpy', 'Wet roots']);
    });

    test('a feedback with only a custom issue answers the question', () {
      final result = FeedbackOpenIssuesService.openIssues([
        feedback(1, {frontHarsh}),
        feedback(5, {}, custom: [wetRoots]),
      ]);

      expect(aspects(result), [wetRoots.aspect]);
      expect(result?.isDialledIn, false);
    });

    test('a deleted feedback is skipped', () {
      final result = FeedbackOpenIssuesService.openIssues([
        feedback(1, {frontHarsh}),
        feedback(5, {const NoIssueKey()}).copyWith(isDeleted: true),
      ]);

      expect(aspects(result), [frontHarsh.aspect]);
    });
  });
}
