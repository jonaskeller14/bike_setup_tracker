import 'package:drift/drift.dart';

import '../converters/local_floating_datetime_converter.dart';
import '../converters/location_data_converter.dart';
import '../converters/placemark_converter.dart';
import '../converters/utc_datetime_converter.dart';
import '../converters/weather_converter.dart';
import 'bikes.dart';
import 'setups.dart';

@DataClassName('RatingEntryDb')
class RatingEntries extends Table {
  TextColumn get id => text()();

  TextColumn get bikeId => text().references(Bikes, #id, onDelete: KeyAction.cascade)();
  TextColumn get setupId => text().references(Setups, #id)();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime().map(const UtcDateTimeConverter())();

  TextColumn get name => text().nullable()();
  DateTimeColumn get dateTimeUTC => dateTime().map(const UtcDateTimeConverter())();
  DateTimeColumn get dateTimeLocal => dateTime().map(const LocalFloatingDateTimeConverter())();
  TextColumn get notes => text().nullable()();

  TextColumn get position => text().map(const LocationDataConverter()).nullable()();
  TextColumn get place => text().map(const PlacemarkConverter()).nullable()();
  TextColumn get weather => text().map(const WeatherConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
