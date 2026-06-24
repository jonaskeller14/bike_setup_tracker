import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/mappers.dart';
import '../models/adjustment/adjustment.dart';
import '../models/selected_data.dart';

class DatabaseMigrationService {
  final AppDatabase db;
  DatabaseMigrationService(this.db);

  Future<void> migrateFromSelectedData(SelectedData data) async {
    await db.batch((batch) {
      // -----------------------------------------------------------------------
      // Level 0: Independent entities
      // -----------------------------------------------------------------------

      // Persons
      batch.insertAllOnConflictUpdate(
        db.persons,
        data.persons.values.map((p) => p.toCompanion()),
      );

      // Bikes
      batch.insertAllOnConflictUpdate(
        db.bikes,
        data.bikes.values.map((b) => b.toCompanion()),
      );

      // Ratings
      batch.insertAllOnConflictUpdate(
        db.ratings,
        data.ratings.values.map((r) => r.toCompanion()),
      );

      // Task Rules
      batch.insertAllOnConflictUpdate(
        db.taskRules,
        data.taskRules.values.map((tr) => tr.toCompanion()),
      );

      // -----------------------------------------------------------------------
      // Level 1: Sub-Components (References Level 0)
      // -----------------------------------------------------------------------

      // Components
      batch.insertAllOnConflictUpdate(
        db.components,
        data.components.values.map((c) => c.toCompanion()),
      );

      // -----------------------------------------------------------------------
      // Level 2: Nested Objects (References Level 0 and Level 1)
      // -----------------------------------------------------------------------

      // Task Entries
      batch.insertAllOnConflictUpdate(
        db.taskEntries,
        data.taskEntries.values.map((te) => te.toCompanion()),
      );

      // Installations (nested in components)
      final List<InstallationsCompanion> installationsToInsert = [];
      for (final component in data.components.values) {
        for (final installation in component.installations) {
          installationsToInsert.add(
            installation.toCompanion(
              id: const Uuid().v4(), // generate an ID as legacy didn't have one
              componentId: component.id,
            ),
          );
        }
      }
      batch.insertAllOnConflictUpdate(db.installations, installationsToInsert);

      // Adjustments (nested in components, persons, ratings)
      final List<AdjustmentsCompanion> adjustmentsToInsert = [];

      void addAdjustments(
        List<Adjustment> adjustments, {
        String? componentId,
        String? personId,
      }) {
        for (int i = 0; i < adjustments.length; i++) {
          final adj = adjustments[i];
          adjustmentsToInsert.add(
            adj.toCompanion(
              componentId: componentId,
              personId: personId,
              orderIndex: i,
            ),
          );
        }
      }

      for (final c in data.components.values) {
        addAdjustments(c.adjustments, componentId: c.id);
      }
      for (final p in data.persons.values) {
        addAdjustments(p.adjustments, personId: p.id);
      }

      batch.insertAllOnConflictUpdate(db.adjustments, adjustmentsToInsert);

      // Rating metrics (nested in ratings) live in their own table.
      final List<RatingMetricsCompanion> ratingMetricsToInsert = [];
      for (final r in data.ratings.values) {
        for (int i = 0; i < r.metrics.length; i++) {
          ratingMetricsToInsert.add(r.metrics[i].toCompanion(ratingId: r.id, orderIndex: i));
        }
      }
      batch.insertAllOnConflictUpdate(db.ratingMetrics, ratingMetricsToInsert);

      // Rating Entries
      batch.insertAllOnConflictUpdate(
        db.ratingEntries,
        data.ratingEntries.values.map((re) => re.toCompanion()),
      );

      // -----------------------------------------------------------------------
      // Level 3: Events
      // -----------------------------------------------------------------------

      // Setups
      batch.insertAllOnConflictUpdate(
        db.setups,
        data.setups.values.map((s) => s.toCompanion()),
      );

      // -----------------------------------------------------------------------
      // Level 4: Junctions
      // -----------------------------------------------------------------------

      // Setup Adjustment Values
      final List<SetupAdjustmentValuesCompanion> valuesToInsert = [];
      for (final setup in data.setups.values) {
        // Bike adjustments
        for (final entry in setup.bikeAdjustmentValues.entries) {
          valuesToInsert.add(
            SetupAdjustmentValuesCompanion.insert(
              setupId: setup.id,
              adjustmentId: entry.key,
              value: entry.value.toString(),
            ),
          );
        }
        // Person adjustments
        for (final entry in setup.personAdjustmentValues.entries) {
          valuesToInsert.add(
            SetupAdjustmentValuesCompanion.insert(
              setupId: setup.id,
              adjustmentId: entry.key,
              value: entry.value.toString(),
            ),
          );
        }
      }

      batch.insertAllOnConflictUpdate(db.setupAdjustmentValues, valuesToInsert);

      // Rating Entry Values
      final List<RatingEntryValuesCompanion> ratingEntryValuesToInsert = [];
      for (final ratingEntry in data.ratingEntries.values) {
        for (final entry in ratingEntry.metricValues.entries) {
          if (entry.value == null) continue;
          ratingEntryValuesToInsert.add(
            RatingEntryValuesCompanion.insert(
              ratingEntryId: ratingEntry.id,
              ratingMetricId: entry.key,
              value: entry.value.toString(),
            ),
          );
        }
      }
      batch.insertAllOnConflictUpdate(db.ratingEntryValues, ratingEntryValuesToInsert);
    });
  }
}
