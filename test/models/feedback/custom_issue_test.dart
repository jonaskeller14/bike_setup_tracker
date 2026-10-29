import 'package:bike_setup_tracker/models/feedback/custom_issue.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_observation.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_summary.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomIssue.fromLabel', () {
    test('slug is trimmed, whitespace collapsed and lowercase; the label stays as typed', () {
      final issue = CustomIssue.fromLabel('  Wet   ROOTS ')!;
      expect(issue.slug, 'wet roots');
      expect(issue.label, 'Wet   ROOTS');
    });

    test('blank labels give no issue', () {
      expect(CustomIssue.fromLabel(''), isNull);
      expect(CustomIssue.fromLabel(' \n\t '), isNull);
    });

    test('the slug is cut at 40 characters without a trailing space', () {
      final slug = CustomIssue.slugOf('${'a' * 39} bbbb');
      expect(slug, 'a' * 39);
      expect(CustomIssue.slugOf('x' * 60), 'x' * 40);
    });

    test('labels that differ in case or spacing share a slug', () {
      expect(CustomIssue.fromLabel('Wet roots')!.slug, CustomIssue.fromLabel('wet   roots ')!.slug);
    });

    test('key and aspect carry the slug', () {
      const issue = CustomIssue('wet roots', 'Wet roots');
      expect(issue.key.raw, 'issue.custom:wet roots');
      expect(issue.aspect.raw, 'custom:wet roots');
      expect(
        issue.toObservation(),
        const FeedbackObservation(key: CustomIssueKey('wet roots'), value: 1, textValue: 'Wet roots'),
      );
    });
  });

  group('RideFeedback custom issues', () {
    RideFeedback feedback(Set<FeedbackObservation> observations) => RideFeedback(
      bike: 'bike',
      setupId: 'setup',
      dateTimeUTC: DateTime.utc(2026, 6, 1),
      dateTimeLocal: DateTime(2026, 6, 1),
      observations: observations,
    );

    test('are read from the observations, ordered by label ignoring case', () {
      final f = feedback({
        const CustomIssue('wet roots', 'Wet roots').toObservation(),
        const CustomIssue('apex', 'apex').toObservation(),
        const FeedbackObservation.flag(IssueKey(FeedbackEnd.front, FeedbackAttribute.grip)),
      });
      expect(f.customIssues.map((i) => i.label), ['apex', 'Wet roots']);
      expect(f.issues, {const IssueKey(FeedbackEnd.front, FeedbackAttribute.grip)});
    });

    test('a flag without a label falls back to its slug', () {
      final f = feedback({const FeedbackObservation.flag(CustomIssueKey('wet roots'))});
      expect(f.customIssues, [const CustomIssue('wet roots', 'wet roots')]);
    });

    test('summary lists built-in issues first, then custom ones', () {
      final f = feedback({
        const CustomIssue('wet roots', 'Wet roots').toObservation(),
        const FeedbackObservation.flag(IssueKey(FeedbackEnd.rear, FeedbackAttribute.grip)),
        const FeedbackObservation.flag(IssueKey(FeedbackEnd.front, FeedbackAttribute.comfort)),
      });
      expect(f.issuesSummary, 'Front: Harsh · Rear: Low grip · Wet roots');
      expect(f.orderedIssues.last.hint, isNull);
      expect(f.orderedIssues.first.hint, FeedbackAttribute.comfort.hint);
    });

    test('survive a JSON round trip', () {
      final f = feedback({const CustomIssue('wet roots', 'Wet roots').toObservation()});
      expect(RideFeedback.fromJson(f.toJson()).customIssues, f.customIssues);
    });
  });
}
