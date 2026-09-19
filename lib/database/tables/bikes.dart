import 'package:drift/drift.dart';

import '../converters/duration_converter.dart';
import '../converters/utc_datetime_converter.dart';

@DataClassName('BikeDb')
class Bikes extends Table {
  TextColumn get id => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime().map(const UtcDateTimeConverter())();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get person => text().nullable()();
  TextColumn get stravaGear => text().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  RealColumn get initialDistance => real().withDefault(const Constant(0.0))();
  RealColumn get initialElevationGain => real().withDefault(const Constant(0.0))();
  IntColumn get initialMovingTime => integer().withDefault(const Constant(0)).map(const DurationConverter())();
  IntColumn get initialElapsedTime => integer().withDefault(const Constant(0)).map(const DurationConverter())();
  IntColumn get initialActivityCount => integer().withDefault(const Constant(0))();
  RealColumn get initialKilojoules => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}
