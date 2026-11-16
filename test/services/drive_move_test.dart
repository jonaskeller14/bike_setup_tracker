import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/services/data_export_service.dart';
import 'package:bike_setup_tracker/services/database_migration_service.dart';
import 'package:bike_setup_tracker/services/drive_move.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

DateTime _t(int seconds) => DateTime.utc(2026, 6, 1).add(Duration(seconds: seconds));

Bike _bike(String id, String name, {int at = 0}) => Bike(id: id, name: name, person: null, lastModified: _t(at));

SelectedData _data(List<Bike> bikes) => SelectedData(bikes: {for (final bike in bikes) bike.id: bike});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DriveMove.run', () {
    late AppDatabase database;
    late List<String> calls;
    late bool driveOn;

    setUp(() async {
      database = AppDatabase.memory();
      await DatabaseMigrationService(database).migrateFromSelectedData(
        _data([_bike('local', 'Local bike'), _bike('shared', 'Old name')]),
      );
      calls = [];
      driveOn = true;
    });

    tearDown(() => database.close());

    DriveMove move(Future<SelectedData?> Function() readDrive) => DriveMove(
      readDrive: readDrive,
      database: database,
      afterMerge: () async => calls.add('afterMerge'),
      syncNow: () async => calls.add('sync'),
      turnOffDrive: () => driveOn = false,
    );

    Future<Map<String, String>> bikeNames() async {
      final data = SelectedData.fromJson(await DataExportService.backupDatabaseToJson(database));
      return {for (final bike in data.bikes.values) bike.id: bike.name};
    }

    test('merges the Drive copy like a file import, syncs, then turns Drive off', () async {
      final state = await move(
        () async => _data([_bike('shared', 'New name', at: 10), _bike('drive', 'Drive bike')]),
      ).run();

      expect(state, DriveMoveState.done);
      expect(await bikeNames(), {'local': 'Local bike', 'shared': 'New name', 'drive': 'Drive bike'});
      expect(calls, ['afterMerge', 'sync']);
      expect(driveOn, isFalse);
    });

    test('the merged records are queued for cloud sync', () async {
      final before = await database.syncDao.watchPendingCount().first;
      await move(() async => _data([_bike('drive', 'Drive bike')])).run();

      expect(await database.syncDao.watchPendingCount().first, greaterThan(before));
    });

    test('an older Drive copy does not overwrite newer local data', () async {
      await DatabaseMigrationService(database).migrateFromSelectedData(_data([_bike('shared', 'Newer here', at: 20)]));

      await move(() async => _data([_bike('shared', 'Older in Drive', at: 10)])).run();

      expect((await bikeNames())['shared'], 'Newer here');
    });

    test('no Drive copy: nothing to move, Drive still turns off', () async {
      final state = await move(() async => null).run();

      expect(state, DriveMoveState.nothingToMove);
      expect(calls, isEmpty);
      expect(driveOn, isFalse);
    });

    final failures = <DriveMoveState, Exception>{
      DriveMoveState.signInFailed: const DriveReadException(DriveReadFailure.signIn),
      DriveMoveState.offline: const DriveReadException(DriveReadFailure.offline),
      DriveMoveState.failed: Exception('Drive API not initialized'),
    };
    for (final MapEntry(key: expected, value: error) in failures.entries) {
      test('${expected.name}: Drive stays on and nothing changes', () async {
        final state = await move(() async => throw error).run();

        expect(state, expected);
        expect(await bikeNames(), {'local': 'Local bike', 'shared': 'Old name'});
        expect(calls, isEmpty);
        expect(driveOn, isTrue);
      });
    }
  });

  group('driveNoticeFor', () {
    DriveNotice? notice({
      bool driveOn = true,
      bool syncActive = false,
      bool? premium = false,
      bool syncOn = false,
      bool onAccount = false,
      bool released = true,
    }) => driveNoticeFor(
      driveOn: driveOn,
      syncActive: syncActive,
      premium: premium,
      syncOn: syncOn,
      onAccount: onAccount,
      endingReleased: released,
    );

    test('only Google Drive users get a notice', () {
      expect(notice(driveOn: false), isNull);
      expect(notice(driveOn: false, syncActive: true, premium: true, syncOn: true, onAccount: true), isNull);
    });

    test('active cloud sync offers the move, even before the ending notice ships', () {
      expect(notice(syncActive: true, premium: true, syncOn: true, onAccount: true), DriveNotice.move);
      expect(notice(syncActive: true, premium: true, syncOn: true, onAccount: true, released: false), DriveNotice.move);
    });

    test('every known subscription state without sync gets the ending notice once it ships', () {
      expect(notice(), DriveNotice.ending, reason: 'no subscription');
      expect(notice(onAccount: true), DriveNotice.ending, reason: 'no subscription, on an account');
      expect(notice(premium: true), DriveNotice.ending, reason: 'subscriber, sync off');
      expect(notice(premium: true, onAccount: true), DriveNotice.ending, reason: 'subscriber on an account, sync off');
      expect(notice(premium: true, syncOn: true), DriveNotice.ending, reason: 'subscriber, sync on, no account');
      expect(notice(released: false), isNull);
    });

    test('waits while the subscription is unknown or the sync is starting', () {
      expect(notice(premium: null), isNull);
      expect(notice(premium: null, syncOn: true, onAccount: true), isNull);
      expect(notice(premium: true, syncOn: true, onAccount: true), isNull);
    });
  });

  group('driveEndingOfferFor', () {
    test('offers the next missing step to cloud sync', () {
      expect(driveEndingOfferFor(premium: false, syncOn: false), DriveEndingOffer.subscribe);
      expect(driveEndingOfferFor(premium: false, syncOn: true), DriveEndingOffer.subscribe);
      expect(driveEndingOfferFor(premium: true, syncOn: false), DriveEndingOffer.turnOnSync);
      expect(driveEndingOfferFor(premium: true, syncOn: true), DriveEndingOffer.connectStrava);
    });
  });

  group('DriveNoticePrompts', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('each notice is remembered as shown on its own', () async {
      expect(await DriveNoticePrompts.wasShown(DriveNotice.move), isFalse);
      await DriveNoticePrompts.markShown(DriveNotice.move);
      expect(await DriveNoticePrompts.wasShown(DriveNotice.move), isTrue);
      expect(await DriveNoticePrompts.wasShown(DriveNotice.ending), isFalse);
    });
  });
}
