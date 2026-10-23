import 'package:bike_setup_tracker/models/context/context_position.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_comparison.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_observation.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const frontHarsh = IssueKey(FeedbackEnd.front, FeedbackAttribute.comfort);
  const rearUnsettled = IssueKey(FeedbackEnd.rear, FeedbackAttribute.calm);

  RideFeedback build({
    Set<FeedbackObservation>? observations,
    Set<FeedbackComparison>? comparisons,
  }) => RideFeedback(
    id: 'f1',
    lastModified: DateTime.utc(2026, 10, 1),
    bike: 'bike1',
    setupId: 's2',
    stravaActivityId: 12345678901,
    dateTimeUTC: DateTime.utc(2026, 10, 1, 10),
    dateTimeLocal: DateTime(2026, 10, 1, 12),
    notes: 'Wet roots',
    position: const ContextPosition(latitude: 47.1, longitude: 8.2),
    observations:
        observations ??
        {
          const FeedbackObservation.flag(frontHarsh),
          const FeedbackObservation(key: UnknownFeedbackKey('future:m1'), value: 102.5, textValue: '102500000'),
        },
    comparisons:
        comparisons ??
        {
          const FeedbackComparison(referenceSetupId: 's1', aspect: OverallAspect(), outcome: 1),
          const FeedbackComparison(
            referenceSetupId: 's1',
            aspect: EndAspect(FeedbackEnd.front, FeedbackAttribute.comfort),
            outcome: -1,
          ),
        },
  );

  group('RideFeedback JSON', () {
    test('roundtrips all fields', () {
      final feedback = build();
      final json = feedback.toJson();
      expect(json['version'], 1);
      final restored = RideFeedback.fromJson(json);
      expect(restored, feedback);
      expect(restored.hashCode, feedback.hashCode);
      expect(restored.stravaActivityId, 12345678901);
      expect(restored.dateTimeLocal.isUtc, isFalse);
    });

    test('stores keys and aspects as strings', () {
      final json = build().toJson();
      expect(
        (json['observations'] as List).map((o) => (o as Map)['key']),
        containsAll(['issue.front.comfort', 'future:m1']),
      );
      expect((json['comparisons'] as List).map((c) => (c as Map)['aspect']), containsAll(['overall', 'front.comfort']));
    });

    test('keeps unknown keys and aspects through a roundtrip', () {
      final json = build().toJson();
      (json['observations'] as List).add({'key': 'segment:9.elapsed', 'value': 61.2, 'textValue': null});
      (json['comparisons'] as List).add({'referenceSetupId': 's1', 'aspect': 'front.speed', 'outcome': 1});
      final restored = RideFeedback.fromJson(json);
      expect(restored.observations.map((o) => o.key), contains(const UnknownFeedbackKey('segment:9.elapsed')));
      expect(restored.comparisons.map((c) => c.aspect), contains(const UnknownAspect('front.speed')));
      expect(RideFeedback.fromJson(restored.toJson()), restored);
    });

    test('reads a minimal JSON without children or context', () {
      final feedback = RideFeedback.fromJson(const {
        'bike': 'bike1',
        'setupId': 's1',
        'dateTimeUTC': '2026-10-01T10:00:00Z',
        'dateTimeLocal': '2026-10-01T12:00:00.000',
      });
      expect(feedback.observations, isEmpty);
      expect(feedback.comparisons, isEmpty);
      expect(feedback.stravaActivityId, isNull);
    });

    test('requires the local time', () {
      expect(() => RideFeedback.fromJson(build().toJson()..remove('dateTimeLocal')), throwsA(isA<TypeError>()));
    });

    test('rejects an unknown version', () {
      expect(() => RideFeedback.fromJson({...build().toJson(), 'version': 2}), throwsException);
    });
  });

  group('RideFeedback equality', () {
    test('ignores the order of observations and comparisons', () {
      final a = build(
        observations: {
          const FeedbackObservation.flag(frontHarsh),
          const FeedbackObservation.flag(rearUnsettled),
        },
      );
      final b = build(
        observations: {
          const FeedbackObservation.flag(rearUnsettled),
          const FeedbackObservation.flag(frontHarsh),
        },
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different outcome makes it unequal', () {
      final other = build(
        comparisons: {
          const FeedbackComparison(referenceSetupId: 's1', aspect: OverallAspect(), outcome: 2),
        },
      );
      expect(other == build(), isFalse);
    });
  });

  group('RideFeedback copyWith', () {
    test('clears nullable fields with an explicit null', () {
      final cleared = build().copyWith(stravaActivityId: null, notes: null, position: null);
      expect(cleared.stravaActivityId, isNull);
      expect(cleared.notes, isNull);
      expect(cleared.position, isNull);
      expect(cleared.setupId, 's2');
    });

    test('keeps everything when nothing is passed', () {
      expect(build().copyWith(), build());
    });
  });

  test('deepCopy gets a new id and date, keeps the answers, drops context and Strava link', () {
    final original = build();
    final copy = original.deepCopy();
    expect(copy.id, isNot(original.id));
    expect(copy.dateTimeUTC.isAfter(original.dateTimeUTC), isTrue);
    expect(copy.position, isNull);
    expect(copy.stravaActivityId, isNull);
    expect(copy.observations, original.observations);
    expect(copy.comparisons, original.comparisons);
  });

  group('derived answers', () {
    test('issues lists the flagged problems only', () {
      expect(build().issues, {frontHarsh});
      expect(build().nothingStoodOut, isFalse);
    });

    test('"Nothing stood out" is its own state', () {
      final feedback = build(observations: {const FeedbackObservation.flag(NoIssueKey())});
      expect(feedback.issues, isEmpty);
      expect(feedback.nothingStoodOut, isTrue);
    });

    test('no answers: no issues and not dialled in', () {
      final feedback = build(observations: const {});
      expect(feedback.issues, isEmpty);
      expect(feedback.nothingStoodOut, isFalse);
    });
  });

  group('FeedbackComparison', () {
    test('validates the outcome against the aspect range', () {
      expect(const FeedbackComparison(referenceSetupId: 's', aspect: OverallAspect(), outcome: -2).isValid, isTrue);
      expect(const FeedbackComparison(referenceSetupId: 's', aspect: OverallAspect(), outcome: 3).isValid, isFalse);
      const aspect = EndAspect(FeedbackEnd.rear, FeedbackAttribute.grip);
      expect(const FeedbackComparison(referenceSetupId: 's', aspect: aspect, outcome: 1).isValid, isTrue);
      expect(const FeedbackComparison(referenceSetupId: 's', aspect: aspect, outcome: 2).isValid, isFalse);
    });

    test('roundtrips through JSON', () {
      const comparison = FeedbackComparison(referenceSetupId: 's1', aspect: OverallAspect(), outcome: -1);
      expect(FeedbackComparison.fromJson(comparison.toJson()), comparison);
    });
  });

  test('FeedbackObservation copyWith clears values', () {
    const observation = FeedbackObservation(key: UnknownFeedbackKey('future:m1'), value: 1, textValue: 'x');
    expect(observation.copyWith(value: null, textValue: null), const FeedbackObservation(key: UnknownFeedbackKey('future:m1')));
    expect(FeedbackObservation.fromJson(observation.toJson()), observation);
  });
}
