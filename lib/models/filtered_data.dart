import 'package:flutter/material.dart';
import 'app_data.dart';
import 'bike.dart';
import 'component.dart';
import 'person.dart';
import 'setup.dart';
import 'rating.dart';

class FilteredData extends ChangeNotifier {
  AppData _appData;

  // Undeleted Items
  Map<String, Person> _persons = {};
  Map<String, Bike> _bikes = {};
  Map<String, Setup> _setups = {};
  Map<String, Component> _components = {};
  Map<String, Rating> _ratings = {};

  Map<String, Person> get persons => _persons;
  Map<String, Bike> get bikes => _bikes;
  Map<String, Setup> get setups => _setups;
  Map<String, Component> get components => _components;
  Map<String, Rating> get ratings => _ratings;

  // Filtered Items
  Bike? _selectedBike;

  Map<String, Bike> _filteredBikes = {};
  Map<String, Person> _filteredPersons = {};
  Map<String, Rating> _filteredRatings = {};
  Map<String, Component> _filteredComponents = {};
  Map<String, Setup> _filteredSetups = {};

  Bike? get selectedBike => _selectedBike;

  Map<String, Bike> get filteredBikes => _filteredBikes;
  Map<String, Person> get filteredPersons => _filteredPersons;
  Map<String, Rating> get filteredRatings => _filteredRatings;
  Map<String, Component> get filteredComponents => _filteredComponents;
  Map<String, Setup> get filteredSetups => _filteredSetups;

  FilteredData(this._appData);

  void update(AppData newAppData) {
    _appData = newAppData;
    _updateData();
    _filter();
    notifyListeners();
  }

  void _updateData() {
    _bikes = Map.fromEntries(_appData.bikes.entries.where((entry) => !entry.value.isDeleted));
    _components = Map.fromEntries(_appData.components.entries.where((entry) => !entry.value.isDeleted));
    _setups = Map.fromEntries(_appData.setups.entries.where((entry) => !entry.value.isDeleted));
    _persons = Map.fromEntries(_appData.persons.entries.where((entry) => !entry.value.isDeleted));
    _ratings = Map.fromEntries(_appData.ratings.entries.where((entry) => !entry.value.isDeleted));
  }

  void filter() {
    _filter();
    notifyListeners();
  }

  void _filter() {
    if (selectedBike != null && !bikes.containsValue(_selectedBike!)) {
      _selectedBike = null;
    }

    _filterBikes();
    _filterComponents();
    _filterSetups();
    _filterPersons();
    _filterRatings();
  }

  void _filterBikes() {
    _filteredBikes = selectedBike == null 
        ? bikes
        : Map.fromEntries(bikes.entries.where((entry) => entry.value == selectedBike));
  }

  void _filterComponents() {
    _filteredComponents = selectedBike == null
        ? components
        : Map.fromEntries(components.entries.where((entry) => entry.value.bike == selectedBike?.id));
  }

  void _filterSetups() {
    _filteredSetups = selectedBike == null
        ? setups
        : Map.fromEntries(setups.entries.where((entry) => entry.value.bike == selectedBike?.id));
  }

  void _filterPersons() {
    _filteredPersons = _selectedBike == null 
        ? persons
        : Map.fromEntries(persons.entries.where((entry) => entry.value.id == _selectedBike?.person));
  }

  void _filterRatings() {
    _filteredRatings = Map.fromEntries(ratings.entries.where((entry) {
      final rating = entry.value;
      if (rating.isDeleted) return false;

      switch (rating.filterType) {
        case FilterType.global: return true;
        case FilterType.person: return true;
        case FilterType.bike: return _selectedBike == null ? true : rating.filter == _selectedBike!.id;
        case FilterType.component: return _selectedBike == null ? true : filteredComponents.values.any((c) => c.id == rating.filter);
        case FilterType.componentType: return _selectedBike == null ? true : filteredComponents.values.any((c) => c.componentType.toString() == rating.filter);
      }
    }));
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
}
