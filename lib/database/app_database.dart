import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/todo_rules.dart';
import 'tables/todo_entries.dart';
import 'tables/bikes.dart';
import 'tables/components.dart';
import 'tables/installations.dart';
import 'tables/adjustments.dart';
import 'tables/setups.dart';
import 'tables/setup_adjustment_values.dart';

import 'tables/persons.dart';
import 'tables/ratings.dart';
import 'tables/strava/strava_activities.dart';
import 'tables/strava/strava_athletes.dart';
import 'tables/strava/strava_gears.dart';

import 'daos/bikes_dao.dart';
import 'daos/components_dao.dart';
import 'daos/setups_dao.dart';
import 'daos/persons_dao.dart';
import 'daos/ratings_dao.dart';
import 'daos/todo_dao.dart';
import 'daos/strava_dao.dart';

// Import the App Models so that Drift generator can find the Enums
import '../models/todo_rule.dart';
import '../models/component.dart';
import '../models/adjustment/adjustment.dart';
import '../models/rating.dart';
import '../models/strava/strava_activity.dart';

import 'package:geocoding/geocoding.dart' as geo;

import 'converters/string_list_converter.dart';
import 'converters/location_data_converter.dart';
import 'converters/placemark_converter.dart';
import 'converters/weather_converter.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  TodoRules,
  TodoEntries,
  Bikes,
  Components,
  Adjustments,
  Installations,
  Setups,
  SetupAdjustmentValues,
  Persons,
  Ratings,
  StravaActivities,
  StravaAthletes,
  StravaGears,
], daos: [
  BikesDao,
  ComponentsDao,
  SetupsDao,
  PersonsDao,
  RatingsDao,
  TodoDao,
  StravaDao,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // DAOs
  late final BikesDao bikesDao = BikesDao(this);
  late final ComponentsDao componentsDao = ComponentsDao(this);
  late final SetupsDao setupsDao = SetupsDao(this);
  late final PersonsDao personsDao = PersonsDao(this);
  late final RatingsDao ratingsDao = RatingsDao(this);
  late final TodoDao todoDao = TodoDao(this);
  late final StravaDao stravaDao = StravaDao(this);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'bike_setup_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
