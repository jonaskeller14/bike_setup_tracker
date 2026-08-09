import 'package:drift/drift.dart';

import '../converters/utc_datetime_converter.dart';

@DataClassName('PersonDb')
class Persons extends Table {
  TextColumn get id => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime().map(const UtcDateTimeConverter())();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get stravaAthlete => integer().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
