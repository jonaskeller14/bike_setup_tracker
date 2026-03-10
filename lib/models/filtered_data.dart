import 'dart:async';
import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../database/mappers.dart';
import 'bike.dart';
import 'component.dart';
import 'person.dart';
import 'setup.dart';
import 'rating.dart';
import 'todo_rule.dart';
import 'todo_entry.dart';
import 'strava/strava_activity.dart';
import 'strava/strava_athlete.dart';
import 'strava/strava_gear.dart';
import '../utils/file_import.dart';
import 'adjustment/adjustment.dart';
import 'package:collection/collection.dart';

class FilteredData extends ChangeNotifier {
  final AppDatabase database;
  final List<StreamSubscription> _subscriptions = [];

  // Raw Items from DB
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

  Set<String> _setupTags = {};
  Set<String> get setupTags => _setupTags;

  // Filtered Items
  String? _selectedBike;
  final Set<String> _selectedSetupTags = {}; 

  Map<String, Bike> _filteredBikes = {};
  Map<String, Person> _filteredPersons = {};
  Map<String, Rating> _filteredRatings = {};
  Map<String, Component> _filteredComponents = {};
  Map<String, Setup> _filteredSetups = {};
  Map<String, TodoRule> _filteredTodoRules = {};
  Map<String, TodoEntry> _filteredTodoEntries = {};
  Map<int, StravaActivity> _filteredStravaActivities = {};

  // Deleted Items (for TrashPage)
  List<Person> _deletedPersons = [];
  List<Bike> _deletedBikes = [];
  List<Component> _deletedComponents = [];
  List<Setup> _deletedSetups = [];
  List<Rating> _deletedRatings = [];

  String? get selectedBike => _selectedBike;
  Set<String> get selectedSetupTags => _selectedSetupTags;

  Map<String, Bike> get filteredBikes => _filteredBikes;
  Map<String, Person> get filteredPersons => _filteredPersons;
  Map<String, Rating> get filteredRatings => _filteredRatings;
  Map<String, Component> get filteredComponents => _filteredComponents;
  Map<String, Setup> get filteredSetups => _filteredSetups;
  Map<String, TodoRule> get filteredTodoRules => _filteredTodoRules;
  Map<String, TodoEntry> get filteredTodoEntries => _filteredTodoEntries;
  Map<int, StravaActivity> get filteredStravaActivities => _filteredStravaActivities;

  List<Person> get deletedPersons => _deletedPersons;
  List<Bike> get deletedBikes => _deletedBikes;
  List<Component> get deletedComponents => _deletedComponents;
  List<Setup> get deletedSetups => _deletedSetups;
  List<Rating> get deletedRatings => _deletedRatings;

  FilteredData(this.database) {
    _initStreams();
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

    // Deleted item streams (for TrashPage)
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
    // Ported from AppData.resolveData()
    final sortedSetupEntries = _setups.entries.toList();
    sortedSetupEntries.sort((a, b) => a.value.datetime.compareTo(b.value.datetime));
    _setups = Map.fromEntries(sortedSetupEntries);
    
    FileImport.determineCurrentSetups(setups: _setups.values.toList(), bikes: _bikes);
    FileImport.determinePreviousSetups(setups: _setups.values);
    
    for (final setup in _setups.values) {
      _updateSetupsAfter(setup: setup);
    }

    _setupTags = _setups.values.map((s) => s.tags).expand((tags) => tags).toSet();
  }

  void _updateSetupsAfter({required Setup setup}) {
    // Ported from AppData._updateSetupsAfter()
    final setupsList = _setups.values.toList();
    final index = setupsList.indexOf(setup);
    if (index == -1 || index == setupsList.length - 1) return;
    
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
        
        if (adjustment?.category == AdjustmentCategory.nutrition || 
            adjustment?.category == AdjustmentCategory.equipment) {
          continue;
        }
            
        final value = adjustmentValue.value;
        for (final afterPersonSetup in afterPersonSetups) {
          if (afterPersonSetup.personAdjustmentValues.containsKey(adjustmentId)) continue;
          afterPersonSetup.personAdjustmentValues[adjustmentId] = value;
        }
      }
    }
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
}
