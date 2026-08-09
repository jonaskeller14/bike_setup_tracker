import 'package:drift/drift.dart';

import '../app_database.dart';

/// Mixin to standardize soft-delete queries across all DAOs.
/// Requires the DAO to specify the table and relevant columns to operate on.
mixin SoftDeletableDaoMixin<T extends Table, D, C extends UpdateCompanion<D>> on DatabaseAccessor<AppDatabase> {
  TableInfo<T, D> get softDeletableTable;
  Expression<bool> get isDeletedColumn;
  Expression<String> get idColumn;
  C createSoftDeleteCompanion();

  /// Watches all records where isDeleted is false
  Stream<List<D>> watchAllActive() => 
      (select(softDeletableTable)..where((_) => isDeletedColumn.equals(false))).watch();

  /// Watches all records where isDeleted is true
  Stream<List<D>> watchAllDeleted() => 
      (select(softDeletableTable)..where((_) => isDeletedColumn.equals(true))).watch();

  /// Performs a soft delete by applying the companion to the record with the given ID
  Future<int> softDelete(String id) {
    return (update(softDeletableTable)..where((_) => idColumn.equals(id))).write(createSoftDeleteCompanion());
  }
}
