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

  RideFeedback feedback(int day, Set<FeedbackKey> flags, {String? notes}) {
    final at = DateTime.utc(2026, 6, day);
    return RideFeedback(
      bike: 'bike',
      setupId: 'setup',
      dateTimeUTC: at,
      dateTimeLocal: at,
      notes: notes,
      observations: {for (final key in flags) FeedbackObservation.flag(key)},
    );
  }

  group('FeedbackOpenIssuesService.openIssues', () {
    test('the latest feedback wins', () {
      final older = feedback(1, {frontHarsh});
      final newer = feedback(5, {rearCalm});

      final result = FeedbackOpenIssuesService.openIssues([older, newer]);

      expect(result?.issues, [rearCalm]);
      expect(result?.feedbackId, newer.id);
      expect(result?.isDialledIn, false);
    });

    test('a later feedback without flags does not clear the issues', () {
      final flagged = feedback(1, {frontHarsh});
      final unanswered = feedback(5, {}, notes: 'Rode it again');

      final result = FeedbackOpenIssuesService.openIssues([unanswered, flagged]);

      expect(result?.issues, [frontHarsh]);
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

      expect(result?.issues, [frontGrip, frontHarsh, rearCalm]);
    });

    test('a deleted feedback is skipped', () {
      final result = FeedbackOpenIssuesService.openIssues([
        feedback(1, {frontHarsh}),
        feedback(5, {const NoIssueKey()}).copyWith(isDeleted: true),
      ]);

      expect(result?.issues, [frontHarsh]);
    });
  });
}
