import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/bikes.dart';
import '../tables/components.dart';
import '../tables/setups.dart';
import 'soft_delete_dao_mixin.dart';

part 'bikes_dao.g.dart';

@DriftAccessor(tables: [Bikes, Components, Setups])
class BikesDao extends DatabaseAccessor<AppDatabase> with _$BikesDaoMixin, SoftDeletableDaoMixin<Bikes, BikeDb, BikesCompanion> {
  BikesDao(super.db);

  @override TableInfo<Bikes, BikeDb> get softDeletableTable => bikes;
  @override Expression<bool> get isDeletedColumn => bikes.isDeleted;
  @override Expression<String> get idColumn => bikes.id;
  @override BikesCompanion createSoftDeleteCompanion() => BikesCompanion(isDeleted: const Value(true), lastModified: Value(DateTime.now().toUtc()));

  Stream<List<BikeDb>> watchAllBikes() => watchAllActive();
  Stream<List<BikeDb>> watchDeletedBikes() => watchAllDeleted();
  Future<List<BikeDb>> getAllBikesBypass() => select(bikes).get();

  Future<BikeDb?> getBike(String id) {
    return (select(bikes)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<BikeDb?> watchBike(String id) {
    return (select(bikes)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<int> insertBike(BikesCompanion entry) => into(bikes).insert(entry);
  Future updateBike(BikesCompanion entry) => update(bikes).replace(entry);
  Future<int> deleteBike(String id) => softDelete(id);
}
