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
  final List<Setup> _setups = [];
  final List<Component> _components = [];
  final Map<String, Rating> _ratings = {};

  Bike? _selectedBike;

  Map<String, Bike> _filteredBikes = {};
  Map<String, Person> _filteredPersons = {};
  Map<String, Rating> _filteredRatings = {};
  List<Component> _filteredComponents = [];
  List<Setup> _filteredSetups = [];

  Map<String, Person> get persons => _persons;
  Map<String, Bike> get bikes => _bikes;
  List<Setup> get setups => _setups;
  List<Component> get components => _components;
  Map<String, Rating> get ratings => _ratings;

  Bike? get selectedBike => _selectedBike;

  Map<String, Bike> get filteredBikes => _filteredBikes;
  Map<String, Person> get filteredPersons => _filteredPersons;
  Map<String, Rating> get filteredRatings => _filteredRatings;
  List<Component> get filteredComponents => _filteredComponents;
  List<Setup> get filteredSetups => _filteredSetups;

  Future<AppData?> load(BuildContext context) async {
    String jsonString = "{}";
    try {
      final prefs = await SharedPreferences.getInstance();
      jsonString = prefs.getString("data") ?? "{}";
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      _clear();
      addJson(data: this, json: jsonData);

      _setups.sort((a, b) => a.datetime.compareTo(b.datetime));
      FileImport.determineCurrentSetups(setups: _setups, bikes: _bikes);
      FileImport.determinePreviousSetups(setups: _setups);

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
    'setups': setups.map((s) => s.toJson()).toList(),
    'components': components.map((c) => c.toJson()).toList(),
    'ratings': ratings.values.map((r) => r.toJson()).toList(),
  };

  static AppData addJson({required AppData data, required Map<String, dynamic> json}) {
    final loadedPersons = (json['persons'] as List<dynamic>? ?? [])
        .map((a) => Person.fromJson(a))
        .toList();
    
    final loadedBikes = (json['bikes'] as List<dynamic>? ?? [])
        .map((a) => Bike.fromJson(a))
        .toList();

    final loadedComponents = (json['components'] as List<dynamic>? ?? [])
        .map((c) => Component.fromJson(json: c))
        .toList();
    
    final loadedSetups = (json['setups'] as List<dynamic>? ?? [])
        .map((s) => Setup.fromJson(json: s))
        .toList();
    
    final loadedRatings = (json['ratings'] as List<dynamic>? ?? [])
        .map((a) => Rating.fromJson(json: a))
        .toList();
    
    data.persons.addAll(<String, Person>{for (var item in loadedPersons) item.id: item});
    data.bikes.addAll(<String, Bike>{for (var item in loadedBikes) item.id: item});
    data.components.addAll(loadedComponents);
    data.setups.addAll(loadedSetups);
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
        ? components.where((c) => !c.isDeleted).toList()
        : components.where((c) => !c.isDeleted && c.bike == selectedBike?.id).toList();
  }

  void _filterSetups() {
    _filteredSetups = selectedBike == null
        ? setups.where((s) => !s.isDeleted).toList()
        : setups.where((s) => !s.isDeleted && s.bike == selectedBike?.id).toList();
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
    FileImport.determineCurrentSetups(setups: _setups, bikes: _bikes);
    FileImport.determinePreviousSetups(setups: _setups);
    _filterSetups();

    notifyListeners();
  }

  void restoreSetups(Iterable<Setup> setups) {
    for (var setup in setups) {
      setup.isDeleted = false;
      setup.lastModified = DateTime.now();
    }
    _setups.sort((a, b) => a.datetime.compareTo(b.datetime)); // not really necessary
    FileImport.determineCurrentSetups(setups: _setups, bikes: _bikes);
    FileImport.determinePreviousSetups(setups: _setups);
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

    _selectedBike = null;
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
    _components.add(component);
    _filterComponents();
    
    notifyListeners();
  }

  void editComponent({required Component oldComponent, required Component newComponent}) {
    final index = _components.indexOf(oldComponent);
    if (index != -1) {
      _components[index] = newComponent;
    }
    _filterComponents();

    notifyListeners();
  }

  void addSetup(Setup setup) {
    _setups.add(setup);
    _setups.sort((a, b) => a.datetime.compareTo(b.datetime));
    FileImport.determineCurrentSetups(setups: _setups, bikes: _bikes);
    FileImport.determinePreviousSetups(setups: _setups);
    FileImport.updateSetupsAfter(setups: _setups, setup: setup);
    _filterSetups();

    notifyListeners();
  }

  void editSetup({required Setup oldSetup, required Setup newSetup}) {
    final index = _setups.indexOf(oldSetup);
    if (index != -1) _setups[index] = newSetup;
    _setups.sort((a, b) => a.datetime.compareTo(b.datetime));
    FileImport.determineCurrentSetups(setups: _setups, bikes: _bikes);
    FileImport.determinePreviousSetups(setups: _setups);
    FileImport.updateSetupsAfter(setups: _setups, setup: newSetup);
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
    final componentToMove = filteredComponents[oldIndex];
    oldIndex = components.indexOf(componentToMove);
    final targetComponent = newIndex < filteredComponents.length
        ? filteredComponents[newIndex]
        : null;
    newIndex = targetComponent == null
        ? components.length 
        : components.indexOf(targetComponent);

    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    final component = components.removeAt(oldIndex);
    components.insert(adjustedNewIndex, component);
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
    _setups.sort((a, b) => a.datetime.compareTo(b.datetime));
    FileImport.determineCurrentSetups(setups: _setups, bikes: _bikes);
    FileImport.determinePreviousSetups(setups: _setups);
    for (final setup in _setups) {
      FileImport.updateSetupsAfter(setups: _setups, setup: setup);
    }
    _filter();

    notifyListeners();
  }
}
