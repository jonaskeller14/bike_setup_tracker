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

String? validate(List<Installation> installations) =>
    installationTimelineIssue(installations)?.message;

Archival archive(int day) => Archival(
      dateTimeUTC: _utc(day),
      dateTimeLocal: _utc(day).toLocal(),
    );

void main() {
  group('isComplexInstallationTimeline', () {
    test('treats a single from-beginning entry as simple', () {
      expect(
        isComplexInstallationTimeline([
          Installation.sinceBeginning(parent: 'b1'),
        ]),
        isFalse,
      );
    });

    test('treats a dated entry as complex', () {
      expect(isComplexInstallationTimeline([installOn('b1', 1)]), isTrue);
    });

    test('treats multiple entries as complex', () {
      expect(
        isComplexInstallationTimeline([
          Installation.sinceBeginning(parent: 'b1'),
          uninstall(2),
        ]),
        isTrue,
      );
    });
  });

  group('shouldUseInstallationTimeline', () {
    test('uses the timeline for complex data when the feature is disabled', () {
      expect(
        shouldUseInstallationTimeline(
          featureEnabled: false,
          installations: [
            Installation.sinceBeginning(parent: 'b1'),
            uninstall(2),
          ],
        ),
        isTrue,
      );
    });

    test('keeps simple data in single-entry mode when the feature is disabled', () {
      expect(
        shouldUseInstallationTimeline(
          featureEnabled: false,
          installations: [Installation.sinceBeginning(parent: 'b1')],
        ),
        isFalse,
      );
    });
  });

  group('installationTimelineIssue messages', () {
    test('rejects an empty timeline', () {
      expect(validate([]), 'At least one entry is required');
    });

    test('accepts a single entry', () {
      expect(validate([installOn('b1', 1)]), isNull);
      expect(validate([uninstall(1)]), isNull);
      expect(validate([archive(1)]), isNull);
    });

    test('accepts archival as the last entry', () {
      expect(
        validate([installOn('b1', 1), archive(2)]),
        isNull,
      );
    });

    test('rejects archival before another entry', () {
      expect(
        validate([archive(1), installOn('b1', 2)]),
        'Archival can only be the last entry in the timeline',
      );
    });

    test('rejects consecutive uninstallations', () {
      expect(
        validate([installOn('b1', 1), uninstall(2), uninstall(3)]),
        'Cannot have consecutive uninstallations',
      );
    });

    test('rejects consecutive installations on the same bike', () {
      expect(
        validate([installOn('b1', 1), installOn('b1', 2)]),
        'Cannot have consecutive installations on the same bike',
      );
    });

    test('accepts consecutive installations on different bikes', () {
      expect(
        validate([installOn('b1', 1), installOn('b2', 2)]),
        isNull,
      );
    });

    test('rejects multiple from-beginning entries', () {
      expect(
        validate([
          Installation.sinceBeginning(parent: 'b1'),
          Installation.sinceBeginning(),
        ]),
        'Multiple "From beginning" entries are not allowed',
      );
    });

    test('accepts a single from-beginning entry', () {
      expect(
        validate([
          Installation.sinceBeginning(parent: 'b1'),
          uninstall(2),
        ]),
        isNull,
      );
    });

    test('accepts a valid mixed timeline', () {
      expect(
        validate([
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
        validate([
          archive(5),
          uninstall(2),
          installOn('b2', 3),
          installOn('b1', 1),
          uninstall(4),
        ]),
        isNull,
      );
    });

    test('rejects two entries in the same minute', () {
      final at = DateTime.utc(2026, 1, 1, 14, 32);
      expect(
        validate([
          BikeInstallation(bikeId: 'b1', dateTimeUTC: at, dateTimeLocal: at.toLocal()),
          BikeInstallation(bikeId: 'b2', dateTimeUTC: at, dateTimeLocal: at.toLocal()),
        ]),
        'Two entries cannot have the same date & time',
      );
    });

    test('rejects entries that only differ by seconds', () {
      final at = DateTime.utc(2026, 1, 1, 14, 32);
      expect(
        validate([
          BikeInstallation(bikeId: 'b1', dateTimeUTC: at, dateTimeLocal: at.toLocal()),
          BikeInstallation(
            bikeId: 'b2',
            dateTimeUTC: at.add(const Duration(seconds: 47)),
            dateTimeLocal: at.add(const Duration(seconds: 47)).toLocal(),
          ),
        ]),
        'Two entries cannot have the same date & time',
        reason: 'sub-minute precision is truncated away on construction',
      );
    });

    test('reports duplicate from-beginning entries with their own message', () {
      expect(
        validate([
          Installation.sinceBeginning(parent: 'b1'),
          Installation.sinceBeginning(parent: 'b2'),
        ]),
        'Multiple "From beginning" entries are not allowed',
      );
    });

    test('sorts before validating: unsorted invalid timeline is rejected', () {
      // Chronologically this is install(b1) → install(b1) → uninstall.
      expect(
        validate([
          uninstall(3),
          installOn('b1', 2),
          installOn('b1', 1),
        ]),
        'Cannot have consecutive installations on the same bike',
      );
    });
  });

  group('stampInstallationNow', () {
    final now = DateTime(2026, 1, 1, 14, 32, 47, 123);

    test('truncates to the minute', () {
      final at = stampInstallationNow([], now: now);
      expect(at.local, DateTime(2026, 1, 1, 14, 32));
      expect(at.utc, now.toUtc().copyWith(second: 0, millisecond: 0, microsecond: 0));
      expect(at.utc.isUtc, isTrue);
    });

    test('moves to the next free minute when the current one is taken', () {
      final taken = Uninstallation(dateTimeUTC: now.toUtc(), dateTimeLocal: now);
      final at = stampInstallationNow([taken], now: now);

      expect(at.local, DateTime(2026, 1, 1, 14, 33));
      expect(at.utc, taken.dateTimeUTC.add(const Duration(minutes: 1)));
    });

    test('keeps moving past a run of taken minutes', () {
      final entries = [
        Uninstallation(dateTimeUTC: now.toUtc(), dateTimeLocal: now),
        BikeInstallation(
          bikeId: 'b1',
          dateTimeUTC: now.toUtc().add(const Duration(minutes: 1)),
          dateTimeLocal: now.add(const Duration(minutes: 1)),
        ),
      ];
      final at = stampInstallationNow(entries, now: now);

      expect(at.local, DateTime(2026, 1, 1, 14, 34));
      expect(isValidInstallationTimeline([
        ...entries,
        Uninstallation(dateTimeUTC: at.utc, dateTimeLocal: at.local),
      ]), isTrue);
    });

    test('ignores entries in other minutes', () {
      final other = Uninstallation(
        dateTimeUTC: now.toUtc().add(const Duration(minutes: 5)),
        dateTimeLocal: now.add(const Duration(minutes: 5)),
      );
      expect(stampInstallationNow([other], now: now).local, DateTime(2026, 1, 1, 14, 32));
    });
  });

  group('installationTimelineIssue', () {
    test('points at both parents of consecutive uninstallations, by input index', () {
      final issue = installationTimelineIssue([
        uninstall(3),
        installOn('b1', 1),
        uninstall(2),
      ]);

      expect(issue!.message, 'Cannot have consecutive uninstallations');
      expect(issue.parentIndices, {0, 2});
      expect(issue.dateTimeIndices, isEmpty);
    });

    test('points at both parents of consecutive installations on the same bike', () {
      final issue = installationTimelineIssue([installOn('b1', 1), installOn('b1', 2)]);

      expect(issue!.parentIndices, {0, 1});
      expect(issue.dateTimeIndices, isEmpty);
    });

    test('points at the parent of a non-final archival, by input index', () {
      final issue = installationTimelineIssue([installOn('b1', 5), archive(1)]);

      expect(issue!.message, 'Archival can only be the last entry in the timeline');
      expect(issue.parentIndices, {1});
    });

    test('points at the date & time of every entry sharing an instant', () {
      final issue = installationTimelineIssue([
        installOn('b1', 1),
        installOn('b2', 1),
        installOn('b3', 1),
      ]);

      expect(issue!.message, 'Two entries cannot have the same date & time');
      expect(issue.dateTimeIndices, {0, 1, 2});
      expect(issue.parentIndices, isEmpty);
    });

    test('points at the date & time of every "From beginning" entry', () {
      final issue = installationTimelineIssue([
        Installation.sinceBeginning(parent: 'b1'),
        Installation.sinceBeginning(parent: 'b2'),
      ]);

      expect(issue!.message, 'Multiple "From beginning" entries are not allowed');
      expect(issue.dateTimeIndices, {0, 1});
    });

    test('highlights nothing for an empty timeline', () {
      final issue = installationTimelineIssue([]);

      expect(issue!.dateTimeIndices, isEmpty);
      expect(issue.parentIndices, isEmpty);
    });

    test('returns null for a valid timeline', () {
      expect(installationTimelineIssue([installOn('b1', 1), uninstall(2)]), isNull);
    });
  });

  group('isValidInstallationTimeline', () {
    test('mirrors installationTimelineIssue', () {
      expect(isValidInstallationTimeline([installOn('b1', 1)]), isTrue);
      expect(isValidInstallationTimeline([]), isFalse);
      expect(isValidInstallationTimeline([archive(1), uninstall(2)]), isFalse);
    });
  });
}
