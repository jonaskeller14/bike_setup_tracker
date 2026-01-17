import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'person.dart';
import 'bike.dart';
import 'setup.dart';
import 'component.dart';
import 'rating.dart';
import '../utils/file_import.dart';

class AppData extends ChangeNotifier {
  final Map<String, Person> _persons = {};
  final Map<String, Bike> _bikes = {};
  final Map<String, Setup> _setups = {};
  final Map<String, Component> _components = {};
  final Map<String, Rating> _ratings = {};

  Bike? _selectedBike;

  Map<String, Bike> _filteredBikes = {};
  Map<String, Person> _filteredPersons = {};
  Map<String, Rating> _filteredRatings = {};
  Map<String, Component> _filteredComponents = {};
  Map<String, Setup> _filteredSetups = {};

  Map<String, Person> get persons => _persons;
  Map<String, Bike> get bikes => _bikes;
  Map<String, Setup> get setups => _setups;
  Map<String, Component> get components => _components;
  Map<String, Rating> get ratings => _ratings;

  Bike? get selectedBike => _selectedBike;

  Map<String, Bike> get filteredBikes => _filteredBikes;
  Map<String, Person> get filteredPersons => _filteredPersons;
  Map<String, Rating> get filteredRatings => _filteredRatings;
  Map<String, Component> get filteredComponents => _filteredComponents;
  Map<String, Setup> get filteredSetups => _filteredSetups;

