import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/file_export.dart';
import 'adjustment/adjustment.dart';
import 'person.dart';
import 'bike.dart';
import 'setup.dart';
import 'component.dart';
import 'rating.dart';
import 'strava/strava_activity.dart';
import '../utils/file_import.dart';
import 'strava/strava_gear.dart';
import 'strava/strava_athlete.dart';

class AppData extends ChangeNotifier {
  DateTime _lastModified = DateTime.now().toUtc();
  final Map<String, Person> _persons = {};
  final Map<String, Bike> _bikes = {};
  final Map<String, Setup> _setups = {};
  final Map<String, Component> _components = {};
  final Map<String, Rating> _ratings = {};
  final Map<int, StravaAthlete> _stravaAthletes = {};
  final Map<int, StravaActivity> _stravaActivities = {};
  final Map<String, StravaGear> _stravaGears = {};

  DateTime get lastModified => _lastModified;
  Map<String, Person> get persons => _persons;
  Map<String, Bike> get bikes => _bikes;
  Map<String, Setup> get setups => _setups;
  Map<String, Component> get components => _components;
  Map<String, Rating> get ratings => _ratings;
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
    _setups.clear();
    _stravaActivities.clear();
  }

  Map<String, dynamic> toJson() => {
    'persons': persons.values.map((p) => p.toJson()).toList(),
    'bikes': bikes.values.map((b) => b.toJson()).toList(),
    'setups': setups.values.map((s) => s.toJson()).toList(),
    'components': components.values.map((c) => c.toJson()).toList(),
    'ratings': ratings.values.map((r) => r.toJson()).toList(),
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
    data._stravaAthletes.addAll(<int, StravaAthlete>{for (var item in loadedStravaAthletes) item.id: item});
    data._stravaGears.addAll(<String, StravaGear>{for (var item in loadedStravaGears) item.id: item});
    data.stravaActivities.addAll(<int, StravaActivity>{for (var item in loadedStravaActivities) item.id: item});
    
    return data;
  }

  void removeBike(Bike bike) {
    bike.isDeleted = true;
    bike.lastModified = DateTime.now().toUtc();
    
    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void restoreBike(Bike bike) {
    bike.isDeleted = false;
    bike.lastModified = DateTime.now().toUtc();

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void removeComponents(Iterable<Component> components) {
    for (var component in components) {
      component.isDeleted = true;
      component.lastModified = DateTime.now().toUtc();
    }

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void restoreComponents(Iterable<Component> components) {
    for (var component in components) {
      component.isDeleted = false;
      component.lastModified = DateTime.now().toUtc();
    }

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void removeSetups(Iterable<Setup> setups) {
    for (var setup in setups) {
      setup.isDeleted = true;
      setup.lastModified = DateTime.now().toUtc();
    }
    FileImport.determineCurrentSetups(setups: _setups.values.toList(), bikes: _bikes);
    FileImport.determinePreviousSetups(setups: _setups.values);

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void restoreSetups(Iterable<Setup> setups) {
    for (var setup in setups) {
      setup.isDeleted = false;
      setup.lastModified = DateTime.now().toUtc();
    }
    final sortedSetupEntries = _setups.entries.toList();
    sortedSetupEntries.sort((a, b) => a.value.datetime.compareTo(b.value.datetime));
    _setups.clear();
    _setups.addEntries(sortedSetupEntries); // not really necessary
    FileImport.determineCurrentSetups(setups: _setups.values.toList(), bikes: _bikes);
    FileImport.determinePreviousSetups(setups: _setups.values);
    
    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void removePerson(Person person) {
    person.isDeleted = true;
    person.lastModified = DateTime.now().toUtc();

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void restorePerson(Person person) {
    person.isDeleted = false;
    person.lastModified = DateTime.now().toUtc();
    
    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void removeRating(Rating rating) {
    rating.isDeleted = true;
    rating.lastModified = DateTime.now().toUtc();

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void restoreRating(Rating rating) {
    rating.isDeleted = false;
    rating.lastModified = DateTime.now().toUtc();

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void addBike(Bike bike) {
    _bikes[bike.id] = bike;

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void addPerson(Person person) {
    _persons[person.id] = person;

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void addRating(Rating rating) {
    _ratings[rating.id] = rating;
    
    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void addComponent(Component component) {
    _components[component.id] = component;
    
    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void editPerson(Person person) {
    _persons[person.id] = person;

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void editBike(Bike bike) {
    _bikes[bike.id] = bike;

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void editComponent(Component component) {
    _components[component.id] = component;

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void editRating(Rating rating) {
    _ratings[rating.id] = rating;
    
    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void addSetup(Setup setup) {
    _setups[setup.id] = setup;
    final sortedSetupEntries = _setups.entries.toList();
    sortedSetupEntries.sort((a, b) => a.value.datetime.compareTo(b.value.datetime));
    _setups.clear();
    _setups.addEntries(sortedSetupEntries);
    FileImport.determineCurrentSetups(setups: _setups.values.toList(), bikes: _bikes);
    FileImport.determinePreviousSetups(setups: _setups.values);
    _updateSetupsAfter(setup: setup);

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void editSetup(Setup setup) {
    _setups[setup.id] = setup;
    final sortedSetupEntries = _setups.entries.toList();
    sortedSetupEntries.sort((a, b) => a.value.datetime.compareTo(b.value.datetime));
    _setups.clear();
    _setups.addEntries(sortedSetupEntries);
    FileImport.determineCurrentSetups(setups: _setups.values.toList(), bikes: _bikes);
    FileImport.determinePreviousSetups(setups: _setups.values);
    _updateSetupsAfter(setup: setup);

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void reorderRating({required int oldIndex, required int newIndex, required List<Rating> filteredRatingsList}) {
    final ratingsList = ratings.values.toList();

    final ratingToMove = filteredRatingsList[oldIndex];
    oldIndex = ratingsList.indexOf(ratingToMove);
    final targetRating = newIndex < filteredRatingsList.length
        ? filteredRatingsList[newIndex]
        : null;
    newIndex = targetRating == null
        ? ratingsList.length 
        : ratingsList.indexOf(targetRating);

    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    final rating = ratingsList.removeAt(oldIndex);
    ratingsList.insert(adjustedNewIndex, rating);

    _ratings.clear();
    _ratings.addAll({for (var element in ratingsList) element.id : element});
    
    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void reorderPerson({required int oldIndex, required int newIndex, required List<Person> filteredPersonsList}) {
    final personsList = persons.values.toList();

    final personToMove = filteredPersonsList[oldIndex];
    oldIndex = personsList.indexOf(personToMove);
    final targetPerson = newIndex < filteredPersonsList.length
        ? filteredPersonsList[newIndex]
        : null;
    newIndex = targetPerson == null
        ? personsList.length 
        : personsList.indexOf(targetPerson);

    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    final person = personsList.removeAt(oldIndex);
    personsList.insert(adjustedNewIndex, person);

    _persons.clear();
    _persons.addAll({for (var element in personsList) element.id : element});

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void reorderComponent({required int oldIndex, required int newIndex, required List<Component> filteredComponentsList}) {
    final componentsList = components.values.toList();

    final componentToMove = filteredComponentsList[oldIndex];
    oldIndex = componentsList.indexOf(componentToMove);
    final targetComponent = newIndex < filteredComponentsList.length
        ? filteredComponentsList[newIndex]
        : null;
    newIndex = targetComponent == null
        ? componentsList.length 
        : componentsList.indexOf(targetComponent);

    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    final person = componentsList.removeAt(oldIndex);
    componentsList.insert(adjustedNewIndex, person);

    _components.clear();
    _components.addAll({for (var element in componentsList) element.id : element});

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void reorderBike({required int oldIndex, required int newIndex, required List<Bike> filteredBikesList}) {
    final bikesList = bikes.values.toList();

    final bikeToMove = filteredBikesList[oldIndex];
    oldIndex = bikesList.indexOf(bikeToMove);
    final targetBike = newIndex < filteredBikesList.length
        ? filteredBikesList[newIndex]
        : null;
    newIndex = targetBike == null
        ? bikes.length
        : bikesList.indexOf(targetBike);

    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    final bike = bikesList.removeAt(oldIndex);
    bikesList.insert(adjustedNewIndex, bike);

    _bikes.clear();
    _bikes.addAll({for (var element in bikesList) element.id : element});

    _lastModified = DateTime.now().toUtc();
    notifyListeners();
  }

  void _updateSetupsAfter({required Setup setup}) {
    // Call after sorting setups!
    // Handles case: New Component, New Setup with new component with date in the past
    // --> Solves Bug: component references current setup with missing values for new component
    final setupsList = _setups.values.toList();


    if (setup.isCurrent) return;
    final index = setupsList.indexOf(setup);
    if (index == -1) return;
    if (index == setupsList.length -1) return; // ==isCurrent
    final afterSetups = setupsList.sublist(index + 1);

    final afterBikeSetups = afterSetups.where((s) => s.bike == setup.bike);
    for (final adjustmentValue in setup.bikeAdjustmentValues.entries) {
      final adjustment = adjustmentValue.key;
      final value = adjustmentValue.value;
      for (final afterBikeSetup in afterBikeSetups) {
        if (afterBikeSetup.bikeAdjustmentValues.containsKey(adjustment)) continue;
        afterBikeSetup.bikeAdjustmentValues[adjustment] = value;
      }
    }

    final person = _persons[setup.person];
    if (person != null) {
      final afterPersonSetups = afterSetups.where((s) => s.person != null && s.person == setup.person);
      for (final adjustmentValue in setup.personAdjustmentValues.entries) {
        final adjustmentId = adjustmentValue.key;
        final Adjustment? adjustment = person.adjustments.firstWhereOrNull((a) => a.id == adjustmentId);
        switch (adjustment?.category) {
          case AdjustmentCategory.nutrition: continue;  // Not propagate
          case AdjustmentCategory.equipment: continue;  // Not propagate
          default: break;
        }
        final value = adjustmentValue.value;
        for (final afterPersonSetup in afterPersonSetups) {
          if (afterPersonSetup.personAdjustmentValues.containsKey(adjustmentId)) continue;
          afterPersonSetup.personAdjustmentValues[adjustmentId] = value;
        }
      }
    }
  }

  void resolveData() {
    final sortedSetupEntries = _setups.entries.toList();
    sortedSetupEntries.sort((a, b) => a.value.datetime.compareTo(b.value.datetime));
    _setups.clear();
    _setups.addEntries(sortedSetupEntries);
    FileImport.determineCurrentSetups(setups: _setups.values.toList(), bikes: _bikes);
    FileImport.determinePreviousSetups(setups: _setups.values);
    for (final setup in _setups.values) {
      _updateSetupsAfter(setup: setup);
    }


    notifyListeners();
  }

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
