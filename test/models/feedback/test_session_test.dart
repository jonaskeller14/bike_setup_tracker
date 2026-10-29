import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/feedback/test_session_method.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const adjustmentTypes = {
    'lsr': AdjustmentType.step,
    'pressure': AdjustmentType.numerical,
    'lockout': AdjustmentType.boolean,
  };

  TestSession build() => TestSession(
    id: 'session1',
    lastModified: DateTime.utc(2026, 10, 1),
    bike: 'bike1',
    name: 'Fork rebound',
    method: const PatternSearch(),
    adjustmentIds: const ['lsr', 'pressure'],
    goal: const [
      EndAspect(FeedbackEnd.front, FeedbackAttribute.calm),
      EndAspect(FeedbackEnd.front, FeedbackAttribute.grip),
    ],
    locks: const {'lsr': StepValue(8)},
    startedAtUTC: DateTime.utc(2026, 10, 1, 9),
    startedAtLocal: DateTime(2026, 10, 1, 11),
    endedAtUTC: DateTime.utc(2026, 10, 1, 12),
    endedAtLocal: DateTime(2026, 10, 1, 14),
    notes: 'Dry',
    proposals: const {
      'run2': {'lsr': StepValue(10)},
      'run3': {'lsr': StepValue(8), 'pressure': NumericalValue(72.5)},
    },
  );

  group('TestSession JSON', () {
    test('roundtrips all fields', () {
      final session = build();
      final json = session.toJson();
      expect(json['version'], 1);
      expect(json['goal'], ['front.calm', 'front.grip']);
      final restored = TestSession.fromJson(json: json, adjustmentTypes: adjustmentTypes);
      expect(restored, session);
      expect(restored.hashCode, session.hashCode);
    });

    test('defaults when optional fields are missing', () {
      final session = TestSession.fromJson(
        json: const {
          'bike': 'bike1',
          'adjustmentIds': ['lsr'],
          'startedAtUTC': '2026-10-01T09:00:00Z',
          'startedAtLocal': '2026-10-01T11:00:00.000',
        },
        adjustmentTypes: adjustmentTypes,
      );
      expect(session.method, isNull);
      expect(session.endedAtUTC, isNull);
      expect(session.endedAtLocal, isNull);
      expect(session.goal, isEmpty);
      expect(session.locks, isEmpty);
      expect(session.proposals, isEmpty);
      expect(session.isRunning, isTrue);
      expect(session.displayName, TestSession.namePlaceholder);
    });

    test('stores a free session without a method', () {
      final free = build().copyWith(method: null);
      final json = free.toJson();
      expect(json['method'], isNull);
      expect(TestSession.fromJson(json: json, adjustmentTypes: adjustmentTypes), free);
    });

    test('roundtrips a tournament with its candidates', () {
      final session = build().copyWith(method: const Tournament(candidateSetupIds: ['s1', 's2', 's3']));
      final json = session.toJson();
      expect(json['method'], {
        'type': 'tournament',
        'candidateSetupIds': ['s1', 's2', 's3'],
      });
      expect(TestSession.fromJson(json: json, adjustmentTypes: adjustmentTypes), session);
    });

    test('keeps the local wall-clock time independent of the UTC time', () {
      final json = build().toJson();
      expect(json['startedAtUTC'], '2026-10-01T09:00:00.000Z');
      expect(json['startedAtLocal'], '2026-10-01T11:00:00.000');
      final restored = TestSession.fromJson(json: json, adjustmentTypes: adjustmentTypes);
      expect(restored.startedAtLocal.isUtc, isFalse);
      expect(restored.endedAtLocal, DateTime(2026, 10, 1, 14));
    });

    test('requires the local start time', () {
      expect(
        () => TestSession.fromJson(json: build().toJson()..remove('startedAtLocal'), adjustmentTypes: adjustmentTypes),
        throwsA(isA<TypeError>()),
      );
    });

    test('keeps values of adjustments that are not in the backup', () {
      final restored = TestSession.fromJson(json: build().toJson(), adjustmentTypes: const {});
      expect(restored.locks['lsr'], isA<UnresolvedValue>());
      expect(TestSession.fromJson(json: restored.toJson(), adjustmentTypes: adjustmentTypes), build());
    });

    test('keeps unknown goal aspects', () {
      final json = build().toJson()..['goal'] = ['front.calm', 'front.speed'];
      final restored = TestSession.fromJson(json: json, adjustmentTypes: adjustmentTypes);
      expect(restored.goal, [
        const EndAspect(FeedbackEnd.front, FeedbackAttribute.calm),
        const UnknownAspect('front.speed'),
      ]);
    });

    test('rejects an unknown method or version', () {
      expect(
        () => TestSession.fromJson(
          json: build().toJson()..['method'] = {'type': 'bayesian'},
          adjustmentTypes: adjustmentTypes,
        ),
        throwsException,
      );
      expect(
        () => TestSession.fromJson(json: build().toJson()..['version'] = 2, adjustmentTypes: adjustmentTypes),
        throwsException,
      );
    });
  });

  group('TestSession equality', () {
    test('knob order matters', () {
      expect(build().copyWith(adjustmentIds: ['pressure', 'lsr']) == build(), isFalse);
    });

    test('compares proposals by value', () {
      final other = build().copyWith(
        proposals: {
          'run2': {'lsr': const StepValue(10)},
          'run3': {'lsr': const StepValue(9), 'pressure': const NumericalValue(72.5)},
        },
      );
      expect(other == build(), isFalse);
      expect(other.copyWith(proposals: build().proposals), build());
    });
  });

  group('TestSession copyWith', () {
    test('reopens a session by clearing both end times', () {
      final reopened = build().copyWith(endedAtUTC: null, endedAtLocal: null);
      expect(reopened.isRunning, isTrue);
      expect(reopened.startedAtUTC, build().startedAtUTC);
      expect(reopened.startedAtLocal, build().startedAtLocal);
    });

    test('rejects an end time without its local counterpart', () {
      expect(() => build().copyWith(endedAtLocal: null), throwsAssertionError);
    });

    test('clears nullable fields with an explicit null', () {
      final cleared = build().copyWith(name: null, notes: null);
      expect(cleared.name, isNull);
      expect(cleared.notes, isNull);
      expect(cleared.goal, build().goal);
    });
  });
}
