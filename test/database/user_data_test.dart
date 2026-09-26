import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertBike({bool isDeleted = false}) async {
    await db
        .into(db.bikes)
        .insert(
          BikesCompanion.insert(
            id: 'bike',
            lastModified: DateTime.now().toUtc(),
            name: 'Bike',
            isDeleted: Value(isDeleted),
          ),
        );
  }

  group('watchHasUserData', () {
    test('is false for an empty database', () async {
      expect(await db.watchHasUserData().first, isFalse);
    });

    test('counts soft-deleted rows as data', () async {
      await insertBike(isDeleted: true);
      expect(await db.watchHasUserData().first, isTrue);
    });

    test('is false after deleteAllUserData', () async {
      await insertBike();
      expect(await db.watchHasUserData().first, isTrue);

      await db.deleteAllUserData();

      expect(await db.watchHasUserData().first, isFalse);
      expect(await db.select(db.bikes).get(), isEmpty);
    });
  });
}
