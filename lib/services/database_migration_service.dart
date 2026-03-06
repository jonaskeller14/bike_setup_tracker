import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../models/app_data.dart';
import '../models/adjustment/adjustment.dart';
import '../database/app_database.dart';

class DatabaseMigrationService {
  final AppDatabase db;
  DatabaseMigrationService(this.db);

  Future<void> migrateFromAppData(AppData appData) async {
    await db.batch((batch) {
      // -----------------------------------------------------------------------
      // Level 0: Independent entities
      // -----------------------------------------------------------------------
      
      // Persons
      batch.insertAllOnConflictUpdate(db.persons, appData.persons.values.map((p) => PersonsCompanion.insert(
        id: p.id,
        isDeleted: Value(p.isDeleted),
        lastModified: p.lastModified,
        name: p.name,
        notes: Value(p.notes),
        stravaAthlete: Value(p.stravaAthlete),
      )));

      // Bikes
      batch.insertAllOnConflictUpdate(db.bikes, appData.bikes.values.map((b) => BikesCompanion.insert(
        id: b.id,
        isDeleted: Value(b.isDeleted),
        lastModified: b.lastModified,
        name: b.name,
        person: Value(b.person),
        stravaGear: Value(b.stravaGear),
        notes: Value(b.notes),
      )));

      // Ratings
      batch.insertAllOnConflictUpdate(db.ratings, appData.ratings.values.map((r) => RatingsCompanion.insert(
        id: r.id,
        isDeleted: Value(r.isDeleted),
        lastModified: r.lastModified,
        name: r.name,
        notes: Value(r.notes),
        filter: Value(r.filter),
        filterType: r.filterType,
      )));

      // Todo Rules
      batch.insertAllOnConflictUpdate(db.todoRules, appData.todoRules.values.map((tr) => TodoRulesCompanion.insert(
        id: tr.id,
        isDeleted: Value(tr.isDeleted),
        lastModified: tr.lastModified,
        name: tr.name,
        notes: Value(tr.notes),
        priority: Value(tr.priority),
      )));

      // Strava Athletes
      batch.insertAllOnConflictUpdate(db.stravaAthletes, appData.stravaAthletes.values.map((sa) => StravaAthletesCompanion.insert(
        id: Value(sa.id),
        lastModified: sa.lastModified,
        firstname: Value(sa.firstname),
        lastname: Value(sa.lastname),
        profile: Value(sa.profile),
        gears: sa.gears,
      )));

      // Strava Gears
      batch.insertAllOnConflictUpdate(db.stravaGears, appData.stravaGears.values.map((sg) => StravaGearsCompanion.insert(
        id: sg.id,
        lastModified: sg.lastModified,
        name: sg.name,
      )));

      // -----------------------------------------------------------------------
      // Level 1: Sub-Components (References Level 0)
      // -----------------------------------------------------------------------
      
      // Components
      batch.insertAllOnConflictUpdate(db.components, appData.components.values.map((c) => ComponentsCompanion.insert(
        id: c.id,
        isDeleted: Value(c.isDeleted),
        lastModified: c.lastModified,
        name: c.name,
        componentType: c.componentType,
        notes: Value(c.notes),
      )));

      // -----------------------------------------------------------------------
      // Level 2: Nested Objects (References Level 0 and Level 1)
      // -----------------------------------------------------------------------
      
      // Todo Entries
      batch.insertAllOnConflictUpdate(db.todoEntries, appData.todoEntries.values.map((te) => TodoEntriesCompanion.insert(
        id: te.id,
        isDeleted: Value(te.isDeleted),
        lastModified: te.lastModified,
        name: te.name,
        notes: Value(te.notes),
        dateTimeUTC: te.dateTimeUTC,
        dateTimeLocal: te.dateTimeLocal,
        todoRule: te.todoRule,
      )));

      // Installations (nested in components)
      final List<InstallationsCompanion> installationsToInsert = [];
      for (final component in appData.components.values) {
        for (final installation in component.installations) {
          installationsToInsert.add(InstallationsCompanion.insert(
            id: const Uuid().v4(), // generate an ID as legacy didn't have one
            componentId: component.id,
            parent: Value(installation.parent),
            dateTimeUTC: installation.dateTimeUTC,
            dateTimeLocal: installation.dateTimeLocal,
          ));
        }
      }
      batch.insertAllOnConflictUpdate(db.installations, installationsToInsert);

      // Adjustments (nested in components, persons, ratings)
      final List<AdjustmentsCompanion> adjustmentsToInsert = [];
      
      void addAdjustments(List<Adjustment> adjustments, {String? componentId, String? personId, String? ratingId}) {
        for (int i = 0; i < adjustments.length; i++) {
          final adj = adjustments[i];
          final jsonMap = adj.toJson();
          // Remove base fields, leaving only subclass specific payload
          jsonMap.removeWhere((key, value) => 
            ['version', 'id', 'name', 'notes', 'type', 'unit', 'category'].contains(key)
          );
          
          final typeString = adj.toJson()['type'] as String;
          final adjType = AdjustmentType.values.firstWhere((e) => e.name == typeString);

          adjustmentsToInsert.add(AdjustmentsCompanion.insert(
            id: adj.id,
            componentId: Value(componentId),
            personId: Value(personId),
            ratingId: Value(ratingId),
            orderIndex: i,
            name: adj.name,
            notes: Value(adj.notes),
            unit: Value(adj.unit),
            category: adj.category,
            type: adjType,
            jsonPayload: Value(jsonEncode(jsonMap)),
          ));
        }
      }

      for (final c in appData.components.values) {
        addAdjustments(c.adjustments, componentId: c.id);
      }
      for (final p in appData.persons.values) {
        addAdjustments(p.adjustments, personId: p.id);
      }
      for (final r in appData.ratings.values) {
        addAdjustments(r.adjustments, ratingId: r.id);
      }
      
      batch.insertAllOnConflictUpdate(db.adjustments, adjustmentsToInsert);

      // -----------------------------------------------------------------------
      // Level 3: Events
      // -----------------------------------------------------------------------

      // Strava Activities
      batch.insertAllOnConflictUpdate(db.stravaActivities, appData.stravaActivities.values.map((sa) => StravaActivitiesCompanion.insert(
        id: Value(sa.id),
        lastModified: sa.lastModified,
        name: sa.name,
        athlete: sa.athlete,
        sportType: sa.sportType,
        startDate: sa.startDate,
        startDateLocal: sa.startDateLocal,
        gearId: Value(sa.gearId),
        startLat: Value(sa.startLat),
        startLon: Value(sa.startLon),
        distance: Value(sa.distance),
        totalElevationGain: Value(sa.totalElevationGain),
        movingTime: sa.movingTime.inSeconds,
        elapsedTime: sa.elapsedTime.inSeconds,
      )));

      // Setups
      batch.insertAllOnConflictUpdate(db.setups, appData.setups.values.map((s) => SetupsCompanion.insert(
        id: s.id,
        bikeId: s.bike,
        personId: Value(s.person),
        isDeleted: Value(s.isDeleted),
        lastModified: s.lastModified,
        name: s.name,
        datetime: s.datetime,
        datetimeLocal: s.datetimeLocal,
        notes: Value(s.notes),
        tags: s.tags,
        position: Value(s.position),
        place: Value(s.place),
        weather: Value(s.weather),
      )));

      // -----------------------------------------------------------------------
      // Level 4: Junctions
      // -----------------------------------------------------------------------

      // Setup Adjustment Values
      final List<SetupAdjustmentValuesCompanion> valuesToInsert = [];
      for (final setup in appData.setups.values) {
        // Bike adjustments
        for (final entry in setup.bikeAdjustmentValues.entries) {
          valuesToInsert.add(SetupAdjustmentValuesCompanion.insert(
            setupId: setup.id,
            adjustmentId: entry.key,
            value: entry.value.toString(),
          ));
        }
        // Person adjustments
        for (final entry in setup.personAdjustmentValues.entries) {
          valuesToInsert.add(SetupAdjustmentValuesCompanion.insert(
            setupId: setup.id,
            adjustmentId: entry.key,
            value: entry.value.toString(),
          ));
        }
        // Rating adjustments
        for (final entry in setup.ratingAdjustmentValues.entries) {
          valuesToInsert.add(SetupAdjustmentValuesCompanion.insert(
            setupId: setup.id,
            adjustmentId: entry.key,
            value: entry.value.toString(),
          ));
        }
      }
      
      batch.insertAllOnConflictUpdate(db.setupAdjustmentValues, valuesToInsert);
    });
  }
}
