import 'package:drift/drift.dart';
import '../converters/utc_datetime_converter.dart';

import '../converters/string_list_converter.dart';
import '../converters/location_data_converter.dart';
import '../converters/placemark_converter.dart';
import '../converters/weather_converter.dart';

import 'bikes.dart';
import 'persons.dart';

@DataClassName('SetupDb')
class Setups extends Table {
  TextColumn get id => text()();

  // A setup always belongs to a bike. Deleting a bike deletes its setups.
  TextColumn get bikeId => text().references(Bikes, #id, onDelete: KeyAction.cascade)();

  // A setup can optionally belong to a person.
  TextColumn get personId =>
      text().nullable().references(Persons, #id, onDelete: KeyAction.setNull)();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime().map(const UtcDateTimeConverter())();

  TextColumn get name => text()();
  DateTimeColumn get datetime => dateTime().map(const UtcDateTimeConverter())(); // UTC
  DateTimeColumn get datetimeLocal => dateTime()();
  TextColumn get notes => text().nullable()();

  TextColumn get tags => text().map(const StringListConverter())();
  TextColumn get position => text().map(const LocationDataConverter()).nullable()();
  TextColumn get place => text().map(const PlacemarkConverter()).nullable()();
  TextColumn get weather => text().map(const WeatherConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
