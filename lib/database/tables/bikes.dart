import 'package:drift/drift.dart';

@DataClassName('BikeDb')
class Bikes extends Table {
  TextColumn get id => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get person => text().nullable()();
  TextColumn get stravaGear => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
