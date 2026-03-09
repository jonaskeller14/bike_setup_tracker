import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/file_export.dart';
import 'person.dart';
import 'bike.dart';
import 'setup.dart';
import 'component.dart';
import 'rating.dart';
import 'todo_rule.dart';
import 'todo_entry.dart';
import 'strava/strava_activity.dart';
import '../utils/file_import.dart';
import 'strava/strava_gear.dart';
import 'strava/strava_athlete.dart';
import '../database/app_database.dart';
import '../database/mappers.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

class AppData extends ChangeNotifier {
  final AppDatabase database;
  
  AppData(this.database);

  DateTime _lastModified = DateTime.now().toUtc();
  final Map<String, Person> _persons = {};
  final Map<String, Bike> _bikes = {};
  final Map<String, Setup> _setups = {};
  final Map<String, Component> _components = {};
  final Map<String, Rating> _ratings = {};
  final Map<String, TodoRule> _todoRules = {};
  final Map<String, TodoEntry> _todoEntries = {};
  final Map<int, StravaAthlete> _stravaAthletes = {};
  final Map<int, StravaActivity> _stravaActivities = {};
  final Map<String, StravaGear> _stravaGears = {};

  DateTime get lastModified => _lastModified;
  Map<String, Person> get persons => _persons;
  Map<String, Bike> get bikes => _bikes;
  Map<String, Setup> get setups => _setups;
  Map<String, Component> get components => _components;
  Map<String, Rating> get ratings => _ratings;
  Map<String, TodoRule> get todoRules => _todoRules;
  Map<String, TodoEntry> get todoEntries => _todoEntries;
  Map<int, StravaAthlete> get stravaAthletes => _stravaAthletes;
  Map<int, StravaActivity> get stravaActivities => _stravaActivities;
  Map<String, StravaGear> get stravaGears => _stravaGears;

  Future<AppData?> load(BuildContext context) async {
    String jsonString = "{}";
    try {
      final prefs = await SharedPreferences.getInstance();
      jsonString = prefs.getString("data") ?? "{}";
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      _clear();
      addJson(data: this, json: jsonData);

      FileImport.cleanupIsDeleted(data: this);
      final sortedSetupEntries = _setups.entries.toList();
      sortedSetupEntries.sort((a, b) => a.value.datetime.compareTo(b.value.datetime));
      _setups.clear();
      _setups.addEntries(sortedSetupEntries);
      FileImport.determineCurrentSetups(setups: _setups.values.toList(), bikes: _bikes);
      FileImport.determinePreviousSetups(setups: _setups.values);
      
      FileExport.deleteOldBackups();

      notifyListeners();
      debugPrint("Loading data successfully");
      return this;
    } catch (e, st) {
      debugPrint("Loading data failed: $e\n$st");
      if (context.mounted) {
        await FileImport.saveErrorJson(context: context, jsonString: jsonString);
      }
      throw Exception("Loading data failed");
    }
  }

  void _clear() {
    _bikes.clear();
    _persons.clear();
    _components.clear();
    _ratings.clear();
    _todoRules.clear();
    _todoEntries.clear();
    _setups.clear();
    _stravaActivities.clear();
  }

  Map<String, dynamic> toJson() => {
    'persons': persons.values.map((p) => p.toJson()).toList(),
    'bikes': bikes.values.map((b) => b.toJson()).toList(),
    'setups': setups.values.map((s) => s.toJson()).toList(),
    'components': components.values.map((c) => c.toJson()).toList(),
    'ratings': ratings.values.map((r) => r.toJson()).toList(),
    'todoRules': todoRules.values.map((tr) => tr.toJson()).toList(),
    'todoEntries': todoEntries.values.map((te) => te.toJson()).toList(),
    'stravaAthletes': _stravaAthletes.values.map((a) => a.toJson()).toList(),
    'stravaGears': _stravaGears.values.map((g) => g.toJson()).toList(),
    'stravaActivities': stravaActivities.values.map((a) => a.toJson()).toList(),
  };

