import 'package:drift/drift.dart';

import '../converters/local_floating_datetime_converter.dart';
import '../converters/placemark_converter.dart';
import '../converters/utc_datetime_converter.dart';
import 'bikes.dart';

@DataClassName('TestSessionDb')
class TestSessions extends Table {
  TextColumn get id => text()();

  TextColumn get bikeId => text().references(Bikes, #id, onDelete: KeyAction.cascade)();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime().map(const UtcDateTimeConverter())();

  TextColumn get name => text().nullable()();

  // JSON-serialized TestSessionMethod; null for a free session.
  TextColumn get method => text().nullable()();

  // JSON lists: ordered adjustment ids, raw goal aspects.
  TextColumn get adjustmentIds => text().withDefault(const Constant('[]'))();
  TextColumn get goal => text().withDefault(const Constant('[]'))();

  // JSON maps of adjustment values, shaped like the backup export.
  TextColumn get locks => text().withDefault(const Constant('{}'))();
  TextColumn get proposals => text().withDefault(const Constant('{}'))();

  DateTimeColumn get startedAtUTC => dateTime().map(const UtcDateTimeConverter())();
  DateTimeColumn get startedAtLocal => dateTime().map(const LocalFloatingDateTimeConverter())();
  DateTimeColumn get endedAtUTC => dateTime().map(const UtcDateTimeConverter()).nullable()();
  DateTimeColumn get endedAtLocal => dateTime().map(const LocalFloatingDateTimeConverter()).nullable()();

  TextColumn get place => text().map(const PlacemarkConverter()).nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
