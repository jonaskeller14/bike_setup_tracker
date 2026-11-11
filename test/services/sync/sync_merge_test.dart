import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/services/sync/sync_merge.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime.utc(2026, 1, 1, 12);

Bike _bike({String name = 'Bike', DateTime? lastModified, bool isDeleted = false}) =>
    Bike(id: 'b1', name: name, person: null, lastModified: lastModified ?? _t0, isDeleted: isDeleted);

void main() {
  group('SyncMerge.resolve', () {
    test('adds a remote record that is missing locally', () {
      expect(SyncMerge.resolve(local: null, remote: _bike()), SyncAction.applyRemote);
    });

    test('skips a remote tombstone of a record missing locally', () {
      expect(SyncMerge.resolve(local: null, remote: _bike(isDeleted: true)), SyncAction.skip);
    });

    test('remote wins when it is newer', () {
      final remote = _bike(lastModified: _t0.add(const Duration(seconds: 1)));

      expect(SyncMerge.resolve(local: _bike(), remote: remote), SyncAction.applyRemote);
    });

    test('local wins when it is newer', () {
      final local = _bike(lastModified: _t0.add(const Duration(seconds: 1)));

      expect(SyncMerge.resolve(local: local, remote: _bike()), SyncAction.keepLocal);
    });

    test('a difference of one microsecond decides', () {
      final newer = _bike(lastModified: _t0.add(const Duration(microseconds: 1)));

      expect(SyncMerge.resolve(local: _bike(), remote: newer), SyncAction.applyRemote);
      expect(SyncMerge.resolve(local: newer, remote: _bike()), SyncAction.keepLocal);
    });

    group('equal timestamps', () {
      test('a remote tombstone beats a local edit', () {
        expect(SyncMerge.resolve(local: _bike(), remote: _bike(isDeleted: true)), SyncAction.applyRemote);
      });

      test('a local tombstone beats a remote edit', () {
        expect(SyncMerge.resolve(local: _bike(isDeleted: true), remote: _bike()), SyncAction.keepLocal);
      });

      test('two tombstones keep the local one', () {
        expect(SyncMerge.resolve(local: _bike(isDeleted: true), remote: _bike(isDeleted: true)), SyncAction.keepLocal);
      });

      test('the same version keeps the local one, so a retried push or re-pull is harmless', () {
        expect(SyncMerge.resolve(local: _bike(), remote: _bike()), SyncAction.keepLocal);
      });

      test('different edits of the same tick: both devices pick the same winner', () {
        final a = _bike(name: 'Edit A');
        final b = _bike(name: 'Edit B');

        final deviceA = SyncMerge.resolve(local: a, remote: b);
        final deviceB = SyncMerge.resolve(local: b, remote: a);

        expect({deviceA, deviceB}, {SyncAction.applyRemote, SyncAction.keepLocal});
      });
    });

    group('tombstone against edit', () {
      test('a newer remote tombstone deletes the local record', () {
        final remote = _bike(isDeleted: true, lastModified: _t0.add(const Duration(minutes: 1)));

        expect(SyncMerge.resolve(local: _bike(), remote: remote), SyncAction.applyRemote);
      });

      test('a newer local edit survives an older remote tombstone', () {
        final local = _bike(lastModified: _t0.add(const Duration(minutes: 1)));

        expect(SyncMerge.resolve(local: local, remote: _bike(isDeleted: true)), SyncAction.keepLocal);
      });

      test('a newer remote edit restores a locally deleted record', () {
        final remote = _bike(lastModified: _t0.add(const Duration(minutes: 1)));

        expect(SyncMerge.resolve(local: _bike(isDeleted: true), remote: remote), SyncAction.applyRemote);
      });
    });
  });
}
