import 'person.dart';
import 'bike.dart';
import 'setup.dart';
import 'component.dart';
import 'rating.dart';

class Data {
  final Map<String, Person> persons;
  final Map<String, Bike> bikes;
  final List<Setup> setups;
  final List<Component> components;
  final Map<String, Rating> ratings;

  Bike? selectedBike;

  Map<String, Bike> filteredBikes = {};
  Map<String, Person> filteredPersons = {};
  Map<String, Rating> filteredRatings = {};
  List<Component> filteredComponents = [];
  List<Setup> filteredSetups = [];

  Data({
    required this.persons,
    required this.bikes,
    required this.setups,
    required this.components,
    required this.ratings,
  });

  Map<String, dynamic> toJson() => {
    'persons': persons.values.map((p) => p.toJson()).toList(),
    'bikes': bikes.values.map((b) => b.toJson()).toList(),
    'setups': setups.map((s) => s.toJson()).toList(),
    'components': components.map((c) => c.toJson()).toList(),
    'ratings': ratings.values.map((r) => r.toJson()).toList(),
  };

  factory Data.fromJson({required Map<String, dynamic> json}) {
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
    
    return Data(
      persons: <String, Person>{for (var item in loadedPersons) item.id: item},
      bikes: <String, Bike>{for (var item in loadedBikes) item.id: item},
      setups: loadedSetups,
      components: loadedComponents,
      ratings: <String, Rating>{for (var item in loadedRatings) item.id: item},
    );
  }

  void filter() {
    filterBikes();
    filterComponents();
    filterSetups();
    filterPersons();
    filterRatings();
  }

  void filterBikes() {
    filteredBikes = selectedBike == null 
        ? Map.fromEntries(bikes.entries.where((entry) => !entry.value.isDeleted))
        : Map.fromEntries(bikes.entries.where((entry) => !entry.value.isDeleted && entry.value == selectedBike));
  }

  void filterComponents() {
    filteredComponents = selectedBike == null
        ? components.where((c) => !c.isDeleted).toList()
        : components.where((c) => !c.isDeleted && c.bike == selectedBike?.id).toList();
  }

  void filterSetups() {
    filteredSetups = selectedBike == null
        ? setups.where((s) => !s.isDeleted).toList()
        : setups.where((s) => !s.isDeleted && s.bike == selectedBike?.id).toList();
  }

  void filterPersons() {
    filteredPersons = Map.fromEntries(persons.entries.where((entry) => !entry.value.isDeleted));
  }

  void filterRatings() {
    filteredRatings = Map.fromEntries(ratings.entries.where((entry) => !entry.value.isDeleted));
  }

  void onBikeTap(Bike? bike) {
    selectedBike = (bike == null || selectedBike == bike) 
        ? null 
        : selectedBike = bike;
    filterBikes();
    filterComponents();
    filterSetups();
  }
}
