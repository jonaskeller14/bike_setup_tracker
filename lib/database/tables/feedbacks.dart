import 'package:drift/drift.dart';

import '../converters/context_position_converter.dart';
import '../converters/local_floating_datetime_converter.dart';
import '../converters/placemark_converter.dart';
import '../converters/utc_datetime_converter.dart';
import '../converters/weather_converter.dart';
import 'bikes.dart';
import 'setups.dart';

@DataClassName('FeedbackDb')
class Feedbacks extends Table {
  TextColumn get id => text()();

  TextColumn get bikeId => text().references(Bikes, #id, onDelete: KeyAction.cascade)();

  // Write-once provenance; may dangle once the setup is purged.
  TextColumn get setupId => text().references(Setups, #id)();

  // Soft link: the activity may be deleted or cleared on disconnect.
  IntColumn get stravaActivityId => integer().nullable()();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime().map(const UtcDateTimeConverter())();

  DateTimeColumn get dateTimeUTC => dateTime().map(const UtcDateTimeConverter())();
  DateTimeColumn get dateTimeLocal => dateTime().map(const LocalFloatingDateTimeConverter())();
  TextColumn get notes => text().nullable()();

  TextColumn get position => text().map(const ContextPositionConverter()).nullable()();
  TextColumn get place => text().map(const PlacemarkConverter()).nullable()();
  TextColumn get weather => text().map(const WeatherConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
