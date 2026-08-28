import 'package:bike_setup_tracker/database/adjustment_value_codec.dart';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/services/setup_activity_analysis_service.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SetupActivityAnalysisService service;
  final baseTime = DateTime.utc(2025, 1, 1, 12);

  Future<void> insertSetup(String id, double adjustmentValue) async {
    await db
        .into(db.setups)
        .insert(
          SetupsCompanion.insert(
            id: id,
            bikeId: 'bike',
            lastModified: baseTime,
            datetime: baseTime,
            datetimeLocal: baseTime,
            tags: const {},
          ),
        );
    await db
        .into(db.setupAdjustmentValues)
        .insert(
          SetupAdjustmentValuesCompanion.insert(
            setupId: id,
            adjustmentId: 'adjustment',
            value: encodeAdjustmentValue(adjustmentValue),
          ),
        );
  }

  Future<void> insertActivity(int id) async {
    await db
        .into(db.stravaActivities)
        .insert(
          StravaActivitiesCompanion.insert(
            id: Value(id),
            lastModified: baseTime,
            name: 'Activity $id',
            athlete: 1,
            sportType: SportType.Ride,
            startDate: baseTime.add(Duration(hours: id)),
            startDateLocal: baseTime.add(Duration(hours: id)),
            gearId: const Value('gear'),
            movingTime: 60,
            elapsedTime: 60,
          ),
        );
  }

  setUp(() async {
    db = AppDatabase.memory();
    await db
        .into(db.bikes)
        .insert(
          BikesCompanion.insert(
            id: 'bike',
            lastModified: baseTime,
            name: 'Bike',
            stravaGear: const Value('gear'),
          ),
        );
    await db
        .into(db.components)
        .insert(
          ComponentsCompanion.insert(
            id: 'component',
            lastModified: baseTime,
            name: 'Fork',
            componentType: ComponentType.fork,
          ),
        );
    await db
        .into(db.adjustments)
        .insert(
          AdjustmentsCompanion.insert(
            id: 'adjustment',
            componentId: const Value('component'),
            orderIndex: 0,
            name: 'Pressure',
            type: AdjustmentType.numerical,
            jsonPayload: const Value('{"version":2,"type":"numerical"}'),
          ),
        );
    await insertSetup('setup', 20);
    await insertActivity(1);
    service = SetupActivityAnalysisService(db);
  });

  tearDown(() async {
    service.dispose();
    await db.close();
  });

  Future<void> settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  test('shares completed counts and histogram work', () async {
    final firstCounts = await service.getSetupActivityCounts();
    final secondCounts = await service.getSetupActivityCounts();
    final firstHistogram = await service.getAdjustmentHistogram('adjustment');
    final secondHistogram = await service.getAdjustmentHistogram('adjustment');

    expect(identical(firstCounts, secondCounts), isTrue);
    expect(identical(firstHistogram, secondHistogram), isTrue);
    expect(firstCounts, {'setup': 1});
    expect(firstHistogram.bars.single.activityCount, 1);
    expect(firstHistogram.bars.single.exactValue, 20.0);
  });

  test('invalidates after setup values and setup rows change', () async {
    final initial = await service.getAdjustmentHistogram('adjustment');
    await db
        .into(db.setupAdjustmentValues)
        .insertOnConflictUpdate(
          SetupAdjustmentValuesCompanion.insert(
            setupId: 'setup',
            adjustmentId: 'adjustment',
            value: encodeAdjustmentValue(25.0),
          ),
        );
    await settle();

    final changedValue = await service.getAdjustmentHistogram('adjustment');
    expect(identical(initial, changedValue), isFalse);
    expect(changedValue.bars.single.exactValue, 25.0);

    await (db.update(db.setups)..where((table) => table.id.equals('setup'))).write(
      const SetupsCompanion(isDeleted: Value(true)),
    );
    await settle();
    expect((await service.getAdjustmentHistogram('adjustment')).isEmpty, isTrue);
  });

  test('invalidates counts after activity and bike gear changes', () async {
    expect(await service.getSetupActivityCounts(), {'setup': 1});
    await insertActivity(2);
    await settle();
    expect(await service.getSetupActivityCounts(), {'setup': 2});

    await (db.update(db.bikes)..where((table) => table.id.equals('bike'))).write(
      const BikesCompanion(stravaGear: Value('other-gear')),
    );
    await settle();
    expect(await service.getSetupActivityCounts(), {'setup': 0});
  });

  test('tracks full-database activity existence transitions', () async {
    await service.getSetupActivityCounts();
    expect(service.hasAnyActivity, isTrue);

    await db.delete(db.stravaActivities).go();
    await settle();
    expect(service.hasAnyActivity, isFalse);
    expect((await service.getAdjustmentHistogram('adjustment')).isEmpty, isTrue);

    await insertActivity(3);
    await settle();
    expect(service.hasAnyActivity, isTrue);
  });

  test('disposes safely while a read is in flight', () async {
    final future = service.getAdjustmentHistogram('adjustment');
    service.dispose();

    await expectLater(future, completes);
  });
}
