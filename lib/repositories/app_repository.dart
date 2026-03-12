import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/mappers.dart';

import '../models/bike.dart';
import '../models/component.dart';
import '../models/person.dart';
import '../models/setup.dart';
import '../models/rating.dart';
import '../models/todo_rule.dart';
import '../models/todo_entry.dart';
import '../models/strava/strava_activity.dart';
import '../models/strava/strava_athlete.dart';
import '../models/strava/strava_gear.dart';
import '../models/selected_data.dart';

import '../services/setup_resolution_service.dart';
import '../utils/file_export.dart';

class AppRepository extends ChangeNotifier {
  final AppDatabase database;
  final List<StreamSubscription> _subscriptions = [];

  // ---------------------------------------------------------------------------
  // RAW STATE FROM DB (Read-Only Cache for immediate access)
  // ---------------------------------------------------------------------------
  Map<String, Person> _persons = {};
  Map<String, Bike> _bikes = {};
  Map<String, Setup> _setups = {};
  Map<String, Component> _components = {};
  Map<String, Rating> _ratings = {};
  Map<String, TodoRule> _todoRules = {};
  Map<String, TodoEntry> _todoEntries = {};
  Map<int, StravaAthlete> _stravaAthletes = {};
  Map<int, StravaActivity> _stravaActivities = {};
  Map<String, StravaGear> _stravaGears = {};

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

