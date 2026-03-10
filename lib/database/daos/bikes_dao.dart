import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/bikes.dart';
import '../tables/components.dart';
import '../tables/setups.dart';

part 'bikes_dao.g.dart';

@DriftAccessor(tables: [Bikes, Components, Setups])
class BikesDao extends DatabaseAccessor<AppDatabase> with _$BikesDaoMixin {
  BikesDao(super.db);

  Stream<List<BikeDb>> watchAllBikes() => (select(bikes)..where((t) => t.isDeleted.equals(false))).watch();
  Stream<List<BikeDb>> watchDeletedBikes() => (select(bikes)..where((t) => t.isDeleted.equals(true))).watch();

  Future<BikeDb?> getBike(String id) {
    return (select(bikes)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<BikeDb?> watchBike(String id) {
    return (select(bikes)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<int> insertBike(BikesCompanion entry) => into(bikes).insert(entry);
  Future updateBike(BikesCompanion entry) => update(bikes).replace(entry);
  Future deleteBike(String id) => (update(bikes)..where((t) => t.id.equals(id))).write(BikesCompanion(isDeleted: const Value(true), lastModified: Value(DateTime.now().toUtc())));
}
