import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/utils/installation_timeline_validation.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _utc(int day) => DateTime.utc(2026, 1, day);

BikeInstallation installOn(String bikeId, int day) => BikeInstallation(
      bikeId: bikeId,
      dateTimeUTC: _utc(day),
      dateTimeLocal: _utc(day).toLocal(),
    );

Uninstallation uninstall(int day) => Uninstallation(
      dateTimeUTC: _utc(day),
      dateTimeLocal: _utc(day).toLocal(),
    );

Archival archive(int day) => Archival(
      dateTimeUTC: _utc(day),
      dateTimeLocal: _utc(day).toLocal(),
    );

void main() {
  group('validateInstallationTimeline', () {
    test('rejects an empty timeline', () {
      expect(validateInstallationTimeline([]), 'At least one entry is required');
    });

    test('accepts a single entry', () {
      expect(validateInstallationTimeline([installOn('b1', 1)]), isNull);
      expect(validateInstallationTimeline([uninstall(1)]), isNull);
      expect(validateInstallationTimeline([archive(1)]), isNull);
    });

    test('accepts archival as the last entry', () {
      expect(
        validateInstallationTimeline([installOn('b1', 1), archive(2)]),
        isNull,
      );
    });

    test('rejects archival before another entry', () {
      expect(
        validateInstallationTimeline([archive(1), installOn('b1', 2)]),
        'Archival can only be the last entry in the timeline',
      );
    });

    test('rejects consecutive uninstallations', () {
      expect(
        validateInstallationTimeline([installOn('b1', 1), uninstall(2), uninstall(3)]),
        'Cannot have consecutive uninstallations',
      );
    });

    test('rejects consecutive installations on the same bike', () {
      expect(
        validateInstallationTimeline([installOn('b1', 1), installOn('b1', 2)]),
        'Cannot have consecutive installations on the same bike',
      );
    });

    test('accepts consecutive installations on different bikes', () {
      expect(
        validateInstallationTimeline([installOn('b1', 1), installOn('b2', 2)]),
        isNull,
      );
    });

    test('rejects multiple from-beginning entries', () {
      expect(
        validateInstallationTimeline([
          Installation.sinceBeginning(parent: 'b1'),
          Installation.sinceBeginning(),
        ]),
        'Multiple "From beginning" entries are not allowed',
      );
    });

    test('accepts a single from-beginning entry', () {
      expect(
        validateInstallationTimeline([
          Installation.sinceBeginning(parent: 'b1'),
          uninstall(2),
        ]),
        isNull,
      );
    });

    test('accepts a valid mixed timeline', () {
      expect(
        validateInstallationTimeline([
          installOn('b1', 1),
          uninstall(2),
          installOn('b2', 3),
          uninstall(4),
          archive(5),
        ]),
        isNull,
      );
    });

    test('sorts before validating: unsorted valid timeline passes', () {
      expect(
        validateInstallationTimeline([
          archive(5),
          uninstall(2),
          installOn('b2', 3),
          installOn('b1', 1),
          uninstall(4),
        ]),
        isNull,
      );
    });

    test('sorts before validating: unsorted invalid timeline is rejected', () {
      // Chronologically this is install(b1) → install(b1) → uninstall.
      expect(
        validateInstallationTimeline([
          uninstall(3),
          installOn('b1', 2),
          installOn('b1', 1),
        ]),
        'Cannot have consecutive installations on the same bike',
      );
    });
  });

  group('isValidInstallationTimeline', () {
    test('mirrors validateInstallationTimeline', () {
      expect(isValidInstallationTimeline([installOn('b1', 1)]), isTrue);
      expect(isValidInstallationTimeline([]), isFalse);
      expect(isValidInstallationTimeline([archive(1), uninstall(2)]), isFalse);
    });
  });
}
