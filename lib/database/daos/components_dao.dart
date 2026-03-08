import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/components.dart';
import '../tables/adjustments.dart';
import '../tables/installations.dart';

part 'components_dao.g.dart';

@DriftAccessor(tables: [Components, Adjustments, Installations])
class ComponentsDao extends DatabaseAccessor<AppDatabase> with _$ComponentsDaoMixin {
  ComponentsDao(super.db);

  Stream<List<ComponentDb>> watchAllComponents() {
    return (select(components)..where((t) => t.isDeleted.equals(false))).watch();
  }

  Future<ComponentDb?> getComponent(String id) {
    return (select(components)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<List<AdjustmentDb>> watchAdjustmentsForComponent(String componentId) {
    return (select(adjustments)
          ..where((t) => t.componentId.equals(componentId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .watch();
  }

  Stream<List<InstallationDb>> watchInstallationsForComponent(String componentId) {
    return (select(installations)
          ..where((t) => t.componentId.equals(componentId))
          ..orderBy([(t) => OrderingTerm(expression: t.dateTimeUTC, mode: OrderingMode.desc)]))
        .watch();
  }

  // Helper to find which bike a component is currently on
  Stream<String?> watchCurrentBikeForComponent(String componentId) {
    return (select(installations)
          ..where((t) => t.componentId.equals(componentId))
          ..orderBy([(t) => OrderingTerm(expression: t.dateTimeUTC, mode: OrderingMode.desc)])
          ..limit(1))
        .watchSingleOrNull()
        .map((i) => i?.parent);
  }

  Future<int> insertComponent(ComponentsCompanion entry) => into(components).insert(entry);
  Future updateComponent(ComponentsCompanion entry) => update(components).replace(entry);
  Future deleteComponent(String id) => (update(components)..where((t) => t.id.equals(id))).write(const ComponentsCompanion(isDeleted: Value(true)));

  // Adjustment operations
  Future<int> insertAdjustment(AdjustmentsCompanion entry) => into(adjustments).insert(entry);
  Future updateAdjustment(AdjustmentsCompanion entry) => update(adjustments).replace(entry);
  Future deleteAdjustment(String id) => (delete(adjustments)..where((t) => t.id.equals(id))).go();
}
