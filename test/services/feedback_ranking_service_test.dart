import 'package:bike_setup_tracker/models/feedback/feedback_comparison.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/services/feedback_ranking_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bikeA = 'bike-a';
  const bikeB = 'bike-b';

  Setup setup(String id, {String bike = bikeA, bool isDeleted = false}) {
    final at = DateTime.utc(2026, 1, 1);
    return Setup(
      id: id,
      isDeleted: isDeleted,
      name: id,
      tags: const {},
      datetime: at,
      datetimeLocal: at,
      bike: bike,
      person: null,
      bikeAdjustmentValues: const {},
      personAdjustmentValues: const {},
    );
  }

  FeedbackComparison overall(String referenceSetupId, int outcome) =>
      FeedbackComparison(referenceSetupId: referenceSetupId, aspect: const OverallAspect(), outcome: outcome);

  RideFeedback feedback(Set<FeedbackComparison> comparisons, {String bike = bikeA}) {
    final at = DateTime.utc(2026, 2, 1);
    return RideFeedback(
      bike: bike,
      setupId: 'provenance',
      dateTimeUTC: at,
      dateTimeLocal: at,
      comparisons: comparisons,
    );
  }

  Map<String, Setup> setupsOf(Iterable<Setup> setups) => {for (final s in setups) s.id: s};

  group('FeedbackRankingService.rank', () {
    test('ranks a chain A < B < C', () {
      final setups = setupsOf([setup('a'), setup('b'), setup('c')]);
      final ranks = FeedbackRankingService.rank(
        setups: setups,
        feedbacksBySetup: {
          'b': [
            feedback({overall('a', 2)}),
          ],
          'c': [
            feedback({overall('b', 2)}),
          ],
        },
      );

      expect(ranks['c']?.rank, 1);
      expect(ranks['b']?.rank, 2);
      expect(ranks['a']?.rank, 3);
      expect(ranks.values.map((r) => r.of).toSet(), {3});
      expect(ranks['c']!.strength, greaterThan(ranks['b']!.strength));
      expect(ranks['b']!.strength, greaterThan(ranks['a']!.strength));
      expect(ranks['b']?.comparisonCount, 2);
      expect(ranks['b']?.isConfident, true);
      expect(ranks['a']?.isConfident, false, reason: 'one comparison is not enough');
    });

    test('a cycle ranks every setup equally', () {
      final ranks = FeedbackRankingService.rank(
        setups: setupsOf([setup('a'), setup('b'), setup('c')]),
        feedbacksBySetup: {
          'a': [
            feedback({overall('b', 2)}),
          ],
          'b': [
            feedback({overall('c', 2)}),
          ],
          'c': [
            feedback({overall('a', 2)}),
          ],
        },
      );

      expect(ranks.values.map((r) => r.rank), everyElement(1));
      expect(ranks['a']!.strength, closeTo(ranks['b']!.strength, 1e-9));
    });

    test('"same" outcomes give a shared rank at neutral strength', () {
      final ranks = FeedbackRankingService.rank(
        setups: setupsOf([setup('a'), setup('b')]),
        feedbacksBySetup: {
          'b': [
            feedback({overall('a', 0)}),
          ],
        },
      );

      expect(ranks['a']?.rank, 1);
      expect(ranks['b']?.rank, 1);
      expect(ranks['a']!.strength, closeTo(1, 1e-9));
      expect(ranks['b']!.strength, closeTo(1, 1e-9));
    });

    test('"slightly better" separates less than "better"', () {
      final setups = setupsOf([setup('a'), setup('b')]);
      double gap(int outcome) {
        final ranks = FeedbackRankingService.rank(
          setups: setups,
          feedbacksBySetup: {
            'b': [
              feedback({overall('a', outcome)}),
            ],
          },
        );
        return ranks['b']!.strength / ranks['a']!.strength;
      }

      expect(gap(1), greaterThan(1));
      expect(gap(2), greaterThan(gap(1)));
      expect(gap(-2), lessThan(1));
    });

    test('aspect rows are ignored', () {
      final ranks = FeedbackRankingService.rank(
        setups: setupsOf([setup('a'), setup('b')]),
        feedbacksBySetup: {
          'b': [
            feedback({
              const FeedbackComparison(
                referenceSetupId: 'a',
                aspect: EndAspect(FeedbackEnd.front, FeedbackAttribute.comfort),
                outcome: 1,
              ),
            }),
          ],
        },
      );

      expect(ranks, isEmpty);
    });

    test('repeated comparisons of the same pair add evidence', () {
      final setups = setupsOf([setup('a'), setup('b')]);
      final once = FeedbackRankingService.rank(
        setups: setups,
        feedbacksBySetup: {
          'b': [
            feedback({overall('a', 1)}),
          ],
        },
      );
      final twice = FeedbackRankingService.rank(
        setups: setups,
        feedbacksBySetup: {
          'b': [
            feedback({overall('a', 1)}),
            feedback({overall('a', 1)}),
          ],
        },
      );

      expect(twice['b']!.strength, greaterThan(once['b']!.strength));
      expect(twice['b']?.comparisonCount, 2);
      expect(twice['b']?.isConfident, true);
      expect(once['b']?.isConfident, false);
    });

    test('a self-comparison is ignored', () {
      final ranks = FeedbackRankingService.rank(
        setups: setupsOf([setup('a')]),
        feedbacksBySetup: {
          'a': [
            feedback({overall('a', 2)}),
          ],
        },
      );

      expect(ranks, isEmpty);
    });

    test('a reference to a deleted or missing setup is ignored', () {
      final ranks = FeedbackRankingService.rank(
        setups: setupsOf([setup('a'), setup('b'), setup('gone', isDeleted: true)]),
        feedbacksBySetup: {
          'b': [
            feedback({overall('a', 2), overall('gone', -2), overall('purged', 2)}),
          ],
        },
      );

      expect(ranks.keys, unorderedEquals(['a', 'b']));
      expect(ranks['b']?.comparisonCount, 1);
      expect(ranks['b']?.of, 2);
    });

    test('feedbacks of a deleted setup and deleted feedbacks are ignored', () {
      final ranks = FeedbackRankingService.rank(
        setups: setupsOf([setup('a'), setup('b'), setup('gone', isDeleted: true)]),
        feedbacksBySetup: {
          'gone': [
            feedback({overall('a', 2)}),
          ],
          'b': [
            feedback({overall('a', 2)}).copyWith(isDeleted: true),
          ],
        },
      );

      expect(ranks, isEmpty);
    });

    test('an out-of-range outcome is ignored', () {
      final ranks = FeedbackRankingService.rank(
        setups: setupsOf([setup('a'), setup('b')]),
        feedbacksBySetup: {
          'b': [
            feedback({overall('a', 3)}),
          ],
        },
      );

      expect(ranks, isEmpty);
    });

    test('bikes are ranked separately and cross-bike references are ignored', () {
      final ranks = FeedbackRankingService.rank(
        setups: setupsOf([setup('a1'), setup('a2'), setup('b1', bike: bikeB), setup('b2', bike: bikeB)]),
        feedbacksBySetup: {
          'a2': [
            feedback({overall('a1', 2), overall('b1', 2)}),
          ],
          'b2': [
            feedback({overall('b1', -2)}, bike: bikeB),
          ],
        },
      );

      expect(ranks['a2']?.rank, 1);
      expect(ranks['a2']?.of, 2);
      expect(ranks['a2']?.comparisonCount, 1);
      expect(ranks['b1']?.rank, 1);
      expect(ranks['b1']?.of, 2);
    });

    test('a feedback re-resolving to another setup changes the edge', () {
      final setups = setupsOf([setup('a'), setup('b'), setup('inserted')]);
      final f = feedback({overall('a', 2)});

      final before = FeedbackRankingService.rank(
        setups: setups,
        feedbacksBySetup: {
          'b': [f],
        },
      );
      final after = FeedbackRankingService.rank(
        setups: setups,
        feedbacksBySetup: {
          'inserted': [f],
        },
      );

      expect(before['b']?.rank, 1);
      expect(before.containsKey('inserted'), false);
      expect(after['inserted']?.rank, 1);
      expect(after.containsKey('b'), false);
    });

    test('identical input in another order gives identical output', () {
      final setups = [setup('a'), setup('b'), setup('c'), setup('d')];
      final fb = feedback({overall('a', 1), overall('c', -1)});
      final fc = feedback({overall('a', 2)});
      final fd = feedback({overall('b', 0), overall('c', 1)});

      final forward = FeedbackRankingService.rank(
        setups: setupsOf(setups),
        feedbacksBySetup: {
          'b': [fb],
          'c': [fc],
          'd': [fd],
        },
      );
      final backward = FeedbackRankingService.rank(
        setups: setupsOf(setups.reversed),
        feedbacksBySetup: {
          'd': [fd.copyWith(comparisons: fd.comparisons.toList().reversed.toSet())],
          'c': [fc],
          'b': [fb.copyWith(comparisons: fb.comparisons.toList().reversed.toSet())],
        },
      );

      expect(backward, forward);
    });
  });
}
