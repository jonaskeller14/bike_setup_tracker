import 'package:drift/drift.dart';

@DataClassName('PersonDb')
class Persons extends Table {
  TextColumn get id => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get stravaAthlete => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
