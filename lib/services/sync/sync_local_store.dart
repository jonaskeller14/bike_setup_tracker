import '../../database/app_database.dart';
import '../../database/mappers.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../models/feedback/ride_feedback.dart';
import '../../models/feedback/test_session.dart';
import '../../models/person.dart';
import '../../models/selected_data.dart';
import '../../models/setup.dart';
import '../../models/syncable.dart';
import '../../models/task/task_entry.dart';
import '../../models/task/task_rule.dart';
import '../data_export_service.dart';
import 'sync_collection.dart';

/// The local records as the sync engine sees them: the same models (and so
/// the same JSON) a backup export produces, children included.
class SyncLocalStore {
  final AppDatabase db;

  const SyncLocalStore(this.db);

  /// Every record, trashed ones included. Read inside the transaction that
  /// writes the merge result, so a local edit can't slip in between.
  Future<SelectedData> snapshot() async => SelectedData.fromJson(await DataExportService.backupDatabaseToJson(db));

  /// Writes [record] over the local one, replacing its children as a whole.
  Future<void> write(Syncable record, {required Map<String, AdjustmentType> adjustmentTypes}) async {
    switch (record) {
      case final Person person:
        await db.into(db.persons).insertOnConflictUpdate(person.toCompanion());
        await (db.delete(db.adjustments)..where((t) => t.personId.equals(person.id))).go();
        await _insertAdjustments(person.adjustments, personId: person.id);
      case final Bike bike:
        await db.into(db.bikes).insertOnConflictUpdate(bike.toCompanion());
      case final Component component:
        await db.into(db.components).insertOnConflictUpdate(component.toCompanion());
        await (db.delete(db.adjustments)..where((t) => t.componentId.equals(component.id))).go();
        await _insertAdjustments(component.adjustments, componentId: component.id);
        await (db.delete(db.installations)..where((t) => t.componentId.equals(component.id))).go();
        for (final installation in component.installations) {
          await db.into(db.installations).insertOnConflictUpdate(installation.toCompanion(componentId: component.id));
        }
      case final Setup setup:
        await db.into(db.setups).insertOnConflictUpdate(setup.toCompanion());
        await (db.delete(db.setupAdjustmentValues)..where((t) => t.setupId.equals(setup.id))).go();
        final values = {
          ...Setup.resolveAdjustmentValues(setup.bikeAdjustmentValues, adjustmentTypes),
          ...Setup.resolveAdjustmentValues(setup.personAdjustmentValues, adjustmentTypes),
        };
        for (final MapEntry(:key, :value) in values.entries) {
          await db
              .into(db.setupAdjustmentValues)
              .insertOnConflictUpdate(
                SetupAdjustmentValuesCompanion.insert(setupId: setup.id, adjustmentId: key, value: value.encode()),
              );
        }
      case final TaskRule rule:
        await db.into(db.taskRules).insertOnConflictUpdate(rule.toCompanion());
      case final TaskEntry entry:
        await db.into(db.taskEntries).insertOnConflictUpdate(entry.toCompanion());
      case final RideFeedback feedback:
        await db.feedbackDao.upsertFeedbackWithChildren(
          feedback: feedback.toCompanion(),
          observations: feedback.observationCompanions(),
          comparisons: feedback.comparisonCompanions(),
        );
      case final TestSession session:
        await db.into(db.testSessions).insertOnConflictUpdate(session.toCompanion());
    }
  }

  Future<void> _insertAdjustments(List<Adjustment> adjustments, {String? componentId, String? personId}) async {
    for (var i = 0; i < adjustments.length; i++) {
      await db
          .into(db.adjustments)
          .insertOnConflictUpdate(
            adjustments[i].toCompanion(componentId: componentId, personId: personId, orderIndex: i),
          );
    }
  }
}

extension SyncRecords on SelectedData {
  Map<String, Syncable> recordsOf(SyncCollection collection) => switch (collection) {
    SyncCollection.persons => persons,
    SyncCollection.bikes => bikes,
    SyncCollection.components => components,
    SyncCollection.setups => setups,
    SyncCollection.taskRules => taskRules,
    SyncCollection.taskEntries => taskEntries,
    SyncCollection.feedbacks => feedbacks,
    SyncCollection.testSessions => testSessions,
  };

  Map<String, AdjustmentType> get adjustmentTypes =>
      adjustmentTypesOf(components: components.values, persons: persons.values);
}
