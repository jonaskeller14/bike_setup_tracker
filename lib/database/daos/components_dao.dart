import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/adjustments.dart';
import '../tables/components.dart';
import '../tables/installations.dart';
import 'soft_delete_dao_mixin.dart';

part 'components_dao.g.dart';

@DriftAccessor(tables: [Components, Adjustments, Installations])
class ComponentsDao extends DatabaseAccessor<AppDatabase> with _$ComponentsDaoMixin, SoftDeletableDaoMixin<Components, ComponentDb, ComponentsCompanion> {
  ComponentsDao(super.db);

  @override TableInfo<Components, ComponentDb> get softDeletableTable => components;
  @override Expression<bool> get isDeletedColumn => components.isDeleted;
  @override Expression<String> get idColumn => components.id;
  @override ComponentsCompanion createSoftDeleteCompanion() => ComponentsCompanion(isDeleted: const Value(true), lastModified: Value(DateTime.now().toUtc()));

  Stream<List<ComponentDb>> watchAllComponents() => watchAllActive();
  Stream<List<ComponentDb>> watchDeletedComponents() => watchAllDeleted();

  Stream<List<ComponentWithData>> watchAllComponentsWithData() {
    final query = (select(components)
          ..where((t) => isDeletedColumn.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: components.orderIndex)]))
        .join([
      leftOuterJoin(adjustments, adjustments.componentId.equalsExp(components.id)),
      leftOuterJoin(installations, installations.componentId.equalsExp(components.id)),
    ]);

    return query.watch().map((rows) {
      final Map<String, ComponentWithData> grouped = {};
      for (final row in rows) {
        final component = row.readTable(components);
        final adjustment = row.readTableOrNull(adjustments);
        final installation = row.readTableOrNull(installations);

        final entry = grouped.putIfAbsent(
          component.id,
          () => ComponentWithData(component: component, adjustments: [], installations: []),
        );
        if (adjustment != null && !entry.adjustments.any((a) => a.id == adjustment.id)) {
          entry.adjustments.add(adjustment);
        }
        if (installation != null && !entry.installations.any((i) => i.id == installation.id)) {
          entry.installations.add(installation);
        }
      }
      // The join returns rows in no guaranteed order, so both child lists are
      // sorted explicitly — callers read installations chronologically.
      for (final entry in grouped.values) {
        entry.adjustments.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        entry.installations.sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC));
      }
      return grouped.values.toList();
    });
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
  Future<bool> updateComponent(ComponentsCompanion entry) => update(components).replace(entry);
  Future<int> deleteComponent(String id) => softDelete(id);

  // Adjustment operations
  Future<int> insertAdjustment(AdjustmentsCompanion entry) => into(adjustments).insert(entry);
  Future<bool> updateAdjustment(AdjustmentsCompanion entry) => update(adjustments).replace(entry);
  Future<int> deleteAdjustment(String id) => (delete(adjustments)..where((t) => t.id.equals(id))).go();

  Future<void> insertComponentWithData({
    required ComponentsCompanion component,
    required List<AdjustmentsCompanion> adjustmentsList,
    required List<InstallationsCompanion> installationsList,
  }) async {
    await transaction(() async {
      await into(components).insert(component);
      for (var i = 0; i < adjustmentsList.length; i++) {
        await into(adjustments).insert(adjustmentsList[i]);
      }
      for (final inst in installationsList) {
        await into(installations).insert(inst);
      }
    });
  }

  Future<void> updateComponentWithData({
    required ComponentsCompanion component,
    required List<AdjustmentsCompanion> adjustmentsList,
    required List<InstallationsCompanion> installationsList,
  }) async {
    await transaction(() async {
      await update(components).replace(component);
      
      // Update adjustments: delete old ones for this component and insert new ones
      // (This is simpler than trying to merge/update existing ones)
      await (delete(adjustments)..where((t) => t.componentId.equals(component.id.value))).go();
      for (var i = 0; i < adjustmentsList.length; i++) {
        await into(adjustments).insert(adjustmentsList[i]);
      }

      // Update installations: same approach
      await (delete(installations)..where((t) => t.componentId.equals(component.id.value))).go();
      for (final inst in installationsList) {
        await into(installations).insert(inst);
      }
    });
  }

  Future<List<ComponentWithData>> getAllComponentsWithDataBypass() async {
    final query = select(components).join([
      leftOuterJoin(adjustments, adjustments.componentId.equalsExp(components.id)),
      leftOuterJoin(installations, installations.componentId.equalsExp(components.id)),
    ]);

    final rows = await query.get();
    final Map<String, ComponentWithData> grouped = {};
    for (final row in rows) {
      final component = row.readTable(components);
      final adjustment = row.readTableOrNull(adjustments);
      final installation = row.readTableOrNull(installations);

      final entry = grouped.putIfAbsent(
        component.id,
        () => ComponentWithData(component: component, adjustments: [], installations: []),
      );
      if (adjustment != null && !entry.adjustments.any((a) => a.id == adjustment.id)) {
        entry.adjustments.add(adjustment);
      }
      if (installation != null && !entry.installations.any((i) => i.id == installation.id)) {
        entry.installations.add(installation);
      }
    }
    for (final entry in grouped.values) {
      entry.adjustments.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      entry.installations.sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC));
    }
    return grouped.values.toList();
  }

  Future<void> reorder(List<String> ids) async {
    await transaction(() async {
      for (int i = 0; i < ids.length; i++) {
        await (update(components)..where((t) => t.id.equals(ids[i])))
            .write(ComponentsCompanion(orderIndex: Value(i)));
      }
    });
  }
}

class ComponentWithData {
  final ComponentDb component;
  final List<AdjustmentDb> adjustments;
  final List<InstallationDb> installations;
  ComponentWithData({required this.component, required this.adjustments, required this.installations});
}
