import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedbackKey', () {
    test('builds the stored strings', () {
      expect(const IssueKey(FeedbackEnd.front, FeedbackAttribute.calm).raw, 'issue.front.calm');
      expect(const IssueKey(FeedbackEnd.rear, FeedbackAttribute.bottoming).raw, 'issue.rear.bottoming');
      expect(const NoIssueKey().raw, 'issue.none');
    });

    test('parses every built key back to an equal key', () {
      final keys = <FeedbackKey>[
        for (final aspect in EndAspect.values) aspect.issueKey,
        const NoIssueKey(),
      ];
      for (final key in keys) {
        final parsed = FeedbackKey.parse(key.raw);
        expect(parsed, key);
        expect(parsed.runtimeType, key.runtimeType);
      }
    });

    test('parses an issue key into end and attribute', () {
      final key = FeedbackKey.parse('issue.rear.grip');
      expect(
        key,
        isA<IssueKey>()
            .having((k) => k.end, 'end', FeedbackEnd.rear)
            .having((k) => k.attribute, 'attribute', FeedbackAttribute.grip),
      );
      expect((key as IssueKey).aspect, const EndAspect(FeedbackEnd.rear, FeedbackAttribute.grip));
    });

    test('keeps unknown keys verbatim', () {
      for (final raw in [
        'issue.middle.calm',
        'issue.front.speed',
        'issue.front',
        'issue.front.calm.extra',
        'custom:m1',
        'segment:123.elapsed',
        '',
      ]) {
        final key = FeedbackKey.parse(raw);
        expect(key, isA<UnknownFeedbackKey>(), reason: raw);
        expect(key.raw, raw);
      }
    });

    test('equality and hash follow the stored string', () {
      expect(
        FeedbackKey.parse('issue.front.grip').hashCode,
        const IssueKey(FeedbackEnd.front, FeedbackAttribute.grip).hashCode,
      );
      expect(const UnknownFeedbackKey('a') == const UnknownFeedbackKey('b'), isFalse);
      expect(const UnknownFeedbackKey('x'), const UnknownFeedbackKey('x'));
    });
  });

  group('FeedbackAspect', () {
    test('builds and parses overall and end aspects', () {
      expect(const OverallAspect().raw, 'overall');
      expect(const EndAspect(FeedbackEnd.front, FeedbackAttribute.calm).raw, 'front.calm');
      expect(FeedbackAspect.parse('overall'), const OverallAspect());
      expect(FeedbackAspect.parse('rear.comfort'), const EndAspect(FeedbackEnd.rear, FeedbackAttribute.comfort));
    });

    test('keeps unknown aspects verbatim', () {
      for (final raw in ['front', 'front.speed', 'middle.calm', 'front.calm.x', 'Overall']) {
        final aspect = FeedbackAspect.parse(raw);
        expect(aspect, isA<UnknownAspect>(), reason: raw);
        expect(aspect.raw, raw);
      }
    });

    test('lists all ten end aspects, front first, in attribute order', () {
      expect(EndAspect.values.map((a) => a.raw), [
        'front.grip',
        'front.comfort',
        'front.support',
        'front.calm',
        'front.bottoming',
        'rear.grip',
        'rear.comfort',
        'rear.support',
        'rear.calm',
        'rear.bottoming',
      ]);
    });

    test('issue key and aspect map onto each other', () {
      for (final aspect in EndAspect.values) {
        expect(aspect.issueKey.aspect, aspect);
      }
    });

    test('outcome range: overall -2..2, end aspects -1..1, unknown unchecked', () {
      const overall = OverallAspect();
      expect([-3, -2, 0, 2, 3].map(overall.isValidOutcome), [false, true, true, true, false]);

      const aspect = EndAspect(FeedbackEnd.front, FeedbackAttribute.comfort);
      expect([-2, -1, 0, 1, 2].map(aspect.isValidOutcome), [false, true, true, true, false]);

      const unknown = UnknownAspect('front.speed');
      expect(unknown.outcomeRange, isNull);
      expect(unknown.isValidOutcome(5), isTrue);
    });
  });

  group('FeedbackVocabulary', () {
    test('has five attributes on two ends', () {
      expect(FeedbackEnd.values.map((e) => e.name), ['front', 'rear']);
      expect(FeedbackAttribute.values.map((a) => a.name), ['grip', 'comfort', 'support', 'calm', 'bottoming']);
      expect(FeedbackAttribute.calm.problemLabel, 'Unsettled');
    });

    test('outcome labels cover each aspect range', () {
      expect(FeedbackVocabulary.overallOutcomeLabels.keys, [-2, -1, 0, 1, 2]);
      expect(FeedbackVocabulary.aspectOutcomeLabels.keys, [-1, 0, 1]);
    });
  });
}
