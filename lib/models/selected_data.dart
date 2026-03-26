import 'person.dart';
import 'bike.dart';
import 'component.dart';
import 'setup.dart';
import 'rating.dart';
import 'task_rule.dart';
import 'task_entry.dart';
import 'strava/strava_athlete.dart';
import 'strava/strava_gear.dart';
import 'strava/strava_activity.dart';

class SelectedData {
  final Map<String, Person> persons;
  final Map<String, Bike> bikes;
  final Map<String, Component> components;
  final Map<String, Setup> setups;
  final Map<String, Rating> ratings;
  final Map<String, TaskRule> taskRules;
  final Map<String, TaskEntry> taskEntries;
  final Map<int, StravaAthlete> stravaAthletes;
  final Map<String, StravaGear> stravaGears;
  final Map<int, StravaActivity> stravaActivities;

  SelectedData({
    this.persons = const {},
    this.bikes = const {},
    this.components = const {},
    this.setups = const {},
    this.ratings = const {},
    this.taskRules = const {},
    this.taskEntries = const {},
    this.stravaAthletes = const {},
    this.stravaGears = const {},
    this.stravaActivities = const {},
  });

  factory SelectedData.fromJson(Map<String, dynamic> json) {
    final loadedPersons = (json['persons'] as List<dynamic>? ?? [])
        .map((a) => Person.fromJson(a as Map<String, dynamic>));
    final loadedBikes = (json['bikes'] as List<dynamic>? ?? [])
        .map((a) => Bike.fromJson(a as Map<String, dynamic>));
    final loadedComponents = (json['components'] as List<dynamic>? ?? [])
        .map((a) => Component.fromJson(json: a as Map<String, dynamic>));
    final loadedSetups = (json['setups'] as List<dynamic>? ?? [])
        .map((a) => Setup.fromJson(json: a as Map<String, dynamic>));
    final loadedRatings = (json['ratings'] as List<dynamic>? ?? [])
        .map((a) => Rating.fromJson(json: a as Map<String, dynamic>));
    final loadedTaskRules = (json['taskRules'] as List<dynamic>? ?? [])
        .map((a) => TaskRule.fromJson(a as Map<String, dynamic>));
    final loadedTaskEntries = (json['taskEntries'] as List<dynamic>? ?? [])
        .map((a) => TaskEntry.fromJson(a as Map<String, dynamic>));
    final loadedStravaAthletes = (json['stravaAthletes'] as List<dynamic>? ?? [])
        .map((a) => StravaAthlete.fromJson(a as Map<String, dynamic>));
    final loadedStravaGears = (json['stravaGears'] as List<dynamic>? ?? [])
        .map((g) => StravaGear.fromJson(g as Map<String, dynamic>));
    final loadedStravaActivities = (json['stravaActivities'] as List<dynamic>? ?? [])
        .map((a) => StravaActivity.fromJson(a as Map<String, dynamic>));

    return SelectedData(
      persons: {for (var item in loadedPersons) item.id: item},
      bikes: {for (var item in loadedBikes) item.id: item},
      components: {for (var item in loadedComponents) item.id: item},
      setups: {for (var item in loadedSetups) item.id: item},
      ratings: {for (var item in loadedRatings) item.id: item},
      taskRules: {for (var item in loadedTaskRules) item.id: item},
      taskEntries: {for (var item in loadedTaskEntries) item.id: item},
      stravaAthletes: {for (var item in loadedStravaAthletes) item.id: item},
      stravaGears: {for (var item in loadedStravaGears) item.id: item},
      stravaActivities: {for (var item in loadedStravaActivities) item.id: item},
    );
  }
}
