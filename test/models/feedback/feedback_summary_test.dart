import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_comparison.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_observation.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_summary.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/utils/to_spreadsheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Setup _setup(String id, DateTime local, {String bike = 'b1', bool isDeleted = false}) => Setup(
  id: id,
  name: id.toUpperCase(),
  isDeleted: isDeleted,
  datetime: local.toUtc(),
  datetimeLocal: local,
  tags: const {},
  bike: bike,
  person: null,
  bikeAdjustmentValues: const {},
  personAdjustmentValues: const {},
);

RideFeedback _feedback({
  Set<FeedbackObservation> observations = const {},
  Set<FeedbackComparison> comparisons = const {},
  DateTime? local,
}) {
  final at = local ?? DateTime(2026, 5, 2, 12);
  return RideFeedback(
    bike: 'b1',
    setupId: 's2',
    dateTimeUTC: at.toUtc(),
    dateTimeLocal: at,
    observations: observations,
    comparisons: comparisons,
  );
}

FeedbackComparison _overall(String reference, int outcome) =>
    FeedbackComparison(referenceSetupId: reference, aspect: const OverallAspect(), outcome: outcome);

void main() {
  final setups = {
    's1': _setup('s1', DateTime(2026, 5, 1, 10)),
    's2': _setup('s2', DateTime(2026, 5, 2, 10)),
  };

  group('verdict', () {
    test('names the reference with the outcome', () {
      expect(_feedback(comparisons: {_overall('s1', 1)}).verdict(setups), 'Slightly better than S1');
      expect(_feedback(comparisons: {_overall('s1', 0)}).verdict(setups), 'Same as S1');
    });

    test('falls back for a reference that is gone', () {
      expect(_feedback(comparisons: {_overall('gone', -2)}).verdict(setups), 'Worse than a deleted setup');
    });

    test('ignores aspect rows and out-of-range outcomes', () {
      final feedback = _feedback(
        comparisons: {
          _overall('s1', 5),
          const FeedbackComparison(
            referenceSetupId: 's1',
            aspect: EndAspect(FeedbackEnd.front, FeedbackAttribute.calm),
            outcome: 1,
          ),
        },
      );
      expect(feedback.verdict(setups), isNull);
    });
  });

  group('verdicts', () {
    test('lists every overall comparison, the most recent reference first', () {
      final feedback = _feedback(comparisons: {_overall('s1', 2), _overall('gone', 0), _overall('s2', -1)});
      expect(feedback.verdicts(setups), ['Slightly worse than S2', 'Better than S1', 'Same as a deleted setup']);
    });

    test('ignores aspect rows and out-of-range outcomes', () {
      final feedback = _feedback(
        comparisons: {
          _overall('s1', 5),
          const FeedbackComparison(
            referenceSetupId: 's2',
            aspect: EndAspect(FeedbackEnd.front, FeedbackAttribute.calm),
            outcome: 1,
          ),
        },
      );
      expect(feedback.verdicts(setups), isEmpty);
    });
  });

  group('issuesSummary', () {
    test('orders front before rear, in vocabulary order', () {
      final feedback = _feedback(
        observations: {
          const FeedbackObservation.flag(IssueKey(FeedbackEnd.rear, FeedbackAttribute.grip)),
          const FeedbackObservation.flag(IssueKey(FeedbackEnd.front, FeedbackAttribute.bottoming)),
          const FeedbackObservation.flag(IssueKey(FeedbackEnd.front, FeedbackAttribute.comfort)),
        },
      );
      expect(feedback.issuesSummary, 'Front: Harsh · Front: Bottoms out · Rear: Low grip');
    });

    test('is "Dialled in" for nothing stood out, and null without answers', () {
      expect(_feedback(observations: {const FeedbackObservation.flag(NoIssueKey())}).issuesSummary, 'Dialled in');
      expect(_feedback().issuesSummary, isNull);
    });
  });

  group('ratedSetupIn', () {
    test('is the latest setup of the bike at the feedback time', () {
      expect(_feedback().ratedSetupIn(setups)?.id, 's2');
      expect(_feedback(local: DateTime(2026, 5, 1, 12)).ratedSetupIn(setups)?.id, 's1');
    });

    test('skips other bikes and deleted setups, and is null before the first setup', () {
      final mixed = {
        ...setups,
        's3': _setup('s3', DateTime(2026, 5, 2, 11), bike: 'b2'),
        's4': _setup('s4', DateTime(2026, 5, 2, 11), isDeleted: true),
      };
      expect(_feedback().ratedSetupIn(mixed)?.id, 's2');
      expect(_feedback(local: DateTime(2026, 4, 1)).ratedSetupIn(mixed), isNull);
    });
  });

  test('the CSV export lists feedback while Feedback is on', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    addTearDown(settings.dispose);
    final feedback = _feedback(
      comparisons: {_overall('s1', 2)},
      observations: {const FeedbackObservation.flag(IssueKey(FeedbackEnd.rear, FeedbackAttribute.calm))},
    );
    final data = SelectedData(
      bikes: {'b1': Bike(id: 'b1', name: 'Hightower', person: null)},
      setups: setups,
      feedbacks: {feedback.id: feedback},
    );

    expect(SpreadsheetExport.toCsv(data, settings), isNot(contains('"Feedback"')));

    settings.enableRating = true;
    final csv = SpreadsheetExport.toCsv(data, settings);
    expect(csv, contains('"Feedback"'));
    expect(csv, contains('"Hightower","S2","S1","Better","Rear: Unsettled",""'));
  });
}
