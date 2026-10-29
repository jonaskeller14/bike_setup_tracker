import 'package:bike_setup_tracker/models/feedback/test_session_method.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TestSessionMethod JSON', () {
    test('roundtrips every method', () {
      const methods = <TestSessionMethod>[
        PatternSearch(),
        OrthogonalArray(),
        Tournament(candidateSetupIds: ['s1', 's2']),
      ];
      for (final method in methods) {
        expect(TestSessionMethod.fromJson(method.toJson()), method);
      }
    });

    test('stores the type as a stable string', () {
      expect(const PatternSearch().toJson(), {'type': 'patternSearch'});
      expect(const OrthogonalArray().toJson(), {'type': 'orthogonalArray'});
    });

    test('rejects an unknown type', () {
      expect(() => TestSessionMethod.fromJson(const {'type': 'bayesian'}), throwsException);
    });
  });

  group('TestSessionMethod equality', () {
    test('methods without settings are equal by type', () {
      expect(const PatternSearch(), const PatternSearch());
      expect(const PatternSearch() == const OrthogonalArray(), isFalse);
    });

    test('tournaments compare candidates in order', () {
      const a = Tournament(candidateSetupIds: ['s1', 's2']);
      expect(a, const Tournament(candidateSetupIds: ['s1', 's2']));
      expect(a.hashCode, const Tournament(candidateSetupIds: ['s1', 's2']).hashCode);
      expect(a == const Tournament(candidateSetupIds: ['s2', 's1']), isFalse);
    });
  });
}