  static AppData addJson({required AppData data, required Map<String, dynamic> json}) {
    final loadedPersons = (json['persons'] as List<dynamic>? ?? [])
        .map((a) => Person.fromJson(a));
    
    final loadedBikes = (json['bikes'] as List<dynamic>? ?? [])
        .map((a) => Bike.fromJson(a));

    final loadedComponents = (json['components'] as List<dynamic>? ?? [])
        .map((c) => Component.fromJson(json: c));
    
    final loadedSetups = (json['setups'] as List<dynamic>? ?? [])
        .map((s) => Setup.fromJson(json: s));
    
    final loadedRatings = (json['ratings'] as List<dynamic>? ?? [])
        .map((a) => Rating.fromJson(json: a));
        
    final loadedTodoRules = (json['todoRules'] as List<dynamic>? ?? [])
        .map((a) => TodoRule.fromJson(a as Map<String, dynamic>));

    final loadedTodoEntries = (json['todoEntries'] as List<dynamic>? ?? [])
        .map((a) => TodoEntry.fromJson(a as Map<String, dynamic>));

    final loadedStravaAthletes = (json['stravaAthletes'] as List<dynamic>? ?? [])
        .map((a) => StravaAthlete.fromJson(a));

    final loadedStravaGears = (json['stravaGears'] as List<dynamic>? ?? [])
        .map((g) => StravaGear.fromJson(g));
    
    final loadedStravaActivities = (json['stravaActivities'] as List<dynamic>? ?? [])
        .map((a) => StravaActivity.fromJson(a));
    
    data.persons.addAll(<String, Person>{for (var item in loadedPersons) item.id: item});
    data.bikes.addAll(<String, Bike>{for (var item in loadedBikes) item.id: item});
    data.components.addAll(<String, Component>{for (var item in loadedComponents) item.id: item});
    data.setups.addAll(<String, Setup>{for (var item in loadedSetups) item.id: item});
    data.ratings.addAll(<String, Rating>{for (var item in loadedRatings) item.id: item});
    data.todoRules.addAll(<String, TodoRule>{for (var item in loadedTodoRules) item.id: item});
    data.todoEntries.addAll(<String, TodoEntry>{for (var item in loadedTodoEntries) item.id: item});
    data._stravaAthletes.addAll(<int, StravaAthlete>{for (var item in loadedStravaAthletes) item.id: item});
    data._stravaGears.addAll(<String, StravaGear>{for (var item in loadedStravaGears) item.id: item});
    data.stravaActivities.addAll(<int, StravaActivity>{for (var item in loadedStravaActivities) item.id: item});
    
    return data;
  }

  Future<void> removeBike(Bike bike) async {
    await database.bikesDao.deleteBike(bike.id);
  }

  Future<void> restoreBike(Bike bike) async {
    bike.isDeleted = false;
    bike.lastModified = DateTime.now().toUtc();
    await database.bikesDao.updateBike(bike.toCompanion());
  }

  Future<void> removeComponents(Iterable<Component> components) async {
    for (var component in components) {
      await database.componentsDao.deleteComponent(component.id);
    }
  }

  Future<void> restoreComponents(Iterable<Component> components) async {
    for (var component in components) {
      component.isDeleted = false;
      component.lastModified = DateTime.now().toUtc();
      await database.componentsDao.updateComponent(component.toCompanion());
    }
  }

  Future<void> removeSetups(Iterable<Setup> setups) async {
    for (var setup in setups) {
      await database.setupsDao.deleteSetup(setup.id);
    }
  }

  Future<void> restoreSetups(Iterable<Setup> setups) async {
    for (var setup in setups) {
      setup.isDeleted = false;
      setup.lastModified = DateTime.now().toUtc();
      await database.setupsDao.updateSetupWithValues(
        setup: setup.toCompanion(),
        bikeValues: setup.bikeAdjustmentValues, 
        personValues: setup.personAdjustmentValues, 
        ratingValues: setup.ratingAdjustmentValues
      );
    }
  }

  Future<void> removePerson(Person person) async {
    await database.personsDao.deletePerson(person.id);
  }

  Future<void> restorePerson(Person person) async {
    person.isDeleted = false;
    person.lastModified = DateTime.now().toUtc();
    await database.personsDao.updatePerson(person.toCompanion());
  }

  Future<void> removeRatings(Iterable<Rating> ratings) async {
    for (var rating in ratings) {
      await database.ratingsDao.deleteRating(rating.id);
    }
  }