  DateTime get lastModified {
    final allDates = [
      ..._persons.values.map((p) => p.lastModified),
      ..._bikes.values.map((b) => b.lastModified),
      ..._setups.values.map((s) => s.lastModified),
      ..._components.values.map((c) => c.lastModified),
      ..._ratings.values.map((r) => r.lastModified),
      ..._todoRules.values.map((tr) => tr.lastModified),
      ..._todoEntries.values.map((te) => te.lastModified),
    ].whereType<DateTime>();

    if (allDates.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    return allDates.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  // ---------------------------------------------------------------------------

  // FILTERING STATE
  // ---------------------------------------------------------------------------
  String? _selectedBike;
  final Set<String> _selectedSetupTags = {};
  Set<String> _setupTags = {};

  String? get selectedBike => _selectedBike;
  Set<String> get selectedSetupTags => _selectedSetupTags;
  Set<String> get setupTags => _setupTags;

  Map<String, Bike> _filteredBikes = {};
  Map<String, Person> _filteredPersons = {};
  Map<String, Rating> _filteredRatings = {};
  Map<String, Component> _filteredComponents = {};
  Map<String, Setup> _filteredSetups = {};
  Map<String, TodoRule> _filteredTodoRules = {};
  Map<String, TodoEntry> _filteredTodoEntries = {};
  Map<int, StravaActivity> _filteredStravaActivities = {};

  Map<String, Bike> get filteredBikes => _filteredBikes;
  Map<String, Person> get filteredPersons => _filteredPersons;
  Map<String, Rating> get filteredRatings => _filteredRatings;
  Map<String, Component> get filteredComponents => _filteredComponents;
  Map<String, Setup> get filteredSetups => _filteredSetups;
  Map<String, TodoRule> get filteredTodoRules => _filteredTodoRules;
  Map<String, TodoEntry> get filteredTodoEntries => _filteredTodoEntries;
  Map<int, StravaActivity> get filteredStravaActivities => _filteredStravaActivities;

  // ---------------------------------------------------------------------------
  // DELETED ITEMS (for TrashPage)
  // ---------------------------------------------------------------------------
  List<Person> _deletedPersons = [];
  List<Bike> _deletedBikes = [];
  List<Component> _deletedComponents = [];
  List<Setup> _deletedSetups = [];
  List<Rating> _deletedRatings = [];

  List<Person> get deletedPersons => _deletedPersons;
  List<Bike> get deletedBikes => _deletedBikes;
  List<Component> get deletedComponents => _deletedComponents;
  List<Setup> get deletedSetups => _deletedSetups;
  List<Rating> get deletedRatings => _deletedRatings;

  // ---------------------------------------------------------------------------
  // INITIALIZATION AND STREAMS
  // ---------------------------------------------------------------------------

  AppRepository(this.database) {
    _initStreams();
  }

  Future<void> initialize() async {
    FileExport.deleteOldBackups();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  void _initStreams() {
    _subscriptions.add(database.bikesDao.watchAllBikes().listen((list) {
      _bikes = {for (var b in list) b.id: b.toModel()};
      _dataChanged();
    }));

    _subscriptions.add(database.componentsDao.watchAllComponentsWithData().listen((list) {
      _components = {for (var c in list) c.component.id: c.component.toModel(
        adjustments: c.adjustments.map((a) => a.toModel()).toList(),
        installations: c.installations.map((i) => i.toModel()).toList(),
      )};
      _dataChanged();
    }));

    _subscriptions.add(database.personsDao.watchAllPersonsWithData().listen((list) {
      _persons = {for (var p in list) p.person.id: p.person.toModel(
        adjustments: p.adjustments.map((a) => a.toModel()).toList(),
      )};
      _dataChanged();
    }));

    _subscriptions.add(database.ratingsDao.watchAllRatingsWithData().listen((list) {
      _ratings = {for (var r in list) r.rating.id: r.rating.toModel(
        adjustments: r.adjustments.map((a) => a.toModel()).toList(),
      )};
      _dataChanged();
    }));

    _subscriptions.add(database.todoDao.watchAllRules().listen((list) {
      _todoRules = {for (var r in list) r.id: r.toModel()};
      _dataChanged();
    }));

    _subscriptions.add(database.todoDao.watchAllEntries().listen((list) {
      _todoEntries = {for (var e in list) e.id: e.toModel()};
      _dataChanged();
    }));

    _subscriptions.add(database.stravaDao.watchAllAthletes().listen((list) {
      _stravaAthletes = {for (var a in list) a.id: a.toModel()};
      _dataChanged();
    }));

    _subscriptions.add(database.stravaDao.watchAllActivities().listen((list) {
      _stravaActivities = {for (var a in list) a.id: a.toModel()};
      _dataChanged();
    }));

    _subscriptions.add(database.stravaDao.watchAllGears().listen((list) {
      _stravaGears = {for (var g in list) g.id: g.toModel()};
      _dataChanged();
    }));
    
    _subscriptions.add(database.setupsDao.watchAllSetupsWithValues().listen((list) {
      _setups = {for (var s in list) s.setup.id: s.setup.toModel(values: s.values)};
      _dataChanged();
    }));

    // Deleted item streams
    _subscriptions.add(database.bikesDao.watchDeletedBikes().listen((list) {
      _deletedBikes = list.map((b) => b.toModel()).toList();
      _notifyIfActive();
    }));
    _subscriptions.add(database.componentsDao.watchDeletedComponents().listen((list) {
      _deletedComponents = list.map((c) => c.toModel(adjustments: [], installations: [])).toList();
      _notifyIfActive();
    }));
    _subscriptions.add(database.setupsDao.watchDeletedSetups().listen((list) {
      _deletedSetups = list.map((s) => s.toModel(values: [])).toList();
      _notifyIfActive();
    }));
    _subscriptions.add(database.personsDao.watchDeletedPersons().listen((list) {
      _deletedPersons = list.map((p) => p.toModel(adjustments: [])).toList();
      _notifyIfActive();
    }));
    _subscriptions.add(database.ratingsDao.watchDeletedRatings().listen((list) {
      _deletedRatings = list.map((r) => r.toModel(adjustments: [])).toList();
      _notifyIfActive();
    }));
  }

  void _notifyIfActive() {
    if (hasListeners) {
      notifyListeners();
    }
  }

  void _dataChanged() {
    _resolveData();
    _filter();
    notifyListeners();
  }

  void _resolveData() {
    _setups = SetupResolutionService.resolveSetups(
      setups: _setups,
      bikes: _bikes,
      persons: _persons,
    );
    _setupTags = SetupResolutionService.extractAllTags(_setups.values);
  }

  void filter() {
    _filter();
    notifyListeners();
  }

  void _filter() {
    if (selectedBike != null && !bikes.containsKey(_selectedBike!)) {
      _selectedBike = null;
    }
    _selectedSetupTags.removeWhere((tag) => !setupTags.contains(tag));

    _filterBikes();
    _filterComponents();
    _filterSetups();
    _filterPersons();
    _filterRatings();
    _filterTodoRules();
    _filterTodoEntries();
    _filterStravaActivities();
  }

  void _filterBikes() {
    _filteredBikes = selectedBike == null 
        ? bikes
        : Map.fromEntries(bikes.entries.where((entry) => entry.key == selectedBike));
  }

  void _filterComponents() {
    _filteredComponents = selectedBike == null
        ? components
        : Map.fromEntries(components.entries.where((entry) => entry.value.bike == selectedBike));
  }

  void _filterSetups() {
    _filteredSetups = Map.fromEntries(setups.entries.where((entry) => 
      (selectedBike == null ? true : entry.value.bike == selectedBike) && 
      (selectedSetupTags.isEmpty ? true : entry.value.tags.containsAll(selectedSetupTags))
    ));
  }

  void _filterPersons() {
    _filteredPersons = _selectedBike == null 
        ? persons
        : Map.fromEntries(persons.entries.where((entry) => entry.value.id == bikes[_selectedBike]?.person));
  }

  void _filterRatings() {
    _filteredRatings = Map.fromEntries(ratings.entries.where((entry) {
      final rating = entry.value;
      switch (rating.filterType) {
        case FilterType.global: return true;
        case FilterType.person: return true;
        case FilterType.bike: return _selectedBike == null ? true : rating.filter == _selectedBike;
        case FilterType.component: return _selectedBike == null ? true : filteredComponents.values.any((c) => c.id == rating.filter);
        case FilterType.componentType: return _selectedBike == null ? true : filteredComponents.values.any((c) => c.componentType.toString() == rating.filter);
      }
    }));
  }

  void _filterTodoRules() {
    _filteredTodoRules = todoRules;
  }

  void _filterTodoEntries() {
    _filteredTodoEntries = todoEntries;
  }

  void _filterStravaActivities() {
    if (_selectedBike == null) {
      _filteredStravaActivities = stravaActivities;
      return;
    }
    final selectedStravaGear = bikes[_selectedBike]?.stravaGear;
    if (selectedStravaGear == null) {
      _filteredStravaActivities = stravaActivities;
      return;
    }

    _filteredStravaActivities = Map.fromEntries(stravaActivities.entries.where((entry) {
      return entry.value.gearId == selectedStravaGear;
    }));
  }

  void onBikeTap(String? newBike) {
    if (newBike == null || selectedBike == newBike) {
      _selectedBike = null;
    } else {
      _selectedBike = newBike;
    }
    _filter();
    notifyListeners();
  }

  void selectSetupTag(String newTag) {
    if (!setupTags.contains(newTag)) return;
    _selectedSetupTags.add(newTag);
    _filterSetups();
    notifyListeners();
  }

  void deselectSetupTag(String tag) {
    _selectedSetupTags.remove(tag);
    _filterSetups();
    notifyListeners();
  }

  void deselectAllSetupTags() {
    _selectedSetupTags.clear();
    _filterSetups();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // WRITE OPERATIONS
  // ---------------------------------------------------------------------------

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
  }

  Future<void> setStravaAthletes(Iterable<StravaAthlete> athletes) async {
    for (var a in athletes) {
      await database.stravaDao.upsertAthlete(a.toCompanion());
    }
  }

  Future<void> setStravaGears(Iterable<StravaGear> gears) async {
    for (var g in gears) {
      await database.stravaDao.upsertGear(g.toCompanion());
    }
  }
  
  Future<void> clearStravaData() async {
    await database.delete(database.stravaActivities).go();
    await database.delete(database.stravaAthletes).go();
    await database.delete(database.stravaGears).go();
  }
}
