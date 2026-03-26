import '../database/app_database.dart';
import '../database/mappers.dart';
import '../models/selected_data.dart';

class DataExportService {
  /// Fetches all active and deleted data from the database, converts them
  /// to their respective models with nested data, and serializes to JSON.
  static Future<Map<String, dynamic>> backupDatabaseToJson(
    AppDatabase database, {
    SelectedData? subset,
  }) async {
    final bikes = await database.bikesDao.getAllBikesBypass();
    final components = await database.componentsDao.getAllComponentsWithDataBypass();
    final setups = await database.setupsDao.getAllSetupsWithValuesBypass();
    final persons = await database.personsDao.getAllPersonsWithDataBypass();
    final ratings = await database.ratingsDao.getAllRatingsWithDataBypass();
    
    final taskRules = await database.taskDao.getAllRulesBypass();
    final taskEntries = await database.taskDao.getAllEntriesBypass();
    
    final athletes = await database.stravaDao.getAllAthletesBypass();
    final gears = await database.stravaDao.getAllGearsBypass();
    final activities = await database.stravaDao.getAllActivitiesBypass();

    return {
      'persons': persons
          .where((p) => subset == null || subset.persons.containsKey(p.person.id))
          .map((p) => p.person.toModel(
                adjustments: p.adjustments.map((a) => a.toModel()).toList(),
              ).toJson())
          .toList(),
      'bikes': bikes
          .where((b) => subset == null || subset.bikes.containsKey(b.id))
          .map((b) => b.toModel().toJson())
          .toList(),
      'setups': setups
          .where((s) => subset == null || subset.setups.containsKey(s.setup.id))
          .map((s) => s.setup.toModel(
                values: s.values,
              ).toJson())
          .toList(),
      'components': components
          .where((c) => subset == null || subset.components.containsKey(c.component.id))
          .map((c) => c.component.toModel(
                adjustments: c.adjustments.map((a) => a.toModel()).toList(),
                installations: c.installations.map((i) => i.toModel()).toList(),
              ).toJson())
          .toList(),
      'ratings': ratings
          .where((r) => subset == null || subset.ratings.containsKey(r.rating.id))
          .map((r) => r.rating.toModel(
                adjustments: r.adjustments.map((a) => a.toModel()).toList(),
              ).toJson())
          .toList(),
      'taskRules': taskRules.map((tr) => tr.toModel().toJson()).toList(),
      'taskEntries': taskEntries.map((te) => te.toModel().toJson()).toList(),
      'stravaAthletes': athletes.map((a) => a.toModel().toJson()).toList(),
      'stravaGears': gears.map((g) => g.toModel().toJson()).toList(),
      'stravaActivities': activities.map((a) => a.toModel().toJson()).toList(),
    };
  }
}
