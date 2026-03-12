import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/file_export.dart';
import 'package:uuid/uuid.dart';
import 'person.dart';
import 'bike.dart';
import 'setup.dart';
import 'component.dart';
import 'rating.dart';
import 'todo_rule.dart';
import 'todo_entry.dart';
import 'strava/strava_activity.dart';
import 'strava/strava_gear.dart';
import 'strava/strava_athlete.dart';
import '../database/app_database.dart';
import '../database/mappers.dart';
import 'dart:async';
import 'selected_data.dart';

class AppData extends ChangeNotifier {
  final AppDatabase database;
  
  AppData(this.database);

  DateTime _lastModified = DateTime.now().toUtc();
  DateTime get lastModified => _lastModified;

  Future<void> initialize() async {
    FileExport.deleteOldBackups();
    notifyListeners();
  }

  Future<SelectedData?> loadLegacyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString("data") ?? "{}";
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return SelectedData.fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }

  Future<void> removeBike(Bike bike) async {
    await database.bikesDao.deleteBike(bike.id);
  }

  Future<void> restoreBike(Bike bike) async {
    final updated = bike.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
    await database.bikesDao.updateBike(updated.toCompanion());
  }

  Future<void> removeComponents(Iterable<Component> components) async {
    for (var component in components) {
      await database.componentsDao.deleteComponent(component.id);
    }
  }

  Future<void> restoreComponents(Iterable<Component> components) async {
    for (var component in components) {
      final updated = component.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
      await database.componentsDao.updateComponent(updated.toCompanion());
    }
  }

  Future<void> removeSetups(Iterable<Setup> setups) async {
    for (var setup in setups) {
      await database.setupsDao.deleteSetup(setup.id);
    }
  }

  Future<void> restoreSetups(Iterable<Setup> setups) async {
    for (var setup in setups) {
      final updated = setup.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
      await database.setupsDao.updateSetupWithValues(
        setup: updated.toCompanion(),
        bikeValues: updated.bikeAdjustmentValues, 
        personValues: updated.personAdjustmentValues, 
        ratingValues: updated.ratingAdjustmentValues
      );
    }
  }

  Future<void> removePerson(Person person) async {
    await database.personsDao.deletePerson(person.id);
  }

  Future<void> restorePerson(Person person) async {
    final updated = person.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
    await database.personsDao.updatePerson(updated.toCompanion());
  }

  Future<void> removeRatings(Iterable<Rating> ratings) async {
    for (var rating in ratings) {
      await database.ratingsDao.deleteRating(rating.id);
    }
  }

  Future<void> restoreRatings(Iterable<Rating> ratings) async {
    for (var rating in ratings) {
      final updated = rating.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
      await database.ratingsDao.updateRating(updated.toCompanion());
    }
  }

  Future<void> removeTodoRules(Iterable<TodoRule> rules) async {
    for (var rule in rules) {
      await database.todoDao.deleteRule(rule.id);
    }
  }

  Future<void> restoreTodoRules(Iterable<TodoRule> rules) async {
    for (var rule in rules) {
      final updated = rule.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
      await database.todoDao.updateRule(updated.toCompanion());
    }
  }

  Future<void> removeTodoEntries(Iterable<TodoEntry> entries) async {
    for (var entry in entries) {
      await database.todoDao.deleteEntry(entry.id);
    }
  }

  Future<void> restoreTodoEntries(Iterable<TodoEntry> entries) async {
    for (var entry in entries) {
      final updated = entry.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
      await database.todoDao.updateEntry(updated.toCompanion());
    }
  }

  Future<void> addBike(Bike bike) async {
    final updated = bike.copyWith(lastModified: DateTime.now().toUtc());
    await database.bikesDao.insertBike(updated.toCompanion());
  }

  Future<void> addPerson(Person person) async {
    final updated = person.copyWith(lastModified: DateTime.now().toUtc());
    await database.personsDao.insertPersonWithData(
      person: updated.toCompanion(),
      adjustmentsList: updated.adjustments.asMap().entries.map((entry) => 
        entry.value.toCompanion(personId: updated.id, orderIndex: entry.key)
      ).toList(),
    );
  }

  Future<void> addRating(Rating rating) async {
    final updated = rating.copyWith(lastModified: DateTime.now().toUtc());
    await database.ratingsDao.insertRatingWithData(
      rating: updated.toCompanion(),
      adjustmentsList: updated.adjustments.asMap().entries.map((entry) => 
        entry.value.toCompanion(ratingId: updated.id, orderIndex: entry.key)
      ).toList(),
    );
  }

  Future<void> addTodoRule(TodoRule rule) async {
    final updated = rule.copyWith(lastModified: DateTime.now().toUtc());
    await database.todoDao.insertRule(updated.toCompanion());
  }

  Future<void> editTodoRule(TodoRule rule) async {
    final updated = rule.copyWith(lastModified: DateTime.now().toUtc());
    await database.todoDao.updateRule(updated.toCompanion());
  }

  Future<void> addTodoEntry(TodoEntry entry) async {
    final updated = entry.copyWith(lastModified: DateTime.now().toUtc());
    await database.todoDao.insertEntry(updated.toCompanion());
  }

  Future<void> editTodoEntry(TodoEntry entry) async {
    final updated = entry.copyWith(lastModified: DateTime.now().toUtc());
    await database.todoDao.updateEntry(updated.toCompanion());
  }

  Future<void> addComponent(Component component) async {
    final updated = component.copyWith(lastModified: DateTime.now().toUtc());
    await database.componentsDao.insertComponentWithData(
      component: updated.toCompanion(),
      adjustmentsList: updated.adjustments.asMap().entries.map((entry) => 
        entry.value.toCompanion(componentId: updated.id, orderIndex: entry.key)
      ).toList(),
      installationsList: updated.installations.map((inst) => 
        inst.toCompanion(id: const Uuid().v4(), componentId: updated.id)
      ).toList(),
    );
  }

  Future<void> editPerson(Person person) async {
    final updated = person.copyWith(lastModified: DateTime.now().toUtc());
    await database.personsDao.updatePersonWithData(
      person: updated.toCompanion(),
      adjustmentsList: updated.adjustments.asMap().entries.map((entry) => 
        entry.value.toCompanion(personId: updated.id, orderIndex: entry.key)
      ).toList(),
    );
  }

  Future<void> editBike(Bike bike) async {
    final updated = bike.copyWith(lastModified: DateTime.now().toUtc());
    await database.bikesDao.updateBike(updated.toCompanion());
  }

  Future<void> editComponent(Component component) async {
    final updated = component.copyWith(lastModified: DateTime.now().toUtc());
    await database.componentsDao.updateComponentWithData(
      component: updated.toCompanion(),
      adjustmentsList: updated.adjustments.asMap().entries.map((entry) => 
        entry.value.toCompanion(componentId: updated.id, orderIndex: entry.key)
      ).toList(),
      installationsList: updated.installations.map((inst) => 
        inst.toCompanion(id: const Uuid().v4(), componentId: updated.id)
      ).toList(),
    );
  }

  Future<void> editRating(Rating rating) async {
    final updated = rating.copyWith(lastModified: DateTime.now().toUtc());
    await database.ratingsDao.updateRatingWithData(
      rating: updated.toCompanion(),
      adjustmentsList: updated.adjustments.asMap().entries.map((entry) => 
        entry.value.toCompanion(ratingId: updated.id, orderIndex: entry.key)
      ).toList(),
    );
  }

  Future<void> addSetup(Setup setup) async {
    final updated = setup.copyWith(lastModified: DateTime.now().toUtc());
    await database.setupsDao.insertSetupWithValues(
      setup: updated.toCompanion(), 
      bikeValues: updated.bikeAdjustmentValues, 
      personValues: updated.personAdjustmentValues, 
      ratingValues: updated.ratingAdjustmentValues
    );
  }

  Future<void> editSetup(Setup setup) async {
    final updated = setup.copyWith(lastModified: DateTime.now().toUtc());
    await database.setupsDao.updateSetupWithValues(
      setup: updated.toCompanion(),
      bikeValues: setup.bikeAdjustmentValues, 
      personValues: setup.personAdjustmentValues, 
      ratingValues: setup.ratingAdjustmentValues
    );
  }

  Future<void> reorderRating({required int oldIndex, required int newIndex, required List<Rating> filteredRatingsList}) async {}

  Future<void> reorderPerson({required int oldIndex, required int newIndex, required List<Person> filteredPersonsList}) async {}

  Future<void> reorderComponent({required int oldIndex, required int newIndex, required List<Component> filteredComponentsList, bool adjustNewIndex = true}) async {}

  Future<void> reorderBike({required int oldIndex, required int newIndex, required List<Bike> filteredBikesList}) async {}

  Future<void> setStravaActivities(Iterable<StravaActivity> activities) async {
    for (var a in activities) {
      await database.stravaDao.upsertActivity(a.toCompanion());
    }
    
    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  Future<void> setStravaAthletes(Iterable<StravaAthlete> athletes) async {
    for (var a in athletes) {
      await database.stravaDao.upsertAthlete(a.toCompanion());
    }
    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  Future<void> setStravaGears(Iterable<StravaGear> gears) async {
    for (var g in gears) {
      await database.stravaDao.upsertGear(g.toCompanion());
    }
    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }
  
  Future<void> clearStravaData() async {
    await database.delete(database.stravaActivities).go();
    await database.delete(database.stravaAthletes).go();
    await database.delete(database.stravaGears).go();

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }
}