  Future<void> restoreRatings(Iterable<Rating> ratings) async {
    for (var rating in ratings) {
      rating.isDeleted = false;
      rating.lastModified = DateTime.now().toUtc();
      await database.ratingsDao.updateRating(rating.toCompanion());
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
    bike.lastModified = DateTime.now().toUtc();
    await database.bikesDao.insertBike(bike.toCompanion());
  }

  Future<void> addPerson(Person person) async {
    person.lastModified = DateTime.now().toUtc();
    await database.personsDao.insertPersonWithData(
      person: person.toCompanion(),
      adjustmentsList: person.adjustments.asMap().entries.map((entry) => 
        entry.value.toCompanion(personId: person.id, orderIndex: entry.key)
      ).toList(),
    );
  }

  Future<void> addRating(Rating rating) async {
    rating.lastModified = DateTime.now().toUtc();
    await database.ratingsDao.insertRatingWithData(
      rating: rating.toCompanion(),
      adjustmentsList: rating.adjustments.asMap().entries.map((entry) => 
        entry.value.toCompanion(ratingId: rating.id, orderIndex: entry.key)
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
    component.lastModified = DateTime.now().toUtc();
    await database.componentsDao.insertComponentWithData(
      component: component.toCompanion(),
      adjustmentsList: component.adjustments.asMap().entries.map((entry) => 
        entry.value.toCompanion(componentId: component.id, orderIndex: entry.key)
      ).toList(),
      installationsList: component.installations.map((inst) => 
        inst.toCompanion(id: const Uuid().v4(), componentId: component.id)
      ).toList(),
    );
  }

  Future<void> editPerson(Person person) async {
    person.lastModified = DateTime.now().toUtc();
    await database.personsDao.updatePersonWithData(
      person: person.toCompanion(),
      adjustmentsList: person.adjustments.asMap().entries.map((entry) => 
        entry.value.toCompanion(personId: person.id, orderIndex: entry.key)
      ).toList(),
    );
  }

  Future<void> editBike(Bike bike) async {
    bike.lastModified = DateTime.now().toUtc();
    await database.bikesDao.updateBike(bike.toCompanion());
  }

  Future<void> editComponent(Component component) async {
    component.lastModified = DateTime.now().toUtc();
    await database.componentsDao.updateComponentWithData(
      component: component.toCompanion(),
      adjustmentsList: component.adjustments.asMap().entries.map((entry) => 
        entry.value.toCompanion(componentId: component.id, orderIndex: entry.key)
      ).toList(),
      installationsList: component.installations.map((inst) => 
        inst.toCompanion(id: const Uuid().v4(), componentId: component.id)
      ).toList(),
    );
  }

  Future<void> editRating(Rating rating) async {
    rating.lastModified = DateTime.now().toUtc();
    await database.ratingsDao.updateRatingWithData(
      rating: rating.toCompanion(),
      adjustmentsList: rating.adjustments.asMap().entries.map((entry) => 
        entry.value.toCompanion(ratingId: rating.id, orderIndex: entry.key)
      ).toList(),
    );
  }

  Future<void> addSetup(Setup setup) async {
    setup.lastModified = DateTime.now().toUtc();
    await database.setupsDao.insertSetupWithValues(
      setup: setup.toCompanion(), 
      bikeValues: setup.bikeAdjustmentValues, 
      personValues: setup.personAdjustmentValues, 
      ratingValues: setup.ratingAdjustmentValues
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



  void setStravaActivities(Iterable<StravaActivity> activities) {
    _stravaActivities.clear();
    _stravaActivities.addEntries(activities.map((a) => MapEntry(a.id, a)));
    
    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void setStravaAthletes(Iterable<StravaAthlete> athletes) {
    _stravaAthletes.clear();
    _stravaAthletes.addEntries(athletes.map((a) => MapEntry(a.id, a)));
    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void setStravaGears(Iterable<StravaGear> gears) {
    _stravaGears.clear();
    _stravaGears.addEntries(gears.map((g) => MapEntry(g.id, g)));
    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }
  
  void clearStravaData() {
    _stravaActivities.clear();
    _stravaAthletes.clear();
    _stravaGears.clear();

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }
}