  Future<AppData?> load(BuildContext context) async {
    String jsonString = "{}";
    try {
      final prefs = await SharedPreferences.getInstance();
      jsonString = prefs.getString("data") ?? "{}";
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      _clear();
      addJson(data: this, json: jsonData);

      final sortedSetupEntries = _setups.entries.toList();
      sortedSetupEntries.sort((a, b) => a.value.datetime.compareTo(b.value.datetime));
      _setups.clear();
      _setups.addEntries(sortedSetupEntries);
      FileImport.determineCurrentSetups(setups: _setups.values.toList(), bikes: _bikes);
      FileImport.determinePreviousSetups(setups: _setups.values);

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

    _selectedBike = null;
    _filter();
  }

  Map<String, dynamic> toJson() => {
    'persons': persons.values.map((p) => p.toJson()).toList(),
    'bikes': bikes.values.map((b) => b.toJson()).toList(),
    'setups': setups.values.map((s) => s.toJson()).toList(),
    'components': components.values.map((c) => c.toJson()).toList(),
    'ratings': ratings.values.map((r) => r.toJson()).toList(),
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
    
    data.persons.addAll(<String, Person>{for (var item in loadedPersons) item.id: item});
    data.bikes.addAll(<String, Bike>{for (var item in loadedBikes) item.id: item});
    data.components.addAll(<String, Component>{for (var item in loadedComponents) item.id: item});
    data.setups.addAll(<String, Setup>{for (var item in loadedSetups) item.id: item});
    data.ratings.addAll(<String, Rating>{for (var item in loadedRatings) item.id: item});
    
    data.notifyListeners(); // not strictly necessary in most cases
    return data;
  }

  void filter() {
    _filter();
    notifyListeners();
  }

  void _filter() {
    _filterBikes();
    _filterComponents();
    _filterSetups();
    _filterPersons();
    _filterRatings();
  }

  void _filterBikes() {
    _filteredBikes = selectedBike == null 
        ? Map.fromEntries(bikes.entries.where((entry) => !entry.value.isDeleted))
        : Map.fromEntries(bikes.entries.where((entry) => !entry.value.isDeleted && entry.value == selectedBike));
  }

  void filterComponents() {
    _filterComponents();
    notifyListeners();
  }

  void _filterComponents() {
    _filteredComponents = selectedBike == null
        ? Map.fromEntries(components.entries.where((entry) => !entry.value.isDeleted))
        : Map.fromEntries(components.entries.where((entry) => !entry.value.isDeleted && entry.value.bike == selectedBike?.id));
  }

  void _filterSetups() {
    _filteredSetups = selectedBike == null
        ? Map.fromEntries(setups.entries.where((entry) => !entry.value.isDeleted))
        : Map.fromEntries(setups.entries.where((entry) => !entry.value.isDeleted && entry.value.bike == selectedBike?.id));
  }

  void _filterPersons() {
    _filteredPersons = Map.fromEntries(persons.entries.where((entry) => !entry.value.isDeleted));
  }

  void _filterRatings() {
    _filteredRatings = Map.fromEntries(ratings.entries.where((entry) => !entry.value.isDeleted));
  }
  
  void onBikeTap(Bike? newBike) {
    if (newBike == null || selectedBike == newBike) {
      _selectedBike = null;
    } else {
      _selectedBike = newBike;
    }
    _filter();
    notifyListeners();
  }

  void removeBike(Bike bike) {
    bike.isDeleted = true;
    bike.lastModified = DateTime.now();
    if (bike == selectedBike) {
      onBikeTap(null);  //_filterBikes(); included
    } else {
      _filterBikes();
    }
    
    notifyListeners();
  }

  void restoreBike(Bike bike) {
    bike.isDeleted = false;
    bike.lastModified = DateTime.now();
    _filterBikes();

    notifyListeners();
  }

  void removeComponents(Iterable<Component> components) {
    for (var component in components) {
      component.isDeleted = true;
      component.lastModified = DateTime.now();
    }
    _filterComponents();

    notifyListeners();
  }

  void restoreComponents(Iterable<Component> components) {
    for (var component in components) {
      component.isDeleted = false;
      component.lastModified = DateTime.now();
    }
    _filterComponents();

    notifyListeners();
  }

  void removeSetups(Iterable<Setup> setups) {
    for (var setup in setups) {
      setup.isDeleted = true;
      setup.lastModified = DateTime.now();
    }
    FileImport.determineCurrentSetups(setups: _setups.values.toList(), bikes: _bikes);
    FileImport.determinePreviousSetups(setups: _setups.values);
    _filterSetups();

    notifyListeners();
  }

  void restoreSetups(Iterable<Setup> setups) {
    for (var setup in setups) {
      setup.isDeleted = false;
      setup.lastModified = DateTime.now();
    }
    final sortedSetupEntries = _setups.entries.toList();
    sortedSetupEntries.sort((a, b) => a.value.datetime.compareTo(b.value.datetime));
    _setups.clear();
    _setups.addEntries(sortedSetupEntries); // not really necessary
    FileImport.determineCurrentSetups(setups: _setups.values.toList(), bikes: _bikes);
    FileImport.determinePreviousSetups(setups: _setups.values);
    _filterSetups();
    
    notifyListeners();
  }

  void removePerson(Person person) {
    person.isDeleted = true;
    person.lastModified = DateTime.now();
    _filterPersons();

    notifyListeners();
  }

  void restorePerson(Person person) {
    person.isDeleted = false;
    person.lastModified = DateTime.now();
    _filterPersons();
    
    notifyListeners();
  }

  void removeRating(Rating rating) {
    rating.isDeleted = true;
    rating.lastModified = DateTime.now();
    _filterRatings();

    notifyListeners();
  }

  void restoreRating(Rating rating) {
    rating.isDeleted = false;
    rating.lastModified = DateTime.now();
    _filterRatings();

    notifyListeners();
  }

  void addBike(Bike bike) {
    _bikes[bike.id] = bike;

    _filter();

    notifyListeners();
  }

  void addPerson(Person person) {
    _persons[person.id] = person;
    _filterPersons();

    notifyListeners();
  }

  void addRating(Rating rating) {
    _ratings[rating.id] = rating;
    _filterRatings();
    
    notifyListeners();
  }

  void addComponent(Component component) {
    _components[component.id] = component;
    _filterComponents();
    
    notifyListeners();
  }

  void editPerson(Person person) {
    _persons[person.id] = person;
    _filterPersons();

    notifyListeners();
  }

  void editBike(Bike bike) {
    _bikes[bike.id] = bike;

    if (bike != selectedBike) _selectedBike = null;
    _filter();

    notifyListeners();
  }

  void editComponent(Component component) {
    _components[component.id] = component;
    
    _filterComponents();

    notifyListeners();
  }

  void editRating(Rating rating) {
    _ratings[rating.id] = rating;
    _filterRatings();
    
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
    FileImport.updateSetupsAfter(setups: _setups.values.toList(), setup: setup);
    _filterSetups();

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
    FileImport.updateSetupsAfter(setups: _setups.values.toList(), setup: setup);
    _filterSetups();
  
    notifyListeners();
  }

  void reorderRating(int oldIndex, int newIndex) {
    final ratingsList = ratings.values.toList();
    final filteredRatingsList = filteredRatings.values.toList();

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
    _filterRatings();
    
    notifyListeners();
  }

  void reorderPerson(int oldIndex, int newIndex) {
    final personsList = persons.values.toList();
    final filteredPersonsList = filteredPersons.values.toList();

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
    _filterPersons();

    notifyListeners();
  }

  void reorderComponent(int oldIndex, int newIndex) {
    final componentsList = components.values.toList();
    final filteredComponentsList = filteredComponents.values.toList();

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
    _filterComponents();

    notifyListeners();
  }

  void reorderBike(int oldIndex, int newIndex) {
    final bikesList = bikes.values.toList();
    final filteredBikesList = bikesList.where((b) => !b.isDeleted).toList();

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
    _filterBikes();

    notifyListeners();
  }

  void resolveData() {
    final sortedSetupEntries = _setups.entries.toList();
    sortedSetupEntries.sort((a, b) => a.value.datetime.compareTo(b.value.datetime));
    _setups.clear();
    _setups.addEntries(sortedSetupEntries);
    FileImport.determineCurrentSetups(setups: _setups.values.toList(), bikes: _bikes);
    FileImport.determinePreviousSetups(setups: _setups.values);
    for (final setup in _setups.values) {
      FileImport.updateSetupsAfter(setups: _setups.values.toList(), setup: setup);
    }
    _filter();

    notifyListeners();
  }
}
